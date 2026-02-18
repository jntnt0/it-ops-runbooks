# /runbooks/md-102/intune-win32-app-deployment-failure-troubleshooting.md

Tag: B

# Win32 app deployment failure troubleshooting (Detection rules, return codes, targeting, Company Portal)

## Symptoms

- App shows Failed in Intune
- App stuck at Installing in Company Portal
- App never appears on device
- App installs but Intune still shows Not installed
- Required app does not auto-install
- User receives generic error in Company Portal

---

## Scope

Covers Win32 app (.intunewin) deployments via Intune:

- Detection rule failures
- Return code misconfiguration
- User vs device assignment errors
- Required vs Available deployment behavior
- Company Portal client-side behavior
- Basic log-based troubleshooting

Applies to:

- Windows 10/11 Intune-managed devices
- Win32 apps packaged with Microsoft Win32 Content Prep Tool

Excludes:

- Microsoft Store apps (separate runbook)
- LOB MSI apps added directly without wrapping (separate if needed)
- Autopilot ESP-specific blocking (separate runbook)

---

## Preconditions

- Win32 app already created in Intune
- App assigned to at least one group
- Device enrolled and checking in
- You can access device logs locally or via remote session

Minimum roles (least privilege):

- Intune Administrator (app configuration and assignments)
- Helpdesk role with device sync capability
- Global Reader (read-only validation)

---

## Triage Checklist

Before changing anything:

1) Confirm deployment type:
   - Required or Available?
2) Confirm assignment target:
   - User group or device group?
3) Confirm device is in target group
4) Confirm device check-in time
5) Confirm platform and OS version meet app requirements
6) Confirm architecture matches (x64 vs x86)
7) Confirm no supersedence or dependency conflicts
8) Identify exact error code or failure state in Intune

---

## Fix Steps

### Step 1: Confirm targeting logic (most common issue)

Open Intune:
Apps -> Windows -> Win32 app -> Assignments

Check:

- Required vs Available
- Group type (user vs device)
- Exclusions
- Filters

Common failure patterns:

A) App assigned to user group but device expected to install before login  
- Required user assignment installs only after user signs in.

B) App assigned to device group but testing as different user  
- Device assignment installs regardless of user login.

C) Device not in correct group  
- Verify dynamic or assigned membership
- Confirm Azure AD group membership updated

Fix:
- Align assignment with intent:
  - Device-targeted for baseline system apps
  - User-targeted for role-based apps
- Remove overlapping or conflicting assignments

---

### Step 2: Check detection rules (second most common issue)

Symptom:
App installs successfully, but Intune shows Failed or Not installed.

Go to:
App -> Properties -> Detection rules

Common mistakes:

- Checking wrong file path
- Checking wrong registry hive (HKCU vs HKLM)
- MSI product code mismatch
- Version comparison incorrect
- 32-bit vs 64-bit registry mismatch

Fix:

- Validate detection rule manually on device:
  - Confirm file path exists
  - Confirm registry value exists
  - Confirm product code matches installed app
- Adjust detection rule to match reality
- Re-sync device

Rule:
Detection must confirm install state accurately.  
If detection is wrong, reporting will always be wrong.

---

### Step 3: Validate return codes

Go to:
App -> Properties -> Return codes

Common failure:
Installer returns non-zero code but it is not marked as Success or Soft reboot.

Typical examples:

- 0 = Success
- 3010 = Soft reboot required
- 1641 = Hard reboot

If installer returns 3010 but not defined as Soft reboot, Intune may mark as Failed.

Fix:

- Capture installer return code from logs
- Add correct return code mapping:
  - Success
  - Soft reboot
  - Retry

Do not mark unknown non-zero codes as Success blindly. Validate first.

---

### Step 4: Review installation command

Go to:
App -> Properties -> Program

Check:

- Install command
- Uninstall command
- Install behavior (System vs User)
- Device restart behavior

Common issues:

- Running per-user installer as System
- Incorrect silent switches
- Installer requires elevated context but configured as User
- Installer writes to user profile but assigned as device/system

Fix:

- Test install command locally on device using same context
- Confirm silent switches are correct
- Align Install behavior with installer requirements

---

### Step 5: Check logs on device (IME logs)

Primary log location:

`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`

Important log:
- IntuneManagementExtension.log

Search for:

- App ID
- Exit code
- Detection result
- Download errors

If download fails:
- Check connectivity to Microsoft endpoints
- Check proxy/firewall restrictions
- Confirm device has enough disk space

Capture sanitized log snippets for evidence.

---

### Step 6: Company Portal behavior analysis

If deployment type is Available:

User must:

- Open Company Portal
- See app under Available apps
- Click Install

If app does not appear:

- Confirm user is in correct group
- Confirm no assignment filter excludes device
- Confirm app is available to correct device platform

If app stuck at Installing:

- Check IME logs
- Confirm no dependency waiting
- Confirm no pending reboot blocking

---

### Step 7: Supersedence and dependencies

Check:

- Does app supersede an older version?
- Are dependencies defined?
- Is dependency failing detection?

If dependency fails, primary app may fail.

Fix:

- Validate dependency detection and return codes
- Confirm correct install order

---

## Verification

- App shows Installed in Intune
- Detection rule confirms installation
- IME log shows Success
- No recurring retries
- If Required: installs automatically on newly enrolled device
- If Available: installs successfully via Company Portal

---

## Prevention

- Standardize packaging checklist:
  - Silent install verified
  - Detection rule validated locally
  - Return codes reviewed
  - Install behavior aligned (System vs User)
- Use device-targeting for baseline infrastructure apps
- Use user-targeting for role-based apps
- Test in pilot group before broad deployment
- Maintain version control for app packages
- Avoid overlapping assignments across multiple groups

---

## Rollback

If deployment causes widespread failure:

1) Remove Required assignment immediately
2) Revert to previous working version (if supersedence used)
3) Document faulty detection or return code mapping
4) Correct and redeploy to pilot group first

Never leave broken Required deployments assigned tenant-wide.

---

## Evidence to collect

Store under:

`/evidence/runbooks-md-102-intune-win32-app-deployment-failure-troubleshooting/`

Exports (redacted):
- App configuration (program, detection, return codes)
- Assignment list (groups + deployment type)
- Device install status report
- Group membership confirmation

Screenshots (redacted):
- Detection rule configuration
- Return code configuration
- Assignment view
- Company Portal showing failure or success

Logs (redacted):
- Relevant IME log snippet showing exit code and detection result

Notes:
- Root cause category (targeting, detection, return code, installer issue)
- Fix implemented
- Time to successful deployment
- Pilot vs broad impact summary

---

Next 3 actions
1) Commit this runbook to `/runbooks/md-102/intune-win32-app-deployment-failure-troubleshooting.md`.  
2) Intentionally misconfigure a detection rule in your lab, capture failure evidence, then fix it and capture the success state.  
3) Create a reusable Win32 packaging checklist file under `/templates/` to reduce future deployment errors.