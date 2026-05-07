#!/bin/bash
# require-flow-doc: for feature docs that declare user-visible touchpoints
# (## Surface section present AND non-trivial), require a *.flow.md to exist
# within the feature's scope. Pair to require-feature-doc.sh.
#
# Rationale: feature docs answer "what done means"; flow docs answer
# "how the pipeline runs" (entry points, step tables, named failure
# modes). A user-facing feature without a flow doc leaves a future
# session blind to entry points and failure modes.
#
# Gated by the same .claude/feature-doc-required marker and
# .claude/feature-doc-mode (off/warn/block) knobs as require-feature-doc.

shopt -s extglob globstar 2>/dev/null

INPUT=$(cat)

json_field() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r "$key // \"\""
  else
    case "$key" in
      .tool_name)
        echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
        ;;
      .tool_input.file_path)
        echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p' | sed 's/\\\\/\\/g; s/\\"/"/g'
        ;;
    esac
  fi
}

TOOL_NAME=$(json_field .tool_name)
FILE=$(json_field .tool_input.file_path)

allow() {
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
}

case "$TOOL_NAME" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  "") ;;
  *) allow ;;
esac

if [ -z "$FILE" ]; then allow; fi

# --- Locate marker, mode, skip patterns ---

SCOPE_ROOT=""
dir="$(dirname "$FILE")"
while [ "$dir" != "/" ] && [ "$dir" != "" ] && [ "$dir" != "." ]; do
  if [ -f "$dir/.claude/feature-doc-required" ]; then
    SCOPE_ROOT="$dir"; break
  fi
  parent="$(dirname "$dir")"
  [ "$parent" = "$dir" ] && break
  dir="$parent"
done

[ -z "$SCOPE_ROOT" ] && allow

MODE="block"
MODE_FILE="$SCOPE_ROOT/.claude/feature-doc-mode"
if [ -f "$MODE_FILE" ]; then
  MODE=$(tr -d '[:space:]' < "$MODE_FILE")
  [ -z "$MODE" ] && MODE="block"
fi
[ "$MODE" = "off" ] && allow

# Skip docs/tests/configs/dotfiles (same policy as require-feature-doc)
case "$FILE" in
  */docs/*|*Test*|*test*|*spec*|*.json|*.yml|*.yaml|*.toml|*.md) allow ;;
esac
case "$FILE" in
  */.*|*/.*/*) allow ;;
esac

# --- Locate repo root ---

REPO_ROOT=""
dir="$SCOPE_ROOT"
while [ "$dir" != "/" ] && [ "$dir" != "" ] && [ "$dir" != "." ]; do
  if [ -d "$dir/.git" ]; then REPO_ROOT="$dir"; break; fi
  parent="$(dirname "$dir")"
  [ "$parent" = "$dir" ] && break
  dir="$parent"
done
[ -z "$REPO_ROOT" ] && allow

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

emit_mode_decision() {
  local reason="$1"
  if [ "$MODE" = "warn" ]; then
    echo "WARNING: flow-doc enforcement in warn mode; would block: $reason" >&2
    allow
  fi
  local escaped
  escaped=$(json_escape "$reason")
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$escaped"
  exit 0
}

# --- Collect covering feature docs by walking up from the file's dir ---

FEATURE_DOCS=()
walk_dir="$(dirname "$FILE")"
while true; do
  for fd in "$walk_dir"/*.feature.md; do
    [ -f "$fd" ] || continue
    FEATURE_DOCS+=("$fd")
  done
  [ "$walk_dir" = "$REPO_ROOT" ] && break
  parent="$(dirname "$walk_dir")"
  [ "$parent" = "$walk_dir" ] && break
  walk_dir="$parent"
done

# Also scan legacy docs/features/*.feature.md -- their Scope globs may cover
# this file.
if [ -d "$REPO_ROOT/docs/features" ]; then
  for fd in "$REPO_ROOT/docs/features"/*.feature.md "$REPO_ROOT/docs/features"/*.md; do
    [ -f "$fd" ] || continue
    FEATURE_DOCS+=("$fd")
  done
fi

[ "${#FEATURE_DOCS[@]}" -eq 0 ] && allow

FILE_NORM="${FILE//\\//}"
REPO_ROOT_NORM="${REPO_ROOT//\\//}"
RELPATH="${FILE_NORM#$REPO_ROOT_NORM/}"

# Helper: extract a section from a feature doc. Prints content between
# `## $1` and the next `## `.
extract_section() {
  local doc="$1" name="$2"
  awk -v name="## $name" '
    $0 == name { in_section=1; next }
    in_section && /^## / { in_section=0 }
    in_section { print }
  ' "$doc"
}

# Helper: true if Surface content is non-trivial (not empty, not "none",
# not "internal").
surface_is_meaningful() {
  local content="$1"
  local trimmed
  trimmed=$(printf '%s' "$content" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  case "$trimmed" in
    ""|"none"|"internal"|"none."|"internal.") return 1 ;;
  esac
  return 0
}

# Helper: given a glob-style path pattern (using ** and *), return 0 if
# any *.flow.md path in the repo matches.
any_flow_matching_glob() {
  local glob="$1"
  # Collect all flow docs in the repo once; the loop is cheap.
  local f
  for f in $(cd "$REPO_ROOT" && find . -name "*.flow.md" -not -path "./.git/*" 2>/dev/null); do
    local rel="${f#./}"
    local gp="${glob//\*\*/*}"
    if [[ "$rel" == $gp ]]; then return 0; fi
  done
  return 1
}

