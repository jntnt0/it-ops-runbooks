# /templates/legend-and-scope.md

Tag: A

This file is the stable repo contract. It defines the A/B/C legend, repo rules, evidence rules, and writing standards. It does not contain project backlogs. Project targets live under /story-packs/.

## A/B/C legend

A = Fully demonstrable via GitHub plus automation (scripts, IaC, exports, repeatable runs)  
B = Fully demonstrable with a lab tenant and test devices (you can generate real evidence)  
C = Mostly documentation and story pack only unless you have a real org environment  

## Assumptions (so A/B/C stays honest)

- Entra ID P1 required for real Conditional Access work (otherwise Conditional Access items become C)
- Entra ID P2 required for full PIM, Access Reviews, and deeper Identity Governance (otherwise those items become C)
- Endpoint runbooks marked B require at least one enrollable Windows endpoint (physical or VM) plus the needed licensing
- Do not claim a feature was tested tenant-wide unless the users targeted are actually licensed

## Repo rule (prevents duplicate runbooks)

- One canonical runbook per scenario
- If a scenario is relevant to multiple exams, do not clone it. Link to the canonical runbook from the other exam index
- Canonical home:
  - Identity scenarios live under /runbooks/sc-300/ (Identity)
  - Tenant workload scenarios live under /runbooks/ms-102/ (M365)
  - Endpoint scenarios live under /runbooks/md-102/ (Endpoint)
  - Azure resource scenarios live under /runbooks/az-104/ (Azure)

## Repo folder structure

/runbooks/shared/  
/runbooks/az-104/  
/runbooks/ms-102/  
/runbooks/md-102/  
/runbooks/sc-300/  
/runbooks/sc-401/

/scripts/  
/iac/  
/evidence/  
/story-packs/  
/templates/  

## Runbook template contract (required headings)

Every runbook under /runbooks must include these sections in this order:

1) Symptoms  
2) Scope  
3) Preconditions  
4) Triage checklist  
5) Fix steps  
6) Verification  
7) Prevention  
8) Rollback  
9) Evidence to collect  

Also required:
- Tag: A/B/C near the top
- Actionable, ordered steps
- Include both portal path steps and scriptable evidence collection references when applicable
- Source of truth trail for major steps (Microsoft documentation or primary vendor docs)
- End with a section titled "Next 3 actions" and nothing after it

## Evidence standards

Evidence is mandatory for A and B runbooks, and optional but recommended for C runbooks.

Evidence storage rules:
- Store evidence under: /evidence/<scenario-slug>/
- Do not store evidence in /runbooks/

Minimum evidence set (unless the runbook specifies more):
- /evidence/<scenario-slug>/notes.md
- /evidence/<scenario-slug>/timeline.md
- /evidence/<scenario-slug>/exports/ (CSV/JSON exports)
- /evidence/<scenario-slug>/screenshots/ (redacted)
- /evidence/<scenario-slug>/commands/ (CLI outputs, scripts run, transcripts)

Naming conventions:
- Prefer explicit names and timestamps when useful:
  - sign-in-logs_YYYYMMDD-HHMM.csv
  - audit-logs_YYYYMMDD-HHMM.csv
  - conditional-access-policy_<name>_export.json
  - intune-device-report_<device>_YYYYMMDD.csv
  - message-trace_<message-id>_YYYYMMDD.csv

Redaction rules:
- Redact UPNs, tenant IDs, external IPs, message content as needed
- Preserve timestamps, correlation IDs, error codes, policy names
- Note redactions in notes.md

## Scripts contract (/scripts)

Every script must include:
- prerequisites
- least privilege notes
- safe logging guidance (no secrets, no tokens, no PII)
- how to run (examples)
- expected outputs and where they are saved under /evidence/

## IaC contract (/iac)

Every IaC artifact must include:
- what it deploys
- parameters and defaults
- least privilege notes
- how to deploy
- how to tear down
- evidence outputs (deployment outputs, screenshots/exports if applicable)

## Where project target lists live

- /story-packs/<exam>-targets.md contains the backlog and priorities per exam
- /INDEX.md links to runbooks, targets, templates, and evidence guidance

Next 3 actions
1) Create /templates/legend-and-scope.md with this content and link it from /INDEX.md.
2) Ensure every runbook follows the required headings and ends with "Next 3 actions" only.
3) Keep targets out of templates and store them only under /story-packs/.