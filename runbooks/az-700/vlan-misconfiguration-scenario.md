# /runbooks/networking/vlan-misconfiguration-scenario.md

Tag: A/B

# VLAN misconfiguration scenario

## Symptoms

- A device cannot reach its default gateway
- A device gets a DHCP address from the wrong subnet/VLAN
- Users report “works on one jack, not on another”
- One floor/closet is down, others are fine
- Voice phone works but PC behind it does not (or vice versa)
- “Native VLAN mismatch” messages, intermittent connectivity, weird broadcast behavior
- Trunk is up but expected VLAN traffic is missing

## Scope

Covers:

- Access port VLAN issues (wrong VLAN, missing VLAN, voice VLAN mistakes)
- Trunk VLAN issues (allowed VLAN list, native VLAN mismatch, tagging expectations)
- Common L2 side effects: STP blocking, MAC table confusion, DHCP landing in wrong scope
- Evidence collection using IOS CLI show commands and sanitized config snippets

Not covered:

- Deep routing issues beyond confirming the gateway SVI/subinterface is up
- Wireless controller mis-maps (separate runbook if needed)
- Full NAC/802.1X problems (separate runbook if needed)

## Preconditions

You know:

- The endpoint:
  - MAC address, switchport, and expected VLAN
- The expected subnet:
  - IP range, default gateway, DHCP scope
- The topology basics:
  - access switch, uplink/trunk path to distribution/core
- Whether voice VLAN is in play

Minimum roles (least privilege):

- Read-only CLI access to relevant switches (for triage)
- Change rights only after you identify the exact misconfig and have approval
- Ability to run a test from the endpoint or a known-good device

## Triage checklist

1. Confirm the endpoint symptoms on the client
   - IP, mask, gateway, DHCP server, DNS
2. Confirm switchport identity
   - Correct switch, correct interface
3. Confirm expected VLAN exists and is active
4. Confirm the port mode is correct
   - access vs trunk
5. Confirm VLAN is allowed end-to-end on trunks
6. Confirm STP is not blocking the path for that VLAN
7. Confirm the gateway SVI/subinterface is up and reachable
8. Identify last change
   - port move, closet work, uplink change, VLAN changes

## Fix steps

### Step 1: Capture client evidence first

Windows:

- `ipconfig /all`
- `arp -a`
- `ping <gateway>`
- `tracert <gateway>` (optional, usually fails early in VLAN issues)

Linux:

- `ip a`
- `ip r`
- `arp -n`
- `ping <gateway>`

Evidence:

- `/evidence/runbooks-networking-vlan-misconfiguration-scenario/commands/client-net-<date>.txt`

### Step 2: Identify the access port and current VLAN state

On the access switch:

- `show interface status`
- `show mac address-table | include <endpoint-mac>`
- `show interface <int> switchport`
- `show run interface <int>`

If voice is in play:

- `show interfaces <int> switchport | include (Access Mode VLAN|Voice VLAN)`
- `show cdp neighbors detail` (phones often show here)
- `show lldp neighbors detail` (if used)

What to look for:

- Port is in the wrong access VLAN
- Port is accidentally a trunk (or DTP negotiated)
- Voice VLAN set but access VLAN wrong
- Port is in a suspended/err-disabled state

Evidence:

- `/evidence/runbooks-networking-vlan-misconfiguration-scenario/commands/access-port-state-<date>.txt`

### Step 3: Confirm VLAN exists and is not pruned

On the same switch:

- `show vlan brief`
- `show vlan id <vlan-id>`
- `show interfaces trunk`

What to look for:

- VLAN missing on the access switch (not created or VTP mismatch)
- VLAN exists but not active on the trunk allowed list
- VLAN is pruned due to configuration
- Native VLAN mismatch warnings

Evidence:

- `/evidence/runbooks-networking-vlan-misconfiguration-scenario/commands/vlan-and-trunk-<date>.txt`

### Step 4: Trace the VLAN end-to-end across trunks to the gateway

Your job is to prove the VLAN is allowed at every hop.

Process:

1. Identify uplink from access switch:
   - `show cdp neighbors`
   - `show lldp neighbors`
2. On each trunk uplink:
   - `show interfaces <uplink> trunk`
   - `show run interface <uplink>`
3. Confirm:
   - VLAN is in “allowed VLANs”
   - VLAN is in “active in management domain”
   - VLAN is not removed by manual allowed list
   - Native VLAN matches on both sides

Common failures:

- Allowed VLAN list does not include the VLAN
- One side is trunk, other side is access
- Native VLAN mismatch causes untagged traffic to land wrong
- Someone “cleaned up” trunks and removed a VLAN they thought was unused

Evidence:

- `/evidence/runbooks-networking-vlan-misconfiguration-scenario/commands/trunk-path-trace-<date>.txt`

### Step 5: Check STP for the VLAN

Even with correct trunking, STP can block paths and create “works sometimes” issues.

Commands:

- `show spanning-tree vlan <vlan-id>`
- `show spanning-tree interface <uplink> detail`

