#!/bin/bash
# stale-feature-check: warn at Stop time if feature docs are missing Success
# Criteria or ## Status sections. Scans colocated *.feature.md under the repo.
# Gated on .claude/feature-doc-required. FAILS LOUDLY on internal errors: any
# missing prerequisite (git, find, grep) or unexpected state is reported to
# stderr so a silent stop-hook does not hide broken checks from the user.

# Prerequisite checks -------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
    echo "stale-feature-check: 'git' not on PATH; cannot determine repo root." >&2
    exit 1
fi
if ! command -v find >/dev/null 2>&1; then
    echo "stale-feature-check: 'find' not on PATH; cannot scan for feature docs." >&2
    exit 1
fi
if ! command -v grep >/dev/null 2>&1; then
    echo "stale-feature-check: 'grep' not on PATH; cannot inspect feature docs." >&2
    exit 1
fi

# Repo root -----------------------------------------------------------------

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
    # Not inside a git repo. Legitimate "not applicable"; stay silent.
    exit 0
fi

# Opt-in gate ---------------------------------------------------------------

if [ ! -f "$REPO_ROOT/.claude/feature-doc-required" ]; then
    # No marker; repo hasn't opted into framework enforcement. Stay silent.
    exit 0
fi

# Scan ----------------------------------------------------------------------

ISSUES=""
DOC_COUNT=0

check_doc() {
    local doc="$1"
    local label="$2"
    if [ ! -f "$doc" ]; then
        echo "stale-feature-check: expected file disappeared mid-scan: $doc" >&2
        return
    fi
    if ! grep -qi "Success Criteria" "$doc"; then
        ISSUES="$ISSUES
  - $label: missing Success Criteria section"
    fi
    if ! grep -qi "## Status" "$doc"; then
        ISSUES="$ISSUES
  - $label: missing Status section"
    fi
}

# Do NOT suppress find's stderr -- if directories are unreadable, user sees it.
while IFS= read -r -d '' doc; do
    DOC_COUNT=$((DOC_COUNT + 1))
    label="${doc#$REPO_ROOT/}"
    check_doc "$doc" "$label"
done < <(find "$REPO_ROOT" -name '*.feature.md' -not -path '*/.git/*' -not -path '*/node_modules/*' -print0)

# Report --------------------------------------------------------------------

if [ "$DOC_COUNT" -eq 0 ]; then
    echo "stale-feature-check: marker .claude/feature-doc-required is present but no *.feature.md files found in $REPO_ROOT. Either create a feature doc or remove the marker." >&2
fi

if [ -n "$ISSUES" ]; then
    echo "Feature doc issues:$ISSUES"
fi

exit 0
