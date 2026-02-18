# /runbooks/ms-102/exchange-mail-flow-troubleshooting-message-trace-connectors-spf-dkim-dmarc.md

Tag: B

# Mail flow troubleshooting (Message trace, connectors, SPF/DKIM/DMARC)

## Symptoms

- User reports email not delivered
- Sender receives NDR (non-delivery report)
- Email marked as spam unexpectedly
- External sender cannot reach your domain
- Internal to external mail fails
- External to internal mail fails
- Mail delayed significantly
- DMARC/SPF failure reported by third party

---

## Scope

Covers Exchange Online mail flow troubleshooting:

- Message trace analysis
- Transport rules impact
- Connector configuration
- SPF record validation
- DKIM configuration
- DMARC alignment and failures

Applies to:

- Microsoft 365 Exchange Online tenants
- Domains hosted in M365
- Hybrid environments at high level (connector logic only)

Excludes:

- On-prem Exchange deep transport pipeline
- Advanced third-party gateway appliances (separate runbook)

---

## Preconditions

- Affected message details:
  - Sender address
  - Recipient address
  - Approximate timestamp (with timezone)
  - Subject (if possible)
- Access to Exchange admin center
- Access to DNS records for domain

Minimum roles (least privilege):

- Exchange Administrator
- Security Reader (for threat insights)
- Global Reader (limited visibility)

---

## Triage Checklist

Before making changes:

1) Confirm scope:
   - One sender?
   - One recipient?
   - One domain?
   - All mail?
2) Determine direction:
   - Internal to internal
   - Internal to external
   - External to internal
3) Confirm timestamp and timezone
4) Collect NDR details (error code, SMTP response)
5) Confirm domain status in M365 (verified, active)

Do not change DNS or connectors before confirming trace results.

---

## Fix Steps

### Step 1: Run message trace (source of truth)

Exchange admin center -> Mail flow -> Message trace

Filter by:
- Sender
- Recipient
- Date/time range
- Status (All, Failed, Pending)

Review:

- Delivery status
- Event timeline
- Transport rule hits
- Connector used
- Spam filtering verdict
- Final action (Delivered, Quarantined, Failed, Dropped)

If message not found:
- Confirm correct tenant
- Confirm correct timestamp
- Confirm message actually left sending system

---

### Step 2: Interpret NDR codes

Common patterns:

5.1.1 – User not found  
- Recipient address incorrect
- Mailbox missing or deleted

5.7.1 – Access denied / policy block  
- Transport rule
- Anti-spam policy
- Connector restriction
- SPF/DMARC failure enforcement

4.x.x – Temporary failure  
- Transient network or DNS issue
- Retry likely

Never ignore the exact SMTP code.

---

### Step 3: Connector logic validation

Exchange admin center -> Mail flow -> Connectors

Check:

- Inbound connectors (from partner/on-prem)
- Outbound connectors (to smart host or partner)

Validate:

- Scope (which domains apply)
- TLS settings
- Certificate validation
- IP restrictions
- Domain restriction (restricted to specific domains?)

Common failure:

- Connector restricted to specific domain but sender using different domain
- TLS mismatch
- Incorrect smart host configuration

Test:

- Send test mail
- Confirm which connector is used in message trace

Do not leave overly broad connectors enabled.

---

### Step 4: Transport rules (mail flow rules)

Exchange admin center -> Mail flow -> Rules

Check:

- Block rules
- Redirect rules
- Header modification
- Forwarding or rejection logic

Common issues:

- Rule too broad (affects all senders)
- Rule misconfigured condition
- Rule priority order incorrect

If a rule is suspected:
- Disable temporarily (controlled test)
- Re-run test
- Adjust conditions precisely

---

### Step 5: SPF validation

Check DNS:

TXT record for domain:

Example:
v=spf1 include:spf.protection.outlook.com -all

Validate:

- No multiple SPF records
- Includes correct sending systems
- No syntax errors
- Not exceeding DNS lookup limits

Common SPF issues:

- Third-party sender not included
- Multiple SPF records (invalid)
- Using ~all when policy expects -all

Use external validation tools if needed, but record results.

---

### Step 6: DKIM validation

Exchange admin center -> DKIM

Check:

- DKIM enabled for domain
- CNAME records correctly published
- Selector matches expected configuration

If DKIM not enabled:
- Enable and publish CNAMEs
- Wait for DNS propagation

If DKIM failing:
- Validate DNS records
- Confirm domain alignment

---

### Step 7: DMARC validation

Check DNS:

TXT record at:
_dmarc.domain.com

Example:
v=DMARC1; p=quarantine; rua=mailto:reports@domain.com;

Check:

- Policy (none, quarantine, reject)
- Alignment mode (aspf, adkim)
- Reporting addresses

Common DMARC issues:

- Strict alignment causing legitimate mail to fail
- Third-party sender failing SPF/DKIM alignment
- DMARC set to reject without validating flows first

Fix approach:

- Confirm SPF or DKIM alignment passes
- Adjust third-party sender configuration
- Do not weaken DMARC permanently without justification

---

### Step 8: Quarantine and threat policies

If message trace shows Quarantined:

Exchange admin center -> Threat management -> Review quarantine

Check:

- Spam verdict
- Phish verdict
- Malware detection

If false positive:
- Release message (controlled)
- Adjust anti-spam policy or allow list carefully

Do not blanket allow domains without review.

---

## Verification

- New test email successfully delivered
- Message trace shows Delivered status
- No unexpected connector used
- SPF passes
- DKIM passes
- DMARC aligned
- No unintended rule triggered
- No new NDRs generated

---

## Prevention

- Maintain single authoritative SPF record
- Enable DKIM for all accepted domains
- Monitor DMARC reports
- Review connectors quarterly
- Review transport rules quarterly
- Avoid overlapping or redundant connectors
- Document third-party senders and required DNS entries

---

## Rollback

If change breaks mail flow:

1) Re-enable previous connector settings
2) Restore prior DNS record (SPF/DKIM/DMARC)
3) Disable new transport rule
4) Re-test with pilot mailbox before full validation

Document every mail flow change with timestamp and reason.

---

## Evidence to collect

Store under:

`/evidence/runbooks-ms-102-exchange-mail-flow-troubleshooting-message-trace-connectors-spf-dkim-dmarc/`

Exports (redacted):
- Message trace results (CSV)
- Connector configuration summary
- Transport rule list
- DNS record outputs (SPF, DKIM, DMARC)

Screenshots (redacted):
- Message trace event details
- Connector configuration page
- DKIM status page
- DNS TXT record view

Notes:
- Direction of mail flow (inbound/outbound/internal)
- SMTP error code
- Root cause (SPF, DKIM, connector, rule, quarantine)
- Fix applied
- Validation test result

---

Next 3 actions
1) Commit this runbook to `/runbooks/ms-102/exchange-mail-flow-troubleshooting-message-trace-connectors-spf-dkim-dmarc.md`.  
2) In your lab, intentionally misconfigure SPF or create a test transport rule to generate a failure and capture full evidence.  
3) Add a DNS validation checklist template under `/templates/` for reuse across domains.