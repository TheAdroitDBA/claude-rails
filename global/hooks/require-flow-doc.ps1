# require-flow-doc: for feature docs that declare user-visible touchpoints
# (## Surface section present AND non-trivial), require a *.flow.md to exist
# within the feature's scope. Pair to require-feature-doc.ps1.

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$ToolName = $payload.tool_name
$File = $payload.tool_input.file_path

$EditTools = @('Edit', 'Write', 'MultiEdit', 'NotebookEdit')
if ($ToolName -and ($EditTools -notcontains $ToolName)) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}
if (-not $File) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

$ScopeRoot = $null
$dir = Split-Path $File -Parent
while ($dir -and (Test-Path $dir)) {
    if (Test-Path (Join-Path $dir ".claude/feature-doc-required")) {
        $ScopeRoot = $dir; break
    }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $ScopeRoot) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

$Mode = "block"
$ModeFile = Join-Path $ScopeRoot ".claude/feature-doc-mode"
if (Test-Path $ModeFile) {
    $modeContent = (Get-Content $ModeFile -ErrorAction SilentlyContinue -Raw)
    if ($modeContent) { $Mode = $modeContent.Trim() }
    if (-not $Mode) { $Mode = "block" }
}
if ($Mode -eq "off") {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

if ($File -match '[/\\]docs[/\\]|[Tt]est|[Ss]pec|\.(json|yml|yaml|toml|md)$|[/\\]\.') {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

function Invoke-ModeDecision {
    param([string]$Reason)
    if ($Mode -eq "warn") {
        [Console]::Error.WriteLine("WARNING: flow-doc enforcement in warn mode; would block: $Reason")
        Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        exit 0
    }
    @{hookSpecificOutput = @{hookEventName = "PreToolUse"; permissionDecision = "deny"; permissionDecisionReason = $Reason}} | ConvertTo-Json -Compress | Write-Output
    exit 0
}

$RepoRoot = $null
$dir = $ScopeRoot
while ($dir -and (Test-Path $dir)) {
    if (Test-Path (Join-Path $dir ".git")) { $RepoRoot = $dir; break }
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

function Convert-GlobToRegex($glob) {
    $g = $glob -replace '\*\*', 'XDBLSTARX'
    $g = [regex]::Escape($g)
    $g = $g -replace 'XDBLSTARX', '.*'
    $g = $g -replace '\\\*', '[^/\\]*'
    $g = $g -replace '\\\?', '.'
    return "^$g$"
}

function Extract-Section($content, $name) {
    if ($content -match "(?ms)^## $name\s*\r?\n(.*?)(?=^## |\z)") {
        return $Matches[1]
    }
    return ""
}

function Surface-IsMeaningful($content) {
    $trimmed = ($content -replace '\s', '').ToLower()
    if (-not $trimmed) { return $false }
    if ($trimmed -eq 'none' -or $trimmed -eq 'internal' -or $trimmed -eq 'none.' -or $trimmed -eq 'internal.') { return $false }
    return $true
}

$RepoRootNormalized = $RepoRoot -replace '\\', '/'
$FileNormalized = $File -replace '\\', '/'
$RelPath = $FileNormalized
if ($FileNormalized.StartsWith($RepoRootNormalized + '/')) {
    $RelPath = $FileNormalized.Substring($RepoRootNormalized.Length + 1)
}

# Collect feature docs: colocated walk + legacy docs/features
$FeatureDocs = @()
$walkDir = Split-Path $File -Parent
while ($walkDir) {
    $colocated = Get-ChildItem (Join-Path $walkDir "*.feature.md") -ErrorAction SilentlyContinue
    if ($colocated) { $FeatureDocs += $colocated }
    $walkDirNorm = $walkDir -replace '\\', '/'
    if ($walkDirNorm -eq $RepoRootNormalized) { break }
    $parent = Split-Path $walkDir -Parent
    if (-not $parent -or $parent -eq $walkDir) { break }
    $walkDir = $parent
}
$LegacyDir = Join-Path $RepoRoot "docs/features"
if (Test-Path $LegacyDir) {
    $legacy = Get-ChildItem (Join-Path $LegacyDir "*.md") -ErrorAction SilentlyContinue
    if ($legacy) { $FeatureDocs += $legacy }
}

if ($FeatureDocs.Count -eq 0) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

# Pre-collect repo flow docs (relative paths).
$AllFlowDocs = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.flow.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[/\\]\.git[/\\]' } |
    ForEach-Object {
        ($_.FullName -replace '\\', '/').Substring($RepoRootNormalized.Length + 1)
    }

function Any-FlowMatchingGlob($glob) {
    $regex = Convert-GlobToRegex $glob
    foreach ($p in $AllFlowDocs) {
        if ($p -match $regex) { return $true }
    }
    return $false
}

function Any-FlowUnderDir($dir) {
    $dirNorm = ($dir -replace '\\', '/')
    $relDir = $dirNorm
    if ($dirNorm.StartsWith($RepoRootNormalized + '/')) {
        $relDir = $dirNorm.Substring($RepoRootNormalized.Length + 1)
    } elseif ($dirNorm -eq $RepoRootNormalized) {
        $relDir = ""
    }
    foreach ($p in $AllFlowDocs) {
        if ($relDir -eq "" -or $p.StartsWith($relDir + '/')) { return $true }
        if ($p -eq ($relDir + '/' + (Split-Path $p -Leaf))) { return $true }
    }
    return $false
}

$CoveringDocs = @()
foreach ($doc in $FeatureDocs) {
    $content = Get-Content $doc.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $scope = Extract-Section $content "Scope"
    $scopeClean = $scope -replace '(?s)<!--.*?-->', ''
    $tokens = $scopeClean -split '[,\n\r]' | ForEach-Object {
        ($_ -replace '^\s*-\s*', '').Trim() -replace '^`|`$', ''
    } | Where-Object { $_ }

    $covered = $false
    if ($tokens.Count -gt 0) {
        foreach ($glob in $tokens) {
            $regex = Convert-GlobToRegex $glob
            if ($RelPath -match $regex) { $covered = $true; break }
        }
    } else {
        $docDir = Split-Path $doc.FullName -Parent
        $docDirNorm = $docDir -replace '\\', '/'
        if ($FileNormalized.StartsWith($docDirNorm + '/') -or $FileNormalized -eq $docDirNorm) {
            $covered = $true
        }
    }
    if ($covered) { $CoveringDocs += $doc }
}

if ($CoveringDocs.Count -eq 0) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

function Deviation-CoversFlowDoc($content) {
    $dev = Extract-Section $content "Deviation from conventions"
    if (-not $dev) { return $false }
    # Bullet with convention-name containing "flow" + colon + rationale
    if ($dev -match '(?m)^\s*-\s*[a-zA-Z0-9._-]*flow[a-zA-Z0-9._-]*:\s*\S+') { return $true }
    return $false
}

$MissingFlowDocs = @()
foreach ($doc in $CoveringDocs) {
    $content = Get-Content $doc.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $surface = Extract-Section $content "Surface"
    if (-not (Surface-IsMeaningful $surface)) { continue }

    if (Deviation-CoversFlowDoc $content) { continue }

    $scope = Extract-Section $content "Scope"
    $scopeClean = $scope -replace '(?s)<!--.*?-->', ''
    $tokens = $scopeClean -split '[,\n\r]' | ForEach-Object {
        ($_ -replace '^\s*-\s*', '').Trim() -replace '^`|`$', ''
    } | Where-Object { $_ }

    $hasFlow = $false
    if ($tokens.Count -gt 0) {
        foreach ($glob in $tokens) {
            if (Any-FlowMatchingGlob $glob) { $hasFlow = $true; break }
        }
    } else {
        $docDir = Split-Path $doc.FullName -Parent
        if (Any-FlowUnderDir $docDir) { $hasFlow = $true }
    }

    if (-not $hasFlow) { $MissingFlowDocs += $doc }
}

if ($MissingFlowDocs.Count -eq 0) {
    Write-Output '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
}

$first = $MissingFlowDocs[0]
$firstFull = $first.FullName -replace '\\', '/'
$firstRel = $firstFull
if ($firstFull.StartsWith($RepoRootNormalized + '/')) {
    $firstRel = $firstFull.Substring($RepoRootNormalized.Length + 1)
}
$reason = "Feature doc '$firstRel' declares a ## Surface (user-visible touchpoints) but no sibling *.flow.md exists within its Scope. Flow docs catalogue entry points, step tables, and named failure modes. Create a *.flow.md colocated with the primary entry-point code before editing source, or declare an explicit '## Deviation from conventions' entry in the feature doc with a one-line rationale."
Invoke-ModeDecision $reason
