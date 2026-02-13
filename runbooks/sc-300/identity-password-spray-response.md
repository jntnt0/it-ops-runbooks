Tag: A/B  
Artifact: Runbook  
Owner: IT Ops  
Last updated: 2026-02-09

## Symptoms
- Multiple failed sign-ins across many usernames from one or more source IPs
- Increased account lockouts
- Entra sign-in logs show repeated failures like "Invalid username or password"
- Defender for Cloud Apps or Microsoft Defender alerts for password spray (if integrated)
- Users report unexpected MFA prompts after repeated failures (sometimes follows spray attempts)

## Scope
- Entra ID (Azure AD) user sign-ins (cloud and hybrid)
- Targeted accounts may include: privileged roles, executives, service accounts, shared mailboxes, legacy protocols
- Time window typically minutes to hours, but may persist for days if not blocked

## Preconditions
- At least one admin with:
  - Security Reader (minimum for log review) and ability to create Conditional Access and sign-in risk policies (typically Security Administrator or Conditional Access Administrator)
  - Ability to block IPs at edge (firewall, WAF) if applicable
- Access to:
  - Entra admin center (sign-in logs, audit logs)
  - Microsoft 365 Defender portal (optional but preferred)
  - Evidence folder structure under /evidence (you will redact screenshots/logs)

## Triage checklist
1. Confirm it is spray (many usernames, few IPs) vs brute force (one username, many attempts).
2. Identify:
   - Impacted users (top targets)
   - Source IPs / ASN / geo
   - Apps involved (OfficeHome, Exchange Online, legacy protocols)
   - Authentication type (password, legacy auth, IMAP/POP/SMTP AUTH)
3. Check if any successful sign-ins occurred from same IPs after failures.
4. Check whether targeted users include admins or high value roles.
5. Decide containment level:
   - Minimal: block IPs + tighten CA
   - Aggressive: force password resets and revoke sessions for impacted users

## Fix steps
### 1) Capture initial evidence (do this before making changes)
Portal checks (Entra admin center)
- Entra admin center -> Identity -> Monitoring & health -> Sign-in logs
  - Filter: Status = Failure
  - Add columns: IP address, User, App, Client app, Authentication requirement, Conditional Access, Result description
  - Export filtered results (CSV) and save to /evidence with redaction
- Entra admin center -> Identity -> Monitoring & health -> Audit logs
  - Filter for changes during incident window (Conditional Access changes, user updates)

Scripted evidence collection (references)
- Run: `/scripts/entra-export-signinlogs.ps1` with time window and status filters
- Run: `/scripts/entra-export-auditlogs.ps1` for the same time window
- Run: `/scripts/entra-list-risky-users.ps1` (if Entra ID Protection is available)
Save outputs to `/evidence/identity-password-spray-response/` (redact as needed)

### 2) Immediate containment: block the spray source
Preferred: Conditional Access named locations + policy
1. Create Named Location(s) for suspicious IPs:
   - Entra admin center -> Protection -> Conditional Access -> Named locations
   - Add the IP ranges (single IPs as /32)
2. Create a temporary Conditional Access policy:
   - Assignments:
     - Users: All users (exclude break glass accounts explicitly)
     - Cloud apps: All cloud apps (or start with Office 365 if you must reduce blast radius)
     - Conditions:
       - Locations: Include Any location, Exclude trusted locations, Include the suspicious named locations (or invert based on your tenant standard)
       - Client apps: Include Browser + Mobile apps and desktop clients, also include "Other clients" if legacy auth is in play
   - Access controls: Block access
   - Enable policy (Report-only first only if you are confident the spray is not ongoing; otherwise enable immediately)

Parallel: edge blocking (if you control ingress)
- Block source IPs on firewall/WAF/VPN concentrator as appropriate
- If you use a third party email security gateway or IdP proxy, block there too

### 3) Close common spray doors (same-day hardening)
1. Disable legacy authentication if still allowed:
   - Prefer Conditional Access: Block legacy auth for all users
   - Also verify per-protocol settings if present (SMTP AUTH, IMAP, POP)
2. Ensure MFA is enforced for all users (minimum) and for admins (stronger):
   - Entra -> Protection -> Conditional Access -> policies
   - If you use Security Defaults, confirm it is on (small tenants) or move to CA based MFA
3. Add sign-in frequency and persistent browser session controls for risky scenarios if your org policy allows it
4. Confirm break glass accounts:
   - Excluded from CA policies
   - Strong passwords stored securely
   - Monitored sign-ins and alerting

### 4) Account level actions for targeted users
Do this for accounts that show high attempt volume or any suspicious success:
1. Reset password (or require change at next sign-in) if you suspect password disclosure.
2. Revoke sessions:
   - Entra admin center -> Users -> select user -> Revoke sessions
3. Force sign-out:
   - Entra admin center -> Users -> select user -> Sign out of all sessions
4. Review MFA methods:
   - Entra admin center -> Users -> Authentication methods
   - Remove unknown methods, require re-registration if needed
5. If an admin account is involved:
   - Disable account temporarily if suspicious success occurred
   - Move to PIM eligible roles if you have it, reduce standing privilege

### 5) Validate there was no follow-on compromise
1. Check for successful sign-ins from suspicious IPs:
   - Sign-in logs -> Status = Success + IP filter
2. Check audit logs for:
   - New app registrations or consent grants
   - Changes to Conditional Access, MFA methods, password resets
   - Role assignments (especially Global Admin, Privileged Role Admin)
3. If Defender portal is available:
   - Microsoft 365 Defender -> Incidents & alerts
   - Correlate user, IP, and device indicators

## Verification
- Failed sign-in volume drops to baseline after block
- No successful sign-ins from suspicious IPs during and after containment
- Conditional Access "Block spray IPs" policy is firing as intended (Sign-in logs -> Conditional Access tab)
- No unexpected audit log events (app consent, role changes, mailbox rules)

## Prevention
- Permanent Conditional Access baseline:
  - Block legacy authentication tenant-wide
  - Require MFA for all users, phishing resistant MFA for admins where possible
  - Restrict admin portals to trusted locations and compliant devices
- Enable and tune identity protection:
  - User risk and sign-in risk policies (if licensed)
- Alerting:
  - Sentinel or Defender alerts for high failure rates, risky sign-ins, unfamiliar locations
- Password hygiene:
  - Ban common passwords, encourage passphrases, implement SSPR and MFA registration campaigns

## Rollback
- If business disruption occurs:
  1. Disable only the temporary "Block spray IPs" CA policy first
  2. Remove IPs from Named Locations only if proven false positive
  3. Keep legacy auth blocks in place unless you have a documented exception path
- Document rollback reason and timestamps in /evidence

## Evidence to collect
- Entra sign-in logs export (CSV) for the incident window with failures and any successes from suspect IPs
- Entra audit logs export for incident window
- Conditional Access policy JSON (or screenshots of assignments and controls)
- Named locations configuration (IPs, timestamps)
- List of impacted users and actions taken (reset, revoke sessions, disabled)
- Defender incident summary (if applicable)
- Correlation IDs and exact UTC timestamps for key events
- Script outputs saved under `/evidence/identity-password-spray-response/` (redacted)

## Next 3 actions
- Create `/evidence/identity-password-spray-response/` and add redacted exports for sign-in logs, audit logs, and CA policy screenshots.
- Add the temporary CA policy pattern as a reusable baseline policy document under `/story-packs/`.
- Implement or stub the referenced scripts in `/scripts/` so this runbook is fully repeatable.
