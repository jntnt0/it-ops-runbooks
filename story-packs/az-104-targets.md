# /story-packs/az-104-targets.md

Legend
A = Fully demonstrable via GitHub plus automation (scripts, IaC, exports, repeatable runs)
B = Fully demonstrable with a lab tenant and test devices (you can generate real evidence)
C = Mostly documentation and story pack only unless you have a real org environment

Assumptions (so A/B/C stays honest)
- Azure items are demoable if you have an Azure subscription, even if small
- Identity governance items that depend on Entra P2 are handled in SC-300, not here

Repo rule (prevents duplicate runbooks)
- One canonical runbook per scenario
- If a scenario is relevant to multiple exams, do not clone it. Link to the canonical runbook from the other exam index
- Canonical home: Azure resource scenarios live under AZ-104/Azure

AZ-104 target projects (queue)

1) Compute and VM operations
- VM provisioning choices and tradeoffs: availability sets vs zones, sizes, disks, extensions (A/B)
- VM access and recovery: serial console, reset password, run command, boot diagnostics (B)
- VM backup and restore testing: vault, policies, file restore vs full restore (A/B)
- Storage for VMs: managed disks, snapshots, disk encryption, performance tiers (A/B)

2) Azure networking baseline
- VNet and subnet design, address planning, peering (A/B)
- NSGs: effective rules, troubleshooting flow (A/B)
- UDRs and route tables: common blackhole causes (A/B)
- Azure DNS vs custom DNS, private DNS zones, name resolution in VNets (A/B)
- VPN Gateway basics and troubleshooting story (B/C)
- Load Balancer vs Application Gateway vs Front Door: when and why (A/B)

3) Identity and governance in Azure (Azure RBAC, not Entra admin roles)
- Azure RBAC in practice: scope hierarchy, deny assignments, custom roles, least privilege (A/B)
- Managed identities: system vs user assigned, where they matter, how auth works (A/B)
- Resource locks and how they bite you (A/B)
- Azure Policy basics: initiative vs policy, deny vs audit, remediation (A/B)
- Tags and naming standards enforcement (A)
- Management groups and subscriptions strategy (basic org design) (C)

4) Storage and data services
- Storage accounts: LRS/ZRS/GRS tradeoffs, access tiers, lifecycle management (A/B)
- Storage security: private endpoints, firewall rules, SAS vs Entra auth, key rotation (A/B)
- File shares and Azure File Sync basics: what it is, why you use it (B/C)
- Blob access patterns and common 403 causes (A/B)

5) Monitoring and troubleshooting
- Azure Monitor agent basics (AMA) and what data goes where (A/B)
- Log Analytics workspace design: retention, cost considerations (A/B)
- KQL basics you can speak aloud: filtering, time ranges, summarizing (A)
- Alerts: metric vs log alerts, action groups, alert fatigue control (A/B)
- Activity log vs resource logs distinction and why it matters (A)
- Monitoring costs: keeping Log Analytics spend from exploding (A/B)

6) Automation and repeatability
- Bicep deployments with parameters, modules, outputs (A)
- Azure CLI or PowerShell basics for repeatability (A)
- Azure Update Manager patching story (B/C)
- Runbooks or Functions for scheduled tasks (A/B)

7) Security and recovery fundamentals
- Key Vault basics: secrets vs keys vs certificates, access policies vs RBAC, soft delete (A/B)
- Defender for Cloud posture basics and what you do with findings (B/C)
- RTO/RPO for Azure workloads and restore testing story (B/C)
- Azure sign-in logs plus Azure Activity logs when troubleshooting changes (A/B)

8) Cost management
- Cost analysis basics, budgets, alerts, tags for chargeback (A/B)
- Why did costs spike triage checklist (A)
- Reserved instances and savings plans basics, when they are smart vs risky (C)

9) Shared foundations to link, not duplicate (canonical /runbooks/shared)
- Basic routing and NAT (A/B)
- Firewall basics (A/B)
- VPN types and common failure modes (C)
- Certificates and PKI basics (A/B)
- Change management: rollout phases, backout plans, comms plans, maintenance windows, risk analysis, documentation (A)

Next 3 actions
1) Create /story-packs/az-104-targets.md with this content and link it from /INDEX.md.
2) Build the top 10 AZ-104 runbooks as A/B with IaC or CLI proof where possible, and save outputs under /evidence/<scenario-slug>/.
3) Use Bicep for anything you deploy twice to keep your evidence repeatable.