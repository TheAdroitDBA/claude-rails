# install.ps1 -- link commands and register the plugin in one step
# Idempotent: safe to re-run. Backs up any existing real directory first.
#
# Requires PowerShell 7+. If invoked under Windows PowerShell 5.1, this
# bootstrap auto-installs pwsh via winget and relaunches the script.

# -- Bootstrap: ensure PowerShell 7+ ----------------------------------------
# This block is intentionally written to be 5.1-compatible (no ternary, no
# null-coalescing, no -AsHashtable, no pipeline chain operators).

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        $pwshExe = $pwshCmd.Source
    } else {
        $pwshExe = $null
    }

    if (-not $pwshExe) {
        Write-Host "PowerShell 7+ not found. Installing via winget..."

        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetCmd) {
            Write-Error "PowerShell 7+ is required, and winget is not available to install it. Install pwsh manually from https://aka.ms/powershell and re-run this script."
            exit 1
        }

        winget install --id Microsoft.PowerShell --silent --accept-source-agreements --accept-package-agreements
        $wingetExit = $LASTEXITCODE

        # winget does not refresh PATH in the current session; probe the
        # default install location before falling back to Get-Command.
        $candidate = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
        if (Test-Path $candidate) {
            $pwshExe = $candidate
        } else {
            $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
            if ($pwshCmd) { $pwshExe = $pwshCmd.Source }
        }

        if (-not $pwshExe) {
            Write-Error "winget install finished (exit code $wingetExit) but pwsh.exe was not found. Install PowerShell 7+ manually from https://aka.ms/powershell, then re-run this script."
            exit 1
        }

        Write-Host "PowerShell 7+ installed at $pwshExe"
    }

    Write-Host "Relaunching under pwsh..."
    & $pwshExe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}

# From here on we are guaranteed PowerShell 7+, so 7-only features
# (ConvertFrom-Json -AsHashtable, ternary, null-coalescing) are safe.

$RepoDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommandsSrc  = Join-Path $RepoDir "commands"
$CommandsDst  = Join-Path $env:USERPROFILE ".claude\commands"
$ClaudeDir    = Join-Path $env:USERPROFILE ".claude"
$SettingsFile = Join-Path $ClaudeDir "settings.json"

# -- Step 1: Link commands ---------------------------------------------------

# Verify source exists
if (-not (Test-Path $CommandsSrc)) {
    Write-Error "commands\ not found at $CommandsSrc"
    exit 1
}

# Ensure %USERPROFILE%\.claude exists
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}

# Handle existing destination
if (Test-Path $CommandsDst) {
    $item = Get-Item $CommandsDst -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $existing = $item.Target
        if ($existing -eq $CommandsSrc) {
            Write-Host "Commands: already linked -> $CommandsSrc"
        } else {
            Write-Host "Commands: relinking (was -> $existing)"
            Remove-Item $CommandsDst -Force
            New-Item -ItemType Junction -Path $CommandsDst -Target $CommandsSrc | Out-Null
            Write-Host "Commands: linked -> $CommandsSrc"
        }
    } else {
        $backup = "$CommandsDst.bak"
        Write-Host "Commands: backing up existing directory to $backup"
        Move-Item $CommandsDst $backup
        New-Item -ItemType Junction -Path $CommandsDst -Target $CommandsSrc | Out-Null
        Write-Host "Commands: linked -> $CommandsSrc"
    }
} else {
    New-Item -ItemType Junction -Path $CommandsDst -Target $CommandsSrc | Out-Null
    Write-Host "Commands: linked -> $CommandsSrc"
}

# -- Step 2: Register plugin -------------------------------------------------

# Read existing settings or start fresh
$settings = @{}
if (Test-Path $SettingsFile) {
    try {
        $raw = Get-Content $SettingsFile -Raw -ErrorAction Stop
        $settings = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    } catch {
        Write-Warning "Could not parse $SettingsFile -- backing up and starting fresh"
        Copy-Item $SettingsFile "$SettingsFile.bak" -Force
        $settings = @{}
    }
}

# Ensure top-level keys exist
if (-not $settings.ContainsKey("extraKnownMarketplaces")) {
    $settings["extraKnownMarketplaces"] = @{}
}
if (-not $settings.ContainsKey("enabledPlugins")) {
    $settings["enabledPlugins"] = @{}
}

# Check if already registered correctly
$needsUpdate = $false

$marketplaces = $settings["extraKnownMarketplaces"]
if ($marketplaces.ContainsKey("claude-rails")) {
    $entry = $marketplaces["claude-rails"]
    if ($entry -is [hashtable] -and $entry.ContainsKey("source")) {
        $srcInner = $entry["source"]
        # Normalize paths for comparison (forward slashes)
        $normalizedExisting = if ($srcInner -is [hashtable]) { ($srcInner["path"] -replace '\\', '/') } else { "" }
        $normalizedRepo = $RepoDir -replace '\\', '/'
        if ($normalizedExisting -eq $normalizedRepo -and $settings["enabledPlugins"]["claude-rails@claude-rails"] -eq $true) {
            Write-Host "Plugin:   already registered in $SettingsFile"
        } else {
            $needsUpdate = $true
        }
    } else {
        $needsUpdate = $true
    }
} else {
    $needsUpdate = $true
}

if ($needsUpdate) {
    # Use forward slashes in JSON path for cross-platform consistency
    $jsonPath = $RepoDir -replace '\\', '/'

    $settings["extraKnownMarketplaces"]["claude-rails"] = @{
        "source" = @{
            "source" = "directory"
            "path"   = $jsonPath
        }
    }
    $settings["enabledPlugins"]["claude-rails@claude-rails"] = $true

    $json = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $SettingsFile -Value $json -Encoding UTF8
    Write-Host "Plugin:   registered in $SettingsFile"
}

# -- Step 2.5: Stamp installed version --------------------------------------
# Writes the current claude-rails VERSION to a known location. Adopting repos
# read this to record the framework version they were last validated against.
# Consumed by /check-conformance and the session-start banner.

$VersionFile  = Join-Path $RepoDir "VERSION"
$VersionStamp = Join-Path $env:USERPROFILE ".claude\claude-rails-version"

if (Test-Path $VersionFile) {
    $CurrentVersion = (Get-Content $VersionFile -Raw).Trim()
    Set-Content -Path $VersionStamp -Value $CurrentVersion -Encoding UTF8 -NoNewline
    Write-Host "Version:  $CurrentVersion (stamped to $VersionStamp)"
} else {
    Write-Host "WARNING:  $VersionFile not found; version stamp not written."
}

# -- Step 3: Verification ----------------------------------------------------

Write-Host ""
Write-Host "Verification:"

$linkTarget = (Get-Item $CommandsDst -Force).Target
Write-Host "  Link target : $linkTarget"

Write-Host "  Commands    :"
Get-ChildItem "$CommandsDst\*.md" | ForEach-Object {
    Write-Host "    /$($_.BaseName)"
}

if (Test-Path $SettingsFile) {
    Write-Host "  Settings    : $SettingsFile (exists)"
} else {
    Write-Host "  Settings    : $SettingsFile (NOT FOUND)"
}

$hooksFile = Join-Path $RepoDir ".claude-plugin\hooks\hooks.json"
Write-Host "  Hooks file  : $hooksFile"
if (Test-Path $hooksFile) {
    Write-Host "                (exists)"
} else {
    Write-Host "                (NOT FOUND -- plugin may not fire hooks)"
}

if (Test-Path $VersionStamp) {
    $stamped = (Get-Content $VersionStamp -Raw).Trim()
    Write-Host "  Version     : $stamped (from $VersionStamp)"
}
