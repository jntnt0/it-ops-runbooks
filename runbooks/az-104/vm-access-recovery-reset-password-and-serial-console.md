# /runbooks/az-104/vm-access-recovery-reset-password-and-serial-console.md

Tag: B

# VM access recovery scenario (reset password, serial console)

## Symptoms

- Cannot RDP to Windows VM (auth failure, NLA issues, account locked, password unknown)
- Cannot SSH to Linux VM (key mismatch, password unknown, account locked)
- VM boots but is unreachable (misconfigured firewall, broken sshd/rdp service)
- VM is reachable on network but login is impossible
- You need emergency access without rebuilding the VM

## Scope

Covers:

- Windows VM access recovery:
  - Reset local admin password
  - Repair RDP settings
  - Run commands via VM Run Command
  - Serial Console basics for boot/login recovery
- Linux VM access recovery:
  - Reset password (where possible)
  - Fix sshd config and firewall
  - Run commands via Run Command
  - Serial Console for GRUB/single-user style recovery (when supported)

Not covered:

- Domain-joined AD account recovery (that is AD, not Azure VM access)
- Advanced disk offline repair using recovery VMs and mounting OS disk (separate runbook)
- Network path troubleshooting (NSG/UDR/VPN). Use VNet + NSG troubleshooting runbook first if it is actually a network issue.

## Preconditions

- You can access Azure portal for the subscription and locate the VM
- You have enough permissions:
  - VM Contributor or Contributor on the VM (to run commands and reset credentials)
  - For “reset password” operations, you typically need permissions to run VM extensions / actions
- Serial console prerequisites (common blockers):
  - Serial console feature supported in region and VM type
  - Boot diagnostics enabled
  - VM has a local user you can use (Linux often needs a user configured)
  - RBAC allows you to use serial console (if restricted by org policies)
- You know whether this is Windows or Linux and whether it is domain joined

## Triage checklist

1. Confirm this is not just a network issue
   - Is the VM running?
   - Can you reach the port from a known-good source (bastion/jump box)?
   - If unsure, use the VNet + NSG troubleshooting runbook first.
2. Identify OS type and access method
   - Windows: RDP, local admin, domain join
   - Linux: SSH keys vs password auth
3. Check recent changes
   - NSG change, Windows firewall change, sshd config change, extension install
4. Decide the least invasive recovery path
   - Reset credentials (fast)
   - Run Command to fix services/firewall (fast and auditable)
   - Serial console (when network path is fine but OS/login is broken)
5. Record the incident timeline from the start

## Fix steps

### Step 1: Capture baseline VM state

Portal:

- VM Overview:
  - Power state, region, resource group
- VM Networking:
  - NIC private IP
  - Public IP (if present)
  - NSG attached
- Boot diagnostics status (needed for serial console in many cases)

Evidence:

- `/evidence/runbooks-az-104-vm-access-recovery-reset-password-and-serial-console/screenshots/vm-overview-<date>.png`
- `/evidence/runbooks-az-104-vm-access-recovery-reset-password-and-serial-console/screenshots/vm-networking-<date>.png`

### Step 2: Use VM Run Command first when possible (cleaner than console)

This is the most reliable “I need to fix the OS config” tool.

Portal:

- VM -> Run command

Windows common fixes:

- Restart RDP service:
  - Use Run Command for PowerShell:
    - `Restart-Service TermService -Force`
- Ensure firewall allows RDP (last resort in a lab):
  - `Enable-NetFirewallRule -DisplayGroup "Remote Desktop"`
- Create or reset a local admin user:
  - `net user <user> <NewPasswordHere>`
  - `net localgroup administrators <user> /add`

Linux common fixes:

- Restart sshd:
  - `sudo systemctl restart sshd || sudo systemctl restart ssh`
- Fix UFW/firewalld if you blocked SSH:
  - `sudo ufw allow 22/tcp`
  - `sudo firewall-cmd --add-service=ssh --permanent && sudo firewall-cmd --reload`
- Verify sshd config isn’t broken:
  - `sudo sshd -t` (if available)

Evidence:

- Save the exact Run Command script and output:
  - `/commands/run-command-<date>.txt`
  - Screenshot of Run Command result (redacted) if portal-only

### Step 3: Reset password using the portal reset flow (credential recovery)

Use this when you simply cannot authenticate.

Windows:

