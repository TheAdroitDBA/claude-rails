# Project Hooks

This directory holds project-specific hook definitions that fire IN ADDITION to the global hooks provided by the claude-rails plugin. Both sets run on the same Claude Code events -- project hooks layer on top, they do not replace globals.

## How Hooks Work

Hooks are defined in JSON and use prompt-type handlers (Claude evaluates the enforcement logic directly). No shell scripts needed. This makes them cross-platform by default.

## Wiring

Add hook entries to `.claude/settings.json` at this repo root. Example:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Before allowing this edit, check that [your project-specific condition]."
          }
        ]
      }
    ]
  }
}
```

Claude Code merges hook arrays -- your entries add to the global entries, they do not override them.

## Placement model

See `.claude/rules/hook-placement.md` for the authoritative placement model (litmus test, common mistakes like hardcoding project-specific logic into global hooks).
