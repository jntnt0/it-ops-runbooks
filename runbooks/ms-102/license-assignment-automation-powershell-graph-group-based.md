# /runbooks/ms-102/license-assignment-automation-powershell-graph-group-based.md

Tag: A/B

# License assignment automation (PowerShell + Graph, group-based)

## Symptoms

- Users missing licenses after onboarding
- Licenses assigned manually and inconsistently
- Wrong SKU assigned (SKU sprawl)
- Users keep licenses after offboarding
- License exhaustion due to poor reclamation
- “It worked for one user” but fails at scale

---

## Scope

Covers Microsoft 365 licensing automation using:

- Group-based licensing (primary, preferred)
- PowerShell + Microsoft Graph for reporting and guardrails
- Safe removal patterns during offboarding

Applies to:

- Entra ID users and groups
- Microsoft 365 license SKUs and service plans
- Onboarding/offboarding workflows

Excludes:

- Azure subscription licensing/cost (AZ-104 cost runbooks)
- Application-specific entitlement beyond licensing (separate runbooks)

---

## Preconditions

- Licensing model defined (which SKUs are standard for which roles)
- Security groups exist per license bundle
- Group-based licensing enabled/used in tenant
- Graph PowerShell SDK installed for reporting scripts
- Change control for new SKUs or license bundles

Minimum roles (least privilege):

- License Administrator (assign/remove licenses, manage group-based licensing)
- User Administrator (user lifecycle actions)
- Global Reader (reporting)
- Privileged Role Administrator (only if you manage elevated roles; not needed for licensing)

---

## Triage Checklist

Before automating:

1) Inventory SKUs and identify “approved bundles”
2) Identify what should be licensed by group vs exceptions
3) Confirm group naming convention
4) Confirm licensing is not already driven by conflicting processes
5) Confirm offboarding process removes group membership
6) Confirm you can report current license state reliably

---

## Fix Steps

### Step 1: Standardize license bundles as groups (the only sane model)

Create security groups like:

- `lic-m365-e3-standard`
- `lic-m365-bp-standard`
- `lic-exo-plan1-only`
- `lic-teams-phone`

Rules:

- Users get licenses by group membership only
- No direct per-user licensing except temporary break-fix
- Every exception must have:
  - reason
  - owner
  - expiry date

Assign licenses to groups in Entra:

Entra admin center -> Groups -> select group -> Licenses -> Assign

---

### Step 2: Automate assignment by role mapping (joiner/mover)

Onboarding flow:

1) Create user
2) Add user to:
   - role group(s) (department/job based)
   - license group(s) (bundle)
3) Validate provisioning

Mover flow:

1) Remove old role/license groups
2) Add new role/license groups
3) Verify license impact

Leaver flow:

1) Remove from all license groups
2) Confirm license reclaimed after mailbox handling steps

---

### Step 3: Graph reporting script (safe proof and drift detection)

Use Graph to:

- List SKUs in tenant
- List group-based license assignments
- Find users with direct licenses (policy violations)
- Find users missing required licenses (drift)
- Export results to evidence folder

Example: list users with direct license assignment (not group-based)

```powershell
# Requires Microsoft.Graph module
Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All"

$users = Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,AssignedLicenses,LicenseAssignmentStates
$direct = foreach ($u in $users) {
  $states = $u.LicenseAssignmentStates
  if ($states) {
    $directStates = $states | Where-Object { $_.AssignedByGroup -eq $null -and $_.State -eq "Active" }
    if ($directStates.Count -gt 0) {
      [pscustomobject]@{
        UserPrincipalName = $u.UserPrincipalName
        DisplayName       = $u.DisplayName
        DirectSkuCount    = $directStates.Count
      }
    }
  }
}
$direct | Sort-Object DirectSkuCount -Descending
