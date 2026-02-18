# /runbooks/az-104/azure-activity-log-vs-sign-in-log-correlation.md

Tag: A/B

# Azure Activity log vs sign-in log correlation

## Symptoms

- You see a destructive or suspicious Azure change, but you cannot prove who did it
- Activity Log shows a caller, but you cannot tie it to an actual interactive sign-in event
- A change appears to come from “Microsoft Azure” or an app, not a user
- You need to answer: who initiated the action, from where, and using what auth method

## Scope

Covers:

- Correlating Azure Activity Log events (control plane) with Entra sign-in logs (authentication)
- Determining whether an action was:
  - interactive user
  - app / service principal
  - managed identity
  - automation (CLI, PowerShell, Terraform, GitHub Actions, pipelines)
- Building a repeatable evidence trail suitable for incident notes and audits

Not covered:

- Data plane logging (Storage data access, Key Vault data access, SQL auditing)
- Full SIEM correlation beyond basic tenant evidence collection

## Preconditions

- You have:
  - Subscription ID and target resource ID or resource group
  - Approximate time window of the event
- Minimum roles (least privilege):
  - Azure Activity Log read:
    - Reader on subscription (or Monitoring Reader) is typically sufficient to view Activity Log
  - Entra sign-in logs read:
    - Global Reader or Security Reader usually works, or specific audit log roles depending on tenant config
- Optional but strongly recommended:
  - Log Analytics workspace receiving Activity Log and Entra sign-in logs (cleanest correlation)
  - Your repo scripts for exporting logs:
    - `/scripts/entra-export-signinlogs.ps1`
    - `/scripts/entra-export-auditlogs.ps1`

## Triage checklist

1. Identify the exact Activity Log event(s)
   - operation name, resource ID, time, status, caller
2. Determine identity type from Activity Log
   - user UPN, appId, service principal, managed identity, or unknown
3. Capture correlation identifiers
   - correlationId, operationId, claims (if present)
4. Pull the matching sign-in record(s) for the same identity and time window
5. Decide if the action was interactive or non-interactive
6. Preserve evidence artifacts and timeline

## Fix steps

### Step 1: Pull the Activity Log event first

Portal path:

- Monitor -> Activity log
- Filter:
  - Subscription
  - Resource group or Resource
  - Timespan (tight window)
  - Event categories: Administrative (start here)

Capture these fields from the event details:

- Event timestamp (UTC)
- Operation name (e.g., Microsoft.Compute/virtualMachines/write)
- Status (Succeeded/Failed)
- Resource ID
- Caller
- Correlation ID
- Event initiated by (if present)
- JSON tab content (redacted later)

Evidence:

- Save event JSON and a redacted screenshot:
  - `/evidence/runbooks-az-104-azure-activity-log-vs-sign-in-log-correlation/exports/activitylog-event-<date>.json`
  - `/evidence/runbooks-az-104-azure-activity-log-vs-sign-in-log-correlation/screenshots/activitylog-event-details-<date>.png`

### Step 2: Classify the caller

Use the Activity Log “Caller” to decide which path you are on:

A) Caller is a user UPN (looks like a person)
- Expect an interactive sign-in near the timestamp

B) Caller is an appId or service principal name
- Expect non-interactive sign-in (service principal sign-in) or workload identity
- Might be automation: Terraform, pipeline, GitHub Actions

C) Caller looks like a managed identity
- Treat like workload identity and look for service principal sign-in patterns

D) Caller is blank or generic
- Use the event JSON Claims field (if present) to extract:
  - oid (object id)
  - appid (application id)
  - upn
  - tid (tenant id)

Record the classification in notes.md.

### Step 3: Pull matching Entra sign-in logs

Goal: find the authentication event that enabled the change.

Minimum matching strategy:

- Same identity (UPN or service principal)
- Tight time window (start with plus or minus 15 minutes)
- Match resource and client type where possible:
  - Azure Resource Manager is common for control plane actions
  - Client app: Browser, Azure CLI, Azure PowerShell, Terraform, etc.

Portal path:

- Entra admin center -> Sign-in logs
- Filter:
  - User or Application
  - Date range
  - Resource (look for “Azure Resource Manager” entries when relevant)

Scripted evidence collection:

