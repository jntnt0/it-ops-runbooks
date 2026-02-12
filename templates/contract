# /templates/contract.md

Tag: A

This is the short rules-only contract for the repo. If anything conflicts, this file wins.

## Non-negotiables

- Everything is copy-pasteable Markdown
- No duplicate runbooks: one canonical runbook per scenario, other places link to it
- Evidence never lives in /runbooks
- Every artifact gets an A/B/C tag near the top
- Every runbook ends with "Next 3 actions" and nothing after it

## Folder placement

- Canonical runbooks live under:
  - /runbooks/sc-300/ for identity scenarios
  - /runbooks/ms-102/ for tenant workload scenarios
  - /runbooks/md-102/ for endpoint scenarios
  - /runbooks/az-104/ for Azure resource scenarios
  - /runbooks/shared/ for true fundamentals used everywhere
- Targets live under: /story-packs/<exam>-targets.md
- Navigation lives in: /INDEX.md
- Templates live in: /templates/
- Evidence lives in: /evidence/<scenario-slug>/

## A/B/C truth rules

A = Demonstrable via repo automation and exports, repeatable without a real org  
B = Demonstrable in a lab tenant and test devices with real evidence  
C = Story pack only unless you have a real org environment  

Licensing truth:
- Entra P1 required for Conditional Access. Without it, CA items are C.
- Entra P2 required for PIM, Access Reviews, and Identity Governance depth. Without it, those items are C.
- Do not claim tenant-wide testing unless users targeted are actually licensed.

## Runbook required structure

Every runbook must contain these sections in this order:
1) Symptoms
2) Scope
3) Preconditions
4) Triage checklist
5) Fix steps
6) Verification
7) Prevention
8) Rollback
9) Evidence to collect

Runbook writing rules:
- Steps are ordered and executable
- Include portal paths and command examples
- Include a source-of-truth reference list (Microsoft docs or primary vendor docs)
- Include explicit rollback steps
- End with "Next 3 actions" only

## Evidence contract

Required for A and B runbooks.

Evidence folder:
- /evidence/<scenario-slug>/

Minimum files:
- notes.md
- timeline.md
- exports/
- screenshots/ (redacted)
- commands/

Redaction:
- Redact UPNs, tenant IDs, external IPs, and message content as needed
- Preserve timestamps, correlation IDs, error codes, and policy names
- Document redactions in notes.md

## Scripts contract

Every script must include:
- prerequisites
- least privilege notes
- safe logging (no secrets, tokens, PII)
- how to run (examples)
- outputs and evidence paths

## IaC contract

Every IaC artifact must include:
- what it deploys
- parameters and defaults
- least privilege notes
- how to deploy and tear down
- evidence outputs

Next 3 actions
1) Add /templates/contract.md and /templates/legend-and-scope.md to /INDEX.md as the repo rules of the road.
2) Create /story-packs/<exam>-targets.md files and keep backlogs there, not in templates.
3) Enforce the runbook structure and evidence rules for every new file you commit.