# Helper: for an unscoped feature doc (no ## Scope), check for a flow doc
# colocated in the same directory OR any descendant.
any_flow_under_dir() {
  local dir="$1"
  local f
  for f in $(find "$dir" -name "*.flow.md" 2>/dev/null); do
    [ -f "$f" ] && return 0
  done
  return 1
}

# --- Determine which feature doc(s) cover the edited file ---
# A doc covers the file if (a) its Scope globs match the file's relative
# path, or (b) it's unscoped and lives in an ancestor directory of the file.

COVERING_DOCS=()
for doc in "${FEATURE_DOCS[@]}"; do
  scope_section=$(extract_section "$doc" "Scope")
  scope_clean=$(echo "$scope_section" | sed 's/<!--[^>]*-->//g')

  doc_has_entries=0
  covered=0
  while IFS= read -r line; do
    line=$(echo "$line" | tr ',' '\n')
    while IFS= read -r glob; do
      glob=$(echo "$glob" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^`//;s/`$//')
      [ -z "$glob" ] && continue
      doc_has_entries=1
      gpat="${glob//\*\*/*}"
      [[ "$RELPATH" == $gpat ]] && covered=1
    done <<< "$line"
  done <<< "$scope_clean"

  if [ "$doc_has_entries" -eq 0 ]; then
    doc_dir="$(dirname "$doc")"
    doc_dir_norm="${doc_dir//\\//}"
    case "$FILE_NORM" in
      "$doc_dir_norm"/*|"$doc_dir_norm") covered=1 ;;
    esac
  fi

  [ "$covered" -eq 1 ] && COVERING_DOCS+=("$doc")
done

# No covering docs -> require-feature-doc would have already handled it.
[ "${#COVERING_DOCS[@]}" -eq 0 ] && allow

# --- For each covering doc with a meaningful Surface, require a flow doc ---
# Escape hatch: a Deviation entry naming a flow-doc-shaped convention
# (e.g. `flow-doc.skipped: <reason>`) counts as declared. The rationale
# after the colon is enforced at fs: closure; the hook only checks shape.

deviation_covers_flow_doc() {
  local doc="$1"
  local dev_section
  dev_section=$(extract_section "$doc" "Deviation from conventions")
  [ -z "$dev_section" ] && return 1
  # Match any bullet whose convention-name token contains "flow" and is
  # followed by a colon. Keeps the check forgiving to naming variants.
  printf '%s' "$dev_section" | grep -qE '^[[:space:]]*-[[:space:]]*[a-zA-Z0-9._-]*flow[a-zA-Z0-9._-]*:[[:space:]]*[^[:space:]].*' && return 0
  return 1
}

MISSING_FLOW_DOCS=()
for doc in "${COVERING_DOCS[@]}"; do
  surface=$(extract_section "$doc" "Surface")
  surface_is_meaningful "$surface" || continue

  # Skip the requirement entirely if the doc declares a flow-doc deviation.
  if deviation_covers_flow_doc "$doc"; then continue; fi

  scope_section=$(extract_section "$doc" "Scope")
  scope_clean=$(echo "$scope_section" | sed 's/<!--[^>]*-->//g')

  has_flow=0
  doc_has_entries=0
  while IFS= read -r line; do
    line=$(echo "$line" | tr ',' '\n')
    while IFS= read -r glob; do
      glob=$(echo "$glob" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^`//;s/`$//')
      [ -z "$glob" ] && continue
      doc_has_entries=1
      if any_flow_matching_glob "$glob"; then has_flow=1; break 2; fi
    done <<< "$line"
  done <<< "$scope_clean"

  if [ "$doc_has_entries" -eq 0 ] && any_flow_under_dir "$(dirname "$doc")"; then
    has_flow=1
  fi

  [ "$has_flow" -eq 0 ] && MISSING_FLOW_DOCS+=("$doc")
done

[ "${#MISSING_FLOW_DOCS[@]}" -eq 0 ] && allow

# Format a helpful message for the first missing-flow-doc case.
first="${MISSING_FLOW_DOCS[0]}"
first_rel="${first#$REPO_ROOT_NORM/}"
reason="Feature doc '$first_rel' declares a ## Surface (user-visible touchpoints) but no sibling *.flow.md exists within its Scope. Flow docs catalogue entry points, step tables, and named failure modes. Create a *.flow.md colocated with the primary entry-point code before editing source, or declare an explicit '## Deviation from conventions' entry in the feature doc with a one-line rationale."
emit_mode_decision "$reason"
