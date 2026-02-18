# /templates/evidence-method.md

Tag: A  
Artifact: Evidence collection method (runbook execution)  
Last updated: 2026-02-18

## Purpose
Make evidence collection boring, repeatable, and consistent so every runbook execution produces the same predictable structure and file naming.

## Scope
Applies to all scenarios under /runbooks for MD-102, SC-300, AZ-104, MS-102, plus anything in /runbooks/shared.

## Non-negotiables
- Never commit raw, unredacted logs to git.
- No secrets, tokens, keys, certificates, client secrets, refresh tokens, session cookies.
- Redact PII: UPNs/emails, phone numbers, device serials, hostnames if sensitive, tenant IDs, domain names, external IPs (mask if needed), message content.
- Preserve what matters: timestamps, error codes, correlation IDs (mask only if required), policy names, return codes, rule names.

## Evidence folder model
1) One evidence root per runbook is created by the scaffold workflow:
- /evidence/<scenario-slug>/

2) Inside that folder, you store your artifacts in these standard subfolders:
- commands/      CLI and PowerShell outputs, transcripts, config snippets (redacted)
- exports/       CSV/JSON exports from portals or Graph (redacted)
- screenshots/   redacted screenshots (only when exports are not available)
- notes.md       short write-up (what happened, impact, root cause, fix)
- timeline.md    timestamped timeline (T0, T1, T2)
- README.md      folder index (links to key artifacts and outcomes)

Optional (use only when relevant):
- ioc/           indicators (masked)
- policy/        policy exports (CA, Intune, Exchange rules)
- runs/          separate executions when you want clean separation

## Scenario slug rules (so paths do not rot)
Scenario slugs should be stable and safe for paths:
- allowed: lowercase letters, numbers, hyphen
- pattern: [a-z0-9-]+

Avoid spaces and special characters in runbook filenames because the scaffold workflow derives slugs from runbook paths.

## Naming convention (files)
Use UTC-style timestamps in filenames so evidence stays sortable.

Recommended:
- YYYYMMDD-HHMMZ_<source>_<artifact>_<redacted>.ext

Examples:
- 20260218-0310Z_entra_signinlogs_filtered.csv
- 20260218-0315Z_entra_auditlogs_filtered.csv
- 20260218-0330Z_intune_devicecompliance_report.csv
- 20260218-0345Z_powershell_transcript_export-signinlogs.txt
- 20260218-0350Z_cli_show-run_interface-status.txt
- 20260218-0405Z_ca_policy_baseline-export.json
- 20260218-0410Z_message-trace_result.csv

Rules:
- prefer descriptive filenames over “final” or “new”
- never include real usernames or tenant domains in filenames
- if you must include an identifier, mask it (example: user-jdoe, ip-1.2.x.x)

## Minimum evidence set by tag
Tag A (automation-backed)
Required:
- exports/ from scripts or Graph (CSV/JSON)
- commands/ transcript of script execution and key outputs (counts, filters, time range)
- notes.md and timeline.md updated
Recommended:
- policy/ exports if you changed configuration

Tag B (lab tenant + test device)
Required:
- exports/ where possible, screenshots/ only when there is no export
- commands/ for device-side checks (BitLocker, TPM, MDM enrollment, Defender status)
- notes.md and timeline.md updated

Tag C (documentation/story pack)
Required:
- notes.md and timeline.md updated with “what you would collect in prod”
Recommended:
- a “mock” export showing schema only (no real data), or redacted sample output

## Execution method (use this every time)
1) Start with a clean evidence folder
- Confirm /evidence/<scenario-slug>/ exists (run scaffold workflow if missing).
- Create missing subfolders only from the standard list above.

2) Capture baseline before you change anything
- Export or screenshot current state (policy, device status, mailbox rules, etc).
- Save it under exports/ or screenshots/ with a timestamped filename.
- Add a one-paragraph baseline note in notes.md.

3) Run triage commands and exports
- Prefer exports (CSV/JSON) over screenshots.
- Save CLI outputs and PowerShell transcripts under commands/.
- Log only counts and high-level fields (avoid dumping full objects with PII).

4) Apply fix and capture “after” state
- Export the same view again after the change.
- Save as a separate timestamped file (before vs after is proven by timestamps).

5) Verification artifacts are mandatory
- Capture the success signal: sign-in succeeds, app installs, policy applies, compliance flips, mail delivers, etc.
- Save one artifact that proves success (export or screenshot).

6) Update notes.md and timeline.md
notes.md must include:
- what happened
- impact
- root cause (best available)
- fix applied
- follow-ups and prevention

timeline.md must include:
- T0 detection
- T1 triage
- T2 fix
- T3 verification
- any escalation points

7) Commit hygiene
- Review changes before commit:
  - git status
  - git diff
- Use selective add:
  - git add -p evidence/<scenario-slug>/
- If you are unsure whether something is safe, do not commit it.

## Evidence review checklist (quick gate)
- No usernames/emails/tenant IDs in screenshots or exports
- No tokens/secrets in transcripts
- Baseline + after state exists for any configuration change
- At least one verification artifact exists
- notes.md and timeline.md updated

## If licensing or features are unavailable
When a portal feature is missing due to licensing, record it explicitly in notes.md:
- What you expected to export
- What licensing prevented
- What alternate evidence you collected (screenshots, limited exports, mock schema, or story-pack narrative)

## Optional: multi-run separation (when one folder gets messy)
If you run the same scenario many times, create:
- /evidence/<scenario-slug>/runs/YYYY-MM-DD_<type>-01/

Inside each run folder, reuse the same standard subfolders:
- commands/, exports/, screenshots/, plus README.md, notes.md, timeline.md

Root folder README.md becomes the index linking to each run.

## Next 3 actions
1) Add this file as /templates/evidence-method.md.
2) Update /templates/legend-and-scope.md and /evidence/README.md to link to this file as the single source of truth for evidence collection.
3) Add one line to every runbook “Evidence to collect” section: “Follow /templates/evidence-method.md for folder layout and naming.”
