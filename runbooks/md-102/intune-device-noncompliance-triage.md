# /runbooks/md-102/intune-device-noncompliance-triage.md

Tag: B

# Device non-compliance triage (Encryption, Secure Boot, TPM, OS version, Defender)

## Symptoms

- Device shows Not compliant in Intune
- Conditional Access blocks access due to non-compliance
- Compliance policy status is Error / Not evaluated / Conflict
- User reports “Access blocked” for M365 apps on a managed device
- Compliance report shows stale or unknown device state

---

## Scope

Covers triage and remediation for Windows 10/11 device compliance in Intune, focusing on common controls:

- BitLocker / encryption
- Secure Boot
- TPM presence and readiness
- OS version (minimum build)
- Microsoft Defender / AV status (where applicable)

Applies to:

- Entra joined and hybrid joined devices managed by Intune
- Devices evaluated by Conditional Access with “Require compliant device”

Excludes:

- macOS/iOS/Android compliance specifics (separate runbooks)
- Endpoint malware incident response (separate runbook)
- Deep Autopilot enrollment failures (separate runbook)

---

## Preconditions

- Device is enrolled in Intune
- You can access Intune device record and compliance reports
- You can validate Conditional Access results (sign-in logs)
- You have a defined compliance policy baseline and targeting model

Minimum roles (least privilege):

- Helpdesk Operator (basic device actions) or Intune role that allows device read + sync
- Intune Administrator (policy troubleshooting and changes)
- Conditional Access Administrator (to validate CA enforcement)
- Global Reader (read-only triage)

---

## Triage Checklist

Do this in order. Do not guess.

1) Confirm the user impact:
   - Which app is blocked?
   - Is access blocked by Conditional Access?
2) Confirm device identity:
   - Correct device object (duplicate names are common)
3) Confirm device last check-in:
   - If stale, compliance may be wrong or outdated
4) Identify which compliance policy is failing:
   - Encryption, Secure Boot, TPM, OS version, Defender, other
5) Check if status is:
   - Not compliant (actual failure)
   - Error (evaluation issue)
   - Not evaluated (targeting or check-in issue)
   - Conflict (multiple policies)
6) Confirm the device is targeted correctly:
   - Included in compliance policy assignment
   - Not excluded by filter
7) Confirm there is no join state issue:
   - Entra joined vs registered confusion
8) Confirm Conditional Access is the enforcement mechanism:
   - Sign-in logs -> Conditional Access tab

---

## Fix Steps

### Step 1: Confirm CA is actually blocking (don’t chase the wrong thing)

Entra admin center -> Sign-in logs -> user -> failing sign-in

- Check Conditional Access tab
- If policy requires compliant device and result is Failure, proceed.
- If CA is not the reason, stop and use the relevant runbook (password, MFA, license, app issue).

---

### Step 2: Confirm device record and check-in health

Intune admin center -> Devices -> Windows -> select device

Check:

- Last check-in time
- Compliance status
- Managed by (Intune vs co-managed)
- Primary user (sanity)

If last check-in is stale:
- Trigger Sync from Intune device page
- Have user trigger Sync on device:
  Settings -> Accounts -> Access work or school -> Info -> Sync
- Recheck status after sync window

If device never updates:
- Enrollment or connectivity problem (separate runbook)

---

### Step 3: Identify the failing setting and remediate

Use Intune:
Device -> Device compliance -> Per-policy status (or Compliance policy view)

Handle common failures:

#### A) Encryption (BitLocker)

Common causes:
- BitLocker not enabled
- Encryption in progress
- Escrow key missing in Entra
- Device is using unsupported encryption type (rare)

Remediation:
1) Confirm BitLocker status on device (local)
   - Settings -> Privacy & security -> Device encryption
   - Or manage-bde status (collect output, redact)

2) Ensure encryption is enabled and completes
3) Confirm recovery key escrowed
   - Entra -> Devices -> device -> BitLocker keys (if available)
4) Trigger sync after encryption completes

If escrow is missing:
- Confirm the device is properly joined and enrolled
- Confirm policy that enforces escrow is assigned

---

#### B) Secure Boot

Common causes:
- Secure Boot disabled in BIOS/UEFI
- Device in legacy boot mode

Remediation:
1) Confirm Secure Boot state locally
2) Enable Secure Boot in BIOS/UEFI
3) Confirm device boots normally
4) Sync and re-evaluate compliance

This often requires hands-on or remote tooling with reboot.

