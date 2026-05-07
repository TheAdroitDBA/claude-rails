---
description: Audit all project documentation for staleness, duplication, orphaned files, broken references, and sprawl. Works across any project. Recommends delete/merge/move/update actions and asks before acting.
---

# Documentation Audit

Systematic audit of all documentation in the current project. Finds sprawl, staleness, duplication, and broken references. Asks before changing anything.

## Step 1: Identify Project and Discover All Docs

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
echo "Project: $(basename "$PROJECT_ROOT")"
echo "Root: $PROJECT_ROOT"
echo ""

echo "=== All Markdown Files ==="
find "$PROJECT_ROOT" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/vendor/*" -not -path "*/.build/*" -not -path "*/Pods/*" | sort

echo ""
echo "=== Documentation Directories ==="
for dir in docs memory .claude/agents .claude/rules; do
  if [ -d "$PROJECT_ROOT/$dir" ]; then
    COUNT=$(find "$PROJECT_ROOT/$dir" -name "*.md" | wc -l | tr -d ' ')
    echo "[EXISTS] $dir/ ($COUNT files)"
  fi
done

echo ""
echo "=== Key Files ==="
[ -f "$PROJECT_ROOT/CLAUDE.md" ] && echo "[EXISTS] CLAUDE.md ($(wc -l < "$PROJECT_ROOT/CLAUDE.md") lines)" || echo "[MISSING] CLAUDE.md"
[ -f "$PROJECT_ROOT/README.md" ] && echo "[EXISTS] README.md" || echo "[MISSING] README.md"
for idx in "$PROJECT_ROOT/memory/MEMORY.md" "$PROJECT_ROOT/.claude/memory/MEMORY.md"; do
  [ -f "$idx" ] && echo "[EXISTS] $(echo "$idx" | sed "s|$PROJECT_ROOT/||") ($(wc -l < "$idx") lines)"
done
```

Record the full file list. This is your working set for all subsequent steps.

## Step 2: Check for Broken File References

For every markdown file found, extract file path references and verify they exist.

**What to look for:**
- Relative links: `[text](path.md)`, `[text](../path.md)`
- Code references: backtick paths like `` `src/app/models/foo.py` ``, `` `YouDrawNext/Features/Drawing/...` ``
- Memory index links: `[Title](filename.md)` in MEMORY.md

```bash
# Extract markdown links from each doc and check if targets exist
for doc in $(find "$PROJECT_ROOT" -name "*.md" -not -path "*/.git/*" -not -path "*/node_modules/*"); do
  DIR=$(dirname "$doc")
  # Find markdown-style links [text](target)
  grep -oP '\[.*?\]\(\K[^)]+' "$doc" 2>/dev/null | while read -r target; do
    # Skip URLs, anchors, images
    [[ "$target" == http* ]] && continue
    [[ "$target" == "#"* ]] && continue
    [[ "$target" == mailto:* ]] && continue
    # Resolve relative path
    RESOLVED="$DIR/$target"
    if [ ! -f "$RESOLVED" ] && [ ! -d "$RESOLVED" ]; then
      echo "BROKEN_LINK: $(echo "$doc" | sed "s|$PROJECT_ROOT/||") -> $target"
    fi
  done
done
```

Report every broken link with its source file and target.

## Step 3: Check for Stale Code References

For each documentation file, find references to specific code artifacts and verify they still exist.

**Patterns to check:**
- Function/class names in backticks: grep the codebase for them
- File paths with line numbers (e.g., `Brush.swift:142`): verify the file exists and the line number is roughly correct
- Specific variable or property names described as being in a specific file

```bash
# Find docs that reference specific file:line patterns
grep -rn '[A-Za-z]\+\.\(swift\|py\|ts\|js\|go\|rs\):[0-9]\+' "$PROJECT_ROOT/memory/" "$PROJECT_ROOT/docs/" "$PROJECT_ROOT/.claude/agents/" 2>/dev/null | head -50
```

For each file:line reference found, read the referenced file at that line and check if the described content is still there. Flag mismatches.

## Step 4: Check for Duplication

Look for the same information living in multiple places. Common duplication patterns:

1. **CLAUDE.md vs memory files** -- rules stated in both
2. **Memory files vs agent specs** -- architecture described in both
3. **Feature docs vs memory files** -- feature details in both locations
4. **Multiple memory files covering the same topic** -- often created in different sessions

```bash
# Find memory files with similar names (potential duplicates)
ls "$PROJECT_ROOT/memory/"*.md 2>/dev/null | xargs -I{} basename {} | sort

# Find feature-related content in memory that should be a *.feature.md next to code
grep -l "Success Criteria\|## Status\|IN PROGRESS\|NOT STARTED" "$PROJECT_ROOT/memory/"*.md 2>/dev/null

# Check for topics mentioned in both CLAUDE.md and memory
if [ -f "$PROJECT_ROOT/CLAUDE.md" ] && [ -d "$PROJECT_ROOT/memory" ]; then
  echo "=== Potential CLAUDE.md / memory overlap ==="
  # Extract section headers from CLAUDE.md
  grep "^##" "$PROJECT_ROOT/CLAUDE.md" | while read -r header; do
    TOPIC=$(echo "$header" | sed 's/^## //' | tr '[:upper:]' '[:lower:]')
    MATCHES=$(grep -ril "$TOPIC" "$PROJECT_ROOT/memory/"*.md 2>/dev/null | head -3)
    [ -n "$MATCHES" ] && echo "  Topic '$TOPIC' in CLAUDE.md AND: $MATCHES"
  done
fi
```

Read the overlapping files and determine which is the canonical source. Flag the duplicate for removal or consolidation.

## Step 5: Check for Orphaned Files

**Orphaned memory files:** exist in `memory/` but not indexed in MEMORY.md
**Orphaned feature docs:** `*.feature.md` files referencing code that no longer exists
**Orphaned flow docs:** `*.flow.md` files where the flow has been removed or renamed

```bash
# Memory files not in MEMORY.md index
if [ -f "$PROJECT_ROOT/memory/MEMORY.md" ]; then
  echo "=== Orphaned memory files ==="
  for f in "$PROJECT_ROOT/memory/"*.md; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    [ "$BASENAME" = "MEMORY.md" ] && continue
    if ! grep -q "$BASENAME" "$PROJECT_ROOT/memory/MEMORY.md"; then
      echo "  ORPHANED: $BASENAME (not in MEMORY.md index)"
    fi
  done
fi

# Feature docs with no matching code
echo "=== Feature docs with no code matches ==="
for doc in $(find "$PROJECT_ROOT" -name '*.feature.md' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null); do
  [ -f "$doc" ] || continue
  BASENAME=$(basename "$doc" .md | sed 's/\.feature$//')
  FEATURE_NAME=$(echo "$BASENAME" | tr '-' ' ' | tr '_' ' ')
  # This is a heuristic -- manual review needed
done
```

## Step 6: Check Doc Health Metrics

```bash
echo "=== Size Warnings ==="
# CLAUDE.md over 150 lines
[ -f "$PROJECT_ROOT/CLAUDE.md" ] && LINES=$(wc -l < "$PROJECT_ROOT/CLAUDE.md") && [ "$LINES" -gt 150 ] && echo "  CLAUDE.md: $LINES lines (target: <150)"

# MEMORY.md over 200 lines (truncation limit)
for idx in "$PROJECT_ROOT/memory/MEMORY.md" "$PROJECT_ROOT/.claude/memory/MEMORY.md"; do
  [ -f "$idx" ] && LINES=$(wc -l < "$idx") && [ "$LINES" -gt 200 ] && echo "  MEMORY.md: $LINES lines (truncates at 200)"
done

# Individual memory files over 100 lines (probably should be split or in docs/)
for f in "$PROJECT_ROOT/memory/"*.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f")
  [ "$BASENAME" = "MEMORY.md" ] && continue
  LINES=$(wc -l < "$f")
  [ "$LINES" -gt 100 ] && echo "  memory/$BASENAME: $LINES lines (consider splitting or moving to docs/)"
done

echo ""
echo "=== Feature Doc Health ==="
for doc in $(find "$PROJECT_ROOT" -name '*.feature.md' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null); do
  [ -f "$doc" ] || continue
  BASENAME=$(basename "$doc")
  ISSUES=""
  grep -qi "Success Criteria" "$doc" || ISSUES="missing Success Criteria"
  grep -qi "## Status" "$doc" || ISSUES="${ISSUES:+$ISSUES, }missing Status"
  STATUS=$(grep -i "## Status" -A1 "$doc" | tail -1 | tr -d '[:space:]')
  [ -n "$ISSUES" ] && echo "  $BASENAME: $ISSUES"
done

echo ""
echo "=== Standalone Docs (potential sprawl) ==="
# Markdown files outside of standard directories
find "$PROJECT_ROOT" -maxdepth 1 -name "*.md" -not -name "CLAUDE.md" -not -name "README.md" -not -name "CHANGELOG.md" -not -name "LICENSE.md" -not -name "*.feature.md" -not -name "*.flow.md" | while read -r f; do
  echo "  ROOT: $(basename "$f") -- should this be in docs/ or memory/?"
done
find "$PROJECT_ROOT" -name "*.md" -not -path "*/docs/*" -not -path "*/memory/*" -not -path "*/.claude/*" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.build/*" -not -path "*/Pods/*" -maxdepth 1 -prune -o -name "*.md" -not -path "*/docs/*" -not -path "*/memory/*" -not -path "*/.claude/*" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/Pods/*" -not -path "*/.build/*" -print 2>/dev/null | while read -r f; do
  REL=$(echo "$f" | sed "s|$PROJECT_ROOT/||")
  echo "  SCATTERED: $REL -- does this belong in docs/?"
done
```

## Step 7: Generate Report

Compile all findings into a structured report with these categories:

```
## Documentation Audit Report

### Project: [name]
### Files Scanned: [N]
### Issues Found: [N]

### BROKEN (references to things that don't exist)
- [file]: [broken reference] -> [what happened]

### STALE (content that no longer matches code)
- [file]: [stale claim] vs [current reality]

### DUPLICATE (same info in multiple places)
- [topic]: found in [file1] AND [file2] -> keep [canonical], remove from [other]

### ORPHANED (exists but nothing references it)
- [file]: not indexed / no code match / dead feature

### OVERSIZED (too large for its role)
- [file]: [N] lines, should be [target] or split

### SPRAWL (files outside standard locations)
- [file]: should move to [location] or be deleted

### HEALTHY (no issues found)
- [list of clean files]
```

## Step 8: Present Actions

Group recommended actions by type and present as a numbered list:

**DELETE** -- files that are stale, orphaned, or fully duplicated elsewhere
**MERGE** -- files covering the same topic that should be combined
**MOVE** -- files in the wrong location (e.g., feature spec in memory/ instead of colocated next to its code)
**UPDATE** -- files with broken references or stale line numbers that are otherwise valuable
**TRIM** -- oversized files that need content moved out or condensed

Ask the user: "Which actions should I take? (all / pick by number / skip)"

## Step 9: Execute Approved Actions

For each approved action:
1. Read the file being modified to confirm the issue
2. Make the change (delete, merge, move, update)
3. Update MEMORY.md index if any memory files were added/removed/renamed
4. Update CLAUDE.md references ONLY if a referenced file was moved/renamed (do not change rules or content)

## Step 10: Final Verification

Re-run the broken link check (Step 2) to confirm no new broken references were introduced by the cleanup. Report final state.

## Rules

- NEVER delete files without user approval
- NEVER modify CLAUDE.md content/rules -- only fix broken file path references
- NEVER delete memory files of type `feedback` or `user` -- those are almost never stale
- Read the actual code before declaring a doc stale -- the doc might be right
- When merging duplicates, keep the version in the canonical location (docs/ > memory/, CLAUDE.md > memory/)
- Keep MEMORY.md under 200 lines after any edits
- No emojis in output or documentation
- If a file is borderline (might be stale, might not), flag it as "REVIEW" rather than recommending deletion
