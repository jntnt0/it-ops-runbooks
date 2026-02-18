# /runbooks/ops/outage-triage-framework.md

Tag: A

# Outage triage framework

## Symptoms

- Multiple users report services down at once
- Monitoring alerts spike across many systems
- You cannot quickly answer “what is broken” and “who is impacted”
- Vendor support asks for basics you have not gathered yet
- Leadership asks for ETA and you have no verified facts

## Scope

Covers:

- A repeatable outage triage workflow that produces:
  - a clean timeline
  - an accurate impact scope
  - an escalation-ready vendor packet
- Works for cloud, network, endpoint, identity, and app outages

Not covered:

- Deep technical remediation steps for specific systems (use the relevant runbook)
- Formal postmortem templates beyond the evidence and notes captured here

## Preconditions

- An incident channel exists (Teams/Slack) or you create one immediately
- You can access:
  - Monitoring / logging tools (as applicable)
  - Admin portals (M365, Entra, Azure, firewall, etc.)
- Minimum roles (least privilege):
  - Read access to monitoring and logs is enough to run triage
  - Elevated rights are only used once the failure domain is identified

## Triage checklist

1. Declare incident and start the clock
2. Establish single source of truth for updates
3. Build the timeline as you go (do not “do it later”)
4. Determine impact scope before making changes
5. Identify the failure domain:
   - identity, network, endpoint, cloud platform, vendor SaaS, internal app
6. Apply one change at a time, with timestamped notes
7. Escalate early when vendor/platform is likely at fault

## Fix steps

### Step 1: Declare incident, start timeline, assign roles

Minimum roles during triage:

- Incident lead (owns decisions and updates)
- Scribe (timeline and evidence capture)
- Investigator (technical triage)
- Comms owner (user-facing updates)

If you are solo, you still do all four, just in that order.

Create or open:

- `/evidence/runbooks-ops-outage-triage-framework/notes.md`
- `/evidence/runbooks-ops-outage-triage-framework/timeline.md`

Write immediately in timeline.md:

- T0: first report time (local and UTC)
- Reporter and channel (ticket, phone, Teams)
- First symptom statement (exact wording)

### Step 2: Establish impact scope fast

Impact scope questions (answer with facts, not guesses):

- How many users?
- Which locations?
- Which departments?
- Which services?
- Is it total outage or degraded?
- Is it internal only, external only, or both?
- Is it new sign-ins only or existing sessions too?

Fast checks:

- Can you reproduce from:
  - a known-good internal workstation
  - a mobile hotspot or external network
- Is DNS resolving correctly?
- Is authentication failing (Entra sign-in logs)?
- Is the network edge up (WAN, firewall health)?

Write impact summary in notes.md:

- “Impacted: X users, Y sites, services A/B/C, start time, confirmed repro steps.”

Evidence to collect now:

- Screenshots of:
  - monitoring dashboards showing spike
  - service health pages (Microsoft 365 Service health, Azure status, ISP portal)
- Export a short set of logs relevant to the suspected domain

### Step 3: Narrow failure domain using a quick decision tree

Use this order because it saves time:

1) Identity
- Can users sign in?
- Are CA policies blocking?
- Are token services healthy?

2) Network and DNS
- Can clients resolve names?
- Can clients reach gateway and critical IPs?
- Any changes at edge?

3) Vendor/SaaS platform
- Is there an active incident in the vendor status page?
- Are multiple tenants reporting issues?

4) Internal app or infra
- Any deployments or changes immediately before outage?
- Any certificate expirations, storage full, CPU/memory saturation?

Rule: do not start “fixing” until you can name the failure domain.

### Step 4: Timeline discipline (non-negotiable)

Every action gets:

- Time (local and UTC)
- Who did it
- What changed
- Why
- What happened after

Use this format in timeline.md:

- T0: Report received from <source>. Symptoms: <exact>.
- T1: Confirmed repro from <location>. <test performed>. Result: <pass/fail>.
- T2: Checked <system>. Found <fact>.
- T3: Change made <exact change>. Result <impact>.
- T4: Vendor ticket opened <case id>. ETA <as stated by vendor>.
- T5: Service restored for <scope>. Remaining issues <scope>.

### Step 5: Evidence capture while you triage

Capture evidence continuously, not after the fact.