- Use your existing script and set a narrow time range and a filter for the identity involved:
  - `/scripts/entra-export-signinlogs.ps1`

Evidence:

- `/exports/signins-<identity>-<date>.json` or `.csv`
- `/screenshots/signin-details-<date>.png`

### Step 4: Correlate using hard keys

Best correlation keys, in order:

1) Time proximity + same identity
- Often enough when time window is tight

2) Correlation ID
- If the Activity Log includes a correlationId, compare it to sign-in details where available

3) IP address and device info
- Sign-in record has IP, location, device, client app
- Use this to attribute the change to a workstation or automation runner

4) Resource and client app
- For interactive:
  - Client app might show Browser, Azure Portal
- For automation:
  - Azure CLI, Azure PowerShell, or “Other clients”
  - App display name indicates pipeline identity

Write a short correlation statement:

- “Activity Log event X at time Y was initiated by identity Z. Closest sign-in was at time Y minus N minutes from IP A using client app B. Therefore this action was interactive / automated.”

### Step 5: Determine interactive vs automation

Interactive indicators:

- Sign-in record exists for the user with MFA and a normal user agent
- Conditional Access details make sense (device compliant, MFA, etc.)
- Activity Log “Caller” is the user UPN

Automation indicators:

- Caller is an app or managed identity
- Sign-in logs show service principal sign-ins
- IP is a hosted runner or data center
- Client app shows Azure CLI/Azure PowerShell used by a pipeline identity
- No user sign-in near the event time

If you cannot find a sign-in:

- Expand the time window to 60 minutes
- Confirm you are searching the correct log type:
  - user sign-ins vs service principal sign-ins
- Confirm sign-in logging is retained long enough (retention limitations exist)
- Check if the action came from an internal Azure process or managed service operation

### Step 6: Document and preserve evidence

Update:

- notes.md:
  - what happened, what was changed, who initiated, and how you proved it
- timeline.md:
  - include exact UTC timestamps for sign-in and activity event
- If an incident:
  - include remediation actions and any access changes taken (PIM, role removal, token revoke, etc.)

## Verification

- You can point to:
  - the exact Activity Log event JSON
  - the matching sign-in record(s)
  - the identity type classification (user vs app vs managed identity)
  - the correlation statement with timestamps and IP/client app
- A second reviewer can reproduce your findings from the evidence artifacts

## Prevention

- Send Activity Log to Log Analytics for longer retention and faster queries
- Enable and retain Entra sign-in logs appropriately for your environment
- Require MFA and strong Conditional Access for admin actions
- Use PIM for privileged role activation and keep eligible elevation time-bounded
- For automation:
  - use workload identity or managed identity
  - keep RBAC scopes narrow
  - log and tag deployments so Activity Log entries can be mapped to pipeline runs

## Rollback

If the change was unauthorized or incorrect:

1. Reverse the resource change (restore config, redeploy last known good)
2. Remove or reduce the RBAC assignment that enabled the action
3. Revoke sessions or rotate credentials for the identity involved
4. Capture follow-up Activity Log events for the rollback actions
5. Record final state and closeout notes

## Evidence to collect

Store under: `/evidence/runbooks-az-104-azure-activity-log-vs-sign-in-log-correlation/`

- `exports/`
  - `activitylog-event-<date>.json`
  - `activitylog-query-results-<date>.json`
  - `signins-user-<date>.csv` or `.json`
  - `signins-spn-<date>.csv` or `.json` (if automation)
- `screenshots/` (redacted)
  - `activitylog-event-details-<date>.png`
  - `signin-details-<date>.png`
- `commands/`
  - `log-export-commands-<date>.txt` (CLI/PowerShell used)
- `notes.md`
  - correlation statement, identity type, and conclusion
- `timeline.md`
  - UTC timestamps for sign-in and action, plus any follow-ups

## Next 3 actions

1. Create `/runbooks/az-104/azure-activity-log-vs-sign-in-log-correlation.md` with this content and commit it.
2. In your lab, perform one Azure resource change via portal and one via Azure CLI, then correlate both using Activity Log + sign-in logs and save evidence artifacts.
3. Add a short “interactive vs automation indicators” checklist to notes.md after your lab run based on what you actually observed in your tenant.
