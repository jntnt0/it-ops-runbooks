# /runbooks/identity-conditional-access-rollout.md

Tag: B  
Artifact: Runbook  
Owner: IT Ops  
Last updated: 2026-02-09

## Symptoms
- There is no consistent access control posture (MFA is optional or inconsistent)
- Legacy auth still works for some users or apps
- Users are being phished and accounts are being reused without strong controls
- Audit findings require MFA enforcement, device compliance requirements, or location restrictions
- Ad hoc policy changes are causing outages

## Scope
- Conditional Access policy design, pilot, staged rollout, and enforcement
- Includes break glass strategy, service account strategy, and controlled exceptions
- Applies to Entra sign-ins for M365 and other cloud apps

## Preconditions
- Licensing supports the intended CA features (at minimum CA itself; advanced controls may require Entra ID P1/P2)
- At least two break glass accounts created and tested
- A pilot group exists (small, representative users plus IT)
- A comms path exists (email or Teams announcement plan)
- Ability to collect evidence via portal exports and scripts

## Triage checklist
1. Identify the goal:
   - Enforce MFA for all users
   - Block legacy auth
   - Require compliant devices for key apps
   - Restrict admin portals to trusted locations
2. Inventory current state:
   - Existing CA policies, Security Defaults, per-user MFA, legacy auth usage
3. Identify high risk apps and users:
   - Admin roles, finance, execs, helpdesk
4. Identify technical constraints:
   - Shared devices, service accounts, legacy apps, MFA registration readiness

## Fix steps
### 1) Baseline discovery and evidence capture (before design)
Portal checks
- Entra -> Protection -> Conditional Access -> Policies
  - Screenshot list of existing policies and their state (On/Report-only/Off)
- Entra -> Users -> Per-user MFA (if used) and confirm whether Security Defaults is enabled
- Entra -> Sign-in logs:
  - Filter client app: "Other clients" and legacy protocols indicators
  - Identify legacy auth usage and top apps/users

Scripted evidence collection (references)
- `/scripts/entra-export-ca-policies.ps1`
- `/scripts/entra-export-signinlogs.ps1 -FilterLegacyAuth`
- `/scripts/entra-export-users-adminroles.ps1`
Save outputs to `/evidence/identity-conditional-access-rollout/` (redact)

### 2) Design the policy set (keep it boring and standard)
Minimum recommended policy set (common sequence)
1. Break glass exclusions (not a policy, but a rule):
   - Exclude 2 break glass accounts from all CA policies
   - Monitor those accounts with alerts and sign-in notifications
2. Block legacy authentication (tenant wide)
3. Require MFA for all users (all cloud apps)
4. Require phishing resistant MFA for admins (if possible)
5. Require compliant or hybrid joined device for sensitive apps (optional based on environment)
6. Session controls for high risk (sign-in frequency, persistent browser session) if required by risk profile

Service accounts and automation
- Prefer managed identities, workload identities, app registrations with certificate auth
- Do not use shared user accounts for automation
- If a legacy service account must remain:
  - Exclude narrowly by account and app
  - Require IP restrictions where possible
  - Put an expiry and replacement plan on the exception

### 3) Build policies in Report-only first (except emergency cases)
1. Create pilot groups:
   - CA-Pilot-IT
   - CA-Pilot-Business
2. Implement policies in Report-only:
   - Block legacy auth (Report-only)
   - Require MFA for all users (Report-only, but exclude break glass and any known automation accounts temporarily)
3. Validate with sign-in logs:
   - Sign-in logs -> select a sign-in -> Conditional Access tab
   - Confirm policies are evaluated as expected in report-only

### 4) Pilot enablement (controlled turn-on)
1. Enable policies for pilot groups only:
   - Assignments -> Users:
     - Include: pilot group(s)
     - Exclude: break glass accounts
2. Support readiness checks:
   - Ensure pilot users have MFA registered
   - Provide comms: what to expect, how to enroll, support contact
3. Monitor daily:
   - Sign-in failures
   - Helpdesk tickets
   - Legacy auth blocks

### 5) Expand rollout in stages
Typical stage gates
1. Stage 1: IT + early adopters (1 to 3 days)
2. Stage 2: 10 to 25% of org (1 week)
3. Stage 3: 50 to 75% (1 to 2 weeks)
4. Stage 4: 100% enforce

Operational controls
- Change window for enablement changes
- Freeze policy edits during peak business hours unless incident driven
- Maintain a documented exception request path with expiry

### 6) Enforcement and cleanup
1. Switch policies from Report-only to On
2. Remove per-user MFA if it conflicts with CA strategy (standardize on CA)
3. Confirm Security Defaults is disabled if using custom CA (avoid double controls)
4. Remove temporary exclusions and narrow exceptions
5. Document final policy set and export policy JSON/config state

## Verification
- Report-only logs show intended impact before enforcement
- After enforcement:
  - MFA challenges occur where expected
  - Legacy auth attempts are blocked
  - Admin sign-ins meet stronger controls
- Sign-in failure rate stabilizes after initial rollout period
- CA policies are documented, named consistently, and backed up (export)

## Prevention
- Adopt a standard CA baseline and never freestyle policies in production
- Quarterly access review:
  - Exceptions, excluded accounts, legacy auth usage
- Alerts for:
  - CA policy changes
  - MFA method changes
  - Break glass sign-ins
- Maintain a test tenant or lab group to validate policy changes before production

## Rollback
Rollback hierarchy (fastest to slowest)
1. Disable the newest policy change first (the one you just enabled)
2. Revert user scope from All users back to pilot group
3. Add temporary exclusion for impacted group (with expiry) if needed to restore operations
4. If catastrophic:
   - Disable CA policies in reverse order of rollout (legacy auth block last only if it is breaking critical apps and you have no alternative)
Always capture evidence of what you changed and when

## Evidence to collect
- Before and after exports of CA policies (names, assignments, controls, state)
- Sign-in log samples showing report-only evaluation and then enforcement results
- List of pilot groups and membership counts (not names, redact as needed)
- Exception list with business owner approvals and expiry dates
- Comms artifacts (announcement text, helpdesk KB links)
- Script outputs saved under `/evidence/identity-conditional-access-rollout/` (redacted)

## Next 3 actions
- Create `/evidence/identity-conditional-access-rollout/` and add redacted exports for CA policies plus sign-in log samples for report-only evaluation.
- Add a baseline CA policy naming standard and staged rollout checklist under `/story-packs/`.
- Implement or stub the referenced CA export and legacy auth detection scripts in `/scripts/`.
