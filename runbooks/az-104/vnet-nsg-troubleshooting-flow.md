# /runbooks/az-104/vnet-nsg-troubleshooting-flow.md

Tag: A/B

# VNet + NSG troubleshooting flow

## Symptoms

- VM cannot RDP or SSH from expected source
- App tier cannot reach DB tier on expected port
- Health probes fail (Load Balancer, App Gateway, VMSS)
- Private endpoint name resolves but connection times out
- Inter-VNet connectivity fails (peering exists but traffic drops)
- Traffic works sometimes, then fails after a change (NSG, UDR, firewall)

## Scope

Covers:

- Connectivity troubleshooting inside Azure VNets with NSGs
- Subnet NSG vs NIC NSG precedence and effective rules
- Route path verification (system routes, UDR, next hop, forced tunneling)
- Common Azure patterns: peering, load balancer, private endpoints, NAT gateway, Azure Firewall

Not covered:

- On-prem routing and edge firewall deep dives (collect evidence and hand off)
- Application layer debugging beyond “is the port reachable”

## Preconditions

- You know the source and destination:
  - Source IP, source subnet, and source resource (VM, App Service integration, AKS node, etc.)
  - Destination IP or FQDN, destination resource, and target port and protocol
- You can run at least one of:
  - Azure portal access to the subscription
  - Azure CLI or PowerShell with access to read network objects
- Minimum roles (least privilege):
  - Reader to inspect most network objects
  - Network Contributor to change NSG rules, route tables, NIC settings
  - For Network Watcher diagnostics: Reader is often enough to view, but actions may require elevated rights depending on tenant policies

## Triage checklist

1. Define the exact flow
   - Source: IP, subnet, VM or service
   - Destination: IP, subnet, resource, port, protocol (TCP/UDP/ICMP)
2. Confirm DNS and endpoint selection
   - FQDN resolves to expected IP (public vs private)
3. Confirm the path is inside expected VNet boundary
   - Same VNet, peered VNet, VPN/ExpressRoute, or Internet
4. Check if the destination is listening
   - VM firewall, service health, OS port binding
5. Validate NSG evaluation
   - NIC NSG and subnet NSG, effective rules, priority, direction
6. Validate routing
   - Effective routes on NIC, UDRs, next hop, forced tunneling
7. Validate platform blocks
   - Private endpoints, service endpoints, firewall appliances, Azure Firewall policies
8. Identify last known good change
   - Recent NSG rule edits, route table changes, peering updates

## Fix steps

### Step 1: Capture the flow and basic facts

Write down:

- Source: resource name, NIC, private IP, subnet
- Destination: resource name, private IP or public IP, subnet
- Port and protocol, direction

Evidence to collect now:

- Portal screenshots (redacted) of:
  - Source NIC IP configuration
  - Destination NIC IP configuration
  - Subnet and VNet names
- Save under:
  - `/evidence/runbooks-az-104-vnet-nsg-troubleshooting-flow/screenshots/`

### Step 2: Confirm name resolution and the correct destination IP

From the source VM (or jump host):

- `nslookup <fqdn>`
- `ping <ip>` (ICMP may be blocked, but it is still a quick signal)
- Windows: `Test-NetConnection <ip-or-fqdn> -Port <port>`
- Linux: `nc -vz <ip> <port>` or `curl -v telnet://<ip>:<port>` for quick TCP checks

If the FQDN resolves to a public IP when you expect private:

- Check private DNS zone links, records, and VNet links
- For private endpoints, confirm you are using the private DNS zone pattern for that service

Evidence:

- `/evidence/runbooks-az-104-vnet-nsg-troubleshooting-flow/commands/source-tests-<date>.txt`

### Step 3: Identify the applicable NSGs for source and destination

You must check both:

- Source subnet NSG and source NIC NSG
- Destination subnet NSG and destination NIC NSG

Portal:

- VNet > Subnets > select subnet > Network security group
- VM > Networking > shows NIC NSG and effective rules

CLI (examples):

- List NSGs in RG:
  - `az network nsg list -g <rg> -o table`
- Show subnet NSG association:
  - `az network vnet subnet show -g <rg> --vnet-name <vnet> -n <subnet> -o json`
- Show NIC NSG association:
  - `az network nic show -g <rg> -n <nic> -o json`

Evidence:

- `/exports/nsg-inventory-<date>.json`
- `/commands/nsg-inventory-<date>.txt`

### Step 4: Use effective security rules, not raw rule lists

Raw NSG rules lie by omission. Effective rules show what actually applies after merges.

Portal:

- VM > Networking > Effective security rules

Network Watcher:

- IP flow verify (source VM NIC):
  - Select VM, source IP, destination IP, protocol, port
  - Result: Allow or Deny, and which rule hit

CLI:

- You can export NSG rules, but effective evaluation is best via portal or Network Watcher tools

Common mistakes to catch:

- Wrong direction
  - Inbound rules control traffic to the destination
  - Outbound rules control traffic leaving the source
- Priority conflict
  - Lower number wins
- “Allow VNet inbound/outbound” is blocked by a higher priority deny
- ASG membership missing or incorrect
- Source or destination address prefix too narrow or wrong
- Using “Any” when you meant TCP only, or vice versa

Fix:

- Add or adjust the minimum allow rule at the tightest scope possible
  - Prefer subnet NSG for tier-level policy
  - Prefer NIC NSG for one-off exceptions (then clean it up later)
- Do not add wide allows at high scope as a “quick test” unless you are prepared to revert immediately

