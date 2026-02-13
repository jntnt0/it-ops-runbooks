# /templates/runbook-template.md

Tag: A/B/C  
Artifact: Runbook template  
Owner: IT Ops  
Last updated: 2026-02-12

## Symptoms
- [List user-visible symptoms]
- [List admin-visible alerts or failures]
- [Include common error strings or portal banners]

## Scope
- In scope:
  - [Systems, workloads, apps]
  - [User groups, devices, sites]
- Out of scope:
  - [What this runbook does not cover]
- Impact:
  - [Who is affected and how]

## Preconditions
- Access required:
  - [Least privilege roles]
  - [Break glass or emergency access rules]
- Tools required:
  - [Portals, modules, CLI tools, connectors]
- Licensing assumptions:
  - [Free, P1, P2, Defender, etc]
- Safety:
  - [Change window guidance]
  - [Expected blast radius]

## Triage checklist
1. Confirm the issue is real (not expected behavior or maintenance).
2. Define the time window (UTC) and impacted identities/devices/resources.
3. Determine severity:
   - Sev 1: outage or security incident
   - Sev 2: partial impact or degraded service
   - Sev 3: single user or minor impact
4. Gather quick evidence:
   - [Portal log export]
   - [Scripted export]
5. Identify likely root cause bucket:
   - Config change
   - Policy block
   - Service health
   - Credential/identity issue
   - Network/edge issue
   - Device compliance/enrollment issue

## Fix steps
### 1) Capture evidence before changes
Portal checks
- [Where to click and what to export]
- [What filters to apply]
- [What screenshots to take, redact before commit]

Scripted evidence collection (references)
- Run: `/scripts/<script-name>.ps1` [args]
- Save to: `/evidence/<scenario-slug>/<YYYY-MM-DD>_<case-id>/scripts/`
- Notes:
  - Use safe logging (no secrets, no tokens)
  - Capture UTC timestamps

### 2) Containment or immediate mitigation (if applicable)
- [Stop the bleeding action]
- [Optional: environment-dependent branch]
  - Not available in this environment: [state why]
  - Lab substitute: [how you demonstrate anyway]
  - Evidence: [what you can still collect]

### 3) Remediation (root cause fix)
- Step 1: [Actionable change]
- Step 2: [Actionable change]
- Step 3: [Actionable change]
- Guardrails:
  - [What to avoid]
  - [Order matters notes]

### 4) Recovery (return to normal)
- [Restore access/services safely]
- [Remove temporary blocks if appropriate]
- [Confirm users can operate normally]

### 5) Post-fix hardening (optional but recommended)
- [Baseline policy or configuration improvements]
- [Monitoring/alerting improvements]
- [Documentation updates]

## Verification
- Technical checks:
  - [Exact checks, queries, or commands]
- User validation:
  - [What the user should confirm]
- Success criteria:
  - [Measurable outcome]
- Evidence:
  - [What to export or screenshot after the fix]

## Prevention
- Controls to reduce recurrence:
  - [Policy baseline]
  - [Change management]
  - [Monitoring and alerting]
  - [Access and role hygiene]
- Follow-up tasks:
  - [Backlog items with owner and due date if you track that]

## Rollback
- When to rollback:
  - [Clear criteria]
- Rollback steps (reverse order of changes):
  1. [Disable newest change first]
  2. [Revert scope or settings]
  3. [Restore known-good config]
- Rollback verification:
  - [Checks to confirm rollback worked]
- Record:
  - [Timestamp, who approved, what changed]

## Evidence to collect
Create: `/evidence/<scenario-slug>/<YYYY-MM-DD>_<case-id>/`

Minimum set
- `README.md` (what happened, what you did, outcome, timestamps)
- `exports/` (CSV/JSON exports)
- `screenshots/` (redacted)
- `scripts/` (redacted outputs and logs)

Recommended artifacts
- Before/after config state (exported)
- Relevant logs for the time window (exported)
- Correlation IDs (masked if needed)
- Change record reference (ticket ID, change ID)

## Next 3 actions
- Copy this template to `/runbooks/<scenario-slug>.md` and replace all bracketed placeholders.
- Add the evidence folder path and file naming you will use for this scenario under `/evidence/<scenario-slug>/README.md`.
- List the exact scripts you will reference for repeatable evidence collection under `/scripts/README.md`.