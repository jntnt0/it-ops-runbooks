# /evidence/README.md

Tag: A  
Artifact: Evidence repository guide  
Last updated: 2026-02-09

## Purpose
This folder stores redacted proof that runbooks and automation were executed. Everything here should be safe to share publicly after redaction.

## Rules
- Redact before commit. Always remove:
  - Usernames, emails, phone numbers
  - IP addresses (unless you explicitly want to show a blocked IOC; then partially mask)
  - Tenant IDs, domain names, device names, serial numbers
  - Correlation IDs if they could be sensitive (mask or truncate)
  - Access tokens, refresh tokens, secrets, keys, certificates
- Prefer exports over screenshots:
  - CSV/JSON exports from portals
  - Script output logs with safe logging (no secrets)
- Use UTC timestamps in filenames.
- Keep originals out of git. Only commit redacted artifacts.

## Recommended folder structure
Create a subfolder per runbook and incident:
- `/evidence/identity-password-spray-response/YYYY-MM-DD_incident-01/`
- `/evidence/identity-compromised-account-response/YYYY-MM-DD_incident-01/`
- `/evidence/identity-conditional-access-rollout/YYYY-MM-DD_change-01/`

Inside each incident/change folder:
- `README.md` (short narrative: what happened, what you did, outcome)
- `exports/` (CSV/JSON exports)
- `screenshots/` (redacted portal screenshots)
- `scripts/` (redacted script outputs and logs)
- `ioc/` (optional indicators list with masking)

## What to save (common artifacts)
Identity incidents
- Entra sign-in logs export (filtered)
- Entra audit logs export (filtered)
- Conditional Access policy exports (before and after)
- Named locations config evidence
- Defender incident summary (if available)
- Mailbox evidence for compromised accounts (forwarding, rules, delegates)

Change rollouts
- Report-only evaluation screenshots from Conditional Access tab in sign-in logs
- Pilot group scope evidence (membership counts only, redact names)
- Final policy state exports
- Exception list with expiry (redact names, keep role/team labels)

## Safe logging expectations for scripts
Scripts referenced by runbooks should:
- Log actions, timestamps, and counts
- Avoid logging full objects that include PII
- Write outputs to a specified path under `/evidence/.../scripts/`
- Support a `-WhatIf` mode where applicable

## Next 3 actions
- Create subfolders for the three new runbooks and add a placeholder `README.md` in each with a redaction checklist.
- Standardize filenames to `YYYY-MM-DDThhmmssZ_<artifact>_<redacted>.ext` and stick to it.
- Add or stub the evidence collection scripts referenced by the runbooks under `/scripts/`.
