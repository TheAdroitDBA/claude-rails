---
description: Verifies claude-rails enforcement hooks are active. Checks that commands are discoverable, hooks/hooks.json exists, and enforcement markers are correctly placed in the current repo. Read-only.
---

# Hook Health

You are verifying that claude-rails's enforcement hooks are active in the current session. The user invokes this command when they are unsure whether enforcement is working -- e.g. after registering the plugin, switching machines, or adopting a new repo.

This command is **read-only**. Never write or modify any file. Remediation is advisory.

## Step 1: Verify commands are discoverable

Check whether claude-rails commands are discoverable in this session. If `/project-setup` or `/software-architect` are not available, the commands are not linked.

Report:
- PASS: commands are discoverable
- FAIL: commands not linked. Remediation: run `link-commands.sh` (Mac/Linux) or `link-commands.ps1` (Windows) from the claude-rails directory. See README Quick Start step 2.

## Step 2: Verify hooks.json exists

Check whether the plugin's hooks file exists. The expected location is the `hooks/hooks.json` directory inside the plugin's `.claude-plugin/` directory.

Report:
- PASS: hooks.json found with PreToolUse and Stop entries
- FAIL: hooks.json missing or malformed. Remediation: ensure the claude-rails clone is intact and the plugin path is correct.

## Step 3: Check enforcement markers in current repo

If the user is inside a repo, check:

1. Does `.claude/feature-doc-required` exist? If not, enforcement is inactive in this repo (by design -- this is not a failure, just informational).
2. If the marker exists, what is `.claude/feature-doc-mode`? Report the current mode (`off`, `warn`, `block`, or default `block` if file is absent).

Report:
- ACTIVE (block): marker present, mode is block
- ACTIVE (warn): marker present, mode is warn
- INACTIVE: no marker file. Enforcement hooks will approve all edits in this repo. Run `/project-setup` to opt in.
- OFF: marker present but mode is `off`. Enforcement is explicitly disabled.

## Step 4: Spot-check enforcement hooks

List the three enforcement hooks and their expected behavior:

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| feature-doc coverage | PreToolUse | Edit\|Write\|MultiEdit\|NotebookEdit | Blocks edits to files not covered by a feature doc |
| flow-doc presence | PreToolUse | Edit\|Write\|MultiEdit\|NotebookEdit | Warns when feature doc has ## Surface but no flow doc |
| stale-feature-check | Stop | * | Warns if touched feature docs are missing sections |

All three are prompt-type hooks (Claude evaluates the logic directly). They require no shell scripts, no interpreter, and no per-machine wiring.

## Step 5: Report

Emit a single Markdown report:

```
## Hook Health

| Check | Status | Detail |
|-------|--------|--------|
| Commands linked | PASS/FAIL | ... |
| hooks.json present | PASS/FAIL | ... |
| Enforcement markers | ACTIVE/INACTIVE/OFF | mode: block/warn/off |

### Enforcement hooks (via plugin)

| Hook | Type | Status |
|------|------|--------|
| feature-doc coverage | prompt | active (auto-wired by plugin) |
| flow-doc presence | prompt | active (auto-wired by plugin) |
| stale-feature-check | prompt | active (auto-wired by plugin) |

### Summary

<closing line>
```

Closing lines:
- Commands linked + markers active: `Enforcement is active. Edits to uncovered files will be blocked/warned.`
- Commands linked + no markers: `Commands are linked but this repo has not opted into enforcement. Run /project-setup to set up markers.`
- Commands not linked: `Commands are not linked. Run link-commands.sh or link-commands.ps1 from the claude-rails directory.`

## Do not

- Do not modify any file. Read-only.
- Do not check for interpreter availability. Hooks are prompt-type handlers evaluated by Claude directly.
- Do not run shell commands beyond read-only filesystem checks.
