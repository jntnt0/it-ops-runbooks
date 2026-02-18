# /runbooks/az-104/azure-rbac-in-practice.md

Tag: A/B

# Azure RBAC in practice

## Symptoms

- Someone has Owner on a whole subscription “just to do one thing”
- Devs can edit prod resources (or prod can edit dev) because scopes are sloppy
- Helpdesk can’t do routine actions without asking for Global Admin
- Automation runs under Owner/Contributor at subscription root with no guardrails
- Access reviews are impossible because assignments are user-to-role direct and scattered
- You can’t answer: “who can delete this resource group right now”

---

## Scope

Covers:

- Practical Azure RBAC implementation using groups, scopes, and role hygiene
- Role assignments at management group, subscription, resource group, and resource scope
- Directory roles vs Azure RBAC (stop mixing them)
- Custom roles when built-ins don’t fit
- Privileged Identity Management (PIM) patterns if licensing exists (document if it doesn’t)
- Evidence collection for audits and troubleshooting

Not covered:

- Azure AD/Entra directory role governance beyond “don’t use it to solve Azure RBAC”
- Advanced policy-as-code governance (Blueprints legacy, full enterprise landing zones)

---

## Preconditions

- You can sign into Azure portal and run Azure CLI or PowerShell
- You know the target scope(s): subscription, resource group, or resource IDs
- You have a clear list of tasks to permit (not vague job titles)

Minimum roles (least privilege) to execute changes:

- To create/remove role assignments: User Access Administrator at the target scope
  - Owner also works but don’t normalize it
- To create custom role definitions: Owner (or equivalent permission to create role definitions) at the scope where role definition is stored
- To manage groups in Entra ID: Groups Administrator (or equivalent) if you’re building security groups for RBAC
- If using PIM: the appropriate PIM admin role(s) in Entra, plus licensing (tenant reality varies)

---

## Triage checklist

1. What exact task is being requested (create VM, restart App Service, read logs, manage network, etc.)?
2. What is the narrowest scope that satisfies the task?
   - Resource > Resource Group > Subscription > Management Group
3. Is this Azure RBAC or an Entra directory role problem?
   - If it’s “manage Azure resources,” it’s Azure RBAC.
4. Is the access needed all the time or only occasionally?
5. Is the principal a user, group, service principal, or managed identity?
6. Are there existing assignments creating overlap or accidental privilege?
7. Is there a break-glass path if you lock yourself out?

---

## Fix steps

### Step 1: Inventory current access at the target scope

Goal: know what you’re about to break.

Azure CLI (pick the scope you care about):

- Subscription:
  - `az role assignment list --scope /subscriptions/<subId> -o table`
- Resource group:
  - `az role assignment list --scope /subscriptions/<subId>/resourceGroups/<rgName> -o table`
- Specific resource:
  - `az role assignment list --scope <resourceId> -o table`

PowerShell (Az):

- `Get-AzRoleAssignment -Scope "/subscriptions/<subId>" | Select-Object DisplayName,SignInName,RoleDefinitionName,Scope`

Evidence:
- Save exports under:
  - `/evidence/runbooks-az-104-azure-rbac-in-practice/exports/role-assignments-<scope>-<date>.json`
  - `/evidence/runbooks-az-104-azure-rbac-in-practice/commands/role-assignments-<scope>-<date>.txt`

---

### Step 2: Stop assigning roles directly to users

Rule: user-to-role direct assignments are how RBAC turns into a junk drawer.

Pattern:

- Create an Entra security group per function + environment + scope
  - Example naming (use your repo’s naming standards if different):
    - `AZ-RBAC-Prod-RG-App1-Readers`
    - `AZ-RBAC-Dev-Sub-MySub-Contributors`
    - `AZ-RBAC-Shared-RG-Network-Operators`

Then assign roles to the group, not the user.

Evidence:
- Screenshot or export the group object and membership list (redacted) into:
  - `/evidence/.../exports/groups-<date>.json`
  - `/evidence/.../screenshots/group-membership-<date>.png` (redacted)

---

### Step 3: Choose the smallest built-in role that works

Common built-in roles (practical use):

- Reader: view only (safe default)
- Contributor: can manage resources but cannot grant access
- User Access Administrator: can grant access (treat as privileged)
- Network Contributor: network resources without full Contributor everywhere
- Virtual Machine Contributor: manage VMs without broad rights
- Storage Blob Data Contributor: data-plane access (different from management-plane)

Rules that keep you out of trouble:

- Don’t give Owner to solve “I can’t deploy”
- Don’t give Contributor at subscription root when only one RG is involved
- Separate management-plane and data-plane needs (RBAC role choice changes)

---

### Step 4: Assign at the correct scope (and document why)

Assign at:

- Resource scope if it’s one resource and sensitive (Key Vault, specific storage account)
- RG scope for an app boundary
- Subscription scope only for platform team duties
- Management group scope only when you truly need it everywhere

