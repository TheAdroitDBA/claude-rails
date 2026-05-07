# install.ps1 -- link commands and register the plugin in one step
# Idempotent: safe to re-run. Backs up any existing real directory first.

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
