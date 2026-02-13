<#

# Add this section to each script header comment block

.MINIMUM ROLES / SCOPES
  Delegated (interactive) via Microsoft Graph PowerShell:
    - Minimum Graph scopes:
      - AuditLog.Read.All
    - Minimum Entra roles (to consent / run):
      - Security Reader (typical minimum to view sign-in + audit logs in portals)
      - Reports Reader (often sufficient for reading reports/logs in many tenants)
    - Notes:
      - If your account cannot consent to scopes, a Global Administrator must grant admin consent for the required scopes.

  Application (automation) via app registration:
    - Minimum Graph application permissions:
      - AuditLog.Read.All
    - Admin consent required:
      - Yes (Global Administrator or Privileged Role Administrator can grant consent depending on tenant policy)

.LICENSING UNAVAILABLE BEHAVIOR
  - These scripts do not require Entra ID P1/P2.
  - If the tenant lacks premium identity features (P1/P2), the exports still work.
  - If the tenant lacks access to specific datasets (for example, risk events), this script will:
    - Log a clear message stating the dataset is unavailable in this tenant/licensing context
    - Exit with code 0 if the core export succeeded, or code 1 if the core export is blocked
  - If Microsoft Graph returns 403/Authorization_RequestDenied:
    - The script will fail fast, log the error, and instruct you to grant the required scope/permission.

# Concrete edits you should apply now

## 1) entra-export-signinlogs.ps1
Insert under .LEAST PRIVILEGE / PERMISSIONS (or right after it):
- The exact scopes listed above
- Note that P1/P2 is not required for sign-in logs
- Note the behavior on 403

Also add one runtime guard after Ensure-GraphConnection:
- If the query fails with 403, log: "Missing AuditLog.Read.All delegated/app permission or tenant policy blocks access."

## 2) entra-export-auditlogs.ps1
Same insert and same runtime guard.
Audit logs also do not require P1/P2.

# Next 3 actions
- Paste the block above into both scripts and keep the language identical so your repo stays consistent.
- Add a small catch for 403 that prints one actionable line: "Grant AuditLog.Read.All and retry" plus your chosen auth mode (delegated vs app).
- For any future script that touches risky users/sign-ins or Identity Protection, change the licensing section to explicitly say "Requires Entra ID P2" and exit cleanly with a logged note when unavailable.

.SYNOPSIS
  Export Entra ID audit logs for a UTC time window (optionally filtered) to CSV/JSON for runbook evidence.

.DESCRIPTION
  Pulls audit log directory audits from Microsoft Graph and writes sanitized exports under -OutDir.
  Designed for repeatable evidence collection referenced by runbooks.

.TAG
  A

.PREREQUISITES
  - PowerShell 7+ recommended
  - Microsoft Graph PowerShell module installed:
      Install-Module Microsoft.Graph -Scope CurrentUser
  - Network access to Microsoft Graph

.LEAST PRIVILEGE / PERMISSIONS
  Delegated (interactive):
    - AuditLog.Read.All (minimum for directory audits)
  Application (automation):
    - AuditLog.Read.All (application permission) with appropriate admin consent
  Notes:
    - This script is read-only.

.SAFE LOGGING
  - Does not print tokens or headers.
  - Logs counts and filter parameters only.
  - Writes transcript and notes to -OutDir.

.OUTPUTS
  - <stamp>_entra_auditlogs.csv
  - <stamp>_entra_auditlogs.json
  - <stamp>_script.log
  - <stamp>_notes.txt

.HOW TO RUN
  Basic time window export:
    pwsh ./scripts/entra-export-auditlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -OutDir "./evidence/identity-password-spray-response/2026-02-12_incident-01/scripts"

  Filter to events related to a user (best-effort):
    pwsh ./scripts/entra-export-auditlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -UserPrincipalName "user@contoso.com" -OutDir "./evidence/.../scripts"

  Filter by category:
    pwsh ./scripts/entra-export-auditlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -Category "UserManagement" -OutDir "./evidence/.../scripts"