- VM -> Reset password
  - Mode: Reset password
  - Username: local admin account (not domain)
  - Set new password

Linux:

- VM -> Reset password
  - Depending on distro and settings, you can reset password or reset SSH key
  - If using SSH key auth, prefer resetting the key rather than enabling password auth

Important warnings:

- This can be blocked by policies or extension failures
- It does not fix broken network path or broken services
- Document the change because it is high impact

Evidence:

- Screenshot of reset settings page (redacted)
- Screenshot of result status
- Notes entry with who approved and why

### Step 4: Use Serial Console when the OS is reachable but login/network services are broken

Serial console is for OS-level rescue when you can’t reach it over the network.

Portal:

- VM -> Serial console

Windows typical uses:

- Check boot/login issues
- Run basic recovery commands (depends on what is available in the console)
- In many cases, Run Command is more useful than serial console for Windows

Linux typical uses:

- Interrupt boot / access console login
- Fix a broken sshd config
- Fix networking config errors on the VM

Common blockers:

- Boot diagnostics not enabled
- RBAC restrictions
- No local user available for Linux console login
- Serial console not supported for the VM setup

Evidence:

- Screenshot (redacted) of the serial console session showing:
  - successful connection
  - key commands executed (avoid capturing secrets)

### Step 5: Confirm RDP/SSH works again from a known-good source

Do not test from a random network with unknown rules.

Windows validation:

- From jump host:
  - `Test-NetConnection <ip> -Port 3389`
- RDP login with the recovered account

Linux validation:

- From jump host:
  - `nc -vz <ip> 22`
- SSH login with recovered key/password

Evidence:

- `/commands/validation-tests-<date>.txt`
- Screenshot of successful login (redacted if it shows identity details)

### Step 6: Post-recovery cleanup (do not skip)

This is where people get lazy and leave insecurity behind.

- Rotate credentials again if this was done under pressure
- Remove any temporary users created
- Undo any overly broad firewall changes made as a quick fix
- If you enabled password auth on Linux temporarily, disable it and return to keys
- Ensure access is via the standard method:
  - Bastion/jump host, JIT access (if used), least privilege

Record all cleanup in notes.md.

## Verification

- VM is reachable on the required port (3389 or 22) from the approved source
- You can authenticate successfully
- Run Command output shows services are running (TermService or sshd)
- Any emergency changes (temporary users, broad firewall) are removed
- Timeline.md includes:
  - initial report time
  - recovery action time
  - verification time
  - cleanup time

## Prevention

- Standardize access method:
  - Use Azure Bastion or a locked-down jump host rather than public IP RDP/SSH
- Use JIT VM access where supported and enforced
- Keep a documented break-glass local admin account stored securely
- Ensure boot diagnostics is enabled for VMs where serial console may be needed
- Use configuration management/IaC so RDP/SSH settings don’t drift silently
- Log access recovery actions and review monthly

## Rollback

Rollback here means “undo emergency changes”:

1. Remove temporary admin accounts created for recovery
2. Revert firewall rule changes to baseline
3. Rotate the recovered password again and store it properly
4. If extensions were installed for recovery and are not standard, remove them (only if safe)
5. Confirm normal access paths still work after cleanup

## Evidence to collect

Store under: `/evidence/runbooks-az-104-vm-access-recovery-reset-password-and-serial-console/`

- `screenshots/` (redacted)
  - `vm-overview-<date>.png`
  - `vm-networking-<date>.png`
  - `reset-password-result-<date>.png`
  - `serial-console-session-<date>.png`
  - `successful-login-<date>.png`
- `commands/`
  - `run-command-<date>.txt`
  - `validation-tests-<date>.txt`
  - `cleanup-steps-<date>.txt`
- `exports/`
  - `activity-log-recovery-actions-<date>.json` (optional but recommended)
- `notes.md`
  - What failed, what recovery method used, approvals, and what was changed
- `timeline.md`
  - T0 report, T1 triage, T2 action, T3 verify, T4 cleanup

## Next 3 actions

1. Create `/runbooks/az-104/vm-access-recovery-reset-password-and-serial-console.md` with this content and commit it.
2. In your lab, intentionally break access (wrong password, stop sshd/disable RDP), then recover using Run Command first and serial console second, saving evidence artifacts.
3. Add a short “standard access baseline” note in notes.md after the lab (bastion/jump, no public RDP/SSH, boot diagnostics on).
