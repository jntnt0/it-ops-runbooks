# /runbooks/sc-300/identity-mfa-rollout-strategy-enforcement.md

Tag: B

# MFA Rollout Strategy + Enforcement (Break glass, service accounts, phased rollout)

## Symptoms

- Users are not being prompted for MFA when they should be
- Users are being locked out due to MFA enforcement without preparation
- Legacy auth or “basic auth” workflows still bypass controls
- Admin accounts are protected inconsistently
- Service accounts or automations break after MFA enforcement
- Rollout causes widespread helpdesk impact

---

## Scope

Covers planning, rollout, and enforcement of MFA using:

- Conditional Access (preferred)
- Authentication methods policy (registration controls)
- Break glass account strategy
- Service account and automation exceptions
- Phased enforcement and rollback

Applies to:

- Entra ID tenant access
- Microsoft 365 apps
- Azure management and admin portals

Excludes:

- Detailed phishing-resistant MFA implementation (separate runbook)
- On-prem ADFS/3rd-party IdP MFA specifics (separate runbook)

---

## Preconditions

- Entra ID licensing that supports Conditional Access for target users (tenant reality varies)
- At least two break glass accounts created and tested
- An emergency access procedure documented and stored offline
- A defined pilot group and enforcement groups
- Ability to review sign-in logs and Conditional Access results

Minimum roles (least privilege):

- Conditional Access Administrator (create and manage CA policies)
- Security Administrator / Authentication Policy Administrator (auth methods policy tasks)
- Global Reader (read-only review)

---

## Triage Checklist

Before changing anything:

1. Verify current MFA enforcement mechanisms in use:
   - Security Defaults enabled?
   - Per-user MFA enabled (legacy)?
   - Conditional Access policies already requiring MFA?
2. Confirm at least two break glass accounts exist and can sign in.
3. Identify service accounts, app registrations, and automations that could break.
4. Identify legacy auth usage (for visibility and cleanup).
5. Confirm an initial pilot group exists and includes a small, representative set.
6. Confirm how users will register MFA methods (communications + timing).

---

## Fix Steps

### Step 1: Establish break glass correctly (non-negotiable)

Create two emergency access accounts that are:

- Cloud-only (no hybrid dependency)
- Strong unique passwords stored offline
- Excluded from all Conditional Access policies (explicit exclusion)
- No mailbox license unless required
- Monitored (alerts on sign-in)

Break glass configuration checklist:

- Accounts named clearly (example: `bg-admin-01`, `bg-admin-02`)
- Protected with the strongest password policy you can enforce
- Tested quarterly
- Use only during incident recovery

Evidence expectation:
- A screenshot of CA exclusions and a sign-in test log entry (redacted)

---

### Step 2: Identify and classify account types

You will break things if you treat every account the same.

Classify:

A) Humans (interactive sign-in)  
- Should use MFA

B) Admin humans (Tier 0)  
- Must use MFA first, no exceptions

C) Service accounts (non-interactive)  
- Should not be used for interactive sign-in
- Replace with managed identity, workload identity federation, or app registrations

D) Automations (scripts, runbooks, connectors)  
- App-only auth or certificate-based auth preferred
- Eliminate user/password flows

---

### Step 3: Build policies in the right order (phased enforcement)

#### Phase 0: Visibility (report-only)

Goal: see impact before breaking people.

- Create a Conditional Access policy in Report-only:
  - Users: pilot group
  - Cloud apps: All cloud apps (or start with Office 365 + Azure management)
  - Grant: Require multifactor authentication
  - Exclude: break glass accounts
  - Conditions: set as needed (device platforms if you want to limit noise)

Monitor:
- Sign-in logs -> Conditional Access tab -> Report-only results

Exit criteria:
- You can list the top failure reasons and fix them proactively.

---

#### Phase 1: Protect admins first (enforce)

Policy: Require MFA for admin roles

- Users: Directory roles (Global Admin, Privileged Role Admin, etc.)
- Cloud apps: All cloud apps (or at minimum Azure management + M365 admin portals)
- Grant: Require multifactor authentication
- Exclude: break glass accounts

Hard rule:
- Do not exclude day-to-day admins because they complain.
- Fix their enrollment and device issues.

Exit criteria:
- All admins can sign in reliably with MFA.
- No admin accounts using legacy auth paths.

