# link-commands.ps1 -- junction claude-rails\commands into %USERPROFILE%\.claude\commands
# Idempotent: safe to re-run. Backs up any existing real directory first.

$RepoDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommandsSrc = Join-Path $RepoDir "commands"
$CommandsDst = Join-Path $env:USERPROFILE ".claude\commands"

# Verify source exists
if (-not (Test-Path $CommandsSrc)) {
    Write-Error "commands\ not found at $CommandsSrc"
    exit 1
}

# Ensure %USERPROFILE%\.claude exists
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}

# Handle existing destination
if (Test-Path $CommandsDst) {
    $item = Get-Item $CommandsDst -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $existing = $item.Target
        if ($existing -eq $CommandsSrc) {
            Write-Host "Already linked: $CommandsDst -> $CommandsSrc"
        } else {
            Write-Host "Relinking: was -> $existing"
            Remove-Item $CommandsDst -Force
            New-Item -ItemType Junction -Path $CommandsDst -Target $CommandsSrc | Out-Null
            Write-Host "Linked: $CommandsDst -> $CommandsSrc"
        }
    } else {
        $backup = "$CommandsDst.bak"
        Write-Host "Backing up existing directory to $backup"
        Move-Item $CommandsDst $backup
        New-Item -ItemType Junction -Path $CommandsDst -Target $CommandsSrc | Out-Null
        Write-Host "Linked: $CommandsDst -> $CommandsSrc"
    }
} else {
    New-Item -ItemType Junction -Path $CommandsDst -Target $CommandsSrc | Out-Null
    Write-Host "Linked: $CommandsDst -> $CommandsSrc"
}

# Verify
Write-Host ""
Write-Host "Verification:"
$linkTarget = (Get-Item $CommandsDst -Force).Target
Write-Host "  Link target : $linkTarget"
Write-Host "  Commands    :"
Get-ChildItem "$CommandsDst\*.md" | ForEach-Object {
    Write-Host "    /$($_.BaseName)"
}
