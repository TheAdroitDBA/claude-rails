---
description: Verifies claude-rails enforcement hooks are active. Checks that commands are discoverable, hooks/hooks.json exists, and enforcement markers are correctly placed in the current repo. Offers to fix broken setup when possible.
---

# Hook Health

You are verifying that claude-rails's enforcement hooks are active in the current session. The user invokes this command when they are unsure whether enforcement is working -- e.g. after registering the plugin, switching machines, or adopting a new repo.

This command is **diagnostic first, remedial when needed**. Always ask before modifying anything.

## Step 1: Verify commands are discoverable

Check whether claude-rails commands are discoverable in this session. If `/project-setup` or `/software-architect` are not available, the commands are not linked.

Report:
- PASS: commands are discoverable
- FAIL: commands not linked.

If FAIL: check whether `~/.claude/commands/` exists and whether it points at this repo's `commands/` directory. **Offer to fix** by running the install script (`install.sh` on Mac/Linux, `install.ps1` on Windows) or by creating the symlink/junction directly. Ask the user before proceeding.

## Step 2: Verify plugin is registered

Read `~/.claude/settings.json` and check whether `claude-rails` is present in `extraKnownMarketplaces` and `claude-rails@claude-rails` is enabled in `enabledPlugins`.

Report:
- PASS: plugin registered and enabled
- FAIL: plugin not registered or not enabled

If FAIL: read `~/.claude/settings.json` (or start with `{}` if it does not exist), add the missing registration keys, and **offer to write the updated file back**. Show the user the diff before writing. Ask the user before proceeding. The keys to add:

```json
{
  "extraKnownMarketplaces": {
    "claude-rails": {
      "source": { "source": "directory", "path": "<repo-path>" }
    }
  },
  "enabledPlugins": {
    "claude-rails@claude-rails": true
  }
}
```

Where `<repo-path>` is the absolute path to the claude-rails clone directory.

## Step 3: Verify hooks.json exists

Check whether the plugin's hooks file exists. The expected location is the `hooks/hooks.json` directory inside the plugin's `.claude-plugin/` directory.

Report:
- PASS: hooks.json found with PreToolUse and Stop entries
- FAIL: hooks.json missing or malformed. Remediation: ensure the claude-rails clone is intact and the plugin path is correct.

## Step 4: Check enforcement markers in current repo

If the user is inside a repo, check:

1. Does `.claude/feature-doc-required` exist? If not, enforcement is inactive in this repo (by design -- this is not a failure, just informational).
2. If the marker exists, what is `.claude/feature-doc-mode`? Report the current mode (`off`, `warn`, `block`, or default `block` if file is absent).

Report:
- ACTIVE (block): marker present, mode is block
- ACTIVE (warn): marker present, mode is warn
- INACTIVE: no marker file. Enforcement hooks will approve all edits in this repo. Run `/project-setup` to opt in.
- OFF: marker present but mode is `off`. Enforcement is explicitly disabled.

## Step 5: Spot-check enforcement hooks

List the three enforcement hooks and their expected behavior:

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| feature-doc coverage | PreToolUse | Edit\|Write\|MultiEdit\|NotebookEdit | Blocks edits to files not covered by a feature doc |
| flow-doc presence | PreToolUse | Edit\|Write\|MultiEdit\|NotebookEdit | Warns when feature doc has ## Surface but no flow doc |
| stale-feature-check | Stop | * | Warns if touched feature docs are missing sections |

All three are prompt-type hooks (Claude evaluates the logic directly). They require no shell scripts, no interpreter, and no per-machine wiring.

## Step 6: Report

Emit a single Markdown report:

```
## Hook Health

| Check | Status | Detail |
|-------|--------|--------|
| Commands linked | PASS/FAIL | ... |
| Plugin registered | PASS/FAIL | ... |
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
- All checks pass + markers active: `Enforcement is active. Edits to uncovered files will be blocked/warned.`
- All checks pass + no markers: `Commands and plugin are working but this repo has not opted into enforcement. Run /project-setup to set up markers.`
- Commands or plugin failed + fixed: `Issues detected and repaired. Restart Claude Code for changes to take effect.`
- Commands or plugin failed + not fixed: `Issues detected. Run install.sh (Mac/Linux) or install.ps1 (Windows) from the claude-rails directory to fix.`

## Do not

- Do not modify any file without asking the user first.
- Do not check for interpreter availability. Hooks are prompt-type handlers evaluated by Claude directly.
- Do not run shell commands beyond read-only filesystem checks (unless the user approves a fix).
