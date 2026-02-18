Conditional Access named location block (best inside Entra)

Prereq: Entra ID P1 (or a bundle that includes Conditional Access).

Steps:

Entra admin center -> Protection -> Conditional Access -> Named locations

Create a named location:

Name: Block - Spray IPs - YYYY-MM-DD

Type: IP ranges

Add the attacker IPs (single IPs use /32)

Conditional Access -> Policies -> New policy

Name: Block - Spray IPs - Emergency

Users: All users (or start with a pilot group if you must)

Exclude: Break glass accounts (bg-admin01/bg-admin02)

Cloud apps: All cloud apps (or start with Office 365 + Azure management)

Conditions -> Locations:

Include: Any location

Exclude: Trusted locations (optional)

Or set Include to the named location you just created (depends on UI)

Access controls: Block access

Enable policy

Notes that matter:

This blocks sign-ins from those IPs across Microsoft cloud apps. It does not stop the traffic from hitting the login page, but it stops authentication.

Attackers rotate IPs. This is containment, not a cure.

Evidence:

Screenshot of Named location

Screenshot of CA policy conditions and exclusions

Audit log export showing policy created/updated

Sign-in logs showing failures changed to CA block for those IPs
