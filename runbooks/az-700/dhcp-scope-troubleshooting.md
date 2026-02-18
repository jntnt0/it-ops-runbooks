# /runbooks/networking/dhcp-scope-troubleshooting.md

Tag: A/B

# DHCP scope troubleshooting

## Symptoms

- Clients show APIPA address (169.254.x.x) or no IPv4 address
- Clients get an address but cannot reach gateway or DNS
- Wrong subnet handed out (clients land in unexpected IP range)
- Duplicate IP conflicts, flapping connectivity, intermittent drops
- New devices do not receive leases but existing devices still work
- Scope is out of addresses (no free leases)
- DHCP works in one VLAN/subnet but fails in another (relay/helper issue)

## Scope

Covers:

- DHCP server scope health (address pool, exclusions, reservations)
- DHCP options (router, DNS, domain search, NTP)
- Lease conflicts and exhaustion
- DHCP relay (ip helper) and VLAN/subnet boundary issues
- Evidence collection suitable for both Windows DHCP and router-based DHCP

Not covered:

- Full switch port/VLAN troubleshooting (use VLAN/trunk runbooks if needed)
- Deep Wi-Fi controller issues (collect evidence and hand off)
- IPv6 DHCPv6 (separate runbook if needed)

## Preconditions

You know:

- Affected subnet/VLAN and expected scope range
- DHCP server location:
  - Windows DHCP server
  - Router or firewall DHCP service
- Default gateway IP for the subnet
- Whether DHCP relay is in use (router-on-a-stick, L3 SVI, firewall interface)

Minimum roles (least privilege):

- Read-only on DHCP server (DHCP Administrators or equivalent) to view scope status
- Rights on network device to view relay config and interfaces (read-only is fine for triage)
- Local admin on a test client (for ipconfig / release / renew and packet capture)

## Triage checklist

1. Confirm the problem is DHCP, not just DNS or routing
   - Client has no lease or APIPA
   - DORA process fails (discover/offer/request/ack)
2. Identify the affected scope
   - VLAN, subnet, gateway, DHCP server
3. Determine blast radius
   - One client, one VLAN, multiple VLANs, whole site
4. Check whether existing clients can renew
   - If renew works but new leases fail, exhaustion or policy is likely
5. Look for recent changes
   - Scope edits, exclusions, reservations, relay changes, VLAN changes
6. Capture one failing client’s full config and event timestamps

## Fix steps

### Step 1: Capture client-side evidence (one failing client)

Windows:

- `ipconfig /all`
- `ipconfig /release`
- `ipconfig /renew`
- `ipconfig /displaydns` (optional, for later)
- Event logs:
  - System log for Dhcp-Client events

Linux:

- `ip a`
- `nmcli dev show` (if NetworkManager)
- `sudo dhclient -v -r && sudo dhclient -v`

Evidence:

- `/evidence/runbooks-networking-dhcp-scope-troubleshooting/commands/client-ipconfig-<date>.txt`
- `/evidence/runbooks-networking-dhcp-scope-troubleshooting/screenshots/dhcp-client-events-<date>.png` (redacted)

If you can, take a packet capture on the client:

- Filter: `udp.port == 67 || udp.port == 68`

Evidence:

- `/evidence/runbooks-networking-dhcp-scope-troubleshooting/exports/dhcp-client-capture-<date>.pcapng` (redacted if needed)

### Step 2: Check scope health on the DHCP server

Windows DHCP server checks:

- Scope state: Active
- Address pool: start/end range correct
- Exclusions: not wiping out the pool
- Reservations: not overlapping pool incorrectly
- Lease availability: free addresses remaining
- Conflicts: conflict detection settings (rarely used but note it)
- Server authorization in AD (if domain DHCP)

Server-side quick commands (PowerShell):

- `Get-DhcpServerv4Scope -ComputerName <dhcpServer>`
- `Get-DhcpServerv4ScopeStatistics -ComputerName <dhcpServer> -ScopeId <scopeNetwork>`
- `Get-DhcpServerv4OptionValue -ComputerName <dhcpServer> -ScopeId <scopeNetwork>`

Router/firewall DHCP checks:

- Pool configured, not exhausted
- Exclusions correct
- Lease time sane
- Options set

Evidence:

- `/evidence/runbooks-networking-dhcp-scope-troubleshooting/commands/dhcp-scope-status-<date>.txt`
- `/evidence/runbooks-networking-dhcp-scope-troubleshooting/screenshots/scope-statistics-<date>.png` (redacted)

Common fixes:

- If exhausted:
  - Expand the scope range
  - Reduce lease time temporarily to churn leases faster
  - Clear stale reservations or stale leases (carefully)
- If wrong subnet:
  - Fix the scope network, or fix relay/interface mapping so requests hit the correct scope

### Step 3: Verify DHCP options (router, DNS, domain)

Most common breakages:

- Wrong default gateway option (003 Router)
- Wrong DNS servers option (006 DNS Servers)
- Wrong domain suffix (015 DNS Domain Name)
- Old DNS server IPs left behind after migration

