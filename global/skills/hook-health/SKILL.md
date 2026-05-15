---
name: hook-health
description: Verifies claude-config's enforcement hooks are wired correctly on this machine. Reads ~/.claude/settings.local.json, locates each claude-config hook, and checks the script exists, the interpreter is on PATH, the canonical hooks are wired on the right events, and there is no OS mismatch or duplicate wiring. Read-only.
---

# Hook Health

You are verifying that claude-config's enforcement hooks are wired correctly on this machine. The user invokes this skill when they are unsure whether `require-feature-doc`, `auto-lint`, or `stale-feature-check` will actually fire -- e.g. after editing `~/.claude/settings.local.json`, switching machines, or installing a new interpreter.

This skill is **read-only**. Never write, fix, or run any installation step. Remediation is advisory.

## Step 1: Read settings.local.json

Read `~/.claude/settings.local.json`. If the file is missing, empty, or contains no hook entries whose `command` string contains `claude-config/global/hooks/`, report:

> No claude-config hooks detected on this machine.
>
> Remediation: see claude-config README.md Quick Start step 3 to wire enforcement hooks in `~/.claude/settings.local.json`.

Then stop. Do not run further checks.

## Step 2: Enumerate claude-config hooks

For every `command` string under `hooks.*[].hooks[]` whose value contains `claude-config/global/hooks/`, record:

- **Event**: the parent key (`PreToolUse`, `PostToolUse`, `Stop`, or `UserPromptSubmit`).
- **Matcher**: the entry's `matcher` field (often `Edit|Write`; absent on `Stop`).
- **Command**: the full `command` string verbatim.
- **Script path**: the path component of the command (everything after `bash ` or `pwsh -... -File ` or `powershell -... -File `).
- **Hook name**: the script basename without extension (e.g. `require-feature-doc`).
- **Extension**: `.sh` or `.ps1`.

Build the list before running any check. Treat each list entry as one row in the final report.

## Step 3: Per-hook checks

For each enumerated hook, run these checks via Bash tool calls. Record `PASS` / `FAIL` / `WARN` per check.

### Check A -- script file exists

`test -f <script-path> && echo PASS || echo FAIL`

FAIL detail: the resolved path that does not exist. Remediation: verify the path in `settings.local.json` matches the actual claude-config clone location on this machine.

### Check B -- interpreter on PATH

For `.sh` extension: `command -v bash >/dev/null && echo PASS || echo FAIL`
For `.ps1` extension: `command -v pwsh >/dev/null || command -v powershell >/dev/null && echo PASS || echo FAIL`

FAIL detail: the missing interpreter name. Remediation: install bash (Mac/Linux) or PowerShell 7+ (`pwsh`) and retry.

### Check C -- OS match

Detect OS via `uname -s` (`Linux` / `Darwin`) or absence of uname (Windows).

- On Linux/Darwin: extension must be `.sh`. A `.ps1` command is FAIL: "PowerShell command wired on Mac/Linux; use the bash form."
- On Windows: extension must be `.ps1`. A `.sh` command is FAIL: "bash command wired on Windows; use the pwsh form."

## Step 4: Canonical-hook checks

These are repo-level checks (not per-hook). The framework ships exactly three canonical enforcement hooks. For each name + expected event, walk the enumerated list:

| Hook name | Expected event | Expected matcher |
|---|---|---|
| `require-feature-doc` | `PreToolUse` | `Edit\|Write` |
| `auto-lint` | `PostToolUse` | `Edit\|Write` |
| `stale-feature-check` | `Stop` | (none) |

For each row:

- **MISSING** if no enumerated hook matches the name (any event).
- **MISWIRED** if the hook is enumerated but on the wrong event or wrong matcher. Report the actual event/matcher alongside the expected.
- **PASS** otherwise.

A fourth optional hook -- `require-flow-doc` (`PreToolUse` `Edit|Write`) -- is reported as INFO if present, never as MISSING. Do not flag its absence.

## Step 5: Cross-file duplicate check

Read `~/.claude/settings.json` if it exists. For each hook command in `settings.local.json`, check whether the same `command` string also appears in `settings.json`. If so, emit a WARN per duplicate:

> Hook `<command>` is wired in both `settings.json` and `settings.local.json`. Claude Code unions hook arrays; the hook will fire twice.

Remediation: keep wiring in `settings.local.json` only and remove the duplicate from `settings.json`.

## Step 6: Report

Emit a single Markdown report in this shape:

```
## Hook Health

### Per-hook checks

| Hook | Event | File exists | Interpreter | OS match |
|---|---|---|---|---|
| require-feature-doc | PreToolUse | PASS | PASS (bash) | PASS |
| auto-lint | PostToolUse | PASS | PASS (bash) | PASS |
| stale-feature-check | Stop | FAIL: /missing/path | -- | -- |

### Canonical hooks

| Hook | Status | Detail |
|---|---|---|
| require-feature-doc | PASS | wired on PreToolUse Edit|Write |
| auto-lint | PASS | wired on PostToolUse Edit|Write |
| stale-feature-check | FAIL | wired on Stop, but file missing |

### Warnings

(None) -- or a bullet list of WARN entries.

### Summary

<N> failures, <M> warnings.

<closing line>
```

Closing line:

- All green (zero failures, zero warnings): `Hooks are wired and reachable.`
- Any failure: `Fix the failure(s) above. Common fix: re-check ~/.claude/settings.local.json against claude-config README Quick Start step 3.`
- Warnings only: `Hooks are reachable but have warnings; review above.`

Never emit an overall PASS verdict for hook-health itself -- per-check PASS/FAIL is objective from filesystem state, but the user judges whether the configuration is acceptable.

## Do not

- Do not modify any file. Read-only.
- Do not auto-fix wiring or rewrite settings.local.json.
- Do not assume claude-config's clone location. Every path comes from settings.local.json content.
- Do not extrapolate beyond hook wiring. Manifest correctness, feature-doc enforcement state, and other framework concerns are out of scope.
- Do not run shell commands beyond the read-only checks listed in Step 3 (`test -f`, `command -v`, `uname -s`).
