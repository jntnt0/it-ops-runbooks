# /runbooks/windows/kerberos-vs-ntlm-explanation.md

Tag: A

# Kerberos vs NTLM explanation runbook

## Symptoms

- Users can access shares and apps on some machines but not others
- Authentication is slow, prompts repeatedly, or falls back unexpectedly
- Security team asks: “Why are we still using NTLM?”
- Legacy app breaks when NTLM is blocked
- You need to explain auth behavior during troubleshooting without hand-waving

## Scope

Covers:

- What Kerberos is and why it is the default in modern AD
- What NTLM is and why it still shows up
- Practical differences that matter in day to day troubleshooting
- How to identify which protocol was used for a given logon
- Safe operational guidance for reducing NTLM without breaking everything

Not covered:

- Deep cryptography internals
- Full AD design or forest trust design beyond basic implications
- Kerberos constrained delegation deep dives (separate runbook)

## Preconditions

- You have an AD domain environment (lab or real)
- You can access:
  - A domain-joined Windows client
  - A domain controller (or at least event logs exported from one)
- Minimum roles (least privilege):
  - Local admin on a test workstation (to read security logs, run klist, etc.)
  - Domain admin not required for most observation tasks, but may be needed to change NTLM policy settings or audit settings
  - Rights to read DC security logs (Event Log Readers or equivalent) if pulling DC evidence

## Triage checklist

1. Is the computer and user domain joined and in the same forest?
2. Is DNS healthy (clients resolve DCs and service hosts correctly)?
3. Is time sync correct (Kerberos is sensitive to time skew)?
4. Is the user accessing by hostname (Kerberos) or IP (often NTLM)?
5. Is there an SPN for the service the user is hitting?
6. Are there any local accounts in play (NTLM more likely)?
7. Are there policies restricting NTLM, and are you in audit or enforce mode?

## Fix steps

### Step 1: Explain Kerberos in practical terms

Kerberos is ticket-based authentication used by Active Directory.

The simple mental model:

- User signs in and gets a Ticket Granting Ticket (TGT) from the KDC (domain controller).
- When the user accesses a service (file share, web app, SQL, etc.), the client requests a service ticket for that specific service.
- The service ticket proves the user’s identity to the service without sending the user’s password across the network.

Why it matters:

- It supports mutual authentication (client knows it is talking to the real service).
- It is designed for single sign-on (SSO) across many services.
- It relies heavily on:
  - DNS (to find the right service host)
  - time sync
  - SPNs (Service Principal Names) so the service has a Kerberos identity

### Step 2: Explain NTLM in practical terms

NTLM is an older challenge-response protocol.

The simple mental model:

- Client requests access.
- Server sends a challenge.
- Client proves knowledge of password hash via a response.

Why it matters:

- It does not do mutual authentication the same way Kerberos does.
- It is more vulnerable to certain attack classes (relay, pass-the-hash style abuse).
- It is used when Kerberos cannot be used.

### Step 3: Explain when and why fallback happens

Most “Kerberos vs NTLM” troubleshooting is just identifying why Kerberos failed.

Common reasons Kerberos is not used:

- Accessing a service by IP address instead of hostname
- SPN missing, duplicated, or wrong (Kerberos cannot map service name to an account)
- Cross-forest/trust or legacy scenarios where Kerberos is not available
- Time skew (Kerberos tickets invalid)
- DNS misconfiguration (client cannot locate correct DC or service host)
- Local account auth (not domain)
- NTLM forced by policy or app design

Common indicators:

- Kerberos works for most internal services, NTLM shows up for:
  - old SMB targets
  - older apps
  - weird hostname usage
  - “localhost” and loopback edge cases

### Step 4: Identify which protocol was used (client side)

On a Windows client:

Kerberos tickets:

- `klist`

If Kerberos was used to access a service, you will see a service ticket for it.

Example: accessing a file server:
- Look for a ticket for `cifs/servername`

SMB session view:

- `Get-SmbConnection`
  - Shows whether the session is using Kerberos or NTLM for SMB

Evidence:

- `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/commands/klist-<date>.txt`
- `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/commands/get-smbconnection-<date>.txt`

