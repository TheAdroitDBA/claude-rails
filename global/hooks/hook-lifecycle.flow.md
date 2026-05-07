# Flow: Hook Lifecycle

## Entry Point

User types a message or invokes a slash command in Claude Code (any OS).

## Steps (current -- plugin era)

| Phase | Mechanism | Trigger | Expected Output |
|-------|-----------|---------|-----------------|
| 1 | Slash command / commands/<name>.md | User types /<name> | Skill content injected as context; no shell execution |
| 2 | PreToolUse (Edit\|Write) / require-feature-doc | Tool call on a covered file | {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow\|deny"}} |
| 3 | PostToolUse (Edit\|Write) / auto-lint | After Edit or Write tool | none (side effect: formatter runs) |
| 4 | Stop / stale-feature-check | Session stop | text (if any issues) printed as warning |

Phase 1 is no longer a hook. Shorthand expansion is replaced by native slash
commands distributed via the plugin (plugin-distribution.feature.md, 2026-05-04).
Slash commands are OS-agnostic: no shell subprocess, no manifest parsing, no
parity scripts. Pasted text containing former shorthand patterns (n:, f:, etc.)
does not trigger any expansion.

## Cross-OS Matrix (current)

| Mechanism | Mac | Win | Linux |
|-----------|-----|-----|-------|
| Slash commands | native (no shell) | native (no shell) | native (no shell) |
| require-feature-doc | Claude instructions (CLAUDE.md) | Claude instructions (CLAUDE.md) | Claude instructions (CLAUDE.md) |
| stale-feature-check | Claude instructions (CLAUDE.md) | Claude instructions (CLAUDE.md) | Claude instructions (CLAUDE.md) |
| require-flow-doc | Claude instructions (CLAUDE.md) | Claude instructions (CLAUDE.md) | Claude instructions (CLAUDE.md) |
| auto-lint | bash auto-lint.sh | pwsh auto-lint.ps1 | bash auto-lint.sh |

Note: `--plugin-dir` does NOT load the plugin's CLAUDE.md. It loads skills,
agents, hooks.json, and the plugin's settings.json. The CLAUDE.md enforcement
instructions (## Plugin Enforcement) apply when working on claude-config itself
but are NOT auto-distributed to adopted repo sessions via the plugin.

Current distribution path for enforcement hooks: per-machine
`~/.claude/settings.local.json` wiring (see README Quick Start).

Planned distribution path (not yet implemented): ship a cross-platform
`settings.json` in the plugin root that wires enforcement hooks without
requiring per-machine setup. Requires hooks to be written in a cross-platform
runtime (e.g. Node.js) so a single settings.json entry works on all OSes.
Tracked in plugin-distribution.feature.md criterion 4.

Auto-lint (PostToolUse formatter runner) remains as shell scripts because it
runs real formatting tools (prettier, black, gofmt, etc.) that require a shell
process. Wire per-machine via `~/.claude/settings.local.json`.

Shell scripts for all enforcement hooks are retained in global/hooks/ as the
current hard-enforcement path via manual settings.local.json wiring.

## Historical note: shorthand-expand hook (removed 2026-05-04)

The UserPromptSubmit / shorthand-expand hook intercepted "n:", "f:", "b:", etc.
and returned additionalContext by parsing shortcuts-manifest.json. It required
paired .sh + .ps1 scripts per OS, was fragile to junction resolution on Windows,
and accidentally triggered on pasted text containing shorthand patterns.
Replaced by native slash commands. Scripts retired to migration/retired-hooks/.

## Why Hooks Stream JSON

Claude Code invokes each hook as a subprocess, piping JSON to stdin, reading
JSON or plain text from stdout, and interpreting the structured response to
allow/block tool calls or inject context.

## Files Involved

- commands/ (slash command skill files -- replaces shorthand-expand)
- global/hooks/require-feature-doc.sh, .ps1
- global/hooks/auto-lint.sh, .ps1
- global/hooks/stale-feature-check.sh, .ps1
- settings.*.json (enforcement hook wiring -- local per machine)
