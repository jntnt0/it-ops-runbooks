# /runbooks/sc-300/identity-break-glass-account-build-and-validation.md
Tag: A

## Symptoms
- Admin is locked out due to Conditional Access, MFA outage, IdP outage, or device compliance enforcement
- Privileged admin account is blocked, compromised, or cannot satisfy sign-in requirements
- Widespread sign-in failures and you need a known-good path to regain control
- Emergency access is required during tenant-wide incident response

## Scope
- Microsoft Entra ID (Azure AD) cloud-only emergency access accounts (break glass)
- Covers creation, hardening, Conditional Access exclusions, monitoring, and validation
- Does not cover on-prem AD break glass, federation IdP break glass, or network edge access

## Preconditions
- You have Global Administrator access now (before you get locked out)
- Two separate break glass accounts will be created (minimum) and stored securely
- You have a secure password vault (enterprise vault preferred; second-best is offline sealed storage)
- Logging and alerting is enabled (sign-in logs and audit logs)
- You understand this is for emergency use only, not daily admin

## Triage checklist
- Confirm current admin access is stable enough to perform setup (no active lockouts on your session)
- Confirm you have at least two independent recovery paths:
  - Two break glass accounts
  - At least one out-of-band MFA recovery method for daily admins (not on break glass)
- Confirm your Conditional Access baseline:
  - You have a policy set for privileged access
  - You can identify which policies would block an emergency sign-in
- Confirm licensing reality:
  - Conditional Access requires Entra ID P1 or equivalent licensing
  - If Conditional Access is not available, document the limitation and shift controls to strong passwords, monitoring, and strict operational handling
- Confirm monitoring path:
  - You can export sign-in logs and audit logs via script or portal

## Fix steps

### 1) Create two dedicated break glass user accounts
1. Entra admin center -> Identity -> Users -> New user
2. Create accounts with a clear naming standard, examples:
   - `bg-admin01@<tenant>.onmicrosoft.com`
   - `bg-admin02@<tenant>.onmicrosoft.com`
3. Use cloud-only identities (no sync from on-prem)
4. Set Usage location as required for licensing (if needed)

Hard rules:
- Do not use personal email addresses
- Do not associate with day-to-day admins
- Do not reuse passwords from any other account

### 2) Assign least necessary privileged role
Minimum:
- Global Administrator (typical for true emergency access)

If you are disciplined and have operational maturity:
- Consider splitting duties into separate emergency accounts (one GA, one Privileged Role Admin)
- Do not overcomplicate if you will not maintain it

Actions:
1. Entra admin center -> Identity -> Users -> select `bg-admin01` -> Assigned roles
2. Assign Global Administrator
3. Repeat for `bg-admin02`

If using PIM (recommended for normal admins):
- Break glass accounts should generally be exempt from PIM activation requirements
- Keep them out of normal privileged workflows

### 3) Set authentication controls for break glass
Goal: Maximum availability during outages, with compensating controls.

Recommended baseline:
- Long, random password (32+ chars) stored in vault
- No phone number, no email, no Authenticator registration for break glass account
- Enforce strong password and prevent reuse through policy where available

Actions:
1. Set initial password to a long random value
2. Immediately store password in vault with restricted access and dual control if possible
3. Do not enroll MFA methods on break glass accounts unless your organization requires it for policy reasons
4. Ensure Self-Service Password Reset is not required for break glass (SSPR dependency can fail during incidents)

Note:
- Some tenants enforce security defaults or other MFA requirements. If you cannot create an MFA-free emergency path, document it and build the most resilient alternative (for example, FIDO2 key stored offline and tested).

### 4) Exclude break glass accounts from Conditional Access (only the policies that can lock you out)
This is the make-or-break part.

Actions:
1. Entra admin center -> Protection -> Conditional Access -> Policies
2. Identify policies that could block emergency sign-in:
   - Require MFA for all users
   - Require compliant device
   - Require hybrid joined device
   - Block legacy auth (fine, but ensure break glass can still use modern auth)
   - Named locations restrictions that could block remote recovery
3. For each relevant policy:
   - Add `bg-admin01` and `bg-admin02` to Exclude Users
4. Document exactly which policies exclude them and why

