# require-feature-doc: enforce feature-doc presence for paths under a marker-scoped directory.
# Scans colocated *.feature.md files walking up from the edited file to the repo root.
# Three knobs: .claude/feature-doc-required marker, .claude/feature-doc-mode (off|warn|block),
# and ## Scope sections in feature docs. See memory/HOOK-INVENTORY.md.

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$ToolName = $payload.tool_name
$File = $payload.tool_input.file_path

# Only enforce on edit-class tools.
$EditTools = @('Edit', 'Write', 'MultiEdit', 'NotebookEdit')
if ($ToolName -and ($EditTools -notcontains $ToolName)) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

if (-not $File) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

# Walk upward from the file's dirname looking for .claude/feature-doc-required
$ScopeRoot = $null
$dir = Split-Path $File -Parent
while ($dir -and (Test-Path $dir)) {
    if (Test-Path (Join-Path $dir ".claude/feature-doc-required")) {
        $ScopeRoot = $dir
        break
    }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}

if (-not $ScopeRoot) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

# Read mode (default: block)
$ModeFile = Join-Path $ScopeRoot ".claude/feature-doc-mode"
$Mode = "block"
if (Test-Path $ModeFile) {
    $modeContent = (Get-Content $ModeFile -ErrorAction SilentlyContinue -Raw)
    if ($modeContent) { $Mode = $modeContent.Trim() }
    if (-not $Mode) { $Mode = "block" }
}

if ($Mode -eq "off") {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

# Skip patterns: docs, tests, configs, dotfiles. Always allow.
if ($File -match '[/\\]docs[/\\]|[Tt]est|[Ss]pec|\.(json|yml|yaml|toml|md)$|[/\\]\.') {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

# Helper: emit block/warn decision
function Invoke-ModeDecision {
    param([string]$Reason)
    if ($Mode -eq "warn") {
        [Console]::Error.WriteLine("WARNING: feature-doc enforcement in warn mode; would block: $Reason")
        Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        exit 0
    }
    @{hookSpecificOutput = @{hookEventName = "PreToolUse"; permissionDecision = "deny"; permissionDecisionReason = $Reason}} | ConvertTo-Json -Compress | Write-Output
    exit 0
}

# Find repo root
$RepoRoot = $null
$dir = $ScopeRoot
while ($dir -and (Test-Path $dir)) {
    if (Test-Path (Join-Path $dir ".git")) {
        $RepoRoot = $dir
        break
    }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}

if (-not $RepoRoot) {
    $RepoRoot = git -C $ScopeRoot rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) {
        Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        exit 0
    }
}

# --- Collect colocated *.feature.md walking from edited file's dir up to RepoRoot ---

$FeatureDocs = @()
$walkDir = Split-Path $File -Parent
$RepoRootNormalized = $RepoRoot -replace '\\', '/'
while ($walkDir) {
    $colocated = Get-ChildItem (Join-Path $walkDir "*.feature.md") -ErrorAction SilentlyContinue
    if ($colocated) {
        $FeatureDocs += $colocated
    }
    $walkDirNorm = $walkDir -replace '\\', '/'
    if ($walkDirNorm -eq $RepoRootNormalized) { break }
    $parent = Split-Path $walkDir -Parent
    if (-not $parent -or $parent -eq $walkDir) { break }
    $walkDir = $parent
}

# Read current-feature hint
$CurrentFeature = $null
$CurrentFeatureFile = Join-Path $ScopeRoot ".claude/current-feature"
if (Test-Path $CurrentFeatureFile) {
    $cf = Get-Content $CurrentFeatureFile -ErrorAction SilentlyContinue -Raw
    if ($cf) { $CurrentFeature = $cf.Trim() }
}

if ($FeatureDocs.Count -eq 0) {
    if ($CurrentFeature) {
        Invoke-ModeDecision "No feature doc found. Create $CurrentFeature.feature.md next to the code you are working on."
    } else {
        Invoke-ModeDecision "No feature doc found. Create a *.feature.md file next to the code you are editing."
    }
}

# Normalize paths for matching
$FileNormalized = $File -replace '\\', '/'
$RelPath = $FileNormalized
if ($FileNormalized.StartsWith($RepoRootNormalized + '/')) {
    $RelPath = $FileNormalized.Substring($RepoRootNormalized.Length + 1)
}

function Convert-GlobToRegex($glob) {
    $g = $glob -replace '\*\*', 'XDBLSTARX'
    $g = [regex]::Escape($g)
    $g = $g -replace 'XDBLSTARX', '.*'
    $g = $g -replace '\\\*', '[^/\\]*'
    $g = $g -replace '\\\?', '.'
    return "^$g$"
}

# --- Check coverage ---
# For each feature doc:
#   If it has ## Scope with entries -> check globs
#   If unscoped -> covers its own directory and everything below

$Matched = $false
foreach ($doc in $FeatureDocs) {
    $content = Get-Content $doc.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Extract ## Scope section
    $hasScope = $false
    $tokens = @()
    if ($content -match '(?ms)^## Scope\s*\r?\n(.*?)(?=^## |\z)') {
        $hasScope = $true
        $scopeText = $Matches[1]
        $scopeText = [regex]::Replace($scopeText, '(?s)<!--.*?-->', '')
        $tokens = $scopeText -split '[,\n\r]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }

    if ($hasScope -and $tokens.Count -gt 0) {
        # Explicit scope: check globs
        foreach ($glob in $tokens) {
            $regex = Convert-GlobToRegex $glob
            if ($RelPath -match $regex) {
                $Matched = $true
                break
            }
        }
        if ($Matched) { break }
    } else {
        # Unscoped: covers the doc's directory and all descendants
        $docDir = Split-Path $doc.FullName -Parent
        $docDirNorm = $docDir -replace '\\', '/'
        if ($FileNormalized.StartsWith($docDirNorm + '/') -or $FileNormalized -eq $docDirNorm) {
            $Matched = $true
            break
        }
    }
}

if ($Matched) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

Invoke-ModeDecision "Edited file ($RelPath) is not covered by any feature doc. Create a *.feature.md next to the file, or add its path to a feature doc's ## Scope section."