What to look for:

- Unexpected root bridge
- Uplink in blocking state for the VLAN
- Topology changes flapping (ports bouncing)
- Inconsistent port type (portfast on trunk where it should not be)

Fix:

- Restore intended STP root placement
- Fix trunk consistency issues
- Remove incorrect portfast on trunks if it caused instability

Evidence:

- `/evidence/runbooks-networking-vlan-misconfiguration-scenario/commands/stp-check-<date>.txt`

### Step 6: Confirm the gateway interface for the VLAN is up

If gateway is an SVI:

- `show ip interface brief | include Vlan<vlan-id>`
- `show run interface Vlan<vlan-id>`
- `show interface Vlan<vlan-id>`

If gateway is router-on-a-stick:

- `show ip interface brief | include <subif>`
- `show run interface <parent>`
- `show run interface <parent>.<vlan-id>`

What to look for:

- Interface is shutdown or line protocol down
- Wrong IP address/subnet
- Wrong encapsulation dot1q VLAN ID
- ACL applied blocking expected traffic

Evidence:

- `/evidence/runbooks-networking-vlan-misconfiguration-scenario/commands/gateway-check-<date>.txt`

### Step 7: Apply the minimal fix

Do not “redo the whole switch config.” Fix the one thing you proved is wrong.

Common minimal fixes:

A) Access port in wrong VLAN:

- `conf t`
- `interface <int>`
- `switchport mode access`
- `switchport access vlan <vlan-id>`
- `spanning-tree portfast` (only on true edge ports)
- `end`

B) Voice + data port:

- `conf t`
- `interface <int>`
- `switchport mode access`
- `switchport access vlan <data-vlan>`
- `switchport voice vlan <voice-vlan>`
- `spanning-tree portfast`
- `end`

C) Trunk allowed list missing VLAN:

- `conf t`
- `interface <uplink>`
- `switchport mode trunk`
- `switchport trunk allowed vlan add <vlan-id>`
- `end`

D) Native VLAN mismatch:

- Pick the intended native VLAN and make both sides match
- Avoid using VLAN 1 as native in modern designs
- Document the standard (example: native VLAN 99)

Evidence:

- Save before/after interface config snippets:
  - `/commands/config-before-<device>-<int>-<date>.txt`
  - `/commands/config-after-<device>-<int>-<date>.txt`

### Step 8: Force the endpoint to renew and re-test

On the endpoint:

- Release/renew DHCP
- Confirm it lands in the correct subnet
- Ping gateway
- Test a known internal host and DNS

Evidence:

- `/commands/post-fix-client-tests-<date>.txt`

## Verification

- Endpoint obtains correct DHCP lease from expected scope
- Endpoint can reach:
  - default gateway
  - DNS server
  - one internal resource beyond gateway
- MAC address appears on expected switchport and VLAN:
  - `show mac address-table | include <endpoint-mac>`
- Trunk path shows VLAN allowed at every hop
- STP shows stable topology for the VLAN (no constant changes)

## Prevention

- Standardize VLAN scheme and trunk allowed lists (documented)
- Use templates for access ports and voice ports
- Disable DTP on edge ports where you do not want trunks
- Use consistent native VLAN policy (and avoid VLAN 1)
- Enable DHCP snooping and DAI where appropriate to reduce rogue behavior
- Change control for trunk allowed VLAN list edits (most outages come from “cleanup”)

## Rollback

If your fix causes impact:

1. Revert the interface config to the saved “before” snippet
2. Remove VLAN from trunk allowed list if it was added incorrectly
3. Restore native VLAN to previous value on both sides if changed
4. Confirm original impacted users return to prior state
5. Document rollback in notes.md and timeline.md

## Evidence to collect

Store under: `/evidence/runbooks-networking-vlan-misconfiguration-scenario/`

- `commands/`
  - `client-net-<date>.txt`
  - `access-port-state-<date>.txt`
  - `vlan-and-trunk-<date>.txt`
  - `trunk-path-trace-<date>.txt`
  - `stp-check-<date>.txt`
  - `gateway-check-<date>.txt`
  - `config-before-<device>-<int>-<date>.txt`
  - `config-after-<device>-<int>-<date>.txt`
  - `post-fix-client-tests-<date>.txt`
- `screenshots/` (redacted)
  - `switchport-details-<date>.png` (optional)
- `exports/`
  - `running-config-snippets-<date>.txt` (sanitized)
- `notes.md`
  - Root cause (wrong access VLAN, trunk allowed list, native mismatch, missing VLAN, STP)
- `timeline.md`
  - T0 report, T1 identify port, T2 trace VLAN, T3 change, T4 verify

## Next 3 actions

1. Create `/runbooks/networking/vlan-misconfiguration-scenario.md` with this content and commit it.
2. In your lab, reproduce three failures (wrong access VLAN, missing VLAN on trunk allowed list, native VLAN mismatch), then fix each and save evidence artifacts.
3. Add a short standards note to notes.md after the lab: your canonical VLAN IDs, native VLAN policy, and edge-port template commands.
