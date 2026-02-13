# /INDEX.md

Tag: A

This is the navigation front door for the repo. Templates define the rules. Story packs define targets. Runbooks contain execution steps. Evidence contains artifacts.

## Start here

- Repo rules and standards:
  - /templates/legend-and-scope.md
  - /templates/contract.md

- Evidence guidance:
  - /evidence/README.md

## Runbooks (by exam)

- AZ-104
  - /runbooks/az-104/
  - Targets: /story-packs/az-104-targets.md

- MS-102
  - /runbooks/ms-102/
  - Targets: /story-packs/ms-102-targets.md

- MD-102
  - /runbooks/md-102/
  - Targets: /story-packs/md-102-targets.md

- SC-300
  - /runbooks/sc-300/
  - Targets: /story-packs/sc-300-targets.md

- SC-401
  - /runbooks/sc-401/
  - Targets: /story-packs/sc-401-targets.md

## Shared runbooks (fundamentals)

- /runbooks/shared/
  - DNS records and name resolution
  - DHCP scopes and options
  - VLANs and subnets
  - Basic routing and NAT
  - Kerberos vs NTLM
  - AD replication (high level)
  - Time sync for authentication
  - Certificates and PKI basics
  - Change management templates (pilot, rollback, comms)

## Scripts and IaC

- Scripts: /scripts/
- IaC: /iac/

## Evidence folder convention

- Evidence for a scenario lives at: /evidence/<scenario-slug>/
- Minimum files:
  - notes.md
  - timeline.md
  - exports/
  - screenshots/
  - commands/

## Suggested build order (so you do not stall)

1) Create shared fundamentals runbooks first under /runbooks/shared/
2) Build the first 5 SC-300 identity runbooks (they unblock MS-102 and MD-102 scenarios)
3) Build the first 5 MD-102 endpoint runbooks (Autopilot, compliance, app deployment, updates)
4) Build the first 5 MS-102 workload runbooks (mail flow, shared mailbox perms, OneDrive)
5) Build the first 5 AZ-104 runbooks (VNet, NSG, VM recovery, Monitor, Key Vault)

Next 3 actions
1) Commit this /INDEX.md plus the two template files, then create the four target files under /story-packs/.
2) Create the /runbooks/<exam>/ folders and a /runbooks/shared/ folder, even if empty, so links are valid.
3) Pick one target from SC-300 and write the first runbook using the template, saving real evidence under /evidence/<scenario-slug>/.