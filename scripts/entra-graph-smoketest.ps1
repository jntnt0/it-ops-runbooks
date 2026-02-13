<#
.SYNOPSIS
  Fast wiring test for Microsoft Graph from this repo.
.DESCRIPTION
  Proves local Graph auth + basic API call + evidence write path.
PREREQUISITES
  - PowerShell 5.1+ (7+ recommended)
  - Microsoft.Graph installed
LEAST PRIVILEGE
  - Delegated: AuditLog.Read.All (admin consent may be required)
SAFE LOGGING
  - Writes only metadata and counts, no sensitive event payloads
HOW TO RUN
  pwsh -NoProfile -File .\scripts\entra-graph-smoketest.ps1 -Slug "entra-smoketest"
#>

param(
  [string]$Slug = "entra-smoketest"
)

$ErrorActionPreference = "Stop"

# Evidence paths
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$raw  = Join-Path $root "evidence\$Slug\raw"
$sum  = Join-Path $root "evidence\$Slug\summary"
New-Item -ItemType Directory -Force -Path $raw,$sum | Out-Null

# Connect (idempotent)
try { Get-MgContext | Out-Null } catch { }

if (-not (Get-MgContext)) {
  Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome
}

$ctx = Get-MgContext
$meta = [ordered]@{
  TimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
  TenantId     = $ctx.TenantId
  ClientId     = $ctx.ClientId
  Scopes       = ($ctx.Scopes -join ",")
  AuthType     = $ctx.AuthType
  Account      = $ctx.Account
}

# Minimal API call: get just 1 audit log record (metadata only)
$eventCount = 0
try {
  $one = Get-MgAuditLogDirectoryAudit -Top 1 -ErrorAction Stop
  if ($one) { $eventCount = 1 }
} catch {
  # If directory audit is empty or blocked, fall back to sign-ins (may require P1/P2 depending on tenant/features)
  try {
    $one2 = Get-MgAuditLogSignIn -Top 1 -ErrorAction Stop
    if ($one2) { $eventCount = 1 }
  } catch {
    $meta["ApiError"] = $_.Exception.Message
  }
}

$meta["GotOneEvent"] = $eventCount

# Write smoke evidence
$meta | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $raw "graph-smoketest.json")
@"
Entra Graph smoke test

Result:
- Connected: $([bool]$ctx)
- GotOneEvent: $eventCount

Notes:
- This file is safe to commit (no raw log payloads).
"@ | Set-Content -Encoding UTF8 (Join-Path $sum "README.md")

Write-Host "OK: wrote evidence to $raw and $sum"
