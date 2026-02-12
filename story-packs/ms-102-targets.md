# /story-packs/ms-102-targets.md

Legend
A = Fully demonstrable via GitHub plus automation (scripts, IaC, exports, repeatable runs)
B = Fully demonstrable with a lab tenant and test devices (you can generate real evidence)
C = Mostly documentation and story pack only unless you have a real org environment

Assumptions (so A/B/C stays honest)
- Entra ID P1 required for real Conditional Access work (otherwise CA items become C)
- Entra ID P2 required for full PIM, Access Reviews, and deeper Identity Governance (otherwise those items are C)

Repo rule (prevents duplicate runbooks)
- One canonical runbook per scenario
- If a scenario is relevant to multiple exams, do not clone it. Link to the canonical runbook from the other exam index
- Canonical home: identity scenarios live under SC-300/Identity, tenant workload scenarios live under MS-102/M365, Azure resource scenarios live under AZ-104/Azure

MS-102 target projects (queue)

1) M365 tenant admin scenarios (canonical MS-102 unless noted)
- Mailbox/Teams issues (B/C)
- Mail flow troubleshooting: message trace, connectors, SPF/DKIM/DMARC failures (B)
- Shared mailbox permissions issues (B)
- Teams client cache problems (B/C)
- Teams calling issues: SIP, firewall, QoS basics (C)
- SharePoint permission inheritance disasters (B/C)
- OneDrive sync failures (B)
- License assignment automation (A/B)

2) Tenant hygiene and licensing (canonical MS-102)
- License assignment strategy: group-based, SKU sprawl control, audits (A/B)
- Baseline configuration: domains, DNS verification, mail routing, branding (B/C)
- Service health and vendor escalation:
  - How you triage when Microsoft is down: Service Health, message center, advisories (A/B)
  - What you collect before opening a ticket: correlation IDs, timestamps, user impact, traces (A)
  - Communicating outages without panicking the business (A)

3) Security operations and incident response (tenant impact view, canonical MS-102 unless noted)
- Compromised account response playbook (A/B) [Canonical identity steps live in SC-300, MS-102 focuses on M365 impact checks]
- Disable token sessions and force sign out everywhere (A/B) [Canonical SC-300, MS-102 links]
- Audit logs and sign-in logs usage (A/B)
- Defender quarantine and investigation (B/C)
- Data loss prevention policies (B/C)
- Backup and restore of mailbox and files (B/C)
- Ransomware containment steps (C)

4) Compliance and data governance (mostly MS-102 adjacencies, deeper coverage under SC-401)
- Retention, litigation hold, mailbox auditing (B/C)
- Transport rules and safe handling: do not break workflows (B)
- Spam/phish policy tuning and false positives process (B/C)
- Purview sensitivity labels and what they actually do (B/C)
- DLP concepts in practice: block, audit, exceptions (B/C)
- eDiscovery basics: who can do what, where data lives (B/C)
- Audit log retention and what requires premium licensing (B/C)

5) Identity integration points (MS-102 links to canonical SC-300)
- Password spray response (A/B) [Link to SC-300 canonical]
- Conditional Access rollout (B) [Link to SC-300 canonical]
- MFA rollout strategy (B) [Link to SC-300 canonical]
- SSO and hybrid identity (C) [Link to SC-300 canonical]
- RBAC design for Entra roles and PIM (A/B/C) [Link to SC-300 canonical]
- User can’t sign in root cause tree (A/B) [Link to SC-300 canonical]

6) Story bank (what you must be able to explain in interviews)
- Onboarding 50 users (C unless simulated with tenant)
- Migrating mailboxes (C)
- Responding to a compromise (B/C)
- Enforcing MFA and Conditional Access (B) [Link to SC-300 canonical]
- Cleaning up DNS and mail flow (B/C)
- Automating repetitive work (A)

7) Shared foundations to link, not duplicate (canonical /runbooks/shared)
- DNS records (A, AAAA, CNAME, MX, TXT, SRV) (A/B)
- Basic DNS/DHCP/AD concepts (A/B)
- Kerberos vs NTLM basics (A)
- How AD replication works at a high level (A/B)
- Why time sync matters for auth (A)
- Certificates and PKI basics (A/B)
- Firewall basics and VPN types (A/B/C depending)
- Change management: rollout phases, backout plans, comms plans, maintenance windows, risk analysis, documentation (A)

Next 3 actions
1) Create /story-packs/ms-102-targets.md with this content and link it from /INDEX.md.
2) Create an MS-102 runbooks index page that links to canonical runbooks and to SC-300 links where identity is canonical.
3) Start with the top 5 B items and collect evidence under /evidence/<scenario-slug>/ for each.