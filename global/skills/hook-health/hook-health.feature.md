# Feature: Hook Health Skill (Plugin Era)

## What It Does

Provides `/hook-health`, a global-pool skill that verifies claude-config's
enforcement hooks are wired correctly on the current machine in the plugin
era. Reads `~/.claude/settings.local.json`, locates each claude-config hook
command, and checks: (a) the wired path resolves to a real file on disk,
(b) the required interpreter is on PATH, (c) the three canonical enforcement
hooks (`require-feature-doc`, `auto-lint`, `stale-feature-check`) are wired
on their correct events, (d) no OS-mismatched commands (`.sh` on Windows,
`.ps1` on Mac/Linux) and no duplicate wiring across `settings.json` +
`settings.local.json`. Read-only; no writes, no auto-fix.

This feature replaces the original `/hook-health` skill (DONE 2026-04-22)
which was tightly coupled to retired infrastructure: the
`shortcuts-manifest.json` shorthand contract, the `~/.claude/hooks` junction
created by `sync.sh`, and the `tests/shortcuts/` harness. All three were
removed in the plugin-distribution migration (2026-05-04 through 2026-05-06).
The skill needs a structural rewrite, not a string patch -- almost every
check in the original SKILL.md targets infrastructure that no longer exists.

## Concern

**framework.** Global-pool skill discovered by every machine that loads
claude-config via `--plugin-dir`. Works against any clone location by
reading paths out of the user's `settings.local.json` rather than guessing.
No hardcoded absolute paths.

## Dependencies

- `plugin-distribution.feature.md` -- IN PROGRESS, but criteria 8 and 9
  (sync scripts deleted, OS settings overlays deleted) are satisfied. The
  rewrite assumes the post-deletion world.

## Open Design Questions (resolve before criteria approval)

A. **Companion script vs. pure-Markdown skill.** Two implementation paths:
   1. **Companion scripts** (`hook-health.sh`, `hook-health.ps1`) per
      decision 0003 shell/PS parity. The skill invokes the appropriate
      script and parses its output. Familiar pattern; matches the original
      design.
   2. **Pure-Markdown skill.** SKILL.md instructs Claude to read
      `~/.claude/settings.local.json`, walk the hook commands, and run
      `ls`/`which` checks via tool calls. No shell scripts; OS parity is
      free because Claude does the inspection. Simpler and removes the
      "did the harness fire?" failure mode that motivated the original
      hook-health in the first place.
   - Recommendation: option 2 (pure-Markdown). The task is JSON parsing +
     filesystem checks, both of which Claude does cleanly through tool
     calls. The original feature existed to detect a broken hook by
     running an out-of-band harness; in the plugin era, hooks are wired
     via direct paths in settings.local.json -- no junction, no manifest,
     no harness needed. A pure-Markdown skill is the right shape.
   - Decision required from user before implementation.

B. **Scope: enforcement hooks only, or any claude-config hook?** The
   original checked the shorthand-expand hook (now retired). The plugin
   era ships exactly three enforcement hooks (`require-feature-doc`,
   `auto-lint`, `stale-feature-check`) plus an optional `require-flow-doc`.
   Should `/hook-health` audit ANY claude-config hook wired in
   settings.local.json, or specifically these four by name?
   - Recommendation: any claude-config hook (path contains
     `claude-config/global/hooks/`). Keeps the skill robust to the user
     adding new hooks later, and surfaces wiring drift even for hooks the
     skill does not know by name.
   - Decision required.

## Success Criteria

(All criteria below assume design questions A and B are resolved as
recommended -- pure-Markdown skill, audits any claude-config hook. If the
user picks differently the criteria adjust accordingly.)

1. Invocable as `/hook-health` with no arguments. Read-only; the skill
   never writes, fixes, or runs sync. Testable: invoke the skill and
   verify no file under `~/.claude/` or in the claude-config repo is
   modified during execution.

2. The skill reads `~/.claude/settings.local.json` and locates every hook
   command whose `command` string contains `claude-config/global/hooks/`.
   Per-hook the skill records: event name (`PreToolUse`/`PostToolUse`/
   `Stop`/`UserPromptSubmit`), matcher pattern, full command string,
   resolved hook script path. Testable: a known-good
   `settings.local.json` produces the expected per-hook list; an empty
   one produces "no claude-config hooks wired" with remediation pointing
   at README Quick Start step 3.

3. For each located hook command, the skill verifies the script file
   exists on disk by stat'ing the path. PASS if the file is readable;
   FAIL with the missing path. Testable: temporarily rename a hook
   script and re-run -- the skill reports FAIL with the exact missing
   path.

4. For each located hook command, the skill verifies the required
   interpreter is on PATH: `bash` for `.sh` commands, `pwsh` (preferred)
   or `powershell` for `.ps1` commands. PASS if found via `which`/
   `Get-Command`; FAIL with install hint. Testable: simulate by checking
   PATH on a system known to lack `pwsh`; the skill reports the FAIL.

5. The skill checks the three canonical enforcement hooks by name. For
   each of `require-feature-doc`, `auto-lint`, `stale-feature-check`:
   reports MISSING if no hook command in settings.local.json points at
   that script; reports MISWIRED if it is wired on the wrong event
   (`require-feature-doc` must be PreToolUse Edit|Write; `auto-lint`
   must be PostToolUse Edit|Write; `stale-feature-check` must be Stop).
   Testable: a settings file that wires `auto-lint` on PreToolUse
   produces a MISWIRED report.

