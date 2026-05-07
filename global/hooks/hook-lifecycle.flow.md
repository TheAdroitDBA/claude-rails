# Flow: Hook Lifecycle

## Entry Point

User types a message or invokes a slash command in Claude Code (any OS).

## Steps

| Phase | Mechanism | Trigger | Expected Output |
|-------|-----------|---------|-----------------|
| 1 | Slash command / commands/<name>.md | User types /<name> | Skill content injected as context; no shell execution |
| 2 | PreToolUse (Edit\|Write) / feature-doc coverage | Tool call on a file in an enforcement scope | approve or block (prompt-type hook evaluates coverage) |
| 3 | PreToolUse (Edit\|Write) / flow-doc presence | Editing a feature doc with ## Surface | approve with optional warning if no flow doc exists |
| 4 | Stop / stale-feature-check | Session stop | warning text if feature docs are missing sections |

## Hook Distribution

Hooks ship via `.claude-plugin/hooks/hooks.json` in the plugin. They auto-wire when the plugin loads -- no per-machine `settings.local.json` wiring needed. All hooks use prompt-type handlers: Claude evaluates enforcement logic directly, no shell subprocess.

This eliminates the cross-platform problem. No paired .sh/.ps1 scripts, no OS detection, no shell parity concerns.

## Cross-OS Matrix

| Mechanism | Mac | Win | Linux |
|-----------|-----|-----|-------|
| Slash commands | native (no shell) | native (no shell) | native (no shell) |
| feature-doc coverage | prompt-type hook | prompt-type hook | prompt-type hook |
| flow-doc presence | prompt-type hook | prompt-type hook | prompt-type hook |
| stale-feature-check | prompt-type hook | prompt-type hook | prompt-type hook |

## Enforcement Gating

All enforcement hooks check for the `.claude/feature-doc-required` marker file in the current repo. If the marker is absent, hooks approve immediately and exit. This means:

- Loading the plugin = hooks are active globally
- The marker file = opt-in switch per repo
- `/project-setup` creates the marker when you want enforcement in a repo

## Why Prompt-Type Hooks

Prompt-type hooks give Claude a text prompt describing the enforcement logic. Claude evaluates the condition against the current file and context, then returns approve or block. Advantages:

- Cross-platform by nature (no shell, no subprocess)
- Auto-wire on plugin load (no settings.json editing)
- Logic is readable text, not script code
- Same mechanism works identically on every OS

## Files Involved

- commands/ (slash command skill files)
- .claude-plugin/hooks/hooks.json (enforcement hook definitions)
- global/hooks/hook-lifecycle.flow.md (this file)
