#!/bin/bash
# require-feature-doc: enforce feature-doc presence for paths under a marker-scoped directory.
# Scans colocated *.feature.md files walking up from the edited file to the repo root.
# Three knobs: .claude/feature-doc-required marker, .claude/feature-doc-mode (off|warn|block),
# and ## Scope sections in feature docs. See memory/HOOK-INVENTORY.md.

shopt -s extglob globstar 2>/dev/null

INPUT=$(cat)

# Extract a JSON string field via jq if available, falling back to sed.
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

# Only enforce on edit-class tools. Read/Bash/Grep/Glob/etc always pass through.
case "$TOOL_NAME" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  "") ;;
  *)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
    ;;
esac

if [ -z "$FILE" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
fi

# Walk upward from the file's dirname looking for .claude/feature-doc-required
SCOPE_ROOT=""
dir="$(dirname "$FILE")"
while [ "$dir" != "/" ] && [ "$dir" != "" ] && [ "$dir" != "." ]; do
  if [ -f "$dir/.claude/feature-doc-required" ]; then
    SCOPE_ROOT="$dir"
    break
  fi
  parent="$(dirname "$dir")"
  if [ "$parent" = "$dir" ]; then break; fi
  dir="$parent"
done

if [ -z "$SCOPE_ROOT" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
fi

# Read mode (default: block)
MODE_FILE="$SCOPE_ROOT/.claude/feature-doc-mode"
MODE="block"
if [ -f "$MODE_FILE" ]; then
  MODE=$(tr -d '[:space:]' < "$MODE_FILE")
  [ -z "$MODE" ] && MODE="block"
fi

if [ "$MODE" = "off" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
fi

# Skip patterns (always allow): docs, tests, configs, dotfiles
case "$FILE" in
  */docs/*|*Test*|*test*|*spec*|*.json|*.yml|*.yaml|*.toml|*.md)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
    ;;
esac
case "$FILE" in
  */.*|*/.*/*)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
    ;;
esac

# JSON-escape a string for embedding in a decision payload.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Helper: apply mode decision once the file is known to be out of scope
emit_mode_decision() {
  local reason="$1"
  if [ "$MODE" = "warn" ]; then
    echo "WARNING: feature-doc enforcement in warn mode; would block: $reason" >&2
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
  fi
  local escaped
  escaped=$(json_escape "$reason")
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$escaped"
  exit 0
}

# Find repo root
REPO_ROOT=""
dir="$SCOPE_ROOT"
while [ "$dir" != "/" ] && [ "$dir" != "" ] && [ "$dir" != "." ]; do
  if [ -d "$dir/.git" ]; then
    REPO_ROOT="$dir"
    break
  fi
  parent="$(dirname "$dir")"
  if [ "$parent" = "$dir" ]; then break; fi
  dir="$parent"
done

if [ -z "$REPO_ROOT" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
fi

# --- Collect colocated *.feature.md walking from edited file's dir up to REPO_ROOT ---

FEATURE_DOCS=()
walk_dir="$(dirname "$FILE")"
while true; do
  for fd in "$walk_dir"/*.feature.md; do
    [ -f "$fd" ] || continue
    FEATURE_DOCS+=("$fd")
  done
  if [ "$walk_dir" = "$REPO_ROOT" ]; then break; fi
  parent="$(dirname "$walk_dir")"
  if [ "$parent" = "$walk_dir" ]; then break; fi
  walk_dir="$parent"
done

# Read current-feature hint
CURRENT_FEATURE=""
if [ -f "$SCOPE_ROOT/.claude/current-feature" ]; then
  CURRENT_FEATURE=$(tr -d '[:space:]' < "$SCOPE_ROOT/.claude/current-feature")
fi

if [ "${#FEATURE_DOCS[@]}" -eq 0 ]; then
  if [ -n "$CURRENT_FEATURE" ]; then
    emit_mode_decision "No feature doc found. Create $CURRENT_FEATURE.feature.md next to the code you are working on."
  else
    emit_mode_decision "No feature doc found. Create a *.feature.md file next to the code you are editing."
  fi
fi

# Normalize paths for matching
FILE_NORM="${FILE//\\//}"
REPO_ROOT_NORM="${REPO_ROOT//\\//}"
RELPATH="${FILE_NORM#$REPO_ROOT_NORM/}"

# --- Check coverage ---
# For each feature doc:
#   If it has ## Scope with entries -> check globs against the edited file
#   If unscoped (no ## Scope or empty) -> covers its own directory and everything below

MATCHED=0
for doc in "${FEATURE_DOCS[@]}"; do
  scope_section=$(awk '
    /^## Scope/ { in_scope=1; next }
    in_scope && /^## / { in_scope=0 }
    in_scope { print }
  ' "$doc")

  scope_clean=$(echo "$scope_section" | sed 's/<!--[^>]*-->//g')

  # Collect scope entries
  doc_has_entries=0
  while IFS= read -r line; do
    line=$(echo "$line" | tr ',' '\n')
    while IFS= read -r glob; do
      glob=$(echo "$glob" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -z "$glob" ] && continue
      doc_has_entries=1
      gpat="${glob//\*\*/*}"
      if [[ "$RELPATH" == $gpat ]]; then
        MATCHED=1
        break 3
      fi
    done <<< "$line"
  done <<< "$scope_clean"

  if [ "$doc_has_entries" -eq 0 ]; then
    # Unscoped doc: covers its directory and all descendants
    doc_dir="$(dirname "$doc")"
    doc_dir_norm="${doc_dir//\\//}"
    case "$FILE_NORM" in
      "$doc_dir_norm"/*|"$doc_dir_norm")
        MATCHED=1
        break
        ;;
    esac
  fi
done

if [ "$MATCHED" -eq 1 ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
fi

emit_mode_decision "Edited file ($RELPATH) is not covered by any feature doc. Create a *.feature.md next to the file, or add its path to a feature doc's ## Scope section."
