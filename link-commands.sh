#!/usr/bin/env bash
# link-commands.sh -- symlink claude-rails/commands into ~/.claude/commands
# Idempotent: safe to re-run. Backs up any existing real directory first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$REPO_DIR/commands"
COMMANDS_DST="$HOME/.claude/commands"

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
    echo "Already linked: $COMMANDS_DST -> $COMMANDS_SRC"
  else
    echo "Relinking: was -> $existing"
    rm "$COMMANDS_DST"
    ln -s "$COMMANDS_SRC" "$COMMANDS_DST"
    echo "Linked: $COMMANDS_DST -> $COMMANDS_SRC"
  fi
elif [ -d "$COMMANDS_DST" ]; then
  backup="${COMMANDS_DST}.bak"
  echo "Backing up existing directory to $backup"
  mv "$COMMANDS_DST" "$backup"
  ln -s "$COMMANDS_SRC" "$COMMANDS_DST"
  echo "Linked: $COMMANDS_DST -> $COMMANDS_SRC"
else
  ln -s "$COMMANDS_SRC" "$COMMANDS_DST"
  echo "Linked: $COMMANDS_DST -> $COMMANDS_SRC"
fi

# Verify
echo ""
echo "Verification:"
echo "  Link target : $(readlink "$COMMANDS_DST")"
echo "  Commands    :"
for f in "$COMMANDS_DST"/*.md; do
  [ -f "$f" ] || continue
  echo "    /$(basename "$f" .md)"
done
