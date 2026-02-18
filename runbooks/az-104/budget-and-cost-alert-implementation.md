# /runbooks/az-104/budget-and-cost-alert-implementation.md

Tag: A/B

# Budget + cost alert implementation

## Symptoms

- Monthly Azure spend is higher than expected
- No one noticed a cost spike until the invoice showed up
- Teams argue about who owns a cost because tagging and scopes are sloppy
- You need predictable alerts at 50/75/90/100 percent so someone acts before the burn continues
- Leadership wants “hard guardrails” but you only have soft alerts today

## Scope

Covers:

- Implementing Azure budgets and alert notifications at:
  - Management group (if used)
  - Subscription
  - Resource group
- Implementing alert routing (email distribution lists, Teams via webhook, ITSM/webhook)
- Practical thresholds and an operational response flow when alerts fire
- Evidence collection for audits and post-incident cost reviews

Not covered:

- Full FinOps chargeback modeling
- Deep application optimization (that is separate work after you find the offender)

## Preconditions

- You know the scope you want to control:
  - Management group, subscription, resource group
- You know the cost owner and notification path (at minimum an email DL)
- Minimum roles (least privilege):
  - To create and manage budgets at a scope: Cost Management Contributor at that scope (or higher)
  - To view costs only: Cost Management Reader
  - If you are working in Billing scope (EA/MCA), you may need billing permissions that vary by agreement
- If you want automation (A):
  - Repo has /scripts and /iac available
  - You can run Azure CLI or PowerShell and authenticate to the tenant

## Triage checklist

1. What exactly is the goal?
   - Early warning only
   - Early warning plus escalation
   - Hard stop (note: budgets do not stop resources by themselves)
2. What scope makes sense?
   - Subscription is usually the cleanest operational boundary
   - Resource group if you have a well-defined app boundary
   - Management group if you run multiple subscriptions under one owner
3. What budget period is expected?
   - Monthly is standard
4. Who gets notified, and who is accountable to act?
5. Are tags usable for cost attribution?
   - If tags are a mess, fix tagging and policy soon or budgets become noise
6. Do you need separate budgets for dev vs prod?
7. Do you need separate budgets for shared services?
8. Is there a known recurring spike date (patching, batch, backups)?

## Fix steps

### Step 1: Choose a budget design that matches how you actually operate

Recommended baseline per subscription:

- Budget: Monthly
- Threshold alerts:
  - 50 percent (heads up)
  - 75 percent (owner action)
  - 90 percent (owner plus manager escalation)
  - 100 percent (incident-style response)
  - Optional: 110 percent (post-mortem required)

Optional splits that reduce noise:

- Separate dev and prod subscriptions with their own budgets
- Separate shared services subscription budget
- If using resource groups as app boundaries: add RG budgets for top spenders

Document your chosen model in notes.md.

### Step 2: Implement budget in Azure portal

Portal path:

- Cost Management + Billing
- Select the correct scope (management group, subscription, or resource group)
- Budgets
- Add

Set:

- Reset period: Monthly
- Start date: beginning of current month (or next month if you want clean reporting)
- End date: optional, leave open-ended unless required
- Amount: use forecast data if available, otherwise start conservative and adjust
- Alerts:
  - Add threshold percentages and notify list
  - Use distribution lists, not individual emails

Evidence:

- Screenshot (redacted):
  - budget overview and alert thresholds
- Export (if available):
  - budget configuration details

### Step 3: Standardize alert routing

Minimum viable routing:

- Email: Cost Owners DL
- Email: IT Ops DL (for 90 and 100)
- Optional: Teams channel via webhook (Action Group or integration)
- Optional: Ticketing integration via webhook

Operational rule:

- Every alert must map to an owner and a required action.
- If you cannot name the owner, you are not ready for alerts.

Evidence:

- Screenshot (redacted) of notification configuration

### Step 4: Add cost anomaly detection and scheduled cost exports (optional but recommended)

If your tenant supports it, enable cost anomaly alerting at the right scope.

Also implement scheduled exports:

- Export daily costs to a storage account or Log Analytics (if used)
- Keep at least one month of exports in your evidence vault for trending

This makes it possible to answer “what changed” without guessing.

Evidence:

- Export configuration screenshot (redacted)
- Sample export file (redacted)

### Step 5: Define the response flow when an alert fires

When you receive a 75/90/100 percent alert:

1. Confirm it is real
   - Cost analysis for the scope, current month, group by Service name and Resource
2. Identify the top contributor(s)
   - Look for a new resource, a scale-up, a region change, or a runaway service
3. Identify the change driver
   - Azure Activity Log for recent writes on the offending resource group
   - Deployment history if IaC is used
4. Decide action
   - Stop or scale down non-prod immediately
   - Add budget alerts to a narrower scope if one app is the offender
   - Create a ticket and assign an owner for remediation if prod cannot be touched

Record this in timeline.md with UTC timestamps.

### Step 6: Hardening moves that prevent repeats (do not skip)

Budgets are alerts, not guardrails. Add basic governance:

- Enforce required tags (costCenter, owner, environment) using Azure Policy
- Prevent expensive SKUs in non-prod using policy or RBAC gating
- Require approvals for scale changes in prod (process, not wishful thinking)
- Separate dev and prod subscriptions if they are currently mixed

## Verification

- A budget exists at the intended scope with the intended monthly amount
- Alerts are configured at the required thresholds
- Notifications go to distribution lists and a real escalation path
- A test alert can be triggered (lower the amount temporarily) and you confirm delivery
- Owners can run cost analysis and identify top resources within 5 minutes

## Prevention

- Monthly review of:
  - Budget levels versus actuals
  - Top services and top resources
  - Untagged resources and tag drift
- Keep scopes clean:
  - Do not run prod and dev in the same subscription if you can avoid it
- Turn “cost alert fired” into a real operational event:
  - Owner assigned
  - Root cause documented
  - Follow-up tracked

## Rollback

If budgets or alerts are causing noise or were mis-scoped:

1. Disable alerts on the budget (do not delete immediately)
2. Confirm notifications stop
3. Adjust scope or thresholds
4. Re-enable alerts with corrected settings
5. If you must delete:
   - Delete the budget
   - Remove any related notification integrations

Record rollback changes in notes.md.

## Evidence to collect

Store under: `/evidence/runbooks-az-104-budget-and-cost-alert-implementation/`

- `screenshots/` (redacted)
  - `budget-overview-<date>.png`
  - `budget-alert-thresholds-<date>.png`
  - `cost-analysis-top-services-<date>.png`
  - `cost-analysis-top-resources-<date>.png`
  - `export-config-<date>.png` (if used)
- `exports/`
  - `cost-analysis-<scope>-<date>.csv` (redacted)
  - `daily-export-sample-<date>.csv` (redacted, if used)
- `commands/`
  - `notes-on-scope-and-thresholds-<date>.txt`
  - `activity-log-query-<date>.txt` (if you used CLI to correlate changes)
- `notes.md`
  - Budget model chosen, owners, thresholds, escalation path
- `timeline.md`
  - Test alert timestamps and any real alert event response steps

## Next 3 actions

1. Create `/runbooks/az-104/budget-and-cost-alert-implementation.md` with this content and commit it.
2. In your lab, set a low temporary budget amount to force a test alert, confirm notifications, then restore the real budget amount and save evidence artifacts.
3. Add one governance follow-up item to your backlog: tag enforcement policy plus a monthly cost review cadence tied to the budgets.