Fix:

- Correct options at the scope level first (not server-wide) unless you intend global defaults
- For multi-site environments, avoid one-size-fits-all DNS/gateway options

Evidence:

- Export DHCP option values:
  - `/commands/dhcp-options-<date>.txt`

### Step 4: Validate DHCP relay (ip helper) if clients are not on the same subnet as DHCP server

If DHCP server is not on the client subnet, you need relay.

Cisco IOS (example checks):

- On the L3 interface for that VLAN/subnet:
  - `show run interface <interface>`
  - Confirm `ip helper-address <dhcpServerIP>` exists
- Relay statistics:
  - `show ip dhcp relay statistics` (platform dependent)
- Debug (use carefully in production):
  - `debug ip dhcp server packet` or relay debug variants

If relay is missing or wrong:

- Add or correct the helper address
- Confirm routing exists between the SVI/gateway and the DHCP server

Evidence:

- `/evidence/runbooks-networking-dhcp-scope-troubleshooting/commands/relay-config-<date>.txt`

Common relay mistakes:

- Helper points to old DHCP server IP
- ACL/firewall blocks UDP 67/68
- DHCP server listens on wrong interface or has scope bound incorrectly
- Multiple helpers causing unexpected offers (rogue DHCP scenario)

### Step 5: Check for rogue DHCP or multiple offers

Symptoms:

- Clients get wrong subnet or wrong gateway sporadically
- Packet capture shows multiple DHCPOFFER packets

Fix:

- Identify rogue source MAC/IP from capture or switch logs
- Shut down the offending port or isolate the device
- Enable DHCP snooping on switches (where supported) and trust only uplinks to legit DHCP

Evidence:

- `/exports/dhcp-multiple-offers-<date>.pcapng`
- `/commands/switch-mac-trace-<date>.txt` (if you trace MAC to port)

### Step 6: Confirm IP conflicts and ARP issues

Symptoms:

- Lease is granted but client cannot communicate reliably
- Duplicate IP warnings
- ARP table flapping

Checks:

- Gateway ARP entry for the client:
  - `show ip arp | include <clientIP>` (Cisco)
- Client ARP cache and conflict events

Fix:

- Clear conflicting reservation/lease
- Reserve problem devices properly
- Investigate static IPs sitting inside the DHCP pool

Evidence:

- `/commands/arp-and-conflicts-<date>.txt`

## Verification

You are done only when:

- A test client can obtain a correct lease in the correct scope
- Client receives correct options:
  - gateway, DNS, domain
- Client can reach:
  - default gateway
  - DNS server
  - an internal resource and an external resource (if applicable)
- Scope statistics show healthy free lease count and no rapid exhaustion
- If relay was involved, relay config matches the intended server IP and path is allowed

Verification commands:

- Client:
  - `ipconfig /renew`
  - `ping <gateway>`
  - `nslookup <internal-name>`
- DHCP server:
  - Re-check scope statistics after renew

## Prevention

- Monitor scope utilization (alerts at 70/85/95 percent)
- Keep a standard for lease times:
  - longer for stable wired networks
  - shorter for guest Wi-Fi or transient networks
- Enforce “no static IP inside DHCP ranges”
- Document helper addresses per VLAN and keep them in config management
- Enable DHCP snooping where supported and maintain trusted port list

## Rollback

If a change broke DHCP:

1. Revert the last scope edit (range, exclusions, options) to the prior known-good values
2. Revert relay helper changes to the previous server IP
3. Remove any temporary broad ACL/firewall allowances you added for testing
4. Renew on a test client and verify lease is restored
5. Document rollback in notes.md and timeline.md

## Evidence to collect

Store under: `/evidence/runbooks-networking-dhcp-scope-troubleshooting/`

- `commands/`
  - `client-ipconfig-<date>.txt`
  - `dhcp-scope-status-<date>.txt`
  - `dhcp-options-<date>.txt`
  - `relay-config-<date>.txt`
  - `arp-and-conflicts-<date>.txt`
  - `switch-mac-trace-<date>.txt` (if rogue DHCP)
- `exports/`
  - `dhcp-client-capture-<date>.pcapng` (optional)
  - `dhcp-scope-export-<date>.xml` or `.json` (if Windows DHCP export used)
- `screenshots/` (redacted)
  - `dhcp-client-events-<date>.png`
  - `scope-statistics-<date>.png`
- `notes.md`
  - Root cause (exhaustion, relay missing, rogue DHCP, wrong options)
- `timeline.md`
  - T0 report, T1 triage, T2 fix, T3 verify, T4 prevention follow-up

## Next 3 actions

1. Create `/runbooks/networking/dhcp-scope-troubleshooting.md` with this content and commit it.
2. In your lab, reproduce two failures (scope exhaustion and missing ip helper) then fix both and save evidence artifacts.
3. Add a prevention note in notes.md: scope utilization alert thresholds and a standard lease-time policy for your environment.
