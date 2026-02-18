# /runbooks/md-102/intune-bitlocker-escrow-and-recovery-process.md

Tag: B

# BitLocker escrow and recovery process (Proof in Entra, access controls, audit trail)

## Symptoms

- User locked out of device due to BitLocker recovery screen
- Recovery key not found in Entra
- Conditional Access blocks access because encryption not confirmed
- Helpdesk cannot access recovery key due to insufficient permissions
- Audit request: “Who accessed this recovery key and when?”

---

## Scope

Covers Windows BitLocker key escrow and recovery when managed by:

- Entra ID (Azure AD) joined devices
- Intune-managed devices
- Hybrid-joined devices where keys are stored in Entra

Includes:

- Confirming escrow presence
- Secure recovery key retrieval
- Access control for recovery key viewing
- Audit and logging of recovery key access
- Validation after recovery

Excludes:

- On-prem AD DS-only escrow (separate runbook)
- macOS FileVault (separate runbook)
- BitLocker policy configuration in depth (separate baseline runbook)

---

## Preconditions

- Device is Entra joined or hybrid joined
- BitLocker policy configured to require key escrow
- Helpdesk role assigned for recovery key access (least privilege)
- You can identify device by hostname or device ID

Minimum roles (least privilege):

- Helpdesk Administrator (can view recovery keys)
- Security Administrator (audit review)
- Global Reader (read-only validation)
- Intune Administrator (policy troubleshooting if escrow failing)

---

## Triage Checklist

Before retrieving any recovery key:

1) Confirm device identity:
   - Device hostname
   - User assigned
   - Device ID
2) Confirm the person requesting the key is authorized:
   - Validate identity (call-back verification if needed)
3) Confirm the device is corporate-owned
4) Confirm the recovery screen displays:
   - Recovery key ID (first 8 characters)
5) Confirm escrow expectation:
   - Device enrolled in Intune?
   - BitLocker policy assigned?
   - Join state correct?

Do not retrieve or share keys without identity validation.

---

## Fix Steps

### Step 1: Confirm BitLocker escrow in Entra

Entra admin center:

Devices -> All devices -> Select device -> BitLocker keys (if available)

OR

Search device by name in Entra -> Device -> Recovery keys

Verify:

- Recovery key exists
- Recovery key ID matches the one displayed on device
- Timestamp of escrow present

If key exists:
- Proceed to controlled recovery

If key does NOT exist:
- Confirm:
  - Device is properly joined
  - Encryption policy enforces escrow
  - Device had network connectivity during encryption
- Check Intune device record and compliance status
- If escrow truly failed:
  - Document as gap
  - Consider re-encryption after fixing policy

---

### Step 2: Controlled recovery process

1) Validate identity of user requesting key
2) Confirm device ownership
3) Confirm recovery key ID on screen matches Entra
4) Provide recovery key verbally or via secure channel
5) Do not email recovery key in plain text

After unlock:

- Confirm device boots successfully
- Confirm BitLocker remains enabled
- Confirm device syncs to Intune

---

### Step 3: Validate recovery key access controls

Review:

Entra -> Roles and administrators -> Helpdesk Administrator (or equivalent)

Confirm:

- Only authorized roles can read BitLocker recovery keys
- No excessive Global Admin dependency
- No broad Reader roles unnecessarily able to retrieve keys

Hard rule:
- Do not allow general IT staff full directory-level admin just to retrieve keys.

---

### Step 4: Audit trail review

Entra audit logs:

Filter for:

- Category: DeviceManagement or Directory
- Activity: BitLocker key retrieval (or equivalent audit event)
- Target: Device or recovery key object
- Actor: Admin account retrieving key

Verify:

- Who accessed the key
- When it was accessed
- From what IP/location (if available)

Document:

- Incident reference
- Requesting user
- Approver (if applicable)
- Admin retrieving key

---

### Step 5: Post-recovery validation

After successful unlock:

1) Confirm BitLocker is still enabled
2) Confirm recovery key remains escrowed
3) Confirm no policy drift occurred
4) If recovery was triggered by hardware change (BIOS update, TPM reset):
   - Confirm Secure Boot and TPM status
   - Re-sync device
   - Confirm compliance state

If escrow was missing:
- Re-enable encryption after correcting policy
- Confirm new key is escrowed before closing ticket

---

## Verification

- Recovery key ID matches Entra escrow entry
- Device successfully unlocked and operational
- Intune device record shows compliant encryption state
- Audit logs show recovery key access event
- No unauthorized access to recovery key detected

---

## Prevention

- Enforce BitLocker policy requiring:
  - Encryption enabled
  - Recovery key escrow to Entra
- Block encryption if escrow fails (where possible)
- Periodically audit:
  - Devices without recovery keys
  - Helpdesk roles with recovery key access
- Document and enforce identity validation procedure
- Use least privilege roles for key retrieval
- Monitor recovery key access events

---

## Rollback

If recovery key was shared incorrectly:

1) Document incident immediately
2) Escalate to security team
3) Consider:
   - Re-encrypting device (rotate key)
   - Resetting user credentials
4) Review access controls and remove excess permissions

If escrow policy change caused issues:

- Revert policy change
- Confirm devices re-escrow keys properly
- Validate compliance status

---

## Evidence to collect

Store under:

`/evidence/runbooks-md-102-intune-bitlocker-escrow-and-recovery-process/`

Exports (redacted):
- Device record showing BitLocker recovery key present
- Audit log entries showing recovery key access
- Compliance policy configuration for encryption
- Device compliance status (before and after recovery)

Screenshots (redacted):
- Recovery key ID match (device screen vs Entra view)
- BitLocker key escrow page in Entra
- Audit log entry showing key retrieval event

Notes:
- Identity validation steps taken
- Reason for recovery event (hardware change, BIOS update, etc.)
- Admin retrieving key
- Post-recovery compliance status

---

Next 3 actions
1) Commit this runbook to `/runbooks/md-102/intune-bitlocker-escrow-and-recovery-process.md`.  
2) In your lab, trigger a BitLocker recovery event and validate escrow + audit logging before and after retrieval.  
3) Review and document which Entra roles in your tenant can access recovery keys and reduce scope if over-privileged.