# /runbooks/ops/evidence-collection-standards.md

Tag: A

## Symptoms

- Evidence is incomplete, inconsistent, or unusable during review
- You cannot reproduce what happened from the artifacts in /evidence
- Logs or screenshots contain secrets, user PII, or tenant identifiers that should not be in git
- Runbooks drift into “trust me bro” because proof is missing

## Scope

Covers:

- Standard evidence folder layout and file naming
- What to capture for commands, exports, screenshots, and timelines
- Redaction rules and what never belongs in the repo
- Linking evidence to the canonical runbook
- Minimum evidence sets per incident/change/runbook execution

Not covered:

- Vendor-specific forensic tooling
- SIEM engineering or long-term log retention design

## Preconditions

- Repo uses the standard structure:
  - /runbooks
  - /scripts
  - /iac
  - /evidence
  - /templates
- Evidence scaffolding exists per runbook at:
  - /evidence/<runbook-path-slug>/
  - with subfolders: commands/, exports/, screenshots/ plus notes.md and timeline.md
- You can capture outputs from:
  - CLI (PowerShell, Azure CLI, network device CLI)
  - Portals (Azure, Entra, Intune, M365)
  - Log exports (CSV/JSON/EVTX) where allowed

## Triage checklist

1. What are you proving?
   - failure exists
   - root cause
   - fix applied
   - verification passed
2. What is the minimum set of artifacts to prove it?
3. Can you capture the evidence without storing secrets or PII?
4. Are you using the correct evidence folder for the runbook slug?
5. Are timestamps recorded in UTC in timeline.md?

## Fix steps

### Step 1: Use the standard evidence folder layout

For every runbook, evidence lives under:

- /evidence/<slug>/
  - commands/
  - exports/
  - screenshots/
  - notes.md
  - timeline.md

Slug rules:

- Derived from relative runbook path without extension
- Replace folder separators with hyphens

Example:

- Runbook: /runbooks/az-104/vnet-nsg-troubleshooting-flow.md
- Evidence folder: /evidence/runbooks-az-104-vnet-nsg-troubleshooting-flow/

Do not invent new layouts per runbook. Consistency beats creativity.

### Step 2: File naming standard (simple, searchable, sortable)

Use:

- <artifact>-<scope>-<yyyymmdd>-<hhmmZ>.<ext>

Rules:

- Always include UTC time with Z
- Keep <artifact> short but specific
- <scope> is subscription, rg, host, device, or user category where relevant
- Use safe extensions:
  - .txt for command outputs
  - .json or .csv for exports
  - .png for screenshots
  - .evtx only if scrubbed and allowed

Examples:

- commands/az-role-assignment-list-sub123-20260218-0315Z.txt
- exports/signins-admin-20260218-0320Z.json
- screenshots/portal-nsg-effective-rules-vm1-20260218-0322Z.png

### Step 3: Commands evidence standards (commands/)

What goes here:

- Raw CLI outputs that prove state:
  - show commands (network)
  - az commands (Azure)
  - PowerShell outputs (Entra/Intune/M365)
- Include the command you ran and the output
- Prefer copy-pasteable plain text

Minimum expectations:

- A “before” capture
- A “change applied” capture (if you changed something)
- An “after” capture proving verification

Safe logging rules:

- Do not log tokens, secrets, SAS, keys, passwords, private keys
- If a command prints a token, rerun with output suppressed or redact before saving
- Redact usernames when not needed. Keep role names, scope, and IDs only as needed.

### Step 4: Exports evidence standards (exports/)

What goes here:

- CSV/JSON exports from portals or scripts
- Activity log, sign-in log exports
- Configuration exports that prove settings

Rules:

- Prefer machine-readable formats (JSON/CSV) over screenshots
- Export narrow time windows
- Keep only what you need to prove the point

Redaction rules:

- Remove:
  - access tokens
  - refresh tokens
  - client secrets
  - recovery keys
  - full user lists unless required
- Minimize tenant identifiers. Keep only what is necessary to correlate events.

### Step 5: Screenshots evidence standards (screenshots/)

What goes here:

