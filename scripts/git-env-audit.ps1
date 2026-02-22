# git-env-audit.ps1
# Broad environment audit: system + PowerShell + network + Git + optional repo details (only if inside a repo)

[CmdletBinding()]
param(
  [string]$OutDir = ".\_audit",
  [string]$OutFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Stop Git pager from hijacking the terminal
$env:GIT_PAGER = "cat"
$env:PAGER     = "cat"

function Ensure-Dir {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-Section {
  param(
    [System.IO.StreamWriter]$Writer,
    [string]$Title
  )
  $Writer.WriteLine("")
  $Writer.WriteLine(("=" * 90))
  $Writer.WriteLine($Title)
  $Writer.WriteLine(("=" * 90))
}

function Write-CommandHeader {
  param(
    [System.IO.StreamWriter]$Writer,
    [string]$CmdText
  )
  $Writer.WriteLine("")
  $Writer.WriteLine(">>> $CmdText")
}

function Write-Exit {
  param(
    [System.IO.StreamWriter]$Writer,
    [int]$ExitCode
  )
  $Writer.WriteLine("<<< exitcode: $ExitCode")
}

function Run-Exe {
  param(
    [System.IO.StreamWriter]$Writer,
    [string]$Exe,
    [string[]]$ArgList
  )

  $cmdText = if ($ArgList -and $ArgList.Count -gt 0) { "$Exe $($ArgList -join ' ')" } else { $Exe }
  Write-CommandHeader -Writer $Writer -CmdText $cmdText

  $exitCode = 0
  $outText = ""

  try {
    $raw = & $Exe @ArgList 2>&1
    $exitCode = $LASTEXITCODE
    $outText = ($raw | Out-String).TrimEnd()
  }
  catch {
    $exitCode = 1
    $outText = ($_ | Out-String).TrimEnd()
  }

  if ([string]::IsNullOrWhiteSpace($outText)) {
    $Writer.WriteLine("(no output)")
  } else {
    $Writer.WriteLine($outText)
  }

  Write-Exit -Writer $Writer -ExitCode $exitCode
  return $exitCode
}

function Run-PS {
  param(
    [System.IO.StreamWriter]$Writer,
    [string]$Label,
    [scriptblock]$Block
  )

  Write-CommandHeader -Writer $Writer -CmdText $Label

  $exitCode = 0
  $outText = ""

  try {
    $raw = & $Block 2>&1
    $outText = ($raw | Out-String).TrimEnd()
  }
  catch {
    $exitCode = 1
    $outText = ($_ | Out-String).TrimEnd()
  }

  if ([string]::IsNullOrWhiteSpace($outText)) {
    $Writer.WriteLine("(no output)")
  } else {
    $Writer.WriteLine($outText)
  }

  Write-Exit -Writer $Writer -ExitCode $exitCode
  return $exitCode
}

# Resolve output directory and file relative to current working directory by default
if (-not [System.IO.Path]::IsPathRooted($OutDir)) {
  $OutDir = Join-Path (Get-Location).Path $OutDir
}
Ensure-Dir -Path $OutDir

if ([string]::IsNullOrWhiteSpace($OutFile)) {
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $OutFile = Join-Path $OutDir "env-audit-$ts.txt"
} elseif (-not [System.IO.Path]::IsPathRooted($OutFile)) {
  $OutFile = Join-Path $OutDir $OutFile
}

$writer = $null
try {
  $writer = New-Object System.IO.StreamWriter($OutFile, $false, (New-Object System.Text.UTF8Encoding($false)))

  Write-Section -Writer $writer -Title "CONTEXT"
  Run-PS  -Writer $writer -Label "pwd" -Block { Get-Location | Format-List * }
  Run-PS  -Writer $writer -Label "Get-Date" -Block { Get-Date | Format-List * }
  Run-Exe -Writer $writer -Exe "whoami.exe"   -ArgList @()
  Run-Exe -Writer $writer -Exe "hostname.exe" -ArgList @()

  Write-Section -Writer $writer -Title "POWERSHELL"
  Run-PS -Writer $writer -Label '$PSVersionTable' -Block { $PSVersionTable | Format-List * }
  Run-PS -Writer $writer -Label "Get-ExecutionPolicy -List" -Block { Get-ExecutionPolicy -List | Format-Table -AutoSize }
  Run-PS -Writer $writer -Label '$env:PATH' -Block { $env:PATH }

  Write-Section -Writer $writer -Title "SYSTEM"
  Run-PS -Writer $writer -Label "Get-ComputerInfo (selected)" -Block {
    Get-ComputerInfo | Select-Object OsName,OsVersion,OsBuildNumber,WindowsVersion,CsName,CsManufacturer,CsModel,CsTotalPhysicalMemory,OsLastBootUpTime | Format-List *
  }
  Run-Exe -Writer $writer -Exe "systeminfo.exe" -ArgList @()

  Write-Section -Writer $writer -Title "NETWORK (BASIC)"
  Run-Exe -Writer $writer -Exe "ipconfig.exe" -ArgList @("/all")
  Run-PS  -Writer $writer -Label "route print" -Block { & route print 2>&1 | Out-String }
  Run-PS  -Writer $writer -Label "netsh winhttp show proxy" -Block { & netsh winhttp show proxy 2>&1 | Out-String }
  Run-PS  -Writer $writer -Label "Test-NetConnection github.com -Port 443" -Block { Test-NetConnection github.com -Port 443 | Format-List * }
  Run-PS  -Writer $writer -Label "Resolve-DnsName github.com" -Block { Resolve-DnsName github.com -ErrorAction SilentlyContinue | Format-Table -AutoSize }

  # Tool presence checks
  $hasGit = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
  $hasGh  = $null -ne (Get-Command gh  -ErrorAction SilentlyContinue)

  Write-Section -Writer $writer -Title "GIT (GLOBAL)"
  if (-not $hasGit) {
    $writer.WriteLine("git not found in PATH")
  } else {
    Run-Exe -Writer $writer -Exe "git" -ArgList @("--version")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","--list","--show-origin")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","--global","--list","--show-origin")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","--system","--list","--show-origin")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","user.name")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","user.email")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","--global","credential.helper")
    Run-Exe -Writer $writer -Exe "git" -ArgList @("config","--show-origin","credential.helper")
  }

  Write-Section -Writer $writer -Title "GITHUB CLI (OPTIONAL)"
  if (-not $hasGh) {
    $writer.WriteLine("gh not found in PATH")
  } else {
    Run-Exe -Writer $writer -Exe "gh" -ArgList @("--version")
    Run-Exe -Writer $writer -Exe "gh" -ArgList @("auth","status")
  }

  Write-Section -Writer $writer -Title "REPO DETAILS (ONLY IF INSIDE A WORK TREE)"
  if (-not $hasGit) {
    $writer.WriteLine("Skipping repo checks because git is missing.")
  } else {
    $insideOut = & git rev-parse --is-inside-work-tree 2>$null
    $inside = ($LASTEXITCODE -eq 0 -and $insideOut -and $insideOut.ToString().Trim().ToLower() -eq "true")

    if (-not $inside) {
      $writer.WriteLine("Not inside a Git work tree. Repo-specific commands skipped.")
    } else {
      Run-Exe -Writer $writer -Exe "git" -ArgList @("rev-parse","--show-toplevel")
      Run-Exe -Writer $writer -Exe "git" -ArgList @("remote","-v")
      Run-Exe -Writer $writer -Exe "git" -ArgList @("status","-sb")
      Run-Exe -Writer $writer -Exe "git" -ArgList @("describe","--tags","--always","--dirty")

      Run-Exe -Writer $writer -Exe "git" -ArgList @("branch","-vv")
      Run-Exe -Writer $writer -Exe "git" -ArgList @("show","-s","--format=fuller","HEAD")
      Run-Exe -Writer $writer -Exe "git" -ArgList @("log","--oneline","--decorate","--graph","-n","30")
      Run-Exe -Writer $writer -Exe "git" -ArgList @("reflog","-n","30")

      & git show-ref --verify --quiet "refs/remotes/origin/main" 2>$null
      $hasOriginMain = ($LASTEXITCODE -eq 0)

      if ($hasOriginMain) {
        Run-Exe -Writer $writer -Exe "git" -ArgList @("rev-list","--left-right","--count","origin/main...HEAD")
        Run-Exe -Writer $writer -Exe "git" -ArgList @("diff","--stat")
        Run-Exe -Writer $writer -Exe "git" -ArgList @("diff","--name-status","origin/main..HEAD")
      } else {
        $writer.WriteLine("origin/main not found, skipping origin comparisons.")
      }

      Run-PS -Writer $writer -Label "git ls-files | Measure-Object" -Block { git ls-files | Measure-Object | Format-List * }

      # Fix: CaseSensitive so uppercase H does not match
      Run-PS -Writer $writer -Label 'git ls-files -v | Select-String -Pattern "^[a-z]" -CaseSensitive | Select-Object -First 50' -Block {
        git ls-files -v | Select-String -Pattern "^[a-z]" -CaseSensitive | Select-Object -First 50
      }

      Run-Exe -Writer $writer -Exe "git" -ArgList @("check-attr","-a","--",".")

      Run-PS -Writer $writer -Label "git ls-files --stage | Select-Object -First 20" -Block {
        git ls-files --stage | Select-Object -First 20
      }

      # Fix: Always read from repo root via git rev-parse --show-toplevel
      Run-PS -Writer $writer -Label "Get-Content .gitignore (repo root, if present)" -Block {
        $path = Join-Path (git rev-parse --show-toplevel) ".gitignore"
        if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path } else { "not present: $path" }
      }

      Run-PS -Writer $writer -Label "Get-Content .gitattributes (repo root, if present)" -Block {
        $path = Join-Path (git rev-parse --show-toplevel) ".gitattributes"
        if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path } else { "not present: $path" }
      }
    }
  }

  $writer.WriteLine("")
  $writer.WriteLine("DONE")
}
finally {
  if ($writer) {
    $writer.Flush()
    $writer.Close()
  }
}

Write-Host "Wrote audit to: $OutFile"