### Methodology to choose containment level (minimal vs aggressive)

You decide containment based on two things:

1. Confidence it is malicious
2. Evidence it already succeeded

If you do not separate those, you either overreact every time or you underreact until you get owned.

## Step 1: Classify what you are looking at

Use sign-in logs to label the event:

A) Noise

* Low volume
* Few users
* Random IPs
* No pattern
  Containment: none or minimal tuning.

B) Spray in progress

* Many usernames
* One IP or small IP set
* Mostly failures
  Containment: usually minimal first, then escalate if it continues.

C) Targeted brute force

* One user hammered hard
* Many attempts in short time
  Containment: aggressive for that user, minimal globally.

D) Confirmed compromise
Any one of these makes it compromise, not just “spray”:

* Successful sign-in from suspicious IP/geo/device
* MFA method added or changed unexpectedly
* New OAuth app consent, service principal, or credential added
* Role assignment changes
* Inbox rules or forwarding changes (if you are also checking M365 side)

Containment: aggressive, immediately.

## Step 2: Decide based on success signals

This is the clean decision rule:

* If you have no suspicious successes and no persistence indicators, start minimal.
* If you have suspicious success for any user, go aggressive for those users.
* If you cannot tell whether there were successes because you do not have logs, go aggressive for high value users (admins, execs) and minimal for everyone else.

## Step 3: Use blast radius and business impact as a brake

Minimal containment is best when:

* Volume is low or short-lived
* No success events
* You can block at identity layer quickly (CA, named locations, sign-in risk if available)
* Password resets would disrupt operations more than necessary

Aggressive containment is best when:

* Success or strong suspicion of success exists
* The targeted users include admins or sensitive roles
* Activity is persistent (keeps coming back after blocks)
* You suspect password reuse (spray works because users reused passwords)

## Step 4: A simple escalation ladder that works

1. Minimal first

* Block IPs if you can at network edge or identity layer (named locations)
* Add temporary CA controls if available (geo blocks, require MFA, require compliant device for admins, etc.)
* Increase monitoring and alerting
* Watch for 15 to 30 minutes

2. Escalate to aggressive if any of these happen

* Attempts continue from new IPs (tooling adapts)
* Any suspicious success appears
* Any admin account is targeted heavily
* You see audit events indicating persistence attempts

## Step 5: Apply it per user tier, not “everyone”

Do not treat all users the same.

Tier 0 (admins, privileged roles)

* Aggressive on suspicion, not just proof
* Reset password, revoke sessions, verify MFA methods, review role assignments

Tier 1 (execs, finance, HR, high impact mailboxes)

* Aggressive if targeted or if any success indicator exists

Tier 2 (standard users)

* Minimal unless success indicators exist or the user is clearly compromised

## What “minimal” and “aggressive” really mean in practice

Minimal

* Block source IPs where feasible
* Tighten CA for admins first, then broader population
* Disable legacy auth if still allowed
* Add alerting and keep evidence exports tight

Aggressive

* Force password reset for impacted users (and any reused credentials you suspect)
* Revoke sessions for impacted users
* Validate MFA methods and remove suspicious methods
* Hunt audit log for persistence actions and roll them back

Rule: aggressive without a user list is chaos. Build the impacted user list first from the cluster (top IPs, top targeted users).

Next 3 actions

1. Pull sign-in logs for a 1 hour window and identify: top 3 IPs, top 10 targeted users, and whether any suspicious successes occurred.
2. Assign each targeted user a tier (0/1/2) and choose containment: minimal for tier 2 unless success, aggressive for tier 0 on suspicion.
3. Write the decision and justification into `notes.md` and log each action with timestamps in `timeline.md`.
