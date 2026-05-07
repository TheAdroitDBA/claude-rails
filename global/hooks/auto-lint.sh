#!/bin/bash
# auto-lint: run language-appropriate formatter on the edited file. See memory/HOOK-INVENTORY.md.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.swift)
    swiftlint --fix --quiet "$FILE" 2>/dev/null
    ;;
  *.ts|*.tsx|*.js|*.jsx)
    npx prettier --write "$FILE" 2>/dev/null
    ;;
  *.py)
    ruff format "$FILE" 2>/dev/null || black "$FILE" 2>/dev/null
    ;;
  *.rs)
    rustfmt "$FILE" 2>/dev/null
    ;;
  *.go)
    gofmt -w "$FILE" 2>/dev/null
    ;;
esac

exit 0
