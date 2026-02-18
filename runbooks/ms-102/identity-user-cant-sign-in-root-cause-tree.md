# /runbooks/shared/identity-user-cant-sign-in-root-cause-tree.md

Tag: A/B

# User can’t sign in – Root cause tree (Entra ID / Microsoft 365)

## Symptoms

- User gets “Your account or password is incorrect”
- User gets “Your sign-in was blocked” or “You can’t get there from here”
- MFA loops or fails
- Login works on one device but not another
- Sign-in succeeds but app access fails (Outlook, Teams, SharePoint)
- New user cannot sign in at all

---

## Scope

Covers interactive user sign-in to:

- Microsoft 365 (portal.office.com)
- Exchange Online (Outlook desktop/mobile/OWA)
- Teams (desktop/mobile/web)
- SharePoint / OneDrive
- Azure portal (if user is blocked there)

Excludes:

- Service principals and app-only auth (use a separate runbook)
- On-prem AD authentication outages beyond basic checks (covered by AD DS health runbooks)

---

## Preconditions

- Access to Entra admin center
- Ability to view Sign-in logs and Audit logs (licensing affects detail)
- Ability to check Conditional Access policies
- If using scripts: Microsoft Graph PowerShell SDK

Minimum roles (least privilege):

- Global Reader (read-only triage)
- Security Reader (view sign-in details)
- Conditional Access Administrator (CA policy review)
- User Administrator / Helpdesk Administrator (reset password, unblock user)

---

## Triage Checklist

Collect first, then change things.

1. Who is affected (single user, group, tenant-wide)?
2. What app is failing (M365 portal, Teams, Outlook, Azure portal)?
3. What device and network (corp LAN, home, mobile, VPN)?
4. When did it start (exact timestamp, timezone)?
5. What error is shown (screenshot, error code, correlation ID)?
6. Has anything changed (password reset, device replaced, CA policy change, license change)?
7. Check Service Health for current incidents.

---

## Fix Steps

### Step 1: Determine blast radius fast

A) Single user only  
Go to Step 2.

B) Many users across apps  
- Check Microsoft 365 Service Health
- Check recent tenant-wide policy changes (Conditional Access, Security Defaults, Identity Protection)
- Check federation/SSO status if applicable (if you use ADFS/3rd party IdP)

If tenant-wide, stop. Do not “fix” users one-by-one.

---

### Step 2: Use Sign-in logs as source of truth

Portal path:
Entra admin center -> Monitoring -> Sign-in logs

Filter by:
- User
- Time range (tight)
- Application
- Status (Failure)

Record:
- Failure reason
- Error code
- Conditional Access tab result
- Device / Location / IP
- Correlation ID

Decision:
- If sign-in never appears in logs, the request may not be reaching Entra (client issue, wrong tenant, cached creds, DNS/proxy block).

---

### Root Cause Tree (use in order)

#### Branch A: Password / account state problems

Symptoms:
- “Invalid username or password”
- Failure reason indicates bad credentials
- Repeated failures then lockout

Checks:
1) Account enabled?  
Entra -> Users -> user -> Account status

2) Sign-in blocked?  
Entra -> Users -> user -> Block sign-in

3) Password expired / must change?  
- If using cloud-only: reset password and require change
- If hybrid: confirm password writeback/PHS/PTA path

4) Smart lockout triggered?  
- Check sign-in failures and lockout policy behavior

Fix:
- Reset password (and confirm user types it correctly)
- Clear “Block sign-in”
- If lockout suspected, wait out window or unlock if you control that path

---

#### Branch B: Conditional Access block

Symptoms:
- User sees “Your sign-in was blocked”
- Sign-in log shows “Failure” with Conditional Access = Failure
- CA tab shows which policy blocked

Checks:
1) In sign-in log: Conditional Access tab  
- Identify policy name and control that triggered (MFA, compliant device, location, etc.)

2) Verify user and group membership  
- Is the user in a pilot or enforcement group?

3) Verify exclusions  
- Break glass should be excluded from strong enforcement policies

Fix patterns:
- If policy requires MFA: ensure user has MFA method registered and can complete challenge
- If policy requires compliant device: move user to “break-fix” exception group temporarily and remediate device compliance
- If policy blocks by location/IP: confirm current IP/location and adjust named locations if correct

Do not permanently weaken policy to “fix” one user.

---

#### Branch C: MFA / Authenticator issues

Symptoms:
- MFA prompt never arrives
- MFA loop
- “Additional authentication required” but user cannot complete
- New phone, number changed, old device lost