- Portal views that prove configuration or results
- Error dialogs with correlation IDs
- Effective rules, effective routes, policy settings, role assignment screens

Rules:

- Screenshot only what matters. Crop aggressively.
- Always capture:
  - the setting/value
  - the scope (resource, subscription, policy name)
  - the timestamp if shown
- Redact:
  - user UPNs
  - email addresses
  - IPs that identify home/office unless necessary
  - tenant name, subscription name if sensitive
  - correlation IDs only if your org treats them as sensitive (usually they are OK)

### Step 6: notes.md and timeline.md are mandatory

notes.md must include:

- Tag: A/B/C
- Runbook: /path/to/runbook.md
- What happened:
- Impact:
- Root cause:
- Fix:
- Follow-ups:

timeline.md must include UTC timestamps:

- T0: first report or first detection
- T1: triage steps
- T2: change applied
- T3: verification passed
- T4: closeout

If you do not keep a timeline, your evidence is weak and your story is unreliable.

### Step 7: Canonical linking rules

Every evidence set must point to one canonical runbook.

- notes.md must include:
  - Runbook: /runbooks/<...>.md
- README.md inside the evidence folder (if present) must include:
  - Canonical runbook path
  - Tag

Do not duplicate runbooks inside /evidence. Evidence points to runbooks. Runbooks do not live inside evidence.

### Step 8: What never goes in the repo

Hard bans:

- passwords, keys, secrets, tokens
- BitLocker recovery keys
- private key material (cert private keys, SSH private keys)
- full mailbox exports
- raw endpoint inventory dumps with serial numbers unless heavily redacted
- unredacted sign-in logs for real users in a real org

If you need to keep raw sensitive artifacts:

- Store them outside git (secure storage) and commit only:
  - a pointer file (path, timestamp, run id)
  - a redacted summary (counts, key fields)

### Step 9: Minimum evidence set (do not under-collect)

For incidents:

- notes.md and timeline.md
- at least one reproduction artifact
- at least one “before” state artifact
- at least one “after” verification artifact
- one export or log that shows the root cause or confirms the fix

For planned changes:

- baseline capture
- change record (command output or portal setting before/after)
- verification proof
- rollback proof if rollback was executed

## Verification

- Evidence folder exists for the runbook slug and contains:
  - commands/ exports/ screenshots/
  - notes.md and timeline.md populated
- Files follow naming standard and include UTC timestamps
- No secrets or sensitive raw dumps are present
- A third party can read notes.md and timeline.md and reproduce the reasoning from artifacts

## Prevention

- Use the evidence scaffold workflow to generate folders consistently
- Add a pre-commit check or CI check to block common secret patterns
- Standardize “redaction first” habits:
  - capture
  - redact
  - then commit
- Treat notes.md and timeline.md as part of the work, not paperwork

## Rollback

If sensitive or incorrect evidence was committed:

1. Remove the files from the repo and commit the removal
2. Rotate any exposed secrets immediately (assume compromise)
3. If history rewrite is required, use the proper git tooling and document it
4. Replace with redacted artifacts or pointer summaries

## Evidence to collect

Store under: `/evidence/runbooks-ops-evidence-collection-standards/`

- `commands/`
  - `repo-evidence-tree-<yyyymmdd>-<hhmmZ>.txt` (example tree listing)
  - `sample-command-output-<yyyymmdd>-<hhmmZ>.txt` (redacted example)
- `exports/`
  - `sample-export-<yyyymmdd>-<hhmmZ>.json` (redacted example)
- `screenshots/`
  - `sample-portal-proof-<yyyymmdd>-<hhmmZ>.png` (redacted example)
- `notes.md`
  - one paragraph explaining how you applied the standard to a real runbook
- `timeline.md`
  - a short sample timeline using UTC timestamps

## Next 3 actions

1. Create `/runbooks/ops/evidence-collection-standards.md` with this content and commit it.
2. Run one of your existing runbooks in the lab and bring its /evidence folder up to this standard (naming, notes.md, timeline.md, before/after proofs).
3. Add a lightweight CI guardrail to block common secret patterns from being committed under /evidence and /scripts output logs.
