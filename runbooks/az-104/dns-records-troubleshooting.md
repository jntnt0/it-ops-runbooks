# /runbooks/az-104/dns-records-troubleshooting.md

Tag: A/B

# DNS records troubleshooting (public DNS, Azure DNS, Private DNS)

## Symptoms

- Name does not resolve (NXDOMAIN) or resolves to the wrong IP
- Some clients resolve, others do not (cache, split DNS, wrong resolver)
- CNAME chain is broken or points somewhere unexpected
- MX/TXT/SRV records missing or incorrect (mail, SPF, autodiscover, service discovery)
- Private endpoint name resolves to a public IP (should be private) or does not resolve at all
- Changes were made but "nothing changed" (TTL, negative caching, wrong authoritative zone)

---

## Scope

Covers:

- Public DNS troubleshooting (registrar delegation, authoritative name servers, common record types)
- Azure DNS public zones and record sets
- Azure Private DNS zones, VNet links, and private endpoint name resolution
- Resolver path troubleshooting (client, custom DNS servers, Azure-provided DNS)

Excludes:

- Deep BIND/Unbound config repair (collect evidence, hand off if needed)
- Full network path troubleshooting after DNS is confirmed correct (use the VNet + NSG runbook)

---

## Preconditions

You must know:

- The exact name being queried (FQDN) and expected answer
- Record type(s): A, AAAA, CNAME, MX, TXT, SRV, NS
- Where the record should live:
  - Public zone (internet)
  - Private zone (inside VNets only)
- Who owns the authoritative DNS:
  - Registrar-hosted, third party (Cloudflare, etc.), or Azure DNS
- Whether clients use:
  - Azure-provided DNS
  - Custom DNS servers (DCs, appliances, resolvers)
  - Private DNS resolver (if deployed)

Minimum roles (least privilege):

- Read-only inspection:
  - Reader on subscription/resource group for Azure DNS zones
- Making DNS changes:
  - DNS Zone Contributor (public zone) or Private DNS Zone Contributor (private zone) at the zone scope
- If registrar delegation must be changed:
  - Access to registrar DNS settings (outside Azure)

---

## Triage Checklist

Do this in order. Do not guess.

1) Define the failing query:
   - FQDN, record type, expected answer, and expected visibility (public or private)
2) Identify the resolver the failing client is using:
   - Windows: ipconfig /all
   - Linux: cat /etc/resolv.conf and systemd-resolve status (if applicable)
3) Test resolution from three vantage points:
   - The client that is failing
   - A known external resolver (public internet)
   - The authoritative name servers for the zone
4) Determine whether the problem is:
   - wrong zone or missing record
   - wrong delegation (NS) at registrar
   - cache/TTL/negative cache
   - split DNS (public and private zones collide)
   - private endpoint DNS not wired (private zone link or custom DNS forwarders)
5) Record timestamps and TTL values (they explain most "still broken" complaints)

---

## Fix Steps

### Step 1: Reproduce and capture the failure (client side)

Windows commands:

- Resolve A/AAAA:
  - `Resolve-DnsName <fqdn> -Type A`
  - `Resolve-DnsName <fqdn> -Type AAAA`
- Force record type in nslookup:
  - `nslookup -type=MX <domain>`
  - `nslookup -type=TXT <domain>`

Linux commands:

- `dig <fqdn> A +noall +answer`
- `dig <fqdn> CNAME +noall +answer`
- `dig <domain> MX +noall +answer`
- `dig <domain> TXT +noall +answer`

Capture:

- Resolver IP used by the client
- Exact output (include TTL if shown)
- Any NXDOMAIN or SERVFAIL

Evidence:

- `/evidence/runbooks-az-104-dns-records-troubleshooting/commands/client-dns-tests-<date>.txt`

---

### Step 2: Find the authoritative zone and authoritative name servers

You need to know where the truth lives.

Public DNS:

- Identify the zone apex (example.com) and query NS:
  - `dig example.com NS +noall +answer`
- If results do not match what you think, delegation is wrong.

If you suspect delegation is wrong, query the TLD (advanced but fast when needed):