---

#### C) TPM

Common causes:
- TPM disabled in BIOS/UEFI
- TPM not initialized/owned
- Older hardware lacking TPM 2.0

Remediation:
1) Confirm TPM presence and version locally
2) Enable TPM in BIOS/UEFI
3) Initialize TPM if required
4) Reboot and re-sync

If hardware lacks TPM 2.0:
- Document as exception path
- Replace device or adjust policy (only if business-approved)

---

#### D) OS version

Common causes:
- Device behind minimum build requirement
- Feature update policy not applied or stuck
- Update ring misassignment

Remediation:
1) Confirm minimum OS version in compliance policy
2) Confirm device OS version
3) Confirm update ring and feature update policy assignments
4) Force Windows Update scan and install
5) Reboot if required, then sync

If device is stuck:
- Use update drift remediation runbook

---

#### E) Defender status (AV / real-time protection / signatures)

Common causes:
- Defender disabled by third-party AV
- Signatures outdated
- Tamper protection issues
- Device not onboarded to Defender for Endpoint when required

Remediation:
1) Confirm what the policy is checking:
   - Defender enabled?
   - Real-time protection?
   - MDE onboarding?
2) If third-party AV is present, ensure policy is aligned to reality
3) Update Defender signatures and platform
4) Confirm services running
5) Sync and re-evaluate

Do not “fix” by weakening security policy unless you have a replacement control.

---

### Step 4: Handle errors, conflicts, and weird states

#### Compliance status = Error
Likely causes:
- Policy evaluation failure
- Device state reporting issue
- Conflicting settings sources (GPO vs Intune)

Actions:
- Check if multiple compliance policies target the device
- Remove conflicting targeting
- Confirm co-management workload ownership
- Re-enroll device if reporting is broken (last resort)

#### Compliance status = Not evaluated
Likely causes:
- Policy not assigned
- Device not checking in
- Assignment filters excluding device

Actions:
- Confirm policy assignments and filters
- Confirm device group membership
- Force sync

---

### Step 5: Temporary access restore (break-fix)

If the user is blocked and business impact is real:

Option A (preferred):
- Fix compliance quickly and re-evaluate

Option B (temporary):
- Put device or user into a time-boxed exception group used by Conditional Access
- Set an expiry and track it
- Remove once compliant

Do not create permanent “noncompliance bypass” groups.

---

## Verification

- Intune device shows Compliant
- Compliance policy status shows Success for target controls
- Conditional Access sign-in succeeds with “Compliant device” satisfied
- Device continues to report compliance after reboot and next check-in window

---

## Prevention

- Keep compliance policies minimal and standardized
- Align compliance requirements with hardware reality (TPM 2.0, Secure Boot)
- Use update rings and feature update policies to prevent OS version drift
- Monitor:
  - Devices not checked in
  - Devices failing encryption escrow
  - Devices failing Secure Boot/TPM
- Keep exception process strict: owner + justification + expiry

---

## Rollback

Rollback should be rare and controlled.

- If policy is too strict and breaks many devices:
  - Move enforcement to report-only temporarily
  - Fix underlying fleet issues
  - Re-enable enforcement after remediation window
- If a single device is mis-evaluated:
  - Do not change tenant-wide policy
  - Fix device or time-box exception

---

## Evidence to collect

Store under:

`/evidence/runbooks-md-102-intune-device-noncompliance-triage/`

Exports (redacted):
- Device compliance status report (before and after)
- Compliance policy settings and assignments
- Device record: last check-in, compliance state, OS version
- Conditional Access sign-in log entry showing compliance block (if applicable)

Screenshots (redacted):
- Device compliance blade showing failing setting
- Compliance policy configuration (requirements)
- CA policy requirement for compliant device
- Sign-in log CA tab for a blocked attempt

Commands (redacted, optional):
- `tpm.msc` summary or system info output
- Secure Boot state proof
- BitLocker status output
- Defender status output (high level)

Notes:
- Root cause category (encryption, secure boot, TPM, OS, Defender)
- Remediation steps taken
- Time to compliance restoration
- Exception use (if any) and expiry

---

Next 3 actions
1) Commit this runbook to `/runbooks/md-102/intune-device-noncompliance-triage.md`.  
2) In your lab, force one compliance failure (example: turn off Secure Boot or remove encryption requirement) and capture full before/after evidence.  
3) Link this runbook from your “User can’t sign in” root cause tree under the device compliance branch.