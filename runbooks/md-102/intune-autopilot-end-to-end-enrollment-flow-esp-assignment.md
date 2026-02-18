# /runbooks/md-102/intune-autopilot-end-to-end-enrollment-flow-esp-assignment.md

Tag: B

# Autopilot end to end (Enrollment flow, ESP, assignment, lab scenario)

## Symptoms

- Device does not enter Autopilot flow at OOBE
- User cannot sign in during Autopilot
- Enrollment Status Page (ESP) stuck or failing
- Device not receiving assigned profile
- Apps or policies not applying during provisioning
- Device ends in wrong join state

---

## Scope

Covers full Windows Autopilot lifecycle in Intune:

- Hardware hash registration
- Autopilot profile assignment
- User-driven deployment flow
- Enrollment Status Page (ESP) behavior
- Policy and app delivery during provisioning
- Post-enrollment validation

Applies to:

- Windows 10/11 devices enrolled via Autopilot
- Lab and production scenarios

Excludes:

- White glove/pre-provisioning deep dive
- Hybrid Autopilot specifics beyond high-level checks
- Non-Windows Autopilot

---

## Preconditions

- Intune tenant configured
- At least one Windows device available (physical or VM that supports TPM/UEFI)
- Autopilot profile created
- Device group structure defined
- User licensed for Intune + M365

Minimum roles (least privilege):

- Intune Administrator
- Cloud Device Administrator (if needed)
- Global Reader (validation)
- User Administrator (for test account)

---

## Triage Checklist

Before enrolling:

1) Confirm device hardware hash registered in Autopilot
2) Confirm Autopilot profile exists
3) Confirm profile assigned to correct device group
4) Confirm test user licensed for Intune
5) Confirm no conflicting enrollment restrictions
6) Confirm join type intent (Entra join vs Hybrid)

---

## Fix Steps

### Step 1: Import device (Hardware hash registration)

Intune path:

Devices -> Windows -> Windows enrollment -> Devices -> Import

Options:

- Manually upload CSV (lab scenario)
- OEM-provided registration (production)

Verify:

- Device appears in Autopilot devices list
- Assigned profile shows correctly
- Deployment profile state = Assigned

If profile not assigned:
- Confirm group membership
- Confirm dynamic group rule if used
- Wait for sync cycle

---

### Step 2: Create and assign Autopilot profile

Intune path:

Devices -> Windows -> Windows enrollment -> Deployment Profiles

Typical lab configuration:

- Deployment mode: User-driven
- Join to: Microsoft Entra ID
- User account type: Standard (preferred)
- Allow pre-provisioning: optional
- Skip privacy settings: yes (lab)
- Skip Cortana/OEM screens: yes
- Apply device name template if desired

Assign profile to device group.

Verify:

- Device shows profile assigned before OOBE reset

---

### Step 3: Reset device and initiate OOBE

On device:

- Reset Windows (Settings -> System -> Recovery -> Reset this PC)
- Or wipe via Intune (for managed device)

At OOBE:

- Connect to internet
- Device should show:
  “Welcome to <Organization Name>”

If it does NOT:

- Confirm hardware hash exists
- Confirm profile assignment
- Confirm device not already enrolled and stuck
- Confirm internet connectivity

---

### Step 4: Enrollment flow (User-driven)

User signs in with Entra credentials.

Flow stages:

1) Azure AD join
2) MDM enrollment
3) ESP (Enrollment Status Page)
4) Policy and app deployment

Monitor ESP:

- Device preparation
- Device setup
- Account setup

Common failure points:

- Required apps failing install
- Network/proxy blocking endpoints
- Device restart loop
- Compliance policy blocking completion

---

### Step 5: Enrollment Status Page (ESP) troubleshooting

ESP settings:

Intune -> Devices -> Windows -> Enrollment -> Enrollment Status Page

Check:

- Are required apps blocking device use?
- Is timeout configured?
- Is user allowed to skip if installation fails?

If ESP stuck:

1) Identify which app or policy is failing
2) Check IME logs
3) Confirm required apps are properly packaged
4) Confirm network connectivity
5) If needed, temporarily adjust ESP to not block on specific non-critical apps (lab only)

Hard rule:
Do not disable ESP controls in production just to “make it work.”

---

### Step 6: Assignment validation

After enrollment:

In Intune device record:

Check:

- Join type (Entra joined)
- Compliance state
- Assigned policies
- Assigned apps
- Primary user

Validate:

- Device is in correct groups
- Update ring assigned
- Compliance policy assigned
- Required apps installed

If wrong configuration applied:

- Confirm group membership logic
- Confirm no conflicting dynamic rules
- Confirm assignment filters not excluding device

---

### Step 7: Post-enrollment compliance and access test

Test:

- User can sign into M365 apps
- Conditional Access satisfied (if requiring compliant device)
- Device shows Compliant in Intune
- Update ring applied
- BitLocker enabled and escrowed
- Required apps installed

---

## Verification

- Device appears in Autopilot devices list with profile assigned
- OOBE shows organization branding
- Device joins Entra ID successfully
- ESP completes without blocking errors
- Device appears as Compliant in Intune
- Sign-in logs show successful join and compliant access

---

## Prevention

- Use pilot Autopilot group before broad deployment
- Keep required app list minimal for ESP blocking
- Validate Win32 apps thoroughly before marking Required
- Maintain clean group targeting (no overlap confusion)
- Standardize profile settings across environment
- Periodically review Autopilot devices list for stale entries

---

## Rollback

If enrollment fails broadly:

1) Pause new device provisioning
2) Review last policy/app changes
3) Revert recent app assignment if causing ESP block
4) Adjust profile only if root cause identified
5) Re-test with pilot device before reopening enrollment

If single device failure:

- Re-wipe device
- Reconfirm profile assignment
- Reattempt enrollment

---

## Evidence to collect

Store under:

`/evidence/runbooks-md-102-intune-autopilot-end-to-end-enrollment-flow-esp-assignment/`

Exports (redacted):
- Autopilot device list showing profile assignment
- Deployment profile configuration
- ESP configuration
- Device record after enrollment (join type, compliance state)
- Assigned policies and apps

Screenshots (redacted):
- OOBE screen showing organization branding
- ESP progress screens
- Intune device summary after enrollment
- Sign-in log for initial enrollment

Logs (redacted):
- IME log snippet if troubleshooting failure
- Enrollment event logs if relevant

Notes:
- Enrollment timeline (OOBE start to completion)
- Any ESP blocking issues encountered
- Policy/app adjustments made
- Final compliance and access validation results

---

Next 3 actions
1) Commit this runbook to `/runbooks/md-102/intune-autopilot-end-to-end-enrollment-flow-esp-assignment.md`.  
2) Run a full lab Autopilot enrollment and capture each stage as evidence.  
3) Link this runbook from your update rings and compliance runbooks to show lifecycle continuity.