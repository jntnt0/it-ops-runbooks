<#
.SYNOPSIS
  Export Entra ID sign-in logs for a UTC time window (optionally filtered) to CSV/JSON for runbook evidence.

.DESCRIPTION
  Pulls sign-in logs from Microsoft Graph and writes sanitized exports under the provided -OutDir.
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
    - AuditLog.Read.All (minimum for sign-in logs)
  Application (automation):
    - AuditLog.Read.All (application permission) with appropriate admin consent
  Notes:
    - This script is read-only.

.SAFE LOGGING
  - Does not print tokens or headers.
  - Logs counts and filter parameters only.
  - Writes transcript and notes to -OutDir.

.OUTPUTS
  - <stamp>_entra_signinlogs.csv
  - <stamp>_entra_signinlogs.json
  - <stamp>_entra_signinlogs_legacy_auth.csv (if -FilterLegacyAuth)
  - <stamp>_script.log
  - <stamp>_notes.txt

.HOW TO RUN
  Basic time window export:
    pwsh ./scripts/entra-export-signinlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -OutDir "./evidence/identity-password-spray-response/2026-02-12_incident-01/scripts"

  Filter failures for a specific user:
    pwsh ./scripts/entra-export-signinlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -UserPrincipalName "user@contoso.com" -Status Failure -OutDir "./evidence/.../scripts"

  Filter by IP and flag legacy auth:
    pwsh ./scripts/entra-export-signinlogs.ps1 -StartUtc "2026-02-12T00:00:00Z" -EndUtc "2026-02-12T06:00:00Z" -IpAddress "1.2.3.4" -FilterLegacyAuth -OutDir "./evidence/.../scripts"

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

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$UserPrincipalName,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$IpAddress,

  [Parameter(Mandatory = $false)]
  [ValidateSet('Success','Failure','All')]
  [string]$Status = 'All',

  [Parameter(Mandatory = $false)]
  [switch]$FilterLegacyAuth,

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

  try {
    $ctx = Get-MgContext
  } catch {
    $ctx = $null
  }

  $needConnect = $true
  if ($ctx -and $ctx.Account -and $ctx.Scopes) {
    foreach ($s in $Scopes) {
      if ($ctx.Scopes -contains $s) { continue } else { $needConnect = $true; break }
    }
    if ($needConnect -ne $true) { $needConnect = $false }
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
    [Parameter(Mandatory = $false)][string]$UserPrincipalName,
    [Parameter(Mandatory = $false)][string]$IpAddress
  )

  $start = $StartUtc.ToUniversalTime().ToString("o")
  $end   = $EndUtc.ToUniversalTime().ToString("o")

  $parts = @()
  $parts += "createdDateTime ge $start"
  $parts += "createdDateTime le $end"

  if ($UserPrincipalName) {
    $upnEsc = $UserPrincipalName.Replace("'","''")
    $parts += "userPrincipalName eq '$upnEsc'"
  }

  if ($IpAddress) {
    $ipEsc = $IpAddress.Replace("'","''")
    $parts += "ipAddress eq '$ipEsc'"
  }

  return ($parts -join " and ")
}

function Convert-SignInToSafeRow {
  param([Parameter(Mandatory = $true)]$s)

  # Keep evidence useful, but avoid dumping entire nested objects by default.
  # User will redact before commit.
  $statusCode = $null
  $statusReason = $null
  if ($s.Status) {
    $statusCode = $s.Status.ErrorCode
    $statusReason = $s.Status.FailureReason
  }

  $caStatus = $null
  $caPolicies = $null
  if ($s.AppliedConditionalAccessPolicies) {
    $caPolicies = ($s.AppliedConditionalAccessPolicies | ForEach-Object {
      "{0}:{1}" -f $_.DisplayName, $_.Result
    }) -join "; "
  }
  if ($s.ConditionalAccessStatus) { $caStatus = $s.ConditionalAccessStatus }

  $authRequirement = $null
  if ($s.AuthenticationRequirement) { $authRequirement = $s.AuthenticationRequirement }

  $authDetails = $null
  if ($s.AuthenticationDetails) {
    $authDetails = ($s.AuthenticationDetails | ForEach-Object {
      # Avoid device IDs or tokens, keep method and result
      "{0}:{1}" -f $_.AuthenticationMethod, $_.Succeeded
    }) -join "; "
  }

  [pscustomobject]@{
    createdDateTime           = $s.CreatedDateTime
    userPrincipalName         = $s.UserPrincipalName
    userId                    = $s.UserId
    appDisplayName            = $s.AppDisplayName
    appId                     = $s.AppId
    resourceDisplayName       = $s.ResourceDisplayName
    clientAppUsed             = $s.ClientAppUsed
    ipAddress                 = $s.IpAddress
    location                  = ( @($s.Location.City, $s.Location.State, $s.Location.CountryOrRegion) | Where-Object { $_ } ) -join ", "
    userAgent                 = $s.UserAgent
    correlationId             = $s.CorrelationId
    conditionalAccessStatus   = $caStatus
    appliedCAPolicies         = $caPolicies
    authenticationRequirement = $authRequirement
    authenticationDetails     = $authDetails
    statusErrorCode           = $statusCode
    statusFailureReason       = $statusReason
    isInteractive             = $s.IsInteractive
  }
}

