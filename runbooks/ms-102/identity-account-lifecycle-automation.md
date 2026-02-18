# /runbooks/identity-account-lifecycle-automation.md

Tag: A/B

# Account Lifecycle Automation – Joiner / Mover / Leaver

## Symptoms

- New hire cannot access required systems
- User missing licenses or group membership
- Departed employee account still active
- Mailbox or OneDrive still consuming license after termination
- Inconsistent permissions across similar roles
- Manual provisioning causing delays or errors

---

## Scope

Covers:

- Entra ID user creation and automation
- Group-based licensing
- Dynamic vs assigned group strategy
- Role-based access alignment
- Secure offboarding
- License removal safety
- Mailbox and OneDrive retention handling

Applies to:

- Microsoft 365
- Entra ID
- Exchange Online
- SharePoint / OneDrive
- Intune (if device-bound access exists)

---

## Preconditions

- Global Admin or User Administrator role
- License Administrator role for SKU assignment
- Access to Microsoft Graph PowerShell SDK
- Established naming and group standards
- Defined department and role mapping model

---

## Triage Checklist

Before acting:

1. Confirm request source is authorized (HR or manager)
2. Confirm employment status and effective date
3. Validate department and role classification
4. Validate required license SKU
5. Confirm no legal hold or compliance hold applies (for leaver)
6. Confirm no shared mailbox or service account dependencies

---

## Fix Steps

### Joiner Workflow

1. Create user in Entra ID  
   - Set proper UPN format  
   - Enforce initial password reset  

2. Assign department and job title attributes  

3. Add user to role-based security groups  
   - Avoid direct license assignment  
   - Use group-based licensing only  

4. Validate license assignment via group membership  
   - Confirm SKU provisioning completes  
   - Confirm mailbox is created  

5. Assign Intune compliance group if required  

6. Validate login and MFA registration  

Automation Example (Graph PowerShell):

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"

New-MgUser -DisplayName "John Doe" `
  -UserPrincipalName "jdoe@domain.com" `
  -MailNickname "jdoe" `
  -AccountEnabled $true `
  -PasswordProfile @{
      ForceChangePasswordNextSignIn = $true
      Password = "TempPassword123!"
  }

Add-MgGroupMember -GroupId <LicenseGroupID> -DirectoryObjectId <UserID>