# /runbooks/networking/nat-troubleshooting-flow.md

Tag: A/B

# NAT troubleshooting flow

## Symptoms

- Clients can reach internal networks but cannot reach the internet
- Internet access works for some VLANs/subnets but not others
- Outbound works but inbound port-forward does not
- One specific destination fails while others work (policy/NAT exemption issue)
- Connections drop after a short time (translation timeout, asymmetric routing)
- Logs show “no translation” or “dropped due to reverse path” on firewall/NVA

## Scope

Covers:

- Source NAT (SNAT/PAT) troubleshooting for outbound internet
- Destination NAT (DNAT/port-forward) troubleshooting for inbound access
- NAT exemptions and policy-based NAT issues
- Common root causes: wrong inside/outside, missing routes, ACL/policy, asymmetric routing

Not covered:

- Deep ISP issues (collect evidence, hand off)
- Full TLS/app issues once L3/L4 is proven good
- Azure-specific SNAT (Load Balancer SNAT, NAT Gateway) beyond basic checks

## Preconditions

You know:

- Source IP/subnet and inside interface/VLAN
- Destination IP/FQDN and port/protocol
- NAT device(s) in path:
  - Router, firewall, NVA, or cloud edge
- Expected NAT behavior:
  - PAT to one public IP
  - NAT pool
  - Static 1:1 NAT
  - Port-forward (DNAT)

Minimum roles (least privilege):

- Read-only access to NAT device CLI or management plane for triage
- Ability to run test traffic from an inside host
- Change rights only after you prove the exact break

## Triage checklist

1. Define the exact flow
   - Source IP, destination IP/FQDN, port/protocol, expected direction
2. Confirm routing works before NAT
   - Inside host can reach the NAT device inside interface
3. Confirm DNS is not the real problem
   - Resolve FQDN to correct IP
4. Identify NAT type involved
   - Outbound PAT vs inbound DNAT vs exemption
5. Check for asymmetry
   - Return traffic must come back through the same NAT device
6. Capture timestamps and run tests while watching translations/logs

## Fix steps

### Step 1: Prove the inside host can reach the NAT device and default gateway

From the inside host:

- Ping default gateway
- Ping NAT device inside interface (if distinct)
- Traceroute to a public IP (use an IP, not a name)

Windows:

- `ping <gw>`
- `tracert 1.1.1.1`
- `Test-NetConnection 1.1.1.1 -Port 53` (or 443)

Linux:

- `ping -c 3 <gw>`
- `traceroute 1.1.1.1` (or `tracepath 1.1.1.1`)
- `nc -vz 1.1.1.1 443`

Evidence:

- `/evidence/runbooks-networking-nat-troubleshooting-flow/commands/inside-host-tests-<date>.txt`

If traceroute dies before the NAT device, stop. That is routing/VLAN, not NAT.

### Step 2: Confirm NAT inside/outside (or trust/untrust) is correct

Classic failure: interfaces swapped or mis-tagged.

Router NAT model:

- Identify inside and outside interfaces:
  - `show run | section interface`
  - `show run interface <inside-int>`
  - `show run interface <outside-int>`

Cisco example indicators:

- `ip nat inside`
- `ip nat outside`

Firewall model:

- Ensure correct zone assignment and policy direction
- Ensure NAT rule applies to the correct source zone and destination zone

Evidence:

- `/evidence/runbooks-networking-nat-troubleshooting-flow/commands/nat-interface-role-<date>.txt`

### Step 3: Validate NAT rules match the intended traffic

Outbound PAT checklist:

- Source match is correct (ACL/object group includes the inside subnets)
- NAT rule applies to the right inside interface/zone
- Translation address/pool exists and is correct
- If policy-based NAT, check destination conditions too

Inbound DNAT checklist:

- Public IP/port maps to correct inside IP/port
- Firewall policy permits inbound after DNAT
- Service actually listens on inside host
- Hairpin NAT is handled if inside clients must reach the service via public IP

Exemption checklist:

- Exemptions are ordered before general PAT (NAT order matters)
- Exemption match is correct on both source and destination

Evidence:

- Save NAT config and NAT policy order:
  - `/commands/nat-rules-<date>.txt`

### Step 4: Watch translations while generating traffic

This is the fastest way to stop guessing.

Cisco IOS examples:

- Clear existing translations (lab only, careful in prod):
  - `clear ip nat translation *`
- Generate traffic from inside host, then check:
  - `show ip nat translations`
  - `show ip nat statistics`

What to look for:

- No translations created: rule match is wrong, inside/outside wrong, or traffic never reaches the device
- Translations created but counters not incrementing: policy/ACL might block
- Translations created but return traffic fails: routing asymmetry or ISP/upstream issue

Firewall examples:

- Session table shows NATed session?
- NAT hit counters increment?
- Logs show deny before or after NAT?

Evidence:

- `/commands/nat-translations-while-testing-<date>.txt`

### Step 5: Confirm the NAT device has correct upstream routing

For outbound internet:

- Default route exists toward ISP/upstream
- Upstream next hop is reachable
- Public interface has correct IP/mask and ARP/neighbor resolution

Cisco:

- `show ip route | include 0.0.0.0`
- `show ip interface brief`
- `ping <isp-next-hop> source <outside-int>`

Evidence:

- `/commands/upstream-routing-<date>.txt`

If default route is missing or wrong, NAT will not save you.

### Step 6: Confirm return path and avoid asymmetric routing

Asymmetry kills NAT.

Common scenarios:

- Multiple internet circuits without proper policy routing
- Inside host uses a different gateway than expected
- Inbound DNAT is reachable from outside, but return traffic leaves a different path
- VPN/peering overlaps cause return traffic to bypass the NAT device

Fix:

- Ensure default route on inside segment points to the NAT device
- Ensure the NAT device is the only egress path (or implement correct routing policy)
- For inbound, ensure inside host returns via the same firewall/router doing DNAT

Evidence:

- `/commands/return-path-validation-<date>.txt`

### Step 7: Check ACL/policy after NAT

NAT is not permission.

Router ACL model:

- Outside inbound ACL permits the translated flow (for DNAT)
- Inside outbound ACL permits the original flow (for SNAT)

Firewall policy model:

- Rule exists allowing source zone to destination zone on required ports
- For DNAT, ensure policy references the post-NAT destination (varies by platform)

Evidence:

- `/commands/policy-and-acl-<date>.txt`

### Step 8: Fix with the smallest change and retest

Common minimal fixes:

- Add missing inside subnet to NAT match ACL/object group
- Correct inside/outside interface marking
- Add or correct default route on NAT device
- Insert NAT exemption above PAT where needed
- Add firewall policy for the flow
- For hairpin:
  - Add hairpin NAT rule and internal DNS override (preferred) or split-horizon DNS

Retest:

- Inside host to public IP by IP and by name
- Confirm translations and counters hit
- Confirm logs show permit and not deny

Evidence:

- `/commands/post-fix-tests-<date>.txt`
- `/commands/nat-translations-post-fix-<date>.txt`

## Verification

- For outbound:
  - Inside hosts can reach multiple public IPs (1.1.1.1, 8.8.8.8) and HTTPS sites
  - NAT translations show expected inside to public mapping
  - NAT stats show hits increasing
- For inbound DNAT:
  - External test reaches the service
  - Session table/logs show correct DNAT mapping
  - Inside host responds and return traffic uses the same NAT device
- No temporary broad allows remain in place

## Prevention

- Document inside subnets and keep NAT match objects updated
- Standardize interface/zone naming and keep “inside/outside” clear
- Monitor NAT pool exhaustion and session table utilization
- For inbound services:
  - Prefer proper reverse proxy/load balancer over scattered port-forwards
- Avoid multi-egress asymmetry without explicit routing policy
- Keep change control around NAT and default routes (these cause real outages fast)

## Rollback

If your change caused impact:

1. Revert NAT rule/object change to the saved baseline
2. Revert ACL/policy change tied to NAT
3. Restore previous default route if changed
4. Clear test translations (lab only) and re-test baseline behavior
5. Document rollback in notes.md and timeline.md

## Evidence to collect

Store under: `/evidence/runbooks-networking-nat-troubleshooting-flow/`

- `commands/`
  - `inside-host-tests-<date>.txt`
  - `nat-interface-role-<date>.txt`
  - `nat-rules-<date>.txt`
  - `nat-translations-while-testing-<date>.txt`
  - `upstream-routing-<date>.txt`
  - `return-path-validation-<date>.txt`
  - `policy-and-acl-<date>.txt`
  - `post-fix-tests-<date>.txt`
  - `nat-translations-post-fix-<date>.txt`
- `screenshots/` (redacted)
  - `firewall-session-table-<date>.png` (if applicable)
  - `firewall-nat-rule-hits-<date>.png` (if applicable)
- `exports/`
  - `running-config-snippets-<date>.txt` (sanitized)
- `notes.md`
  - NAT type, scope, root cause, minimal fix
- `timeline.md`
  - T0 report, T1 triage, T2 observe translations, T3 change, T4 verify

## Next 3 actions

1. Create `/runbooks/networking/nat-troubleshooting-flow.md` with this content and commit it.
2. In your lab, reproduce two failures (missing subnet in PAT ACL and broken default route), then fix both while capturing translations and evidence artifacts.
3. Add a short standards note to notes.md after the lab: NAT rule order, exemption placement, and your canonical inside subnet object list.
