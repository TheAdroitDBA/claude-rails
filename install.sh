#!/usr/bin/env bash
# install.sh -- link commands and register the plugin in one step
# Idempotent: safe to re-run. Backs up any existing real directory first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$REPO_DIR/commands"
COMMANDS_DST="$HOME/.claude/commands"
SETTINGS_FILE="$HOME/.claude/settings.json"

# -- Step 1: Link commands ---------------------------------------------------

# Verify source exists
if [ ! -d "$COMMANDS_SRC" ]; then
  echo "ERROR: commands/ not found at $COMMANDS_SRC" >&2
  exit 1
fi

# Ensure ~/.claude exists
mkdir -p "$HOME/.claude"

# Handle existing destination
if [ -L "$COMMANDS_DST" ]; then
  existing="$(readlink "$COMMANDS_DST")"
  if [ "$existing" = "$COMMANDS_SRC" ]; then
    echo "Commands: already linked -> $COMMANDS_SRC"
  else
    echo "Commands: relinking (was -> $existing)"
    rm "$COMMANDS_DST"
    ln -s "$COMMANDS_SRC" "$COMMANDS_DST"
    echo "Commands: linked -> $COMMANDS_SRC"
  fi
elif [ -d "$COMMANDS_DST" ]; then
  backup="${COMMANDS_DST}.bak"
  echo "Commands: backing up existing directory to $backup"
  mv "$COMMANDS_DST" "$backup"
  ln -s "$COMMANDS_SRC" "$COMMANDS_DST"
  echo "Commands: linked -> $COMMANDS_SRC"
else
  ln -s "$COMMANDS_SRC" "$COMMANDS_DST"
  echo "Commands: linked -> $COMMANDS_SRC"
fi

# -- Step 2: Register plugin -------------------------------------------------

register_plugin() {
  local settings_file="$1"
  local repo_dir="$2"

  # Try jq first (preserves formatting)
  if command -v jq >/dev/null 2>&1; then
    local existing="{}"
    if [ -f "$settings_file" ]; then
      existing="$(cat "$settings_file")"
    fi

    echo "$existing" | jq \
      --arg path "$repo_dir" \
      '.extraKnownMarketplaces["claude-rails"] = {
        "source": { "source": "directory", "path": $path }
      } | .enabledPlugins["claude-rails@claude-rails"] = true' \
      > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"
    return 0
  fi

  # Fall back to python3
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, os, sys

settings_file = sys.argv[1]
repo_dir = sys.argv[2]

settings = {}
if os.path.isfile(settings_file):
    with open(settings_file, 'r') as f:
        settings = json.load(f)

if 'extraKnownMarketplaces' not in settings:
    settings['extraKnownMarketplaces'] = {}
settings['extraKnownMarketplaces']['claude-rails'] = {
    'source': { 'source': 'directory', 'path': repo_dir }
}

if 'enabledPlugins' not in settings:
    settings['enabledPlugins'] = {}
settings['enabledPlugins']['claude-rails@claude-rails'] = True

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
" "$settings_file" "$repo_dir"
    return 0
  fi

  return 1
}

# Check if plugin is already registered correctly
plugin_registered=false
if [ -f "$SETTINGS_FILE" ]; then
  if command -v jq >/dev/null 2>&1; then
    existing_path="$(jq -r '.extraKnownMarketplaces["claude-rails"].source.path // ""' "$SETTINGS_FILE" 2>/dev/null || echo "")"
    enabled="$(jq -r '.enabledPlugins["claude-rails@claude-rails"] // false' "$SETTINGS_FILE" 2>/dev/null || echo "false")"
    if [ "$existing_path" = "$REPO_DIR" ] && [ "$enabled" = "true" ]; then
      plugin_registered=true
    fi
  elif command -v python3 >/dev/null 2>&1; then
    check_result="$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        s = json.load(f)
    path = s.get('extraKnownMarketplaces', {}).get('claude-rails', {}).get('source', {}).get('path', '')
    enabled = s.get('enabledPlugins', {}).get('claude-rails@claude-rails', False)
    print('yes' if path == sys.argv[2] and enabled else 'no')
except: print('no')
" "$SETTINGS_FILE" "$REPO_DIR" 2>/dev/null || echo "no")"
    if [ "$check_result" = "yes" ]; then
      plugin_registered=true
    fi
  fi
fi

if [ "$plugin_registered" = "true" ]; then
  echo "Plugin:   already registered in $SETTINGS_FILE"
else
  if register_plugin "$SETTINGS_FILE" "$REPO_DIR"; then
    echo "Plugin:   registered in $SETTINGS_FILE"
  else
    echo ""
    echo "Plugin:   MANUAL STEP REQUIRED"
    echo "  Neither jq nor python3 found. Add this to $SETTINGS_FILE:"
    echo ""
    echo "  {"
    echo "    \"extraKnownMarketplaces\": {"
    echo "      \"claude-rails\": {"
    echo "        \"source\": { \"source\": \"directory\", \"path\": \"$REPO_DIR\" }"
    echo "      }"
    echo "    },"
    echo "    \"enabledPlugins\": {"
    echo "      \"claude-rails@claude-rails\": true"
    echo "    }"
    echo "  }"
  fi
fi

# -- Step 2.5: Stamp installed version --------------------------------------
# Writes the current claude-rails VERSION to a known location. Adopting repos
# read this to record the framework version they were last validated against.
# Consumed by /check-conformance and the session-start banner.

VERSION_FILE="$REPO_DIR/VERSION"
VERSION_STAMP="$HOME/.claude/claude-rails-version"

if [ -f "$VERSION_FILE" ]; then
  CURRENT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
  printf '%s\n' "$CURRENT_VERSION" > "$VERSION_STAMP"
  echo "Version:  $CURRENT_VERSION (stamped to $VERSION_STAMP)"
else
  echo "WARNING:  $VERSION_FILE not found; version stamp not written."
fi

# -- Step 3: Verification ----------------------------------------------------

echo ""
echo "Verification:"
echo "  Link target : $(readlink "$COMMANDS_DST")"
echo "  Commands    :"
for f in "$COMMANDS_DST"/*.md; do
  [ -f "$f" ] || continue
  echo "    /$(basename "$f" .md)"
done
if [ -f "$SETTINGS_FILE" ]; then
  echo "  Settings    : $SETTINGS_FILE (exists)"
else
  echo "  Settings    : $SETTINGS_FILE (NOT FOUND)"
fi
echo "  Hooks file  : $REPO_DIR/.claude-plugin/hooks/hooks.json"
if [ -f "$REPO_DIR/.claude-plugin/hooks/hooks.json" ]; then
  echo "                (exists)"
else
  echo "                (NOT FOUND -- plugin may not fire hooks)"
fi
if [ -f "$VERSION_STAMP" ]; then
  echo "  Version     : $(cat "$VERSION_STAMP") (from $VERSION_STAMP)"
fi