function Is-LegacyAuthRow {
  param([Parameter(Mandatory = $true)]$row)

  # Heuristic: legacy auth often shows as "Other clients" or specific legacy client names.
  # Keep simple and transparent; user can refine later.
  if (-not $row.clientAppUsed) { return $false }
  $v = $row.clientAppUsed.ToString().ToLowerInvariant()
  return (
    $v -eq "other clients" -or
    $v -like "*imap*" -or
    $v -like "*pop*" -or
    $v -like "*smtp*" -or
    $v -like "*mapi*" -or
    $v -like "*exchange activesync*" -or
    $v -like "*autodiscover*"
  )
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
  if ($UserPrincipalName) { Write-Log -Message "UserPrincipalName filter set." -LogPath $logPath }
  if ($IpAddress) { Write-Log -Message "IpAddress filter set." -LogPath $logPath }
  Write-Log -Message "Status: $Status" -LogPath $logPath
  Write-Log -Message "FilterLegacyAuth: $FilterLegacyAuth" -LogPath $logPath
  if ($Top -gt 0) { Write-Log -Message "Top: $Top" -LogPath $logPath }

  $scopes = @('AuditLog.Read.All')
  Ensure-GraphConnection -Scopes $scopes -LogPath $logPath

  $filter = Build-ODataFilter -StartUtc $StartUtc -EndUtc $EndUtc -UserPrincipalName $UserPrincipalName -IpAddress $IpAddress
  Write-Log -Message "OData filter: $filter" -LogPath $logPath

  $useBeta = $false
  $cmd = Get-Command -Name Get-MgBetaAuditLogSignIn -ErrorAction SilentlyContinue
  if ($cmd) { $useBeta = $true }

  $raw = @()
  if ($useBeta) {
    Write-Log -Message "Using Get-MgBetaAuditLogSignIn." -LogPath $logPath
    Select-MgProfile -Name 'beta' | Out-Null

    if ($Top -gt 0) {
      $raw = Get-MgBetaAuditLogSignIn -Filter $filter -Top $Top
    } else {
      $raw = Get-MgBetaAuditLogSignIn -Filter $filter -All
    }
  } else {
    $cmd2 = Get-Command -Name Get-MgAuditLogSignIn -ErrorAction SilentlyContinue
    if (-not $cmd2) {
      throw "Neither Get-MgBetaAuditLogSignIn nor Get-MgAuditLogSignIn is available. Update Microsoft.Graph module."
    }

    Write-Log -Message "Using Get-MgAuditLogSignIn (v1.0)." -LogPath $logPath
    Select-MgProfile -Name 'v1.0' | Out-Null

    if ($Top -gt 0) {
      $raw = Get-MgAuditLogSignIn -Filter $filter -Top $Top
    } else {
      $raw = Get-MgAuditLogSignIn -Filter $filter -All
    }
  }

  Write-Log -Message "Fetched raw sign-in events: $($raw.Count)" -LogPath $logPath

  $rows = $raw | ForEach-Object { Convert-SignInToSafeRow -s $_ }

  if ($Status -ne 'All') {
    if ($Status -eq 'Failure') {
      $rows = $rows | Where-Object { $_.statusErrorCode -ne 0 -and $_.statusErrorCode -ne $null }
    } elseif ($Status -eq 'Success') {
      $rows = $rows | Where-Object { $_.statusErrorCode -eq 0 }
    }
  }

  Write-Log -Message "Rows after status filter: $($rows.Count)" -LogPath $logPath

  $csvPath  = Join-Path $outFull "${stamp}_entra_signinlogs.csv"
  $jsonPath = Join-Path $outFull "${stamp}_entra_signinlogs.json"

  $rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8
  $rows | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $jsonPath -Encoding utf8

  Write-Log -Message "Wrote CSV:  $csvPath" -LogPath $logPath
  Write-Log -Message "Wrote JSON: $jsonPath" -LogPath $logPath

  if ($FilterLegacyAuth) {
    $legacy = $rows | Where-Object { Is-LegacyAuthRow -row $_ }
    $legacyPath = Join-Path $outFull "${stamp}_entra_signinlogs_legacy_auth.csv"
    $legacy | Export-Csv -LiteralPath $legacyPath -NoTypeInformation -Encoding utf8
    Write-Log -Message "Legacy auth heuristic matches: $($legacy.Count)" -LogPath $logPath
    Write-Log -Message "Wrote Legacy CSV: $legacyPath" -LogPath $logPath
  }

  $notes = @()
  $notes += "UtcStarted: $stamp"
  $notes += "StartUtc: $($StartUtc.ToUniversalTime().ToString('o'))"
  $notes += "EndUtc: $($EndUtc.ToUniversalTime().ToString('o'))"
  $notes += "Filter: $filter"
  $notes += "Status: $Status"
  $notes += "RawCount: $($raw.Count)"
  $notes += "RowCount: $($rows.Count)"
  if ($UserPrincipalName) { $notes += "UserPrincipalName: $UserPrincipalName" }
  if ($IpAddress) { $notes += "IpAddress: $IpAddress" }
  $notes += ""
  $notes += "RedactionChecklist:"
  $notes += "- Redact UPNs, IPs, tenant identifiers, correlation IDs as needed before commit."
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