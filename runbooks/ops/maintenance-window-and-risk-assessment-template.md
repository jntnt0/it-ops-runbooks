# /runbooks/ops/maintenance-window-and-risk-assessment-template.md

Tag: A

# Maintenance window + risk assessment template

## Symptoms

- You need a standardized way to plan changes without winging it
- Changes happen “whenever” and outages follow
- Stakeholders want impact and risk stated clearly before approval
- You need a clear go/no-go decision path during the window

## Scope

Covers:

- A reusable template for:
  - maintenance window planning
  - risk assessment
  - communications
  - validation gates
  - escalation and backout decision points
- Works for cloud, identity, network, endpoint, and app changes

Not covered:

- System-specific procedures (those live in the related runbook)
- Full postmortem format (handled by outage triage + evidence)

## Preconditions

- You have a defined change
- You know:
  - systems in scope
  - owners/approvers
  - expected user impact
- You can capture baseline evidence before the window
- Minimum roles (least privilege):
  - Read access to gather baseline
  - Change rights only for scoped systems during the window

## Triage checklist

1. What is changing, exactly?
2. What is the smallest unit of change you can revert?
3. What is the risk to availability, security, and data integrity?
4. Who is impacted and when?
5. What is the backout trigger and time limit?
6. Who is on call and who can approve rollback?
7. What evidence proves success?

## Fix steps

### Step 1: Fill out the maintenance window header (required)

Paste and complete:

- Change title:
- Change owner:
- Change approver:
- Change type: (config / deployment / policy / migration)
- Requested window (local):
- Requested window (UTC):
- Duration:
- Environment: (prod / non-prod / lab)
- Systems in scope:
- Systems out of scope:
- User impact expectation:
- Change ticket / link:

### Step 2: Risk assessment (availability, security, data)

Rate each as low/medium/high and explain in one sentence.

Availability risk:
- Rating:
- Why:
- Worst-case outcome:

Security risk:
- Rating:
- Why:
- Worst-case outcome:

Data integrity risk:
- Rating:
- Why:
- Worst-case outcome:

Operational risk (people/process):
- Rating:
- Why:
- Worst-case outcome:

### Step 3: Dependencies and prerequisites

List hard dependencies:

- DNS
- Identity (Entra/AD)
- Network edge (WAN/firewall)
- Certificates
- Vendor SaaS availability
- Required admin accounts and break-glass path

Prerequisites checklist:

- Baseline exports captured
- Monitoring dashboards ready
- Vendor support paths confirmed
- Backout plan prepared (link to runbook)
- Tested in lab or non-prod (if applicable)

### Step 4: Communications plan (before, during, after)

Before window:

- Notification audience:
- Message channel(s):
- When to send:
- What to include:
  - expected impact
  - start/end
  - how to report issues

During window:

- Update cadence:
- Who posts updates:
- Where the live notes/timeline are kept:

After window:

- Completion message:
- If issues remain:
  - workaround
  - next update time
  - owner

### Step 5: Execution plan with validation gates

Execution plan must be ordered and explicit.

Format:

- Step 1:
  - action:
  - expected result:
  - evidence captured:
- Step 2:
  - action:
  - expected result:
  - evidence captured:

Validation gates:

- Gate 0 (baseline): pre-change checks pass
- Gate 1 (immediate): change applied and basic health checks pass
- Gate 2 (soak): 15 to 30 minutes stable
- Gate 3 (user validation): real user confirms critical path

Write exact checks for each gate:

- Gate 0 checks:
- Gate 1 checks:
- Gate 2 checks:
- Gate 3 checks:

### Step 6: Go/no-go and backout decision points

Write the decision logic.

Go/no-go before starting:

- If baseline checks fail, do not start.

Backout triggers:

- Define specific triggers and thresholds.

Backout time limit:

- “If not stable by <time UTC>, execute backout.”

Approvals:

- Who can authorize backout:
- Who executes:
- Who communicates:

Link to the system backout plan:

- `/runbooks/ops/backout-plan-template.md` (and the system-specific rollback section in the related runbook)

### Step 7: Evidence capture plan

Minimum evidence set:

- Before:
  - baseline exports and screenshots
- During:
  - command outputs and deployment logs
  - portal screenshots of before/after states
- After:
  - verification outputs and monitoring screenshots
- If rollback:
  - rollback outputs and final verification

Store under:

- `/evidence/runbooks-ops-maintenance-window-and-risk-assessment-template/`

## Verification

- The template is fully completed (no blanks)
- Risks are stated clearly and not minimized
- Dependencies and prerequisites are confirmed
- Validation gates are testable and assigned to a person
- Backout triggers and time limit exist and have an approver

## Prevention

- Require this template for medium/high risk changes
- Require a completed backout plan for any change with potential outage impact
- Use pilot deployments before broad rollout
- Track changes and outcomes so risk ratings become realistic over time

## Rollback

Rollback actions are executed per the linked backout plan and must be recorded in timeline.md with timestamps and results.

## Evidence to collect

Store under: `/evidence/runbooks-ops-maintenance-window-and-risk-assessment-template/`

- `notes.md`
  - completed template fields and approvals
- `timeline.md`
  - execution steps, gate results, go/no-go and rollback decisions
- `exports/`
  - baseline exports
  - post-change exports
- `commands/`
  - commands executed and outputs
- `screenshots/` (redacted)
  - monitoring before/after
  - portal before/after
- Optional:
  - `comms-log-<date>.txt`

## Next 3 actions

1. Create `/runbooks/ops/maintenance-window-and-risk-assessment-template.md` with this content and commit it.
2. Pick one real change scenario from your repo (Conditional Access rollout or RBAC changes) and fill out this template for it as a practice run.
3. Add a repo rule in your contract/templates: any medium/high risk production change requires this template plus a backout plan before execution.
