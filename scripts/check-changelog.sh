#!/usr/bin/env bash
# check-changelog.sh -- verify CHANGELOG.md was updated when a PR touches
# user-visible framework surfaces.
#
# Per A2 in the auto-doc-system feature: any PR to claude-rails that
# changes conventions/, commands/, templates/, or .claude-plugin/hooks/
# must include a CHANGELOG.md entry. This script enforces that.
#
# Usage:
#   bash scripts/check-changelog.sh            # check staged changes
#   bash scripts/check-changelog.sh --range A..B   # check range of commits
#
# Exit codes:
#   0 -- no surface changes, or surface changes accompanied by CHANGELOG update
#   1 -- surface changes without CHANGELOG update
#   2 -- usage error

set -euo pipefail

SURFACE_PATHS_REGEX='^(conventions/|commands/|templates/|\.claude-plugin/hooks/)'
CHANGELOG_PATH='CHANGELOG.md'

# Determine the diff source.
if [ "$#" -eq 0 ]; then
  # Check staged changes (pre-commit context).
  DIFF_CMD="git diff --cached --name-only"
elif [ "$#" -eq 2 ] && [ "$1" = "--range" ]; then
  DIFF_CMD="git diff --name-only $2"
else
  echo "Usage: $0 [--range <ref>..<ref>]" >&2
  exit 2
fi

CHANGED="$($DIFF_CMD)"

# Files that touch the framework's user-visible surface.
SURFACE_TOUCHED="$(echo "$CHANGED" | grep -E "$SURFACE_PATHS_REGEX" || true)"

if [ -z "$SURFACE_TOUCHED" ]; then
  # No surface changes; CHANGELOG update not required.
  exit 0
fi

# Did CHANGELOG.md also change?
CHANGELOG_TOUCHED="$(echo "$CHANGED" | grep -Fx "$CHANGELOG_PATH" || true)"

if [ -n "$CHANGELOG_TOUCHED" ]; then
  exit 0
fi

echo "[FAIL] CHANGELOG.md was not updated, but the following surface files changed:"
echo "$SURFACE_TOUCHED" | sed 's/^/  /'
echo ""
echo "Per conventions/auto-doc.md (Versioning and Releases): every PR that"
echo "changes conventions/, commands/, templates/, or .claude-plugin/hooks/"
echo "must include a CHANGELOG.md entry under [Unreleased] classifying the"
echo "change (Added / Changed / Deprecated / Removed / Fixed / Security)"
echo "and labelling it MAJOR / MINOR / PATCH per the breaking-change table."
echo ""
echo "Add a CHANGELOG.md entry, stage it, and re-run."
exit 1
