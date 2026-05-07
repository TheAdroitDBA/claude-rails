# stale-feature-check: warn at Stop time if feature docs are missing Success
# Criteria or ## Status sections. Scans colocated *.feature.md under the repo.
# Gated on .claude/feature-doc-required. FAILS LOUDLY on internal errors: any
# missing prerequisite or unexpected state is reported to stderr so a silent
# stop-hook does not hide broken checks from the user.

# Prerequisite checks -------------------------------------------------------

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine("stale-feature-check: 'git' not on PATH; cannot determine repo root.")
    exit 1
}

# Repo root -----------------------------------------------------------------

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) {
    # Not inside a git repo. Legitimate "not applicable"; stay silent.
    exit 0
}

# Opt-in gate ---------------------------------------------------------------

if (-not (Test-Path (Join-Path $RepoRoot ".claude/feature-doc-required"))) {
    # No marker; repo hasn't opted into framework enforcement. Stay silent.
    exit 0
}

# Scan ----------------------------------------------------------------------

$Issues = @()
$DocCount = 0

function Test-FeatureDoc {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) {
        [Console]::Error.WriteLine("stale-feature-check: expected file disappeared mid-scan: $Path")
        return
    }
    try {
        $Content = Get-Content $Path -Raw -ErrorAction Stop
    } catch {
        [Console]::Error.WriteLine("stale-feature-check: failed to read $Path -- $($_.Exception.Message)")
        return
    }
    if (-not $Content) { return }
    if ($Content -notmatch '(?i)Success Criteria') {
        $script:Issues += "  - ${Label}: missing Success Criteria section"
    }
    if ($Content -notmatch '(?i)## Status') {
        $script:Issues += "  - ${Label}: missing Status section"
    }
}

# Do NOT suppress Get-ChildItem errors -- surface them on stderr.
try {
    Get-ChildItem $RepoRoot -Filter "*.feature.md" -Recurse -ErrorAction Continue |
        Where-Object { $_.FullName -notmatch '[/\\]\.git[/\\]|[/\\]node_modules[/\\]' } |
        ForEach-Object {
            $script:DocCount++
            $label = $_.FullName -replace [regex]::Escape($RepoRoot + [IO.Path]::DirectorySeparatorChar), ''
            $label = $label -replace '\\', '/'
            Test-FeatureDoc $_.FullName $label
        }
} catch {
    [Console]::Error.WriteLine("stale-feature-check: scan errored -- $($_.Exception.Message)")
}

# Report --------------------------------------------------------------------

if ($DocCount -eq 0) {
    [Console]::Error.WriteLine("stale-feature-check: marker .claude/feature-doc-required is present but no *.feature.md files found in $RepoRoot. Either create a feature doc or remove the marker.")
}

if ($Issues.Count -gt 0) {
    Write-Output "Feature doc issues:"
    $Issues | ForEach-Object { Write-Output $_ }
}
