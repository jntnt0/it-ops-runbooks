# /story-packs/md-102-targets.md

Legend
A = Fully demonstrable via GitHub plus automation (scripts, IaC, exports, repeatable runs)
B = Fully demonstrable with a lab tenant and test devices (you can generate real evidence)
C = Mostly documentation and story pack only unless you have a real org environment

Assumptions (so A/B/C stays honest)
- Intune/MDM requires at least one enrollable Windows endpoint (physical or VM)
- Some scenarios need Windows Enterprise features to be fully realistic (note limitations in evidence)

Repo rule (prevents duplicate runbooks)
- One canonical runbook per scenario
- If a scenario is relevant to multiple exams, do not clone it. Link to the canonical runbook from the other exam index
- Canonical home: endpoint scenarios live under MD-102/Endpoint

MD-102 target projects (queue)

Enrollment and join
- Device enrollment failures (B)
- Autopilot end to end: hash import, profile assignment, ESP, enrollment flow (B)
- Hybrid join vs Entra join tradeoffs (C)

Compliance and configuration
- Intune policy conflict resolution (B)
- Why a device is non compliant and how you prove it (B)
- GPO vs Intune co management conflicts (C)

Apps and updates
- App deployment failures: Win32 detection rules, MSI vs EXE, return codes (B)
- Updating rings (B)
- Update rings and feature update policies strategy (B)
- Driver/firmware updates (B/C)

Device actions and BitLocker
- Remote wipe, retire, selective wipe scenarios (B)
- BitLocker escrow and recovery process in real life (B)

Endpoint security control plane
- Device isolation (B/C)
- ASR rules and common breakage (B/C)
- Web filtering and network protection basics (C)
- Local admin control: LAPS, privilege management story (B/C)

Ops and reporting
- Intune reports (B)
- Patch cadence and exceptions (A/B)
- Emergency patch procedure (A)

Story bank
- Deploying 100 laptops (C unless you simulate)
- “I deployed apps via Win32 packaging” (B)

Shared foundations to link, not duplicate (canonical /runbooks/shared)
- Wi-Fi basics, VPN types, firewall basics
- Change management: rollout phases, backout plans, comms plans, maintenance windows, risk analysis, documentation

Next 3 actions
1) Create /story-packs/md-102-targets.md with this content and link it from /INDEX.md.
2) Stand up one Windows VM or device enrollment path and complete Autopilot + compliance + one Win32 app deployment as your first evidence set.
3) Build the top 5 MD-102 runbooks as B with screenshots, exported reports, and device timelines under /evidence/<scenario-slug>/.