Evidence:

- `/screenshots/effective-security-rules-<vm>-<date>.png`
- `/exports/ip-flow-verify-<date>.json` (manual export notes if portal only)

### Step 5: Validate routing with effective routes and next hop

NSGs are not the only reason traffic dies. Routing is the other half.

Portal:

- NIC > Effective routes

Network Watcher:

- Next hop test (source VM to destination IP)

CLI pointers:

- Identify route table on subnet:
  - `az network vnet subnet show -g <rg> --vnet-name <vnet> -n <subnet> --query routeTable -o json`
- Show route table routes:
  - `az network route-table route list -g <rg> --route-table-name <rt> -o table`

Common routing issues:

- UDR sends traffic to a firewall appliance that does not allow it
- Forced tunneling sends traffic on-prem unexpectedly
- Missing route in appliance (NVA) for return path
- Peering exists but “Use remote gateways” and “Allow gateway transit” are mis-set for the design
- Overlapping address spaces between VNets or on-prem breaks routing
- Destination is behind a private endpoint, but source is not in the linked VNet or DNS is wrong

Fix:

- If a UDR is wrong, correct next hop and prefix
- If peering is wrong, set flags correctly and re-test
- If NVA is involved, confirm it has both forward and return routes, and policy allows the flow

Evidence:

- `/screenshots/effective-routes-<nic>-<date>.png`
- `/commands/next-hop-<date>.txt`
- `/exports/route-tables-<date>.json`

### Step 6: Check platform components that commonly block traffic

Load Balancer (internal or public):

- NSG must allow inbound from the client source to the backend port
- For health probes: allow AzureLoadBalancer service tag inbound to probe port
- Confirm backend pool membership and health

App Gateway:

- Confirm NSG allows required ports and health probes
- Confirm listener and backend settings

Private Endpoint:

- Confirm private DNS zone link and record
- Confirm NSGs allow traffic to the private endpoint IP on required port
- Confirm service-level approval and connection state is Approved

NAT Gateway:

- Only affects outbound SNAT, not inbound. Do not chase it for inbound failures.

Azure Firewall:

- Network rules, application rules, and DNAT rules can block
- Always check logs for deny hits when forced tunneling or UDR sends flows through it

Fix:

- Apply the smallest rule change that directly maps to the failing flow
- Re-run IP flow verify and next hop after each change

Evidence:

- `/screenshots/platform-settings-<component>-<date>.png`
- `/exports/firewall-denies-<date>.json` if applicable

### Step 7: Make the change safely and document it

Process:

1. Create a temporary allow rule with a clear name, low risk scope, and a tight source prefix
2. Re-test connectivity
3. If it works, convert the temp rule into a permanent, properly scoped rule
4. Remove the temporary rule

Good rule naming:

- `ALLOW-AppToDb-TCP-1433-Prod`  
- `ALLOW-HealthProbe-AzureLoadBalancer-80`

Evidence:

- `/commands/change-log-<date>.txt` with:
  - What changed
  - Why
  - Which rule IDs or names
  - Before and after test results

## Verification

You are done only when all are true:

- IP flow verify returns Allow for the exact flow
- Next hop shows the expected path (no surprise NVA unless intended)
- Source test succeeds:
  - Windows: `Test-NetConnection` shows TcpTestSucceeded True
  - Linux: TCP connect succeeds
- Effective rules show the intended allow rule is the one matching, not a lucky broad allow
- Activity log shows your change, with timestamps recorded in timeline.md

## Prevention

- Standardize subnet-level NSG patterns by tier (web, app, db, mgmt)
- Keep NIC-level NSGs rare and temporary
- Use ASGs for role-based grouping instead of IP prefix sprawl
- Avoid UDR sprawl. Document every route table’s intent and owner
- Enable Network Watcher in regions you use and keep a known-good test VM per VNet
- For environments with firewalls or NVAs, keep deny logging and review it during incidents

## Rollback

If your change causes impact:

1. Remove the new NSG rule(s) you added or revert priority to previous state
2. Revert any route table change immediately
3. Re-test with IP flow verify and next hop to confirm you are back to baseline
4. Document rollback in notes.md and timeline.md with why the change was wrong

## Evidence to collect

Store under: `/evidence/runbooks-az-104-vnet-nsg-troubleshooting-flow/`

- `commands/`
  - `source-tests-<date>.txt`
  - `nsg-inventory-<date>.txt`
  - `next-hop-<date>.txt`
  - `change-log-<date>.txt`
- `exports/`
  - `nsg-inventory-<date>.json`
  - `route-tables-<date>.json`
  - `activity-log-<date>.json`
- `screenshots/` (redacted)
  - `effective-security-rules-<vm>-<date>.png`
  - `effective-routes-<nic>-<date>.png`
  - `ip-flow-verify-result-<date>.png`
  - `subnet-nsg-association-<date>.png`
  - `platform-settings-<component>-<date>.png`
- `notes.md`
  - What broke, what was blocked (rule name), and the minimal fix
- `timeline.md`
  - T0 report, T1 triage, T2 change, T3 verify, T4 closeout

## Next 3 actions

1. Create `/runbooks/az-104/vnet-nsg-troubleshooting-flow.md` with this content and commit it.
2. In your lab, build a two-subnet VNet (app and db), intentionally block a port with NSG, then resolve it using IP flow verify and effective routes, saving evidence artifacts.
3. Add one short “common failure examples” note to notes.md after the lab run (wrong direction, priority conflict, UDR to NVA, health probe service tag).