6. The skill detects OS-mismatched commands: a `.sh` command on Windows
   or a `.ps1` command on Mac/Linux. Reports as FAIL with remediation
   pointing at README Quick Start (use the bash form on Mac/Linux, the
   pwsh form on Windows). Testable: on Linux, a settings file that wires
   a `.ps1` command produces FAIL.

7. The skill detects duplicate wiring across `~/.claude/settings.json`
   and `~/.claude/settings.local.json`. If the same hook script is wired
   in both files, reports WARN: "hook wired in both files; Claude Code
   unions hook arrays and the hook will fire twice". Testable: a
   contrived setup with the same command in both files produces the
   warning.

8. Output structure: a per-check table with columns `Check | Status |
   Detail | Remediation`. Status is one of `PASS`, `FAIL`, `WARN`,
   `MISSING`, `MISWIRED`. Followed by a one-line summary
   (`<N> failures, <M> warnings`) and a final next-action line: "All
   green -- enforcement hooks are wired and reachable" OR "Fix the
   failure(s) above; common fix: re-check ~/.claude/settings.local.json
   against claude-config README Quick Start step 3". The skill never
   self-marks an overall PASS verdict (per MEMORY.md Hard Rule);
   PASS/FAIL on individual checks is objective from filesystem state.

9. The skill honors decision 0006: no hardcoded absolute paths. Every
   path consulted comes from `settings.local.json` content. The repo
   location is not assumed; if the user clones to `/opt/claude-config`
   the skill works the same as if they cloned to `~/claude-config`.

10. The skill stops cleanly when claude-config is not wired at all on
    this machine (settings.local.json is missing, empty, or contains no
    `claude-config/global/hooks/` references). Reports "No claude-config
    hooks detected on this machine. See claude-config README Quick Start
    step 3 to wire enforcement hooks." Does not error or stack-trace.
    Testable: rename `settings.local.json` and re-run; the skill exits
    with the not-wired message.

11. Cross-OS smoke test: run `/hook-health` on at least one Mac/Linux
    machine and one Windows machine (or document via `pwsh` from
    Linux). Both runs produce the expected output structure. Per-OS
    nuances (path separators, interpreter names) are handled by the
    skill's tool-call logic, not by per-OS branches in SKILL.md.

12. Migration: the original SKILL.md's manifest/junction/harness checks
    are deleted, not preserved. The legacy NOTE block added in
    2026-05-06 (acknowledging retired infrastructure) is removed because
    the skill no longer references that infrastructure. Testable:
    `grep -E "shortcuts-manifest|junction|tests/shortcuts" SKILL.md`
    returns no matches.

## Status

IN PROGRESS

### Progress

- [x] 2026-05-06: feature doc rewritten for the plugin era. Original
      DONE feature (sync-era hook-health, 2026-04-22) preserved in the
      narrative under "What It Does" so the rewrite intent is clear.
- [x] 2026-05-06: user approved criteria. Design A resolved as
      pure-Markdown skill (no companion `.sh`/`.ps1`); design B resolved
      as audit-any-claude-config-hook with the four canonical names as
      additional named checks.
- [x] 2026-05-06: SKILL.md rewritten from scratch. Six-step flow:
      read settings.local.json -> enumerate hooks -> per-hook checks
      (file exists, interpreter on PATH, OS match) -> canonical-hook
      checks (require-feature-doc / auto-lint / stale-feature-check) ->
      cross-file duplicate check -> Markdown report. All references to
      retired infrastructure (manifest, junction, harness) are gone;
      `grep -E "shortcuts-manifest|junction|tests/shortcuts" SKILL.md`
      is empty (criterion 12 satisfied).
- [ ] NEXT: smoke-test on this Linux machine -- user invokes
      `/hook-health` in a fresh session and pastes output here so we
      can confirm the report shape against criterion 8 and amend if
      needed.
- [ ] Smoke-test on a Windows machine when one is available.
- [ ] Mark Status DONE.

## BUG Criteria

- **[BUG] criterion 13 -- multi-machine hook wiring is inconsistent and unaudited.** Four machines (work-Windows, home-Windows, home-Linux, home-Mac) each have hooks wired differently: wrong clone paths, stale symlinks, entries in `settings.json` instead of `settings.local.json`, and some wiring outside any repo. No machine has been verified against the canonical Quick Start wiring. Fixed when: (a) each machine's `settings.local.json` contains exactly the three canonical enforcement hooks pointing at that machine's actual clone path, (b) no stale symlinks or junction artifacts remain under `~/.claude/`, and (c) `/hook-health` reports zero failures on all four machines.

## Files

- global/skills/hook-health/SKILL.md (full rewrite)
- global/skills/hook-health/hook-health.feature.md (this file)

## Scope

global/skills/hook-health/**

## Honors

- decisions/0004 -- Two-pool placement. The skill stays in the
  global pool because every machine benefits from a hook-wiring audit.
- decisions/0006 -- Global-pool artifacts must discover, not hardcode.
  Criterion 9 makes path-discovery from settings.local.json load-bearing
  rather than optional.

## Supersedes

The 2026-04-22 sync-era hook-health feature (this same file, prior
content). Original criteria depended on the `~/.claude/hooks` junction,
the `shortcuts-manifest.json` contract, and the `tests/shortcuts/`
harness. All three were retired by plugin-distribution.feature.md. The
original "Honors decisions/0004 + 0006" framing is preserved; criteria
1-10 are rewritten because the underlying infrastructure changed.
