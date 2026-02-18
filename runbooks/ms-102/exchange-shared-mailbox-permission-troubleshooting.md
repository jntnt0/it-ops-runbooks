# /runbooks/ms-102/exchange-shared-mailbox-permission-troubleshooting.md

Tag: B

# Shared mailbox permission troubleshooting

## Symptoms

- User cannot open shared mailbox in Outlook
- Shared mailbox not auto-mapping
- User can see mailbox but cannot send from it
- “You do not have permission to send as this user”
- Shared mailbox appears in OWA but not Outlook desktop
- Permissions recently changed but behavior not updated

---

## Scope

Covers Exchange Online shared mailbox access issues:

- Full Access permissions
- Send As permissions
- Send on Behalf permissions
- Auto-mapping behavior
- Outlook desktop vs OWA behavior
- Permission propagation delays

Applies to:

- Microsoft 365 Exchange Online
- Shared mailboxes (not user mailboxes)

Excludes:

- Distribution list permissions
- On-prem Exchange
- Mailbox delegation for executives (covered separately if needed)

---

## Preconditions

- Shared mailbox name and primary SMTP address
- Affected user UPN
- Approximate time issue began
- Access to Exchange admin center
- Ability to review permissions

Minimum roles (least privilege):

- Exchange Administrator
- Global Reader (read-only validation)
- Helpdesk Administrator (if delegated)

---

## Triage Checklist

Before making changes:

1) Confirm the mailbox type is Shared (not user mailbox)
2) Confirm the mailbox still exists and is licensed appropriately (shared mailboxes under 50GB typically unlicensed)
3) Confirm user is assigned:
   - Full Access (for reading)
   - Send As (for sending as)
   - Send on Behalf (if required)
4) Confirm user is signing into correct account
5) Confirm issue scope:
   - One user?
   - Multiple users?
   - All shared mailboxes?
6) Confirm Outlook vs OWA behavior
7) Confirm no recent permission changes

---

## Fix Steps

### Step 1: Validate mailbox exists and is healthy

Exchange admin center:

Recipients -> Mailboxes -> Shared

Check:

- Mailbox type = Shared
- No unexpected conversion to user mailbox
- Not soft-deleted
- No license conflict (if size > 50GB, license required)

If mailbox missing:
- Restore if recently deleted
- Recreate only if necessary (document impact)

---

### Step 2: Validate permissions

Exchange admin center -> Shared mailbox -> Delegation

Check:

- Full Access
- Send As
- Send on Behalf

Common issue patterns:

A) User has Full Access but not Send As  
Result: Can open mailbox but cannot send from it.

B) User has Send As but not Full Access  
Result: Cannot open mailbox in Outlook.

C) Permissions assigned directly to user but group membership changed  
Result: Access inconsistency.

Fix:

- Use group-based delegation where possible
- Avoid stacking redundant permissions
- Add missing required permission explicitly

---

### Step 3: Confirm permission propagation

Permissions can take time to propagate.

After changes:

- Wait 15–60 minutes
- Have user:
  - Fully close Outlook
  - Reopen Outlook
  - Restart device if necessary

If urgent:
- Remove and re-add permission
- Force profile refresh (last resort)

---

### Step 4: Auto-mapping troubleshooting

Auto-mapping works only when:

- Full Access is granted directly to user
- Not through a security group

If user has Full Access via group:
- Mailbox will NOT auto-map automatically
- Must add mailbox manually in Outlook

If auto-mapping not working:

Option A:
- Remove and re-add Full Access (direct assignment)

Option B:
- Instruct user to manually add mailbox:
  Outlook -> Account Settings -> More Settings -> Advanced -> Add mailbox

Document which approach your org standard uses.

---

### Step 5: Send As vs Send on Behalf behavior

Clarify difference:

Send As:
- Message appears from shared mailbox only

Send on Behalf:
- Message shows “User on behalf of Shared Mailbox”

If user reports wrong sender format:

- Confirm correct delegation type
- Remove incorrect permission
- Add correct permission
- Restart Outlook

---

### Step 6: Outlook vs OWA comparison

Test in OWA:

- If OWA works but Outlook fails:
  - Likely local Outlook profile issue
  - Remove and re-add mailbox
  - Recreate Outlook profile (last resort)

If neither works:
- Permission or mailbox configuration issue

---

### Step 7: Check for hidden conflicts

If behavior inconsistent:

- Confirm no duplicate mailbox objects
- Confirm no overlapping group-based permissions
- Confirm no recent mailbox type conversion
- Confirm no Conditional Access restriction impacting shared mailbox access

---

## Verification

- User can open shared mailbox in Outlook and OWA
- User can send from mailbox (Send As or Send on Behalf as intended)
- Auto-mapping works as expected (if using direct assignment)
- No NDR when sending from shared mailbox
- No repeated permission-related errors

---

## Prevention

- Use group-based delegation for consistency
- Document delegation standard:
  - Full Access + Send As for operational mailboxes
- Avoid assigning both Send As and Send on Behalf unnecessarily
- Periodically audit:
  - Shared mailbox permissions
  - Orphaned users in delegation lists
- Document mailbox ownership and business owner

---

## Rollback

If permission change causes issues:

1) Restore prior delegation from audit logs
2) Remove unintended delegation
3) Confirm only intended users have access
4) Notify mailbox owner of changes

Avoid emergency broad access grants.

---

## Evidence to collect

Store under:

`/evidence/runbooks-ms-102-exchange-shared-mailbox-permission-troubleshooting/`

Exports (redacted):
- Shared mailbox delegation list
- Group membership if using group-based delegation
- Audit log showing permission changes
- Message trace (if sending issue involved)

Screenshots (redacted):
- Shared mailbox delegation configuration
- Outlook error message
- OWA access confirmation

Notes:
- Permission type involved (Full Access, Send As, Send on Behalf)
- Root cause (missing permission, propagation delay, auto-mapping behavior)
- Fix applied
- Validation test result

---

Next 3 actions
1) Commit this runbook to `/runbooks/ms-102/exchange-shared-mailbox-permission-troubleshooting.md`.  
2) In your lab, intentionally remove Send As or Full Access from a test mailbox and capture the failure and fix evidence.  
3) Create a small shared mailbox delegation standard document under `/templates/` to prevent future misconfiguration.