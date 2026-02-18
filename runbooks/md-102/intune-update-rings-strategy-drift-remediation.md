# /runbooks/md-102/intune-update-rings-strategy-drift-remediation.md

Tag: B

# Update rings strategy and drift remediation (Baseline, pilot, broad, feature updates, compliance proof)

## Symptoms

- Devices miss quality updates or fall behind patch levels
- Feature updates happen unexpectedly or never happen
- Compliance reports show “Not compliant” due to OS version/update status
- Update policies conflict and devices get unpredictable behavior
- A subset of devices are stuck downloading/installing updates
- Helpdesk sees recurring “reboot pending” / “update failed” issues

---

## Scope

Covers Windows Update for Business management via Intune:

- Baseline ring (broad)
- Pilot ring (early adopters)
- Broad ring (general population)
- Feature update policy strategy
- Drift detection and remediation
- Evidence and compliance proof

Applies to:

- Windows 10/11 devices managed by Intune
- Co-managed devices where Intune controls update workload (call out conflicts)

Excludes:

- Windows Server patching (separate runbook)
- Third-party patching tools (separate runbook)
- Autopatch specifics unless you use it (separate runbook)

---

## Preconditions

- Intune-managed Windows devices available for testing
- Access to Intune admin center
- A defined device grouping strategy (pilot vs broad)
- A maintenance and reboot communication plan
- Licensing/features vary by tenant, document gaps as needed

Minimum roles (least privilege):

- Intune Administrator (policy creation and assignment)
- Endpoint Security Manager (view/report, depending on org setup)
- Global Reader (read-only verification)

---

## Triage Checklist

Before changing policies:

1) Confirm device join type (Entra joined / hybrid / registered)
2) Confirm management state (Intune managed vs co-managed workload)
3) Identify impacted population:
   - One device
   - One group/ring
   - Tenant-wide
4) Check existing update policies assigned to the device:
   - Update ring policies
   - Feature update policies
   - Quality update policies (expedite)
   - Settings catalog policies that overlap
5) Check device update status:
   - Update compliance report
   - Last check-in time
6) Determine if drift is:
   - Policy assignment drift (wrong group)
   - Reporting drift (device not checking in)
   - Patch failure drift (update install failures)

---

## Fix Steps

### Step 1: Establish the ring model (simple and defensible)

Use three rings. Keep it boring.

Ring 0: Pilot (small, controlled)
- IT + power users
- Fast quality update cadence
- Early feature update validation

Ring 1: Baseline / Broad (majority)
- Standard quality update cadence
- Feature update staged after pilot proves stable

Ring 2: Exception / Slow (only if needed)
- Kiosks, specialty apps, fragile hardware
- Must have justification and owner

Rule:
- Every device must be in exactly one update ring group.
- Avoid overlapping assignments.

---

### Step 2: Configure Update Rings (quality updates)

Intune path:
Intune admin center -> Devices -> Windows -> Update rings for Windows 10 and later

Recommended settings (adjust to your reality):

Pilot ring:
- Quality update deferral: 0 to 3 days
- Deadline: short (example 3 to 5 days)
- Grace period: short
- Auto-restart: controlled with active hours
- User experience: allow postponement minimally

Baseline/Broad ring:
- Quality update deferral: 5 to 10 days
- Deadline: moderate (example 7 to 14 days)
- Grace period: moderate

Exception/Slow ring:
- Quality deferral: higher
- Deadline: longer
- Track closely to avoid security exposure

Hard rule:
- Do not set deferrals so long that you’re functionally unpatched.

---

### Step 3: Add Feature Update policy (control version drift)

This prevents random upgrades and makes compliance provable.

Intune path:
Devices -> Windows -> Feature updates for Windows 10 and later

Strategy:
- Lock broad ring to a target version (example: Windows 11 23H2)
- Pilot ring targets the next version first
- Broad ring moves only after pilot success window

Rollout approach:
- Pilot target set first
- Validate app compatibility and drivers
- Move broad target after defined success criteria

---

### Step 4: Detect drift (policy + patch drift)

You care about two drifts:

A) Assignment drift (wrong ring)
- Device is in multiple ring groups
- Device is in no ring group
- Ring policy conflicts with settings catalog or GPO

B) Patch drift (device not updating)
- Device hasn’t checked in
- Update failures
- Stuck download/install
- Reboot pending loops

Evidence sources:
- Intune update reports (Update ring status, Feature update status)
- Device last check-in
- Windows Update event logs on device (if needed)
- Delivery Optimization / network constraints (if relevant)

---

### Step 5: Remediate drift (ordered approach)

#### A) Fix assignment drift first

1) Confirm device group membership
2) Remove device from incorrect ring groups
3) Assign device to correct ring
4) Force sync from device and Intune
5) Wait for policy evaluation

#### B) Fix patch drift second

1) Force device sync (Company Portal or Settings)
2) Confirm Windows Update service health
3) Check free disk space and battery constraints
4) Confirm device can reach Microsoft update endpoints (proxy/firewall)
5) If still failing:
   - Use an Intune remediation script (if available) to reset update components
   - Or perform manual reset procedure (documented, controlled)

If co-managed:
- Confirm update workload is not still on ConfigMgr/GPO

---

### Step 6: Emergency patching (expedite when needed)

If a high-severity vulnerability requires rapid patch:

- Use expedite quality updates policy (if available)
- Scope tightly to required devices
- Track success and remove policy after completion

Do not permanently run in “emergency mode.”

---

## Verification

- Pilot ring devices receive updates first and succeed
- Broad ring devices receive updates after deferral window
- Feature update version matches target for each ring
- Update reports show high success rate and shrinking “Not compliant”
- Devices with prior drift now show:
  - Correct ring assignment
  - Recent check-in
  - Successful update install
  - No reboot pending after defined window

---

## Prevention

- Use dynamic device groups for ring assignment (where safe)
- Enforce “one ring only” membership rules
- Monthly drift review:
  - Devices not checked in
  - Devices behind patch threshold
  - Devices failing install
- Document standard deferral/deadline values and keep them stable
- Keep exception ring small and actively justified
- Publish reboot and maintenance expectations to users

---

## Rollback

Rollback options depend on what you changed:

- If you mis-assigned a policy: remove device/group assignment and re-sync
- If feature update target caused issues:
  - Pause feature update rollout
  - Keep broad ring pinned to known good version
- If deadlines caused user impact:
  - Adjust deadlines and restart behavior
  - Communicate clearly, do not silently change without notes

---

## Evidence to collect

Store under:

`/evidence/runbooks-md-102-intune-update-rings-strategy-drift-remediation/`

Exports (redacted):
- Update ring policy settings (JSON export if available, or screenshots)
- Feature update policy target versions and assignments
- Update reports showing compliance before/after
- List of devices out of compliance and their status reasons
- Device group membership evidence for ring assignment

Screenshots (redacted):
- Update ring configuration pages (settings + assignments)
- Feature update policy target version page
- Update report views showing drift remediation impact
- A sample device record showing last check-in and update status

Commands (redacted, optional):
- Windows update status checks if you use local troubleshooting
- Any remediation script output summary

Notes:
- Ring definitions (pilot/broad/exception) and rationale
- Dates of rollout changes
- Drift remediation actions and outcomes

---

Next 3 actions
1) Commit this runbook to `/runbooks/md-102/intune-update-rings-strategy-drift-remediation.md`.  
2) Implement the three-ring model in your lab tenant and assign at least 2 test devices across pilot and broad.  
3) Capture before/after update compliance reports as your first “real” evidence set under the generated evidence folder.