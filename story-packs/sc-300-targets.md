# /story-packs/sc-300-targets.md

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
- Canonical home: identity scenarios live under SC-300/Identity

SC-300 projects to work through via runbooks (queue)

Identity and authentication
1. Break-glass account build and validation (A)
- Create 2 emergency accounts, exclude from CA, test sign-in, document storage of creds

2. MFA rollout strategy with phased enforcement (B)
- Pilot group, exceptions, service accounts, staged enforcement, rollback plan

3. Auth Methods modernization (A/B)
- Migrate from SMS/voice to Authenticator, enforce number matching, disable legacy methods

4. Password spray response runbook (A/B)
- Sign-in logs triage, risky users, lockout strategy, named locations, CA response

5. Legacy authentication elimination (A/B)
- Identify legacy auth use, block with CA, test impact, document app exceptions

6. Self-service password reset end-to-end (A/B)
- Enable SSPR, test registration, combined registration, write troubleshooting tree

Conditional Access and access controls
7. Baseline Conditional Access policy set (B)
- Admin protection, user protection, device compliance, location rules, report-only first

8. CA troubleshooting lab and decision tree (A)
- CA block, token, license, risk, device, MFA, session

9. Session controls and token lifetime strategy (B/C)
- Sign-in frequency, persistent browser session, sign-out behavior, app session controls

10. Named locations and trusted network design (A/B)
- Create named locations, exclude break-glass, test from mobile vs home vs VPN

11. Guest and B2B access controls (B)
- Invite flows, guest CA, restrictions and monitoring

Identity governance
12. Access reviews program (B/C)
- Reviews for guest users and privileged roles, evidence and cadence

13. Entitlement Management access packages (B/C)
- Access package, approval workflow, expiration, access review tie-in

14. Lifecycle automation: joiner, mover, leaver (A/B)
- Dynamic groups, automated assignments, termination disable flow, offboarding checklist

15. Privileged Identity Management (PIM) implementation (C unless you have P2)
- Eligible roles, approval, MFA, justification, alerts, role access reviews

App access and federation
16. Enterprise app SSO onboarding pack (A/B)
- Add enterprise app, SSO basics, user assignment, claims mapping notes, troubleshooting

17. App consent and permissions governance (A/B)
- Consent settings, admin consent workflow, audit existing grants

18. Conditional Access for apps (A/B)
- Per-app CA, require compliant device for sensitive apps, test UX

19. Managed identities and service principals hygiene (A/B)
- Inventory service principals, rotate secrets, move to certs, document ownership and expiry alerts

RBAC and admin model
20. Role based access control design (least privilege) (A/B)
- Split roles: User Admin, Auth Admin, Conditional Access Admin, Helpdesk, etc
- Build a role map and show role assignments

21. Administrative Units segmentation (C in many labs)
- Use Administrative Units to limit scope, show why and how

Monitoring, logs, and operational readiness
22. Sign-in log and audit log evidence pipeline (A)
- Export logs, evidence structure, standard queries for incidents

23. Risk based remediation playbook (B/C)
- Risky users, risky sign-ins, remediation workflow and escalation

24. Secure score style identity hardening backlog (A/B)
- Turn recommendations into backlog with owner, effort, proof steps

Shared foundations to link, not duplicate (canonical /runbooks/shared)
- DNS/DHCP/AD concepts, Kerberos vs NTLM, time sync, PKI
- Change management: rollout phases, backout plans, comms plans, maintenance windows, risk analysis, documentation

Next 3 actions
1) Create /story-packs/sc-300-targets.md with this content and link it from /INDEX.md.
2) Start with items 1, 2, 4, 7, and 22 and capture evidence for each under /evidence/<scenario-slug>/.
3) Scope every CA and governance test to LAB-PILOT so licensing stays clean.