---

#### Phase 2: Block legacy authentication tenant-wide (enforce)

This removes the easiest bypass routes.

Policy: Block legacy authentication clients

- Users: All users
- Cloud apps: All cloud apps
- Conditions -> Client apps: legacy authentication clients
- Grant: Block access
- Exclude: break glass accounts (optional, but keep consistent)

Exit criteria:
- Legacy auth sign-ins drop to near zero.
- Any remaining are tracked to specific devices or apps with remediation plan.

---

#### Phase 3: Require MFA for all users (enforce)

Policy: Require MFA for all users (phased)

- Users: pilot group first, then broader groups, then all users
- Grant: Require multifactor authentication
- Exclude: break glass accounts
- Optional: exclude service accounts only if they are proven non-interactive (prefer fixing them instead)

Phasing model:
- Pilot (IT + power users)
- Wave 1 (low-risk departments)
- Wave 2 (rest)
- Enforcement (all)

Exit criteria:
- User registration is stable.
- Helpdesk volume returns to baseline.

---

### Step 4: Service accounts and automation handling

This is where most rollouts fail.

Rules:

- No shared passwords for automation accounts.
- No “service account” should be signing in interactively.
- Convert automations to app-only auth where possible.

Common remediations:

- Graph automation: app registration + certificate, or workload identity federation for GitHub Actions
- Azure: managed identities for resources, or service principals with least privilege
- Legacy apps that only support basic auth:
  - Replace app
  - Use modern auth capable integration
  - If unavoidable: isolate with strict controls and documented exception with expiry date

Exception policy standard:

- Create an “MFA exception” group
- Membership must:
  - Have business justification
  - Have an owner
  - Have an expiry date
  - Be reviewed weekly until eliminated

Do not allow “forever exceptions.”

---

### Step 5: Registration strategy (stop the chaos)

You need a registration plan, not just enforcement.

- Communicate ahead of time
- Provide approved methods (Authenticator app, FIDO2 keys if applicable)
- Provide a process for lost device recovery
- Train helpdesk on method reset procedure

---

## Verification

For each phase:

- Confirm policies are in correct state (Report-only or On)
- Perform sign-in tests:
  - Admin sign-in to admin portal requires MFA
  - Regular user sign-in requires MFA (in enforced waves)
  - Legacy auth attempts are blocked
- Validate Sign-in logs show expected CA results

Success indicators:

- Admin sign-ins: MFA required and successful
- User sign-ins: MFA success rate high
- Legacy auth: blocked events logged, not successful sign-ins
- Exceptions: time-boxed and decreasing

---

## Prevention

- Enforce policy drift control:
  - No ad hoc CA exclusions
  - Use change control for CA modifications
- Review MFA exceptions weekly
- Monitor risky sign-ins and MFA failures
- Quarterly break glass test
- Maintain documented “lost device / MFA reset” helpdesk workflow

---

## Rollback

Rollback order (fastest risk reduction first):

1) If widespread outage: disable “MFA for all users” policy first  
2) If admin outage: use break glass account to recover, do not disable admin policy unless tenant is unusable  
3) If legacy app outage: temporarily add scoped exception group with expiry, then remediate properly  

Document every rollback with:
- what broke
- why the change was needed
- what you will do to prevent repeat

---

## Evidence to collect

Store under:

`/evidence/runbooks-sc-300-identity-mfa-rollout-strategy-enforcement/`

Exports (redacted):
- Conditional Access policies list (policy name, state, assignments, grant controls)
- Sign-in logs showing:
  - Report-only evaluation
  - Enforcement success for admins
  - Legacy auth blocks
  - User MFA prompts in enforced wave

Screenshots (redacted):
- Each CA policy configuration page (assignments + grant controls + client apps)
- Break glass exclusion evidence
- Sign-in log entry showing CA policy applied

Notes:
- Rollout timeline (phase dates)
- Pilot group membership and feedback summary
- Exception list with expiry dates and owners

---

Next 3 actions
1) Commit this runbook to `/runbooks/sc-300/identity-mfa-rollout-strategy-enforcement.md`.  
2) Run the scaffold workflow to generate the evidence folder automatically.  
3) In your lab tenant, implement Phase 0 and Phase 1 and capture sign-in log evidence for both.