# /runbooks/ops/backout-plan-template.md

Tag: A

# Backout plan template

## Symptoms

- You need a standardized rollback plan before making a risky change
- A change window requires a documented backout plan and validation steps
- You have been burned by “we can just undo it” with no real procedure
- Stakeholders want a clear decision point: continue or back out

## Scope

Covers:

- A reusable backout plan template for infrastructure, cloud, identity, and endpoint changes
- Required fields: scope, prerequisites, validation gates, exact rollback steps, and evidence capture
- Fits both lab and real environments

Not covered:

- Deep technical rollback procedures for specific systems (those live in the related runbook)

## Preconditions

- You have a defined change with:
  - target systems
  - exact config or deployment actions
  - success criteria
- You have access to:
  - current config/state exports (baseline)
  - deployment tooling (portal, CLI, IaC, scripts)
- Minimum roles (least privilege):
  - Read access to capture baseline
  - Change rights only for the scoped systems during the window

## Triage checklist

1. What is changing, exactly?
2. What is the smallest unit you can roll back?
3. What is the “point of no return”?
4. What is the maximum acceptable outage/degradation?
5. What evidence proves success, and what evidence proves failure?
6. Who approves the backout decision?
7. Who executes backout, and who communicates?

## Fix steps

### Step 1: Fill out the backout plan header (required)

Paste and complete:

- Change title:
- Change type: (config / deployment / policy / migration)
- Owner:
- Approver:
- Date and window (local and UTC):
- Systems in scope:
- Systems out of scope:
- Risk level: (low / medium / high)
- Customer impact expectation:
- Communications channel:

### Step 2: Capture baseline (before change)

Minimum baseline set:

- Current configuration exports
- Current health status
- Current access policy state (if relevant)
- Current routing/DNS state (if relevant)

Record:

- Baseline timestamp (UTC)
- Where exports are stored under evidence path

Suggested evidence location:

- `/evidence/runbooks-ops-backout-plan-template/exports/baseline-<date>/`

### Step 3: Define success criteria and validation gates

Success criteria must be testable.

Examples:

- “Users can sign in with MFA from corp network and external network”
- “App responds 200 OK within 2 seconds from 3 test locations”
- “Devices in pilot ring update within X hours with no install failures”
- “Firewall policy change allows flow A->B on port 443 and blocks C->D”

Validation gates (decision points):

- Gate 1 (immediate): after deployment completes
- Gate 2 (short soak): after 15 to 30 minutes
- Gate 3 (user validation): after 1 to 3 real user tests

Record:

- Who performs each validation
- Exact commands/tests used
- Pass/fail criteria

### Step 4: Define backout triggers (what forces rollback)

Write clear triggers.

Examples:

- More than X percent of users cannot access service
- Error rate exceeds threshold for Y minutes
- Security regression is detected (policy not enforced)
- Performance degradation beyond defined limit
- Unexpected dependency failure (DNS, auth, routing)

Include the “time limit” trigger:

- “If not stable by <time>, back out”

### Step 5: Backout steps (exact, ordered, minimal)

This is the part people usually hand-wave. Do not.

Write steps as copy-pasteable commands or portal clicks.

Structure:

1. Stop further changes
2. Revert the specific change
3. Confirm rollback completed
4. Validate baseline restored
5. Communicate status

Examples (generic patterns):

Config change rollback:

- Restore saved config snippet from baseline export
- Re-apply known-good settings
- Restart dependent services if required

Deployment rollback:

- Re-deploy last known good version
- Roll back slot swap if using deployment slots
- Revert feature flags

Policy rollback:

- Disable or revert policy to audit-only mode
- Remove new assignment or scope
- Confirm policy enforcement returns to prior state

Identity rollback:

- Disable newly created Conditional Access policy
- Revert group membership changes
- Re-enable previous legacy access temporarily only if documented

Network rollback:

- Restore prior route table entries
- Restore prior NSG rules and priorities
- Restore previous DNS records and TTLs

Important:

- For each step, include:
  - expected result
  - how to verify immediately
  - what to do if the step fails

### Step 6: Post-backout stabilization

After rollback:

- Confirm service is stable for at least 15 minutes
- Confirm key user journeys work
- Confirm monitoring returns to baseline
- Document what was rolled back and why

### Step 7: Evidence capture requirements

During the change window:

- Before change:
  - baseline exports, screenshots, health checks
- During change:
  - logs of commands run, deployment outputs
- After change:
  - verification outputs
- If rollback:
  - rollback command outputs and final validation

Store evidence under:

- `/evidence/runbooks-ops-backout-plan-template/`

## Verification

- The backout plan includes:
  - baseline capture location
  - clear success criteria
  - backout triggers and time limit
  - exact rollback steps
  - validation steps after rollback
- A second person can read it and execute it without asking you what you meant

## Prevention

- Require a backout plan for any medium/high risk change
- Keep “last known good” artifacts always available:
  - config snapshots
  - previous release packages
  - exported policy JSON
- Use staged rollouts:
  - pilot first, then broader scope
- Train: run one backout drill per quarter in the lab

## Rollback

This runbook is itself the rollback plan. If you need rollback in a related change runbook, link to this template and include the system-specific steps there.

## Evidence to collect

Store under: `/evidence/runbooks-ops-backout-plan-template/`

- `notes.md`
  - completed plan fields and approvals
- `timeline.md`
  - gate checks and decision points
- `exports/`
  - baseline exports
  - post-change exports
  - rollback exports (if executed)
- `commands/`
  - commands run for change and rollback
- `screenshots/` (redacted)
  - portal before/after states
  - monitoring before/after
- Optional:
  - `comms-log-<date>.txt`

## Next 3 actions

1. Create `/runbooks/ops/backout-plan-template.md` with this content and commit it.
2. Copy this template into a real runbook you already have (Conditional Access rollout or VNet+NSG) and fill it out for a hypothetical risky change.
3. Add one repo rule to your templates or contract: medium/high risk changes require a completed backout plan before execution.
