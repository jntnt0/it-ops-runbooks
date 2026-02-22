story-pack = the repeatable lab script / setup logic / ways to inject failure

Story-packs is for scenarios you can “play through” to generate evidence and prove the runbook works. Symptom replication is one common type, but not the only one.

Use story-packs for:
- Fault injection / symptom replication (break it on purpose)
- Realistic end-to-end walkthroughs (joiner, mover, leaver)
- Mock incidents (password spray, CA block, lockout wave)
- Change events (license policy change, RBAC change, app rollout)
- Edge cases (guest user, shared mailbox, litigation hold, VIP exception)
- Data sets and “inputs” (sample users, groups, naming, timelines)

Where the actual fixes live:
- /runbooks = the operational procedure (triage, fix, verify, rollback, evidence)
- /scripts = automation and exports
- /iac = declarative config (if applicable)
- /evidence = outputs you collected

Rule of thumb:
- If it’s instructions to run an exercise and produce artifacts, it’s story-packs.
- If it’s instructions to resolve an incident/outage in production, it’s a runbook.

If you want consistency, create a convention:
- story-packs/*-symptom-replication.md
- story-packs/*-walkthrough.md
- story-packs/*-incident-sim.md
