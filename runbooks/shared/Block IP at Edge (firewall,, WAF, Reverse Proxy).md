Block at your edge (firewall, WAF, reverse proxy)

Use this if:

You control the network egress or an inbound access proxy

You are protecting something that hits your perimeter (VPN, ADFS, on-prem apps)

Reality:

You cannot firewall-block Microsoft’s login service for the internet. You can only block attackers from reaching your own perimeter services, not from reaching Microsoft directly.

Evidence:

Firewall change ticket or config diff

Rule hit counters

Time of change