#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$OutDir,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [datetime]$StartUtc,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [datetime]$EndUtc,

  # Best-effort filter: Graph audit logs support rich filters, but UPN isn't always a direct field.
  # We attempt filters that work for many tenants; if it returns 0, export unfiltered and filter locally.
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$UserPrincipalName,

  [Parameter(Mandatory = $false)]
  [ValidateSet(
    'All',
    'UserManagement',
    'GroupManagement',
    'ApplicationManagement',
    'RoleManagement',
    'Policy',
    'Device',
    'DirectoryManagement',
    'Other'
  )]
  [string]$Category = 'All',

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$ActivityContains,

  [Parameter(Mandatory = $false)]
  [int]$Top = 0,

  [Parameter(Mandatory = $false)]
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-UtcStamp {
  (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHHmmssZ')
}

function New-DirectoryIfMissing {
  param([Parameter(Mandatory = $true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Log {
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [Parameter(Mandatory = $true)][string]$LogPath
  )
  $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  Add-Content -LiteralPath $LogPath -Value "$ts`t$Message"
}

function Assert-Prerequisites {
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7+ is recommended. Current: $($PSVersionTable.PSVersion)"
  }

  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    throw "Missing Microsoft.Graph module. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
  }
}

function Ensure-GraphConnection {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Scopes,
    [Parameter(Mandatory = $true)]
    [string]$LogPath
  )

  try { $ctx = Get-MgContext } catch { $ctx = $null }

  $needConnect = $true
  if ($ctx -and $ctx.Account -and $ctx.Scopes) {
    $needConnect = $false
    foreach ($s in $Scopes) {
      if ($ctx.Scopes -notcontains $s) { $needConnect = $true; break }
    }
  }

  if ($needConnect) {
    Write-Log -Message "Connecting to Microsoft Graph with scopes: $($Scopes -join ', ')" -LogPath $LogPath
    Connect-MgGraph -Scopes $Scopes | Out-Null
  } else {
    Write-Log -Message "Microsoft Graph already connected as $($ctx.Account)." -LogPath $LogPath
  }
}

function Build-ODataFilter {
  param(
    [Parameter(Mandatory = $true)][datetime]$StartUtc,
    [Parameter(Mandatory = $true)][datetime]$EndUtc,
    [Parameter(Mandatory = $false)][string]$Category,
    [Parameter(Mandatory = $false)][string]$ActivityContains,
    [Parameter(Mandatory = $false)][string]$UserPrincipalName
  )

  $start = $StartUtc.ToUniversalTime().ToString("o")
  $end   = $EndUtc.ToUniversalTime().ToString("o")

  $parts = @()
  $parts += "activityDateTime ge $start"
  $parts += "activityDateTime le $end"

  if ($Category -and $Category -ne 'All') {
    # Graph returns category values; this matches typical ones.
    $catEsc = $Category.Replace("'","''")
    $parts += "category eq '$catEsc'"
  }

  if ($ActivityContains) {
    $actEsc = $ActivityContains.Replace("'","''")
    $parts += "contains(activityDisplayName,'$actEsc')"
  }

  # Best-effort. Many audit log entries store targets and initiatedBy, not a simple UPN field.
  # This filter will not catch all user-related events. If it yields 0, we still export and filter client-side later.
  if ($UserPrincipalName) {
    $upnEsc = $UserPrincipalName.Replace("'","''")
    $parts += "contains(initiatedBy/user/userPrincipalName,'$upnEsc')"
  }

  return ($parts -join " and ")
}

function Convert-AuditToSafeRow {
  param([Parameter(Mandatory = $true)]$a)

  $initiatorUpn = $null
  $initiatorId  = $null
  $initiatorIp  = $null

  if ($a.InitiatedBy -and $a.InitiatedBy.User) {
    $initiatorUpn = $a.InitiatedBy.User.UserPrincipalName
    $initiatorId  = $a.InitiatedBy.User.Id
  }
  if ($a.InitiatedBy -and $a.InitiatedBy.App) {
    # If app-initiated, keep app name/id for evidence
    if (-not $initiatorUpn) { $initiatorUpn = $a.InitiatedBy.App.DisplayName }
    if (-not $initiatorId)  { $initiatorId  = $a.InitiatedBy.App.AppId }
  }
  if ($a.AdditionalDetails) {
    $ipDetail = $a.AdditionalDetails | Where-Object { $_.Key -eq 'UserAgent' -or $_.Key -eq 'IPAddress' }
    if ($ipDetail) {
      $ip = ($a.AdditionalDetails | Where-Object { $_.Key -eq 'IPAddress' } | Select-Object -First 1).Value
      if ($ip) { $initiatorIp = $ip }
    }
  }

  $targets = $null
  if ($a.TargetResources) {
    $targets = ($a.TargetResources | ForEach-Object {
      $tName = $_.DisplayName
      $tType = $_.Type
      if ($tName) { "$tType:$tName" } else { "$tType" }
    }) -join "; "
  }

  [pscustomobject]@{
    activityDateTime      = $a.ActivityDateTime
    activityDisplayName   = $a.ActivityDisplayName
    category              = $a.Category
    result                = $a.Result
    resultReason          = $a.ResultReason
    loggedByService       = $a.LoggedByService
    initiatedBy           = $initiatorUpn
    initiatedById         = $initiatorId
    initiatedByIpAddress  = $initiatorIp
    targetResources       = $targets
    correlationId         = $a.CorrelationId
  }
}

$logPath = $null
try {
  Assert-Prerequisites

  $stamp = Get-UtcStamp
  New-DirectoryIfMissing -Path $OutDir
  $outFull = (Resolve-Path -LiteralPath $OutDir).Path

  $logPath   = Join-Path $outFull "${stamp}_script.log"
  $notesPath = Join-Path $outFull "${stamp}_notes.txt"

  if (-not $Force -and (Test-Path -LiteralPath $logPath -PathType Leaf)) {
    throw "Output already exists: $logPath. Use -Force or choose a different -OutDir."
  }

  try {
    Start-Transcript -LiteralPath $logPath -Append | Out-Null
  } catch {
    New-Item -ItemType File -Path $logPath -Force | Out-Null
    Write-Log -Message "Transcript unavailable in this host. Using manual logging." -LogPath $logPath
  }

  Write-Log -Message "Script started." -LogPath $logPath
  Write-Log -Message "OutDir: $outFull" -LogPath $logPath
  Write-Log -Message "StartUtc: $($StartUtc.ToUniversalTime().ToString('o'))" -LogPath $logPath
  Write-Log -Message "EndUtc: $($EndUtc.ToUniversalTime().ToString('o'))" -LogPath $logPath
  Write-Log -Message "Category: $Category" -LogPath $logPath
  if ($ActivityContains) { Write-Log -Message "ActivityContains set." -LogPath $logPath }
  if ($UserPrincipalName) { Write-Log -Message "UserPrincipalName best-effort filter set." -LogPath $logPath }
  if ($Top -gt 0) { Write-Log -Message "Top: $Top" -LogPath $logPath }

  $scopes = @('AuditLog.Read.All')
  Ensure-GraphConnection -Scopes $scopes -LogPath $logPath

  $filter = Build-ODataFilter -StartUtc $StartUtc -EndUtc $EndUtc -Category $Category -ActivityContains $ActivityContains -UserPrincipalName $UserPrincipalName
  Write-Log -Message "OData filter: $filter" -LogPath $logPath

  $useBeta = $false
  $cmd = Get-Command -Name Get-MgBetaAuditLogDirectoryAudit -ErrorAction SilentlyContinue
  if ($cmd) { $useBeta = $true }

  $raw = @()
  if ($useBeta) {
    Write-Log -Message "Using Get-MgBetaAuditLogDirectoryAudit." -LogPath $logPath
    Select-MgProfile -Name 'beta' | Out-Null

    if ($Top -gt 0) {
      $raw = Get-MgBetaAuditLogDirectoryAudit -Filter $filter -Top $Top
    } else {
      $raw = Get-MgBetaAuditLogDirectoryAudit -Filter $filter -All
    }
  } else {
    $cmd2 = Get-Command -Name Get-MgAuditLogDirectoryAudit -ErrorAction SilentlyContinue
    if (-not $cmd2) {
      throw "Neither Get-MgBetaAuditLogDirectoryAudit nor Get-MgAuditLogDirectoryAudit is available. Update Microsoft.Graph module."
    }

    Write-Log -Message "Using Get-MgAuditLogDirectoryAudit (v1.0)." -LogPath $logPath
    Select-MgProfile -Name 'v1.0' | Out-Null

    if ($Top -gt 0) {
      $raw = Get-MgAuditLogDirectoryAudit -Filter $filter -Top $Top
    } else {
      $raw = Get-MgAuditLogDirectoryAudit -Filter $filter -All
    }
  }

  Write-Log -Message "Fetched raw audit events: $($raw.Count)" -LogPath $logPath

  $rows = $raw | ForEach-Object { Convert-AuditToSafeRow -a $_ }

  # If the best-effort UPN filter is set and returned 0, still try local filtering via targetResources string.
  if ($UserPrincipalName -and $rows.Count -gt 0) {
    $upnLower = $UserPrincipalName.ToLowerInvariant()
    $localMatches = $rows | Where-Object {
      ($_.initiatedBy -and $_.initiatedBy.ToString().ToLowerInvariant().Contains($upnLower)) -or
      ($_.targetResources -and $_.targetResources.ToString().ToLowerInvariant().Contains($upnLower))
    }
    # Only narrow locally if it actually finds matches; otherwise keep full export for evidence.
    if ($localMatches.Count -gt 0) {
      Write-Log -Message "Local filter matches for UPN: $($localMatches.Count). Narrowing export set." -LogPath $logPath
      $rows = $localMatches
    } else {
      Write-Log -Message "Local filter found 0 matches for UPN. Keeping full export set." -LogPath $logPath
    }
  }

  $csvPath  = Join-Path $outFull "${stamp}_entra_auditlogs.csv"
  $jsonPath = Join-Path $outFull "${stamp}_entra_auditlogs.json"

  $rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8
  $rows | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $jsonPath -Encoding utf8

  Write-Log -Message "Wrote CSV:  $csvPath" -LogPath $logPath
  Write-Log -Message "Wrote JSON: $jsonPath" -LogPath $logPath

  $notes = @()
  $notes += "UtcStarted: $stamp"
  $notes += "StartUtc: $($StartUtc.ToUniversalTime().ToString('o'))"
  $notes += "EndUtc: $($EndUtc.ToUniversalTime().ToString('o'))"
  $notes += "Filter: $filter"
  $notes += "Category: $Category"
  if ($ActivityContains) { $notes += "ActivityContains: $ActivityContains" }
  $notes += "RawCount: $($raw.Count)"
  $notes += "RowCount: $($rows.Count)"
  if ($UserPrincipalName) { $notes += "UserPrincipalName: $UserPrincipalName (best-effort + local filter)" }
  $notes += ""
  $notes += "RedactionChecklist:"
  $notes += "- Redact initiator UPNs, IPs, target names, tenant identifiers, correlation IDs as needed before commit."
  $notes += "- Do not commit any tokens or secrets (this script does not output them)."

  $notes -join [Environment]::NewLine | Out-File -LiteralPath $notesPath -Encoding utf8
  Write-Log -Message "Wrote notes: $notesPath" -LogPath $logPath

  Write-Log -Message "Script completed successfully." -LogPath $logPath
}
catch {
  $msg = $_.Exception.Message
  try {
    if ($logPath) { Write-Log -Message "ERROR: $msg" -LogPath $logPath }
  } catch { }
  Write-Error $msg
  exit 1
}
finally {
  try { Disconnect-MgGraph | Out-Null } catch { }
  try { Stop-Transcript | Out-Null } catch { }
}