Rules:
- Exclude from the minimum set of policies necessary to preserve emergency access
- Do not create a single sloppy “exclude break glass from everything” policy without documenting the rationale
- Never exclude break glass from sign-in risk or user risk policies unless you accept the risk and have strong monitoring

### 5) Add strong monitoring and alerting for break glass usage
Every sign-in attempt is a security event.

Minimum monitoring:
- Alert on any sign-in by `bg-admin*`
- Alert on failed sign-in attempts (possible attack)
- Alert on role assignment changes, CA policy changes, and credential changes

Actions:
1. Ensure audit logs are retained and accessible
2. If Microsoft Sentinel is available, create analytics rules for:
   - Sign-in events where user equals `bg-admin01` or `bg-admin02`
   - Audit events for role assignment changes involving those accounts
3. If Sentinel is not available, document a manual process:
   - Daily or weekly review of sign-in and audit logs for those accounts
   - Immediate review after any incident

Scripted evidence collection references:
- `/scripts/entra-export-signinlogs.ps1`
- `/scripts/entra-export-auditlogs.ps1`

### 6) Validate break glass end-to-end (controlled test)
You are not done until you test.

Test plan:
1. Use a private browser session (InPrivate) on a separate device if possible
2. Attempt sign-in to Entra admin center with `bg-admin01`
3. Confirm:
   - Sign-in succeeds
   - You can access critical admin surfaces (Entra admin center, Conditional Access, Users, Roles)
4. Record:
   - Timestamp
   - Public IP and device details
   - Any prompts or blocks
5. Sign out, repeat for `bg-admin02`

Optional hard test (only if you know what you are doing):
- Temporarily enable a restrictive Conditional Access policy that would normally block admins, verify break glass still signs in, then roll back immediately.

## Verification
- `bg-admin01` and `bg-admin02` exist and are cloud-only
- Both accounts have the intended privileged role assignment
- Conditional Access exclusions are applied to the correct blocking policies
- Successful sign-in test performed for both accounts
- Alerting is configured (or manual review procedure documented)
- Evidence folder exists with exports and notes

## Prevention
- Quarterly validation test for both break glass accounts
- Password rotation at least every 6 to 12 months, and immediately after any staff change involving vault access
- Dual control for vault access (two-person rule) if your organization can support it
- Keep break glass accounts out of routine admin usage
- Review Conditional Access policies after every major change to confirm exclusions still make sense
- Maintain a printed and sealed emergency procedure stored in a secure location for true outage scenarios

## Rollback
If you created break glass accounts incorrectly or too permissive:
- Remove unnecessary exclusions from Conditional Access policies
- Remove extra authentication methods or recovery options you added by mistake
- If compromised or mishandled:
  - Reset password immediately
  - Revoke sessions
  - Review sign-in logs and audit logs for suspicious activity
  - Consider deleting and recreating the account(s) if you cannot trust the state

Never “roll back” by deleting both emergency accounts without replacements already validated.

## Evidence to collect
Store under:
- `/evidence/identity-break-glass-account-build-and-validation/`

Minimum:
- `notes.md` (what you built, why, and where it lives)
- `timeline.md` (timestamps of creation and validation tests)
- `exports/signins.json` (or `.csv`) from `/scripts/entra-export-signinlogs.ps1` filtered to break glass users
- `exports/audit.json` (or `.csv`) from `/scripts/entra-export-auditlogs.ps1` including:
  - user creation events
  - role assignments
  - Conditional Access policy edits
- `screenshots/` (redacted):
  - user properties page showing account exists
  - role assignment page
  - Conditional Access policy exclusions
  - sign-in success record for each account
- `run-output/`:
  - transcript logs from script runs (sanitized)
  - any error output (sanitized)

Next 3 actions
1) Create the matching evidence folder `/evidence/identity-break-glass-account-build-and-validation/` with `notes.md`, `timeline.md`, and subfolders `exports/`, `screenshots/`, `run-output/`.
2) Run `/scripts/entra-export-auditlogs.ps1` and `/scripts/entra-export-signinlogs.ps1` right after you create the accounts, then save redacted outputs into `exports/`.
3) Perform the controlled sign-in test for both accounts in a private browser session and capture the screenshots and timestamps into `screenshots/` and `timeline.md`.
