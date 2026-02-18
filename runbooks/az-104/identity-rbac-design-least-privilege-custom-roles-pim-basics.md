# /runbooks/az-104/identity-rbac-design-least-privilege-custom-roles-pim-basics.md

Tag: A/B

# Role-based access control design (Least privilege, custom roles, PIM basics)

## Symptoms

- Too many Global Admins or Owner roles “because it’s easier”
- Users have access to resources they should not manage
- Helpdesk cannot perform routine tasks without over-privileged roles
- No clear answer to “who changed this” or “who can change this”
- Automation uses high privilege identities with no guardrails
- Privileged roles are permanent instead of time-bound

---

## Scope

Covers:

- Azure RBAC design (management groups, subscriptions, resource groups, resources)
- Entra ID directory roles vs Azure RBAC roles
- Least privilege role assignment patterns
- Custom role design and safe use
- Privileged Identity Management (PIM) basics for time-bound elevation
- Break glass handling for privileged access

Applies to:

- Azure resources (AZ-104)
- Entra ID administrative roles that impact Azure governance
- Automation identities (service principals, managed identities)

---

## Preconditions

- Azure subscription with ability to create RBAC assignments
- Access to Microsoft Entra admin center and Azure portal
- Licensing for PIM (tenant reality varies; document gaps if unavailable)
- Naming standards for groups and roles

Minimum roles (least privilege):

- For Azure RBAC: User Access Administrator at required scope (or Owner temporarily during build)
- For custom roles: Owner or User Access Administrator plus ability to create role definitions
- For PIM (if used): Privileged Role Administrator (directory) / appropriate PIM admin role

---

## Triage Checklist

Before designing or changing RBAC:

1. Identify what needs to be done (tasks), not titles
2. Identify scopes involved (MG, subscription, RG, resource)
3. Determine if the permission is Azure RBAC or Entra directory role
4. Confirm whether elevation is needed permanently or just occasionally
5. Identify automation identities and their required actions
6. Identify current over-privileged assignments (Owners, Contributors everywhere)
7. Confirm break glass access exists for recovery

---

## Fix Steps

### Step 1: Separate Azure RBAC from Entra directory roles

Rule:

- Entra directory roles control tenant-level identity and M365 administration.
- Azure RBAC roles control Azure resource management.

Common mistake: giving Global Admin when the real need is Contributor on a subscription.

Fix:
- Assign Azure RBAC roles at the lowest scope that satisfies the task.
- Limit directory roles to true identity administration.

---

### Step 2: Build a least-privilege role model (task-based)

Start with common job functions:

- Helpdesk operator
- Cloud operator (day-to-day)
- Cloud engineer (build/change)
- Security reviewer
- Billing/cost manager
- Read-only auditor

Map to built-in roles first. Only create custom roles if built-in roles are too broad or too narrow.

Examples (built-in first):

- Read-only: Reader
- Support triage: Reader + specific resource roles (example: Virtual Machine Contributor at RG scope)
- Cost: Cost Management Reader (and Billing Reader where needed)
- Networking: Network Contributor (scoped tightly)
- Storage ops: Storage Account Contributor (scoped tightly)

Rule:
- Start at Resource Group scope, not Subscription, unless the job function truly spans all RGs.

---

### Step 3: Use groups for assignments, not individual users

Standard pattern:

- Create Entra security groups per role and scope
- Assign RBAC to group, not to users directly

Naming example:

- `az-rbac-sub-prod-reader`
- `az-rbac-rg-netops-network-contributor`
- `az-rbac-rg-app1-vm-operator`

Benefits:
- Cleaner audits
- Easier joiner/mover/leaver
- Reduced drift

---

### Step 4: Implement time-bound privilege with PIM (basics)

If you have PIM:

- Make privileged roles eligible, not permanent
- Require justification and MFA for activation
- Set maximum activation duration (example: 1 to 4 hours)
- Use approval for high-risk roles (Owner, User Access Administrator)

Targets for PIM:

Azure RBAC high privilege:
- Owner
- User Access Administrator
- Contributor (at subscription scope)

Entra high privilege:
- Global Administrator
- Privileged Role Administrator
- Conditional Access Administrator

If you do not have PIM:
- Document the gap explicitly
- Use manual process:
  - Create “elevation” groups
  - Add user temporarily with a ticket reference
  - Remove when done
  - Log evidence in audit notes

---

### Step 5: Custom roles (only when necessary)

Use custom roles when:

- Built-in roles grant too much
- You need a narrow set of actions (for example only start/stop VMs, not delete)

Rules for custom roles:

- Start by cloning a built-in role JSON definition
- Remove permissions until minimum works
- Avoid wildcards unless truly required
- Avoid data actions unless necessary
- Test in a dev RG first

Example workflow (high level):

1) Identify exact operations needed (read, start, stop, restart)
2) Create custom role definition scoped to a subscription or MG (definition scope)
3) Assign it at RG scope to a group
4) Validate tasks succeed and deletes/creates are blocked

---

### Step 6: Lock down privilege sprawl

Do these cleanup actions:

- Remove user-level “Owner” assignments where unnecessary
- Convert to group-based assignments
- Reduce subscription-level assignments
- Remove stale accounts and stale groups
- Ensure break glass remains available but monitored

---

## Verification

- At least one test user can perform required tasks with the new RBAC assignment
- Test user cannot perform prohibited actions (delete, create, modify outside scope)
- Role assignments show groups, not individuals
- Audit logs show role assignment changes with ticket references
- If using PIM:
  - Users are eligible, not permanently active
  - Activation requires MFA and justification
  - Duration limits are enforced

---

## Prevention

- Enforce “groups only” policy for RBAC assignments
- Use naming standards for RBAC groups and scopes
- Monthly review:
  - Owners at subscription scope
  - User Access Administrators
  - Permanent privileged assignments
- Require change control for role assignments
- Maintain a catalog of approved roles and their intended scope

---

## Rollback

If you broke operations:

1) Re-add the previous RBAC assignment group at the same scope
2) Restore required built-in role temporarily at RG scope (not subscription) if possible
3) Use break glass for emergency only
4) Document what permission was missing and adjust custom role safely

---

## Evidence to collect

Store under:

`/evidence/runbooks-az-104-identity-rbac-design-least-privilege-custom-roles-pim-basics/`

Exports (redacted):
- Role assignments at target scope (subscription and RG)
- List of Owners and User Access Administrators at subscription scope
- Custom role definition JSON (if created)
- PIM role settings and eligible assignments (if available)

Screenshots (redacted):
- RBAC assignments page showing group-based assignments
- PIM activation settings (MFA, duration, approval)
- Custom role permissions summary (high level)

Notes:
- Task-to-role mapping table used for design
- Scope decisions (why RG vs subscription)
- Cleanup actions performed (removed individual Owners, etc.)

---

Next 3 actions
1) Commit this runbook to `/runbooks/az-104/identity-rbac-design-least-privilege-custom-roles-pim-basics.md`.  
2) Add a companion script later that exports RBAC assignments and Owners per subscription into `/evidence/.../exports/`.  
3) In a lab subscription, implement one group-based RBAC model and capture before/after evidence.