### Step 5: Identify which protocol was used (server side)

On the target server (or DC), use Security logs.

Windows Security event signals (high level):

- Logon events (4624) can include authentication package fields indicating Kerberos or NTLM
- Domain controllers can show Kerberos service ticket events (4769) and TGT events (4768) if auditing is enabled

Practical approach:

- On the target server:
  - Find the logon event for the user and check the authentication package
- On the DC (if available):
  - Look for 4769 service ticket requests to see the service name and client IP

Evidence:

- `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/exports/security-events-4624-<date>.evtx`
- `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/exports/dc-events-4769-<date>.evtx`

### Step 6: Safe reduction strategy for NTLM

Do not just “block NTLM” and hope.

Proper reduction sequence:

1. Audit first
   - Enable NTLM auditing so you see what would break
2. Fix the root causes
   - SPNs, DNS, time sync, hostname usage
3. Targeted restrictions
   - Restrict NTLM where you have confidence
4. Enforce last
   - Only after you have evidence and remediation

Operational rules:

- Put the legacy apps on a list with owners
- For each app, document:
  - why it uses NTLM
  - what breaks if NTLM is removed
  - replacement plan

### Step 7: Common fixes when Kerberos should work but does not

A) Fix time sync

- Ensure clients and servers use domain time hierarchy
- Time skew will cause Kerberos failures

B) Fix DNS

- Use correct DNS servers (domain DNS)
- Ensure A records and reverse lookups are sane
- Avoid hardcoded external DNS on domain members

C) Fix SPNs

- If service runs under a service account, it needs correct SPNs
- Duplicate SPNs cause Kerberos failures and fallback
- Use:
  - `setspn -L <account>`
  - `setspn -Q <spn>`

D) Fix how users connect

- Use FQDN or hostname, not IP
- Ensure proper name matches SPN format

Evidence:

- `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/commands/setspn-outputs-<date>.txt`
- `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/commands/dns-and-time-checks-<date>.txt`

## Verification

- For a known service (SMB, web, SQL), you can prove:
  - Kerberos ticket exists (klist shows service ticket)
  - Server logon event indicates Kerberos
- NTLM usage is measured and decreasing over time (audit logs)
- No business-critical apps are broken by restrictions

## Prevention

- Standardize service deployment with correct SPN registration steps
- Keep time sync and DNS configuration locked down via GPO
- Avoid using IPs in documentation and shortcuts for internal services
- Maintain an NTLM exception register with owner, justification, and expiration date
- Use auditing and staged enforcement instead of big-bang blocking

## Rollback

If NTLM reduction breaks something:

1. Revert NTLM restriction policy to audit-only or previous state
2. Confirm service access restored
3. Capture evidence of what broke (event logs, app logs, user impact)
4. Create a tracked remediation item for that app (SPN fix, app upgrade, redesign)
5. Re-apply restrictions only after fix is validated

## Evidence to collect

Store under: `/evidence/runbooks-windows-kerberos-vs-ntlm-explanation/`

- `commands/`
  - `klist-<date>.txt`
  - `get-smbconnection-<date>.txt`
  - `setspn-outputs-<date>.txt`
  - `dns-and-time-checks-<date>.txt`
- `exports/`
  - `security-events-4624-<date>.evtx`
  - `dc-events-4768-<date>.evtx` (optional)
  - `dc-events-4769-<date>.evtx` (optional)
- `screenshots/` (redacted)
  - `event-4624-auth-package-<date>.png`
  - `event-4769-service-ticket-<date>.png` (optional)
- `notes.md`
  - Explanation of why Kerberos should be used, why NTLM appeared, and the remediation plan
- `timeline.md`
  - T0 problem report, T1 identification, T2 fix, T3 verification, T4 prevention

## Next 3 actions

1. Create `/runbooks/windows/kerberos-vs-ntlm-explanation.md` with this content and commit it.
2. In your lab, force one NTLM case (connect by IP) and one Kerberos case (connect by hostname), then capture klist, Get-SmbConnection, and a 4624 event as evidence.
3. Add a short “NTLM reduction plan” note in notes.md listing audit first, fix SPNs/DNS/time, then targeted restriction, then enforcement.
