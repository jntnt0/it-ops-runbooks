# /README.md

Tag: A

This repo is a runbook driven lab and operations playbook for:
- AZ-104 (Azure Administrator)
- MS-102 (Microsoft 365 Administrator)
- MD-102 (Endpoint Administrator)
- SC-300 (Identity and Access Administrator)
- SC-401 (Information Protection and Compliance Administrator)

It is structured to produce repeatable, evidence backed runbooks, not loose notes.

## How to use this repo

1) Start at /INDEX.md
- It links to targets, runbooks, templates, and evidence rules.

2) Pick a target from /story-packs/<exam>-targets.md
- Targets are the backlog and priorities per exam.

3) Execute the runbook under /runbooks/<exam>/
- Follow steps, collect evidence, store artifacts under /evidence/<scenario-slug>/.

4) Keep it honest
- Do not claim features exist if your SKU does not include them.
- Use the A/B/C tags to tell the truth about what is demonstrable.

## Key repo rules

- One canonical runbook per scenario. Do not duplicate runbooks.
- Shared fundamentals live under /runbooks/shared/.
- Evidence never lives in /runbooks/.
- Every runbook must include the required headings and end with "Next 3 actions" only.

See:
- /templates/legend-and-scope.md
- /templates/contract.md

## Repo layout

/runbooks/
- /shared/
- /az-104/
- /ms-102/
- /md-102/
- /sc-300/
- /sc-401/

/story-packs/
- <exam>-targets.md files (project queues)

/templates/
- legend-and-scope.md
- contract.md

/scripts/
- automation and evidence collection helpers

/iac/
- Bicep, ARM, Terraform

/evidence/
- /<scenario-slug>/ evidence folders per runbook

## Evidence standard

Path:
- /evidence/<scenario-slug>/

Minimum:
- notes.md
- timeline.md
- exports/
- screenshots/ (redacted)
- commands/

Redaction:
- Redact UPNs, tenant IDs, external IPs, message content as needed
- Preserve timestamps, correlation IDs, error codes, policy names
- Note redactions in notes.md

## Recommended build order

1) /runbooks/shared fundamentals first
2) SC-300 identity runbooks (unblocks MS-102 and MD-102)
3) MD-102 endpoint runbooks
4) MS-102 workload runbooks
5) AZ-104 Azure runbooks

Next 3 actions
1) Commit /README.md and /INDEX.md, then commit the templates under /templates/.
2) Create the /story-packs/<exam>-targets.md files and commit them.
3) Write the first shared fundamental runbook under /runbooks/shared/ and collect evidence under /evidence/<scenario-slug>/.