Minimum evidence set:

- Screenshots (redacted) of:
  - monitoring alerts
  - admin portal errors
  - vendor status page
- Exports:
  - relevant logs for the 30 to 60 minute window around T0
- Commands output:
  - ping, traceroute, nslookup, curl, Test-NetConnection
- Change records:
  - what you touched and how to revert it

Store under:

- `/evidence/runbooks-ops-outage-triage-framework/screenshots/`
- `/evidence/runbooks-ops-outage-triage-framework/exports/`
- `/evidence/runbooks-ops-outage-triage-framework/commands/`

### Step 6: Vendor escalation packet (what they always ask for)

Do not open a vendor case without a packet. It wastes time.

Vendor packet contents:

- Impact summary
  - who and what is impacted, and since when
- Repro steps
  - exact steps, exact errors
- Time window (UTC)
  - start time, any change times
- Environment details
  - tenant id (if applicable), subscription id, region, service names
- Correlation identifiers
  - request ids, correlation ids, message ids, trace ids
- Logs and screenshots
  - redacted but complete enough to prove the error
- Network path details
  - source IPs, egress IPs, involved ISPs, VPN status, DNS resolvers

Write the packet in:

- `/evidence/runbooks-ops-outage-triage-framework/vendor-escalation.md`

Template to paste into vendor-escalation.md:

- Summary:
- Impact:
- Start time (UTC):
- Affected services/components:
- Repro steps:
- Exact errors:
- Correlation IDs / Request IDs:
- Source IPs / Locations:
- Recent changes:
- Troubleshooting performed:
- Attachments (files in exports/screenshots/commands/):

### Step 7: Stabilize first, then fix

Stabilization moves:

- Stop the bleeding:
  - pause deployments
  - stop automated changes
  - disable a broken CA policy (only if proven)
  - fail over WAN (if proven and available)
- Communicate:
  - current impact, what you are doing, next update time

Fix moves:

- One change at a time
- Verify after each change
- If unsure, do not stack changes

### Step 8: Closeout and immediate follow-ups

When service is restored:

- Confirm recovery with a real user in the impacted scope
- Update impact scope:
  - fully restored or partial
- Document final fix and any rollback performed
- Create follow-up tasks:
  - monitoring gaps, change process gaps, vendor problems, DR gaps

## Verification

- Impacted service(s) are confirmed working by:
  - internal test
  - external test (if relevant)
  - at least one impacted user confirmation
- Timeline is complete with:
  - T0, major checkpoints, fix, restore confirmation
- Vendor escalation packet is complete if vendor was involved
- Evidence folder has enough artifacts for a postmortem

## Prevention

- Require change logging and deployment freeze during incidents
- Implement synthetic checks for critical user journeys:
  - sign-in, DNS resolve, app home page, API call
- Ensure vendor contact paths and account details are documented
- Maintain a list of known critical dependencies:
  - DNS, identity, WAN, key SaaS vendors
- Practice the framework with quarterly tabletop exercises

## Rollback

If your changes made the outage worse:

1. Stop making changes
2. Revert the last known change first (use your own timeline)
3. Confirm whether impact reduces
4. If rollback does not help, revert to pre-incident config snapshot if available
5. Document rollback actions and outcomes in timeline.md

## Evidence to collect

Store under: `/evidence/runbooks-ops-outage-triage-framework/`

- `notes.md`
  - impact summary, decisions, owners
- `timeline.md`
  - timestamped actions and results
- `vendor-escalation.md`
  - escalation packet template filled out
- `screenshots/` (redacted)
  - monitoring spike
  - admin portal errors
  - vendor status page
- `exports/`
  - sign-in logs, audit logs, activity logs (as relevant)
  - system logs or app logs (as relevant)
- `commands/`
  - nslookup, ping, traceroute, curl, Test-NetConnection outputs
- Optional:
  - `chat-transcript-<date>.txt` (redacted)

## Next 3 actions

1. Create `/runbooks/ops/outage-triage-framework.md` with this content and commit it.
2. Add a minimal `vendor-escalation.md` placeholder file under the matching evidence path so the scaffold is always ready.
3. Run one tabletop drill in your lab: pick a fake outage (DNS down or CA block), produce timeline.md, impact summary, and a vendor escalation packet in 15 minutes.
