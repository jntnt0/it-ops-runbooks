# /scripts/README.md

Tag: A  
Artifact: Scripts index and standards  
Owner: IT Ops  
Last updated: 2026-02-12

## Purpose
This folder contains repeatable, least-privilege scripts used by runbooks to:
- Collect evidence (exports, logs, snapshots)
- Perform safe, reversible remediation where appropriate
- Standardize output formats for /evidence

## Rules (non-negotiable)
- No secrets in logs. Never print tokens, client secrets, refresh tokens, passwords, or full headers.
- Default to read-only. Evidence scripts should not modify state unless explicitly marked.
- Least privilege by design:
  - Document required roles/scopes per script.
  - Prefer Security Reader / Reports Reader for exports where possible.
- Safe logging:
  - Log timestamps in UTC.
  - Log counts, not raw objects, unless redacted output is the goal.
  - Write logs to a file, not just console.
- Deterministic outputs:
  - Always write to a specified output directory.
  - Use consistent filenames with UTC timestamps.
- Idempotent where possible:
  - If re-run, do not overwrite without a flag.
  - Support `-Force` or create a new timestamped folder.
- Every script must include a header with:
  - Purpose
  - Prerequisites
  - Required permissions / least privilege notes
  - Inputs
  - Outputs
  - How to run
  - Safety notes and rollback notes (if it changes anything)

## Standard output layout
Scripts should write into an incident/change folder under `/evidence/<scenario-slug>/.../scripts/`:

Example:
- `/evidence/identity-password-spray-response/2026-02-12_incident-01/scripts/`
  - `2026-02-12T031500Z_entra_signinlogs_failures.csv`
  - `2026-02-12T031500Z_entra_auditlogs.csv`
  - `2026-02-12T031500Z_script.log`
  - `2026-02-12T031500Z_notes.txt`

Filename format:
- `YYYY-MM-DDThhmmssZ_<system>_<artifact>.<ext>`
- Use UTC timestamps only.

## Execution environment
Supported shells and tooling:
- PowerShell 7+ preferred
- Windows PowerShell 5.1 acceptable for older modules
- Microsoft Graph PowerShell SDK for Entra/M365 data pulls where possible

Install guidance (example)
- PowerShell 7: install via winget or official installer
- Graph module:
  - `Install-Module Microsoft.Graph -Scope CurrentUser`
  - `Update-Module Microsoft.Graph`

## Authentication standards
Preferred auth patterns:
- Interactive delegated auth for lab and manual runs
- Certificate-based app auth for automation (no client secrets in plaintext)

Rules:
- Use `Connect-MgGraph` with explicit scopes and smallest set of permissions.
- Disconnect after completion.
- Do not cache tokens to disk unless explicitly documented.

## Evidence collection scripts (planned set)
Identity
- `entra-export-signinlogs.ps1`
  - Export sign-in logs for a time window, optional user/app/IP filters
- `entra-export-auditlogs.ps1`
  - Export audit logs for a time window, optional user/category filters
- `entra-export-ca-policies.ps1`
  - Export Conditional Access policies (names, assignments, state) to JSON/CSV
- `entra-export-risky-users.ps1`
  - Export risky users/sign-ins (requires licensing; script must detect and note if unavailable)
- `entra-export-oauth-consents.ps1`
  - Export OAuth consent grants / enterprise app consents (tenant-wide, filterable)

M365 / Exchange
- `m365-export-mailbox-config.ps1`
  - Export mailbox forwarding, inbox rules, delegates (read-only)
- `m365-message-trace-export.ps1`
  - Export message trace results for a time window (read-only)

## Script template (copy/paste skeleton)
Every new script should start with this header and behavior:

- Parameter block:
  - `-OutDir` (required)
  - `-StartUtc` / `-EndUtc` (for log exports)
  - `-WhatIf` for any script that could change state
  - `-Force` to allow overwrite or new folder creation
- Logging:
  - Start transcript to `*.log`
  - Write a `*_notes.txt` summary with counts and key filters

## How runbooks reference scripts
Runbooks should include:
- Exact command line example
- Expected output files
- Where to place artifacts under `/evidence/<scenario-slug>/.../`

Example reference
- `pwsh ./scripts/entra-export-signinlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -OutDir "./evidence/identity-password-spray-response/2026-02-12_incident-01/scripts"`

## Next 3 actions
- Add a `/scripts/_template.ps1` that implements the standard header, parameter block, safe logging, and output layout.
- Implement `entra-export-signinlogs.ps1` and `entra-export-auditlogs.ps1` first since multiple runbooks depend on them.
- Add a short section to each script documenting the minimum roles/scopes required and what happens when licensing features are unavailable.