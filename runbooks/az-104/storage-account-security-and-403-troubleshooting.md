# /runbooks/az-104/storage-account-security-and-403-troubleshooting.md

Tag: A/B

# Storage account security + 403 troubleshooting

## Symptoms

- 403 from Storage (Blob/ADLS Gen2/File/Queue/Table) when accessing from:
  - Azure portal
  - AzCopy
  - Azure CLI / PowerShell
  - App code (SDK)
- Error messages like:
  - AuthorizationFailure
  - AuthorizationPermissionMismatch
  - AuthenticationFailed
  - This request is not authorized to perform this operation
  - PublicAccessNotPermitted
  - AccountRequiresAuthorization
- Upload works but list/read fails (or vice versa)
- Access works from one network, fails from another
- Access works for one identity, fails for another
- SAS works but Entra auth fails (or vice versa)

## Scope

Covers:

- Management plane vs data plane permissions
- Entra RBAC vs shared key vs SAS
- Storage firewall, trusted services, private endpoints, and DNS
- Blob container public access and account-level settings
- Diagnosing 403 causes using logs and portal/CLI checks

Not covered:

- Deep application code debugging beyond confirming auth method and request path
- Non-Azure network edge devices (collect evidence and hand off)

## Preconditions

You must know:

- Storage account name, resource group, subscription
- Which service: Blob, ADLS Gen2, File, Queue, Table
- Which auth method is being used:
  - Entra ID (recommended)
  - SAS
  - Account key (shared key)
  - Managed identity
- The client source:
  - Public internet, VNet, peered VNet, on-prem, Azure service, etc.

Minimum roles (least privilege):

- Reader at storage account scope to inspect configuration
- Storage Account Contributor or Contributor to change account settings
- For Entra data plane access using RBAC:
  - Storage Blob Data Reader / Contributor / Owner as needed
  - Storage Queue Data Contributor, etc. depending on service
- To view diagnostic logs in Log Analytics:
  - Log Analytics Reader (workspace)
  - Or Reader on the resource if logs are in a storage account you control

## Triage checklist

1. Confirm what is failing
   - List containers, list blobs, read blob, write blob, delete blob, get properties
2. Identify auth method in use
   - Entra token, SAS, shared key, managed identity
3. Confirm scope of access
   - Specific container vs whole account
4. Confirm network path
   - Storage firewall restrictions, private endpoint, DNS resolution
5. Confirm time and clock skew if SAS is involved
6. Confirm whether “Allow storage account key access” is disabled
7. Confirm “Public network access” and whether client is on an allowed network
8. Confirm which identity is used and what data-plane RBAC role is assigned
9. Check logs for the 403
   - Storage diagnostic logs, Activity log, or client logs

## Fix steps

### Step 1: Classify the 403: management plane or data plane

This is where people waste hours.

- If the error happens while changing settings in Azure portal (creating container, changing firewall, enabling features):
  - That is management plane and is controlled by Azure RBAC roles like Contributor / Storage Account Contributor.
- If the error happens while reading/writing blobs/files/queues/tables:
  - That is data plane and is controlled by:
    - Entra data roles (Storage Blob Data Contributor, etc.)
    - Or SAS/shared key

Evidence:

- Record the exact operation and where it fails in:
  - `/evidence/runbooks-az-104-storage-account-security-and-403-troubleshooting/notes.md`

### Step 2: Identify the auth method actually used

Common reality:

- Portal can use your Entra identity for some operations, but tools might be using shared key or SAS.
- Applications might be using managed identity while you test with your user account.

Quick indicators:

- Azure CLI:
  - `az storage blob list ...` with no auth flags often defaults to key unless configured
  - Use explicit `--auth-mode login` to force Entra
- AzCopy:
  - `azcopy login` indicates Entra auth
  - SAS URLs indicate SAS auth
- SDK:
  - DefaultAzureCredential suggests Entra/managed identity path
  - Connection string suggests shared key path

Fix:

- Make auth explicit during troubleshooting.
- For Entra tests, force Entra:
  - Azure CLI: `--auth-mode login`
  - PowerShell: use Az + storage cmdlets that support OAuth and avoid connection strings

Evidence:

- Save the command and output:
  - `/commands/auth-method-<date>.txt`

### Step 3: Check storage account security posture that commonly triggers 403

Portal checks (Storage account):

- Networking:
  - Public network access: Enabled/Disabled/Selected networks
  - Firewall rules: allowed IPs, VNets
  - Private endpoint connections
- Data protection / configuration:
  - Allow Blob public access (account-level)
  - Allow storage account key access (if disabled, shared key requests will 403)
  - Minimum TLS version
  - Shared access signature policy (if set)
- Authorization model:
  - If using ADLS Gen2: hierarchical namespace enabled (affects ACLs)
  - If using “Azure RBAC” only model, verify your tooling is using it

Evidence screenshots (redacted):

- `/screenshots/storage-networking-<date>.png`
- `/screenshots/storage-configuration-<date>.png`

### Step 4: Confirm Entra data-plane RBAC role assignment (if using Entra)

At the correct scope:

- Storage account scope is usually simplest for labs
- Container scope is tighter for real environments

Roles to use (Blob):

- Read only: Storage Blob Data Reader
- Read/write: Storage Blob Data Contributor
- Manage ACLs/ownership scenarios: Storage Blob Data Owner (use cautiously)

Portal:

- Storage account > Access control (IAM) > Role assignments
- Ensure you are looking at the right principal (user/group/service principal/managed identity)

CLI:

- `az role assignment list --scope /subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<saName> -o table`

Fix:

- Assign role to a group, then add users to the group. Stop direct user assignments unless lab.

Important gotcha:

- Role assignment propagation takes time. If you test instantly, you may still get 403 briefly.

