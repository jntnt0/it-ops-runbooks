<#
.SYNOPSIS
  Script template for IT Ops Runbooks evidence collection and safe remediation.

.DESCRIPTION
  Use this template for every new script in /scripts.
  Enforces:
  - prerequisites documentation
  - least privilege notes
  - safe logging (no secrets)
  - deterministic evidence outputs under /evidence
  - optional -WhatIf for any state-changing operations

.TAG
  A

.NOTES
  Repo: IT Ops Runbooks
  Folder: /scripts
  Author: <REPLACE>
  LastUpdatedUtc: 2026-02-12

  SAFETY RULES
  - Never write secrets to console or log files (tokens, passwords, client secrets, full headers).
  - Prefer read-only operations; clearly label any state-changing behavior.
  - Log counts and summaries; if you must write objects, write sanitized output only.

#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
  # Required output directory (ideally under /evidence/<scenario>/<case>/scripts)
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$OutDir,

  # Optional UTC time window (common for log exports)
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [datetime]$StartUtc,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [datetime]$EndUtc,

  # Optional identifier inputs
  [Parameter(Mandatory = $false)]
  [string]$UserPrincipalName,

  [Parameter(Mandatory = $false)]
  [string]$IpAddress,

  # Behavior toggles
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
  $line = "$ts `t $Message"
  Add-Content -LiteralPath $LogPath -Value $line
}

function Assert-Prerequisites {
  <#
    Add checks here:
    - PowerShell version
    - Required modules
    - Network connectivity
    - Tenant/environment expectations
  #>

  # Example: PS version
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7+ is recommended. Current: $($PSVersionTable.PSVersion)"
  }

  # Example: module existence check (comment in when you pick a module)
  # if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
  #   throw "Missing module Microsoft.Graph. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
  # }
}

function Get-SafeSummary {
  <#
    Build a small summary object that is safe to write to logs.
    Never include secrets or full object dumps.
  #>
  param(
    [int]$ItemCount = 0,
    [string]$Notes = ''
  )

  [pscustomobject]@{
    UtcCompleted = (Get-Date).ToUniversalTime().ToString('o')
    ItemCount    = $ItemCount
    Notes        = $Notes
  }
}

try {
  $stamp = Get-UtcStamp

  # Normalize OutDir to full path
  $outFull = (Resolve-Path -LiteralPath $OutDir -ErrorAction SilentlyContinue)
  if (-not $outFull) {
    # If it doesn't exist yet, create it then resolve again
    New-DirectoryIfMissing -Path $OutDir
    $outFull = Resolve-Path -LiteralPath $OutDir
  }
  $outFull = $outFull.Path

  # Enforce deterministic output names
  $logPath   = Join-Path $outFull "${stamp}_script.log"
  $notesPath = Join-Path $outFull "${stamp}_notes.txt"

  # If we might overwrite, guard it
  if (-not $Force) {
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
      throw "Output already exists: $logPath. Use -Force or choose a different -OutDir."
    }
  }

  New-DirectoryIfMissing -Path $outFull

  # Start transcript (best effort)
  try {
    Start-Transcript -LiteralPath $logPath -Append | Out-Null
  } catch {
    # Fallback to manual logging if transcript fails in some hosts
    New-Item -ItemType File -Path $logPath -Force | Out-Null
    Write-Log -Message "Transcript unavailable in this host. Using manual logging." -LogPath $logPath
  }

  Write-Log -Message "Script started." -LogPath $logPath
  Write-Log -Message "OutDir: $outFull" -LogPath $logPath

  if ($PSBoundParameters.ContainsKey('StartUtc')) {
    Write-Log -Message "StartUtc: $($StartUtc.ToUniversalTime().ToString('o'))" -LogPath $logPath
  }
  if ($PSBoundParameters.ContainsKey('EndUtc')) {
    Write-Log -Message "EndUtc: $($EndUtc.ToUniversalTime().ToString('o'))" -LogPath $logPath
  }
  if ($UserPrincipalName) {
    Write-Log -Message "UserPrincipalName: $UserPrincipalName" -LogPath $logPath
  }
  if ($IpAddress) {
    Write-Log -Message "IpAddress: $IpAddress" -LogPath $logPath
  }

  Assert-Prerequisites

  <#
    AUTHENTICATION (example skeleton)
    - Prefer delegated auth for labs.
    - Use minimal scopes.
    - Do not log tokens.

    Example (commented out):
      $scopes = @('AuditLog.Read.All','Directory.Read.All')
      Connect-MgGraph -Scopes $scopes | Out-Null
  #>

  <#
    MAIN LOGIC GOES HERE

    Read-only evidence script example pattern:
    - query data
    - sanitize if necessary
    - write CSV/JSON to OutDir
    - write counts to notes

    State-changing scripts:
    - MUST wrap changes in ShouldProcess
    - MUST support -WhatIf automatically via CmdletBinding
    - MUST write rollback guidance to notes
  #>

  $items = @() # Replace with results

  # Example: write empty placeholder export file
  $exportPath = Join-Path $outFull "${stamp}_export_placeholder.json"
  $items | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $exportPath -Encoding utf8

  $summary = Get-SafeSummary -ItemCount $items.Count -Notes "Template run. Replace placeholder export with real data collection."

  $summaryText = @(
    "UtcStarted: $stamp"
    "UtcCompleted: $($summary.UtcCompleted)"
    "ItemCount: $($summary.ItemCount)"
    "Notes: $($summary.Notes)"
    ""
    "RollbackNotes:"
    "- If this script makes changes, document exact changes and provide reversal steps here."
  ) -join [Environment]::NewLine

  $summaryText | Out-File -LiteralPath $notesPath -Encoding utf8

  Write-Log -Message "Wrote export: $exportPath" -LogPath $logPath
  Write-Log -Message "Wrote notes:  $notesPath" -LogPath $logPath
  Write-Log -Message "Script completed successfully." -LogPath $logPath
}
catch {
  $msg = $_.Exception.Message
  try {
    if ($logPath) {
      Write-Log -Message "ERROR: $msg" -LogPath $logPath
    }
  } catch {
    # If logging fails, fall back to stderr only
  }
  Write-Error $msg
  exit 1
}
finally {
  try { Disconnect-MgGraph | Out-Null } catch { }
  try { Stop-Transcript | Out-Null } catch { }
}