- `dig example.com NS @a.gtld-servers.net +noall +answer` (for .com domains)

Azure DNS (public zone):

- Zone exists?
  - `az network dns zone show -g <rg> -n <zoneName> -o json`
- List record sets:
  - `az network dns record-set list -g <rg> -z <zoneName> -o table`

Azure Private DNS:

- Zone exists?
  - `az network private-dns zone show -g <rg> -n <zoneName> -o json`
- VNet links:
  - `az network private-dns link vnet list -g <rg> -z <zoneName> -o table`

Evidence:

- `/evidence/runbooks-az-104-dns-records-troubleshooting/commands/zone-and-ns-inventory-<date>.txt`
- `/evidence/runbooks-az-104-dns-records-troubleshooting/exports/zone-recordsets-<date>.json`

---

### Step 3: Query the authoritative name servers directly

This removes caching and resolver weirdness.

Get the authoritative NS for the zone, then query them:

- `dig @<authoritative-ns> <fqdn> A +noall +answer`
- `dig @<authoritative-ns> <domain> MX +noall +answer`
- `dig @<authoritative-ns> <domain> TXT +noall +answer`

Outcomes:

- Authoritative server has the correct record
  - Then the problem is caching, resolver path, or split DNS
- Authoritative server does not have the record (or wrong record)
  - Then you are editing the wrong zone, or the record is missing/incorrect

Evidence:

- `/evidence/runbooks-az-104-dns-records-troubleshooting/commands/authoritative-queries-<date>.txt`

---

### Step 4: Fix common DNS record problems

Common issues and fixes:

A) Record exists in the wrong zone

- Example: you created `app.example.com` in a different provider than the authoritative zone.
Fix:
- Make the change in the authoritative zone only. Remove junk records elsewhere if they cause confusion.

B) Wrong record type

- A vs CNAME vs AAAA mismatch.
Fix:
- Use the type the client expects. For root/apex records, CNAME is often not allowed by many DNS systems. Use an A record or provider-supported alias feature.

C) Missing intermediate CNAME target

- CNAME points to a name that does not resolve.
Fix:
- Ensure the target name exists and resolves publicly or privately as required.

D) TTL and propagation expectations are wrong

- TTL might be 3600 seconds and clients will keep old answers.
Fix:
- Lower TTL before planned changes (future), then change record, then raise TTL later.

E) Negative caching (NXDOMAIN sticks around)

- Resolvers cache "does not exist" for a while.
Fix:
- Wait for negative TTL, or test against authoritative servers. Flushing local cache does not flush upstream resolvers.

Azure DNS change commands (examples):

Public zone record set (A):

- Create/update:
  - `az network dns record-set a add-record -g <rg> -z <zoneName> -n <recordName> -a <ip>`
- Remove wrong IP:
  - `az network dns record-set a remove-record -g <rg> -z <zoneName> -n <recordName> -a <ip>`

Private DNS record set (A):

- `az network private-dns record-set a add-record -g <rg> -z <privateZoneName> -n <recordName> -a <ip>`

Evidence:

- `/evidence/runbooks-az-104-dns-records-troubleshooting/commands/dns-changes-<date>.txt`
- `/evidence/runbooks-az-104-dns-records-troubleshooting/screenshots/azure-dns-recordset-after-<date>.png` (redacted)

---

### Step 5: Private DNS and private endpoints (most common modern failure)

Symptoms:

- Private endpoint FQDN resolves to a public IP
- Name resolves, but to the wrong place (wrong private zone or wrong VNet)
- Works from one VNet, fails from another (missing zone link)

Checks:

1) Confirm the private DNS zone is correct for the service
   - Example patterns: privatelink.<service-domain>
2) Confirm VNet link exists to the VNet where clients live
3) Confirm auto-created A record exists for the private endpoint (or you created it)
4) Confirm the client is using a resolver that can see the private zone:
   - If using Azure-provided DNS in the VNet, and the zone is linked, it should resolve
   - If using custom DNS servers, those servers must be able to resolve the private zone (forwarding or private resolver design)

Quick validation:

- From a VM in the target VNet:
  - `nslookup <private-endpoint-fqdn>`
  - Confirm answer is the private IP of the endpoint

Fix options:

- Link the private DNS zone to the correct VNet
- If using custom DNS:
  - Ensure the custom DNS servers can resolve the private zone (common fix is deploying Azure DNS Private Resolver and integrating forwarding)
- If records are wrong:
  - Remove incorrect A records and let private endpoint registration recreate them (or correct them manually)

Evidence:

- `/evidence/runbooks-az-104-dns-records-troubleshooting/screenshots/private-dns-zone-links-<date>.png`
- `/evidence/runbooks-az-104-dns-records-troubleshooting/screenshots/private-endpoint-dns-config-<date>.png`
- `/evidence/runbooks-az-104-dns-records-troubleshooting/commands/private-dns-validation-<date>.txt`

---

### Step 6: Cache cleanup and re-test (only after authoritative is correct)

Client cache flush (use sparingly, but useful after you proved authoritative is right):

Windows:

- `ipconfig /flushdns`

Linux (varies):

- systemd-resolved:
  - `sudo resolvectl flush-caches`

Browser and app caches exist too. Do not pretend DNS flush fixes everything.

Re-test:

- Query the record again from:
  - the same client
  - an external resolver
  - the authoritative server

Record the TTL and whether it now matches expected.

Evidence:

- `/evidence/runbooks-az-104-dns-records-troubleshooting/commands/post-fix-tests-<date>.txt`

---

## Verification

- Authoritative name server answers with the correct record and TTL
- Failing client now resolves the correct answer using its configured resolver
- For private DNS:
  - Clients inside the intended VNet resolve to private IPs
  - External clients do not see private-only names (unless intentionally exposed)
- For public DNS:
  - Delegation (NS) matches the correct provider and has not drifted
- Any temporary test records were removed

---

## Prevention

- Standardize DNS ownership:
  - One authoritative provider per zone, documented
- For public zones:
  - Keep delegation and NS values documented in the runbook notes
  - Use change windows when TTL reductions are needed
- For private endpoints:
  - Treat private DNS zone links as part of the deployment, not an optional step
  - If using custom DNS, plan the resolver architecture (private resolver or forwarding) before scaling private endpoints
- Use consistent naming and avoid duplicate split zones unless you intentionally operate split DNS and document it

---

## Rollback

If a DNS change caused impact:

1) Restore previous record values from your exported record set snapshot
2) Restore TTL to prior value if you changed it
3) If delegation (NS) was changed:
   - revert at registrar to the previous authoritative name servers immediately
4) Re-test against authoritative servers and client resolvers
5) Document rollback in notes.md with exact timestamps

---

## Evidence to collect

Store under: `/evidence/runbooks-az-104-dns-records-troubleshooting/`

- `commands/`
  - `client-dns-tests-<date>.txt`
  - `zone-and-ns-inventory-<date>.txt`
  - `authoritative-queries-<date>.txt`
  - `dns-changes-<date>.txt`
  - `private-dns-validation-<date>.txt` (if applicable)
  - `post-fix-tests-<date>.txt`
- `exports/`
  - `zone-recordsets-<date>.json` (public or private zone exports)
- `screenshots/` (redacted)
  - `azure-dns-zone-overview-<date>.png`
  - `azure-dns-recordset-before-<date>.png`
  - `azure-dns-recordset-after-<date>.png`
  - `private-dns-zone-links-<date>.png` (if applicable)
  - `private-endpoint-dns-config-<date>.png` (if applicable)
- `notes.md`
  - Expected answer, authoritative zone, resolver path, and final fix
- `timeline.md`
  - T0 report, T1 authoritative check, T2 change, T3 propagation, T4 verify

---

## Next 3 actions

1. Create `/runbooks/az-104/dns-records-troubleshooting.md` with this content and commit it.
2. In your lab, reproduce two failures (wrong A record in Azure DNS public zone, missing private DNS VNet link for a private endpoint), then fix both and save evidence artifacts.
3. Add one short resolver architecture note to notes.md: Azure-provided DNS vs custom DNS, and how private zones are resolved in your environment.
