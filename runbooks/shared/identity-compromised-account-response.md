# /runbooks/identity-compromised-account-response.md

Tag: A/B  
Artifact: Runbook  
Owner: IT Ops  
Last updated: 2026-02-09

## Symptoms
- User reports "I did not sign in" or unexpected MFA prompts
- Sign-in logs show unfamiliar IP/geo/device, or impossible travel
- Mailbox shows suspicious rules, forwarding, or sent items
- Admin sees risky user/sign-in events or Defender incident tied to user
- New MFA methods added without user approval
- Tokens remain valid even after password reset (session persistence)

## Scope
- Single user compromise or small set of accounts
- Covers Entra ID account, M365 apps (Exchange, SharePoint, Teams), and potential lateral movement
- Includes admin account response escalation path

## Preconditions
- Admin roles available:
  - Security Administrator or Global Administrator for full response
  - Exchange Administrator for mailbox actions
- Access to:
  - Entra admin center (sign-ins, audit logs, auth methods)
  - Microsoft 365 Defender portal (recommended)
  - Exchange admin center (mailbox rules, forwarding, message trace)
- Evidence path ready under /evidence (redact all artifacts)

## Triage checklist
1. Confirm compromise indicators:
   - Successful sign-in from suspicious context
   - Risky sign-in/user risk event
   - Audit logs show MFA method additions, consent grants, mailbox config changes
2. Determine account type:
   - Standard user, VIP, admin, service account
3. Determine blast radius:
   - Mail forwarding, OAuth app consent, SharePoint access, Teams sessions
4. Decide containment:
   - Immediate disable vs controlled lock down (depends on role and business impact)

## Fix steps
### 1) Preserve evidence first (before containment where possible)
Portal checks
- Entra -> Sign-in logs:
  - Filter on user, time window
  - Review: IP, device, client app, CA result, authentication details, session info
  - Export CSV
- Entra -> Audit logs:
  - Filter for user updates, authentication method changes, role assignments, app consent
  - Export CSV
- Entra -> Users -> Authentication methods:
  - Screenshot list of methods and recent changes (redact numbers)
- Microsoft 365 Defender:
  - Incident timeline, alerts, related entities (user, devices, IPs)

Scripted evidence collection (references)
- `/scripts/entra-export-signinlogs.ps1 -User <UPN> -Start <UTC> -End <UTC>`
- `/scripts/entra-export-auditlogs.ps1 -User <UPN> -Start <UTC> -End <UTC>`
- `/scripts/m365-export-mailbox-config.ps1 -User <UPN>` (forwarding, rules, delegates)
- `/scripts/entra-export-oauth-consents.ps1 -User <UPN>` (or tenant wide and filter)
Save outputs to `/evidence/identity-compromised-account-response/` (redact)

### 2) Immediate containment
For standard users
1. Revoke sessions:
   - Entra -> Users -> select user -> Revoke sessions
2. Force sign-out:
   - Entra -> Users -> select user -> Sign out of all sessions
3. Reset password:
   - Force change at next sign-in if policy allows
4. Reset MFA methods:
   - Remove unknown methods
   - Require re-registration (Authentication methods -> require re-register)
5. Block risky sign-ins short-term:
   - Conditional Access: require MFA and block legacy auth, consider blocking by location if clearly malicious

For admin accounts (treat as higher severity)
1. Disable the account immediately (short window) if suspicious success is confirmed.
2. Revoke sessions and force sign-out.
3. Reset password to a strong, unique value stored securely.
4. Remove all MFA methods and re-enroll with verified device.
5. Review privileged role assignments:
   - Entra -> Roles and administrators -> check assignments
   - Move to PIM eligible roles where possible, reduce standing privilege

### 3) Remove persistence and common attacker changes
Exchange / M365 checks
1. Check mailbox forwarding:
   - Exchange admin center -> Mailboxes -> user -> Mailbox features -> Mail flow settings
   - Remove external forwarding
2. Check inbox rules:
   - Remove rules that auto-delete, forward, or move security alerts
3. Check mailbox delegates and app access:
   - Remove unknown delegates, check Full Access and Send As
4. Check OAuth app consent and enterprise apps:
   - Entra -> Enterprise applications / App registrations:
     - Look for newly consented apps, high privilege permissions
     - Disable suspicious enterprise apps and revoke admin consent if needed
5. Check for newly created mail contacts used for forwarding:
   - Exchange -> Recipients -> Contacts

### 4) Investigate and eradicate related activity
1. Review sign-ins for the user before and after the suspicious event:
   - Identify initial access time, IP, user agent, client app
2. Check audit logs for:
   - MFA method additions
   - Password changes
   - Role assignments
   - App registrations or service principal creations
3. If device is involved:
   - If you manage endpoints: isolate device in Defender for Endpoint (if available)
   - Force device compliance check and consider requiring compliant device for access

### 5) Restore safe access and notify
1. Re-enable account (if disabled) only after:
   - Password reset complete
   - MFA re-enrolled
   - Suspicious forwarding/rules removed
   - OAuth persistence removed
2. Notify user with clear instructions:
   - Re-sign in, reconfigure MFA, watch for prompts
3. If regulated environment:
   - Follow breach notification and legal workflows

## Verification
- New sign-ins show expected geo, device, and MFA method
- No forwarding or suspicious rules remain
- No suspicious enterprise apps remain enabled or consented
- Audit logs show containment actions completed
- Defender incident closed or in monitoring state

## Prevention
- Conditional Access baselines:
  - Block legacy auth
  - Require MFA, stronger MFA for admins
  - Require compliant device for sensitive apps if feasible
- Limit OAuth consent:
  - Disable user consent or restrict to verified publishers
- Admin hygiene:
  - PIM, separate admin accounts, break glass controls
- Alerting:
  - Risky sign-in alerts, MFA method change alerts, forwarding creation alerts

## Rollback
- If containment breaks business workflows:
  1. Restore access gradually (enable account, allow sign-in, then reapply CA controls)
  2. Never restore unknown forwarding rules or OAuth consents
  3. Document any temporary exceptions with expiry
- Record rollback actions and times in /evidence

## Evidence to collect
- Entra sign-in logs export for user and incident window
- Entra audit logs export for user and incident window
- Authentication methods before/after (screenshots or exported state)
- Exchange mailbox configuration: forwarding, inbox rules, delegates
- OAuth consent and enterprise app changes related to user
- Defender incident summary and timeline
- Correlation IDs, exact UTC timestamps, IPs and user agents
- Script outputs saved under `/evidence/identity-compromised-account-response/` (redacted)

## Next 3 actions
- Create `/evidence/identity-compromised-account-response/` and add redacted exports and screenshots for sign-ins, audit logs, mailbox rules, and app consents.
- Add a default CA baseline set under `/story-packs/` that blocks legacy auth and restricts risky sign-ins.
- Implement or stub the referenced scripts in `/scripts/` to make evidence collection repeatable.