Checks:
1) User’s auth methods in Entra  
Entra -> Users -> Authentication methods

2) Check if MFA is being enforced by:
- Security Defaults
- Conditional Access
- Per-user MFA (legacy)

Fix:
- Require re-register MFA (remove old methods, re-add)
- Temporarily allow a safe alternate factor to regain access
- If user is stuck in loop on Teams/Outlook: clear client cache and re-auth after methods fixed

---

#### Branch D: Licensing / app assignment issues (sign-in succeeds, app fails)

Symptoms:
- Entra sign-in shows Success
- User cannot access Exchange/Teams/SharePoint
- App says unlicensed or no mailbox

Checks:
1) License assigned?  
M365 admin center -> Users -> Licenses  
Or Entra -> User -> Licenses

2) Group-based licensing delay?  
- Check group membership
- Check provisioning status

3) Mailbox provisioned?  
Exchange admin center -> Recipients  
(Or use script output if you run it)

Fix:
- Correct group membership
- Wait for provisioning, or force remediation steps if stuck
- If mailbox missing: confirm Exchange Online license present and service plan enabled

---

#### Branch E: Device state / PRT / compliance dependency

Symptoms:
- Works on web, fails on desktop apps
- CA requires compliant device
- Device shows noncompliant or not joined correctly

Checks:
1) Intune: device compliance state
2) Join state: Entra joined vs hybrid vs registered
3) PRT health (Windows)  
- dsregcmd /status (collect output, redact tenant info if needed)
4) Teams/Office token cache issues

Fix:
- Remediate compliance (encryption, OS version, Defender, etc.)
- Re-register device if join state broken
- Clear token cache, re-auth
- If PRT broken: fix WAM/AAD Broker issues (separate runbook)

---

#### Branch F: Risk-based blocks / Identity Protection (if available)

Symptoms:
- Sign-in blocked due to risk
- “Risky user” or “Risky sign-in” in logs
- CA policy blocks high risk

Checks:
1) Identity Protection alerts (if licensed)
2) User risk state

Fix:
- Confirm compromise vs false positive
- Reset password, revoke sessions, force MFA re-registration
- Dismiss risk only after remediation

---

#### Branch G: Federation / SSO / legacy auth

Symptoms:
- Hybrid tenant uses ADFS or third-party IdP
- Sign-in logs show federation errors
- Legacy auth client gets blocked

Checks:
1) Is the app using modern auth?
2) Are legacy protocols blocked by CA?
3) If federated: check IdP health and certs

Fix:
- Move client to modern auth
- Exclude only as last resort
- Restore IdP function (separate runbook)

---

## Verification

- User can sign in to portal.office.com successfully
- Sign-in logs show Success for the target app
- Conditional Access result is Success
- Teams and Outlook open and stay signed in after restart
- If device-compliance driven: device shows compliant and access persists

---

## Prevention

- Standardize “break-fix” exception group with time-boxed membership
- Enforce group-based licensing, avoid manual one-offs
- Implement staged CA rollouts (report-only -> pilot -> enforcement)
- Monitor sign-in failures for spike detection
- Maintain documented MFA reset procedure
- Maintain a separate runbook for WAM/token cache remediation

---

## Rollback

Use only if you caused a new outage.

- Revert last policy change (CA)
- Remove user from newly applied enforcement group
- Restore prior license group membership
- If MFA reset broke user access: re-add verified methods

Document rollback reason and what will prevent repeat.

---

## Evidence to collect

Store under:

`/evidence/runbooks-shared-identity-user-cant-sign-in-root-cause-tree/`

Commands (redacted):
- dsregcmd /status (Windows) if device state implicated
- ipconfig /all if DNS is implicated (optional)

Exports (redacted):
- Sign-in logs for failing attempts (CSV/JSON)
- Audit log entries for user changes during incident window
- Conditional Access policy list affecting user (names + results, no sensitive detail)

Screenshots (redacted):
- Error message with correlation ID
- Sign-in log entry details (Status + CA tab)
- User authentication methods page (if MFA issue)

Notes:
- Timeline with timestamps and actions
- Final root cause and preventive follow-up

---

Next 3 actions
1) Commit this runbook to `/runbooks/shared/identity-user-cant-sign-in-root-cause-tree.md`.  
2) Run your scaffold workflow so the matching evidence folder is created automatically.  
3) Populate one full example evidence set using a controlled failure (CA block or license removal) in your lab tenant.