Azure CLI examples:

- Assign Reader to group at RG scope:
  - `az role assignment create --assignee-object-id <groupObjectId> --assignee-principal-type Group --role Reader --scope /subscriptions/<subId>/resourceGroups/<rgName>`

- Assign Contributor to group at a resource scope:
  - `az role assignment create --assignee-object-id <groupObjectId> --assignee-principal-type Group --role Contributor --scope <resourceId>`

Evidence:
- Capture the exact command used and the resulting assignment ID output.
- Store in:
  - `/evidence/.../commands/role-assignment-create-<date>.txt`

---

### Step 5: Validate with an actual access test (not vibes)

Do one of these:

- Use “Check access” in the Azure portal for the user
- Have the user sign in and perform the exact task they requested
- If you can’t use the real user, use a test user placed in the RBAC group

Minimum validation checklist:

- User can do the required task
- User cannot do clearly out-of-scope actions (delete RG, grant access, modify prod if they’re dev)
- Activity log shows the expected principal performing the action

Evidence:
- Activity Log export for the tested action:
  - `/evidence/.../exports/activity-log-<date>.json`
- Screenshot of “Check access” summary (redacted)

---

### Step 6: Tighten automation identities (service principals / managed identities)

Bad pattern: pipeline SP has Contributor on the whole subscription forever.

Better pattern:

- Give the identity only what it needs, at the narrowest scope
- Prefer managed identity when possible (less secret handling)
- Split identities by environment (dev and prod should not share a principal)

Evidence commands:

- `az role assignment list --assignee <appId-or-objectId> -o json`
- Store in:
  - `/evidence/.../exports/automation-role-assignments-<date>.json`

---

### Step 7: Optional: implement just-in-time elevation with PIM (if available)

If tenant licensing supports PIM and you can use it, do it.

Practical approach:

- Permanent low privilege via group RBAC (Reader or narrow Contributor)
- Eligible elevation for high privilege roles (User Access Administrator, Owner) with:
  - Approval (if you can enforce it)
  - MFA requirement
  - Time bound activation
  - Reason required

If you cannot use PIM due to licensing, document that gap in notes and keep Owner assignments rare, explicit, and reviewed.

Evidence:
- Screenshot/export of eligible role assignment policy (redacted)
- A single activation record (redacted) to prove it works

---

## Verification

- Role assignments exist only at intended scopes
- Users are in groups, and groups are assigned roles (minimal direct user assignments)
- No unreviewed Owners at subscription scope except documented break-glass
- Automation identities have scoped roles and are not subscription-wide Contributors unless justified
- You can answer “who can do X” using a single group and a single scope assignment
- Activity Log entries show expected principals for changes

---

## Prevention

- Establish a default policy: no direct user RBAC unless exception is documented
- Standardize group naming and scope mapping (env + scope + role)
- Monthly review:
  - Owners, User Access Administrator assignments
  - Subscription-scope Contributors
  - Automation principals with broad rights
- Add a lightweight “RBAC request form” requirement:
  - Task, scope, duration, justification, approver
- For labs: create a repeatable RBAC demo scenario (dev RG + test user + 3 role groups) and keep the evidence current

---

## Rollback

If access change caused impact:

1. Remove the role assignment you just created (don’t guess, remove the exact assignment)
   - CLI: `az role assignment delete --assignee-object-id <groupObjectId> --role <roleName> --scope <scope>`
2. Re-add the previous known-good assignment (from your inventory export)
3. Confirm the affected user’s task works again
4. Update notes.md with what broke and why your scope/role choice was wrong

---

## Evidence to collect

Store under: `/evidence/runbooks-az-104-azure-rbac-in-practice/`

- `commands/`
  - `az-role-assignment-list-<scope>-<date>.txt`
  - `az-role-assignment-create-<date>.txt`
  - `az-role-assignment-delete-<date>.txt` (if rollback)
- `exports/`
  - `role-assignments-<scope>-<date>.json`
  - `groups-<date>.json` (redacted)
  - `activity-log-<date>.json`
  - `automation-role-assignments-<date>.json`
- `screenshots/` (redacted)
  - `check-access-<user>-<date>.png`
  - `iam-scope-assignments-<date>.png`
  - `pim-eligible-assignment-<date>.png` (if applicable)
- `notes.md`
  - What was requested, what was granted, at what scope, and why
- `timeline.md`
  - T0 request, T1 change, T2 verification, T3 follow-up

---

## Next 3 actions

1. Create this file at `/runbooks/az-104/azure-rbac-in-practice.md` and commit it.
2. Run a lab demo: create 3 RBAC groups (Reader, Contributor, UAA) for one RG, assign roles, then validate with a test user and export Activity Log.
3. Add a short entry in the runbook notes on whether PIM is available in your tenant, and if not, what your “no-PIM” control is (review cadence + strict scope limits).
