## Symptoms
- Repeated credential guessing, password spray, or brute force attempts
- Legacy authentication attempts appear in sign-in logs
- Admin accounts are exposed to single-factor sign-ins
- You need fast, practical CA hardening without overengineering

## Scope
- Microsoft Entra Conditional Access baseline hardening focused on:
  - MFA for privileged roles first
  - Blocking legacy authentication tenant-wide
  - Expanding MFA to all users after admin stability
  - Optional device compliance for privileged roles if Intune is ready
- Applies to cloud identity sign-ins to Microsoft cloud apps
- Does not cover on-prem federation IdP controls, firewall blocks, or endpoint configuration

## Preconditions
- Conditional Access available (Entra ID P1 or equivalent licensing)
- Two break glass accounts exist and are validated:
  - Reference: /runbooks/sc-300/identity-break-glass-account-build-and-validation.md
- You can export and review sign-in logs and audit logs:
  - /scripts/entra-export-signinlogs.ps1
  - /scripts/entra-export-auditlogs.ps1
- You have a rollback plan for each policy (disable policy)

If Conditional Access is not available:
- You cannot execute this runbook. Document the limitation and use alternative containment:
  - password resets for impacted users
  - revoke sessions for impacted users
  - disable legacy auth via other tenant settings if available
  - consider Security Defaults if acceptable

## Triage checklist
- Confirm Conditional Access is present in Entra admin center
- Confirm Security Defaults status (enabled/disabled) and document it
- Confirm break glass exclusions will be applied consistently
- Identify current authentication surfaces from sign-in logs:
  - Client app types
  - Legacy auth attempts
  - Targeted users and apps
- Confirm your target rollout approach:
  - Immediate for admins
  - Phased for all users if needed

## Fix steps

### 1) Policy 1: Require MFA for admins (Tier 0)
Goal: protect privileged roles first with the smallest blast radius.

1. Entra admin center -> Protection -> Conditional Access -> Policies -> New policy
2. Name: `CA - Require MFA - Tier0 Admin Roles`
3. Users:
   - Include: Directory roles (Global Administrator, Privileged Role Administrator, etc.)
   - Exclude: break glass accounts
4. Cloud apps:
   - Include: All cloud apps
   - Optional: start with Azure management + Microsoft admin portals if you need a cautious rollout
5. Grant:
   - Require multifactor authentication
6. Enable policy

Notes:
- Keep this policy simple and stable.
- If MFA breaks your admin workflows, you fix that now, before widening scope.

### 2) Policy 2: Block legacy authentication (tenant-wide)
Goal: remove the easiest spray surface and reduce credential replay paths.

1. New policy
2. Name: `CA - Block Legacy Authentication - All Users`
3. Users:
   - Include: All users
   - Exclude: break glass accounts (optional, but keep consistent)
4. Cloud apps:
   - Include: All cloud apps
5. Conditions:
   - Client apps: select legacy authentication clients
6. Grant:
   - Block access
7. Enable policy

Notes:
- This is high ROI and typically low regret.
- Expect to break old email clients or devices that still use legacy auth.

### 3) Policy 3: Require MFA for all users (after admin policy is stable)
Goal: stop password spray from succeeding even if the password is correct.

1. New policy
2. Name: `CA - Require MFA - All Users`
3. Users:
   - Include: All users
   - Exclude: break glass accounts
4. Cloud apps:
   - Include: All cloud apps
5. Grant:
   - Require multifactor authentication
6. Enable policy

Phasing options:
- If you are worried about blast radius:
  - Apply to a pilot group first (IT + a few users)
  - Then expand group coverage in stages
- If this is a lab tenant:
  - Enable immediately for demonstration and evidence

### 4) Optional policy: Require compliant device for admins (only if Intune is ready)
Goal: reduce risk by binding admin access to managed devices.

1. New policy
2. Name: `CA - Require Compliant Device - Tier0 Admin Roles`
3. Users:
   - Include: Directory roles
   - Exclude: break glass accounts
4. Cloud apps:
   - Include: All cloud apps (or at least admin portals)
5. Grant:
   - Require device to be marked as compliant
6. Enable policy

Warnings:
- This will break admins if Intune enrollment and compliance policies are not already mature.
- Do not use this as your first CA policy.

## Verification
- Confirm policy existence and status: enabled
- Confirm break glass exclusions are present on all policies
- Generate a controlled test:
  - Attempt sign-in as an admin without MFA and confirm it prompts/blocks appropriately
  - Attempt a legacy auth sign-in (if you can simulate) and confirm it is blocked
- Confirm sign-in logs show:
  - Conditional Access result for each test
  - Clear failure reasons or prompts that match policy intent

## Prevention
- Keep the admin MFA policy permanent and simple
- Quarterly review:
  - confirm break glass exclusions still correct
  - confirm no new legacy auth pathways reintroduced
- Treat CA changes like change control:
  - document policy intent
  - export audit logs
  - validate with a small test before widening scope

## Rollback
- Disable the most recent policy you enabled
- Re-test sign-in for impacted users/admins
- If you must roll back broadly:
  - keep Tier0 admin MFA enabled unless it is truly blocking emergency operations
- Document rollback in evidence timeline and audit log exports

## Evidence to collect
Store under:
- `/evidence/conditional-access-fast-hardening-baseline/`

Minimum:
- `notes.md` with:
  - policy names created
  - scope (who included/excluded)
  - why you enabled each policy
  - any impacts observed
- `timeline.md` with:
  - timestamps for create/enable actions
  - timestamps for verification sign-ins
- `exports/audit.json` (or csv):
  - policy create/update events
- `exports/signins.json` (or csv):
  - verification sign-ins showing CA applied/blocked
- `screenshots/` (redacted, optional):
  - each policy overview
  - exclusion list showing break glass accounts

## Operational guidance for incident runbooks
When responding to spray:
- IP block policy buys time
- MFA policies stop success
- Legacy auth block removes easy surfaces

Document in incident execution:
- notes.md:
  - Blocked IPs via CA named location policy: <policy name>
  - CA tightened by enabling MFA for admin roles: <policy name>
  - Break glass excluded: yes, list accounts
  - Result: failures shifted from invalid password to CA block, volume dropped
- timeline.md:
  - Timestamp each policy create/enable
  - Timestamp when sign-in failure pattern changed

If Conditional Access is not available:
- Document limitation and do not pretend you executed CA steps.
- Use alternative containment:
  - force password resets and revoke sessions for impacted users

Next 3 actions
1) Add this file under `/runbooks/shared/` and link it from your spray response runbook and your CA rollout runbook.
2) Create an evidence folder `/evidence/conditional-access-fast-hardening-baseline/` with empty templates for notes.md and timeline.md.
3) When CA becomes available, execute the runbook once in your lab tenant and capture audit + sign-in exports proving policy application.
