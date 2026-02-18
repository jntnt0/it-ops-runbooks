# /runbooks/ms-102/sharepoint-onedrive-sync-failure-troubleshooting.md

Tag: B

# OneDrive sync failure troubleshooting

## Symptoms

- OneDrive icon shows “Sync paused” or “Sync error”
- Files not uploading to cloud
- Files not downloading to local device
- “You’re not signed in” message
- Red X on specific files
- Sync client stuck on “Processing changes”
- Access blocked by Conditional Access
- User sees “We can’t sync this library”

---

## Scope

Covers troubleshooting of the OneDrive sync client for:

- OneDrive for Business
- SharePoint document library sync
- Entra ID authentication issues
- Conditional Access related sync blocks
- File/path limitations
- Client health and version issues

Applies to:

- Windows 10/11 devices
- Intune-managed and unmanaged devices
- Microsoft 365 tenants

Excludes:

- SharePoint permission architecture deep dive
- Tenant-wide service outage (use service health runbook)
- macOS-specific troubleshooting (separate runbook)

---

## Preconditions

- User UPN
- Affected device name
- Time issue started
- Error message screenshot (if available)
- Access to Intune device record (if managed)

Minimum roles (least privilege):

- SharePoint Administrator (site access review)
- Global Reader (read-only checks)
- Helpdesk Operator (basic guidance)
- Conditional Access Administrator (if CA involved)

---

## Triage Checklist

Before changing anything:

1) Confirm scope:
   - One user or multiple?
   - One device or all devices?
2) Confirm service health:
   - Microsoft 365 admin center -> Service health
3) Confirm user license includes OneDrive
4) Confirm OneDrive site is provisioned
5) Confirm user can access OneDrive via web browser
6) Confirm device join state and compliance
7) Confirm OneDrive client version

---

## Fix Steps

### Step 1: Confirm cloud-side health

Test:

- User signs into https://portal.office.com
- Open OneDrive in web
- Confirm files visible and accessible

If web access fails:

- Check license assignment
- Check account sign-in status
- Check Conditional Access block
- Check SharePoint admin center for site existence

If web works but sync fails:
- Likely client-side issue

---

### Step 2: Confirm license and site provisioning

Microsoft 365 admin center:

Users -> Active users -> Licenses

Verify:

- OneDrive/SharePoint service plan enabled

SharePoint admin center:

Active sites -> Filter by OneDrive

Confirm:

- User site exists
- Not locked or set to read-only

If site missing:
- Trigger provisioning by accessing OneDrive in web
- Wait for creation

---

### Step 3: Conditional Access impact

Entra admin center -> Sign-in logs

Filter by:
- User
- Application: Office 365 SharePoint Online

If CA policy fails:

- Check Conditional Access tab
- Identify requirement:
  - Compliant device
  - MFA
  - Location restriction

Remediate:

- Fix compliance issue (use device non-compliance runbook)
- Ensure MFA completed
- Validate device is Entra joined

---

### Step 4: Client-side basic remediation

On affected device:

1) Confirm OneDrive icon in system tray
2) Check for error message
3) Ensure signed in with correct account

If signed out:
- Sign back in
- Confirm correct tenant

If stuck on “Processing changes”:
- Pause and resume sync
- Restart device
- Check network stability

---

### Step 5: Reset OneDrive client (controlled)

If persistent client error:

Run OneDrive reset command:

`%localappdata%\Microsoft\OneDrive\OneDrive.exe /reset`

Then:

- Restart OneDrive manually
- Sign in again
- Monitor re-sync

Use reset only after confirming no cloud-side issue.

---

### Step 6: File/path limitations

Common causes:

- File path exceeds 400 characters
- Unsupported characters in filename
- Invalid file types
- Large files exceeding limit

Check:

- Error details for specific file
- Path length and characters
- Rename or move file to shorter path

---

### Step 7: Disk space and local issues

Check:

- Available disk space
- Antivirus interference
- User profile corruption

If profile corrupted:
- Create new Windows profile (controlled test)
- Re-sync

---

### Step 8: SharePoint library sync issues

If syncing SharePoint library:

- Confirm user has correct permissions
- Confirm library not deleted or renamed
- Remove and re-add library sync
- Confirm no duplicate libraries mapped

---

## Verification

- OneDrive icon shows “Up to date”
- No red X files
- Files created locally appear in web
- Files created in web sync to device
- No Conditional Access failures in sign-in logs
- Sync persists after device reboot

---

## Prevention

- Standardize OneDrive client version (keep current)
- Enforce device compliance if required by CA
- Educate users on path length and invalid characters
- Monitor:
  - Storage quota
  - Sync error reports
- Avoid manual manipulation of OneDrive folder structure

---

## Rollback

If remediation causes new issue:

1) Revert client reset if profile corruption suspected
2) Restore user profile if changed
3) Remove incorrect policy change
4) Re-validate cloud access before further action

Avoid deleting local OneDrive folder without backup validation.

---

## Evidence to collect

Store under:

`/evidence/runbooks-ms-102-sharepoint-onedrive-sync-failure-troubleshooting/`

Exports (redacted):
- Sign-in logs (if CA involved)
- License assignment proof
- SharePoint site status
- Intune device compliance state (if relevant)

Screenshots (redacted):
- OneDrive client error message
- Sign-in log CA tab (if blocked)
- SharePoint site existence
- OneDrive status “Up to date” after fix

Logs (redacted):
- OneDrive client logs (if deep troubleshooting needed)

Notes:
- Root cause category (license, CA, client corruption, path limit, disk space)
- Fix applied
- Time to restore sync
- User validation confirmation

---

Next 3 actions
1) Commit this runbook to `/runbooks/ms-102/sharepoint-onedrive-sync-failure-troubleshooting.md`.  
2) In your lab, simulate a file path length error or temporarily disable license to generate a controlled failure and capture evidence.  
3) Link this runbook to your “User can’t sign in” and “Device non-compliance” runbooks for cross-reference.