Evidence:

- `/exports/role-assignments-<date>.json`
- `/screenshots/iam-role-assignments-<date>.png`

### Step 5: If ADLS Gen2 is involved, check POSIX-style ACLs too

If hierarchical namespace is enabled:

- RBAC can grant you access but ACLs can still deny you.
- For file system paths, you may need both RBAC and ACL permissions.

Checks:

- Storage account > Data storage > Containers (file systems) > Access control (ACL)
- Confirm execute permissions on parent paths (classic reason for “can’t list”)

Fix:

- Add the required ACL entries to the path or parent path, not just the leaf object.

Evidence:

- `/screenshots/adls-acl-<path>-<date>.png`
- Note the path and ACL change in notes.md.

### Step 6: Validate networking (firewall/private endpoints/DNS)

If storage networking is “Selected networks” or “Disabled public access”:

- Requests from outside allowed networks will be blocked.
- Depending on service and configuration, that can surface as 403 or timeouts.

Private endpoint specific:

- DNS must resolve the storage endpoint to the private IP:
  - `nslookup <account>.blob.core.windows.net`
- If it resolves to public IP, you are not using the private DNS zone or not linked to the VNet.

Portal checks:

- Private endpoint connection state: Approved
- Private DNS zone linked to correct VNet
- Client is actually inside the VNet (or has forwarding into it)

Fix:

- For quick lab validation: temporarily allow your public IP in firewall
- For real design: private endpoint + private DNS zone + correct VNet link

Evidence:

- `/commands/dns-<date>.txt`
- `/screenshots/private-endpoint-<date>.png`
- `/screenshots/private-dns-zone-link-<date>.png`

### Step 7: SAS and shared key specific causes

SAS failures:

- Clock skew
- Start time not yet valid
- Expired SAS
- Wrong permissions (sp= missing read/list/write)
- Wrong resource type or service

Shared key failures:

- “Allow storage account key access” disabled
- Wrong key used (rotated)
- Using connection string for the wrong account

Fix:

- For SAS: regenerate with correct perms and time window, set start time slightly in the past
- For shared key: either re-enable key access (if policy allows) or migrate to Entra auth

Evidence:

- Store the SAS parameters and reason (redacted):
  - `/notes.md` with token stripped
- Store key access setting screenshot:
  - `/screenshots/key-access-setting-<date>.png`

### Step 8: Pull logs to confirm the deny reason

Where to look:

- Storage diagnostic logs (recommended if enabled)
- Activity log for management-plane changes
- Client-side logs (AzCopy has logs, SDK logs)

In Log Analytics (if configured):

- Query Storage logs for status 403 and caller identity
- Correlate timestamp to your test command

Fix:

- Use logs to identify whether it was:
  - Auth method mismatch
  - Missing role
  - Network deny
  - ACL deny

Evidence:

- `/exports/diagnostic-logs-403-<date>.csv` (redacted)
- `/screenshots/log-query-403-<date>.png`

## Verification

You are done only when:

- The same command that failed now succeeds using the intended auth method
- You can show:
  - Correct data-plane role assignment at the correct scope
  - Effective network access path (public allowed IP or private endpoint + correct DNS)
  - If ADLS: ACLs permit path traversal and access
- You removed any temporary broad firewall exception used for testing

Verification commands:

- Azure CLI (force Entra):
  - `az storage blob list --account-name <saName> --container-name <container> --auth-mode login -o table`
- AzCopy:
  - `azcopy ls "https://<saName>.blob.core.windows.net/<container>"` (with Entra login or SAS)

## Prevention

- Standardize on Entra auth for data access; avoid shared key in anything modern
- Use groups for data-plane RBAC and keep assignments at appropriate scope
- Enable diagnostic logs for Storage and route to Log Analytics
- If using private endpoints, treat private DNS as part of the deployment, not an afterthought
- For ADLS Gen2, include ACL review in every access change runbook
- Document a “break glass” access method that is controlled and audited (not random account keys)

## Rollback

If your change caused impact:

1. Revert firewall/networking changes first (restore previous selected networks)
2. Remove temporary RBAC assignments added for testing
3. Revert ACL changes (ADLS) if they expanded access too broadly
4. Rotate any SAS tokens or keys if they were exposed during troubleshooting
5. Confirm original intended access still works and unauthorized access is blocked

## Evidence to collect

Store under: `/evidence/runbooks-az-104-storage-account-security-and-403-troubleshooting/`

- `commands/`
  - `source-tests-<date>.txt` (az/azcopy/test-netconnection)
  - `auth-method-<date>.txt`
  - `dns-<date>.txt`
- `exports/`
  - `role-assignments-<date>.json`
  - `diagnostic-logs-403-<date>.csv` (redacted)
  - `activity-log-<date>.json`
- `screenshots/` (redacted)
  - `storage-networking-<date>.png`
  - `storage-configuration-<date>.png`
  - `iam-role-assignments-<date>.png`
  - `private-endpoint-<date>.png`
  - `private-dns-zone-link-<date>.png`
  - `adls-acl-<path>-<date>.png` (if applicable)
  - `log-query-403-<date>.png`
- `notes.md`
  - Operation attempted, auth method, deny reason, fix applied
- `timeline.md`
  - T0 report, T1 classification, T2 config checks, T3 change, T4 verify, T5 cleanup

## Next 3 actions

1. Create `/runbooks/az-104/storage-account-security-and-403-troubleshooting.md` with this content and commit it.
2. In your lab, reproduce a 403 in two ways (missing Blob Data role and storage firewall block), then resolve both and save logs/evidence.
3. Add a short “default stance” section to your notes after the lab: Entra auth first, no shared keys, private endpoints require private DNS, ADLS requires ACL review.
