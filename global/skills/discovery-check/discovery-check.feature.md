# Feature: Discovery Check Skill

## What It Does

Provides `/discovery-check`, a lightweight global-pool skill that verifies the discovery cost of the current repo. The skill asks the four canonical orient questions (what is this, what is done, what is broken, what is next) under a 15k-token budget and reports which topic files are missing if the budget is exceeded. Same verification gate used as criterion 7 of `dogfood-compliance.feature.md`, now packaged so any repo — adopted or not — can run it in one invocation rather than from memorized instructions.

## Concern

**framework.** Global-pool skill synced to every machine's `~/.claude/skills/`. Works on any repo with or without claude-config framework scaffolding (criterion 3 pins discovery at invocation; no hardcodes). Every adopted repo benefits automatically.

## Success Criteria

1. **Skill lives at `global/skills/discovery-check/`** with a `SKILL.md` entry point and a sibling `discovery-check.feature.md`. Placement matches decision 0004 (global pool) and decision 0007 (scope-driven: feature doc scope is contained in the skill directory, so it sits there, not at repo root).

2. **Skill asks the four canonical orient questions in exact order:** (a) what is this repo, (b) what is done, (c) what is broken, (d) what is next. The order is pinned because the questions build on each other — done and broken depend on knowing what the repo is, and next depends on knowing what is broken. No reordering, no merging, no optional skipping.

3. **Discovery at invocation.** The skill determines the repo root via `git rev-parse --show-toplevel`. If the command fails (not a git repo), the skill falls back to the current working directory and notes the fallback in its output. No hardcoded paths, no project-name strings, no absolute user paths. Honors decision 0006.

4. **Cold-orient posture enforced.** The SKILL.md explicitly instructs Claude to answer from files read during the invocation only — not from training, not from session memory of prior work in the same repo. If the session has prior context, the skill still asks Claude to re-read and cite source files for each answer.

5. **Token budget check.** Target is under 15k tokens of reads to produce the four answers. The skill instructs Claude to track approximate reads (file sizes consulted) and to report the total at the end of the output. The 15k number matches the MEMORY.md token-waste-signals budget rule in claude-config.

6. **Gap-naming on budget miss.** If reads exceed 15k tokens, the skill asks Claude to identify exactly one specific missing topic file (e.g. `memory/KNOWN-ISSUES.md`, `memory/HOOK-INVENTORY.md`, or a named flow doc) whose presence would have shortened the path. The output must name the file and what it would have contained, not a vague "more docs would help."

7. **PASS/FAIL handoff belongs to the user.** The skill ends with a fixed handoff line stating that the user marks PASS or FAIL, and that Claude does not self-mark per MEMORY.md Hard Rule. The skill never prints "PASS" or "FAIL" itself.

8. **Read-only.** The skill does not write any file, does not propose fixes, does not recommend framework adoption if the repo has not opted in. If the repo has no `memory/`, no feature docs, or no claude-config scaffolding, the skill notes the absence as a finding but does not unilaterally suggest remedies.

9. **No SKILL.md runtime dependency on claude-config filesystem path.** The skill body is a self-contained instruction block. It does not reference `~/claude-config`, `C:\Code\claude-config`, or any path that would only exist on one machine. Honors decision 0006 and framework-portability criterion 10.

10. **Dogfood verification.** Running `/discovery-check` inside claude-config itself produces answers that match the results of criterion 7 in `dogfood-compliance.feature.md`, which the user already PASSED on 2026-04-21. If the skill's output diverges, either the skill is wrong (criterion fails) or the repo state has drifted since the PASS (open a new session and re-audit).

11. **[BUG] Nested-repo scope ambiguity.** Step 1 of SKILL.md used `git rev-parse --show-toplevel` which returns the git root and wrongly expanded the scope in nested project structures. Resolved 2026-04-21 — Step 1 rewritten to anchor scope to the current working directory by design. Git root is now reported for context only; the CWD is the effective scope. Rationale documented in SKILL.md Step 1: the user chose this directory deliberately when they invoked the skill; honoring CWD lets sub-project audits work and in flat repos CWD and git root match so behavior is unchanged.

12. **[BUG] Broken-items tracker location hardcoded to `memory/KNOWN-ISSUES.md`.** The skill read only `memory/KNOWN-ISSUES.md` and produced false-negative "nothing is broken" in adopted repos with alternative tracker locations. Resolved 2026-04-21 — Step 2 Question 3 rewritten to discover the tracker via a four-step lookup: (1) read CLAUDE.md for a declared tracker location and follow the declaration, (2) fall back to `memory/KNOWN-ISSUES.md`, (3) scan feature docs for `[BUG]` markers regardless of the main tracker, (4) report absence-of-tracker as the finding if nothing is declared or found. Honors decision 0006.

13. **[BUG] "What's done" gated by feature-doc coverage.** The skill reported "done" only from DONE/COMPLETE feature docs, invisibly missing pre-adoption working code. Resolved 2026-04-21 — option (b) chosen: Step 2 Question 2 now explicitly labels its output as "documented as done" with a caveat that undocumented working functionality is invisible and must be flagged as a finding. Option (a) — expanding sources to README / CHANGELOG / git log — deferred because it expands the token budget; the labeling change preserves the 15k target while removing the false-negative risk.

14. **[BUG] Scope override partially honored.** Cold sessions read files outside the declared scope when upstream CLAUDE.md referenced them. Resolved 2026-04-21 — SKILL.md "Do not" section strengthened with an explicit prohibition: files outside the CWD scope are never opened, even when an in-scope file points at them; out-of-scope references are recorded as findings ("CLAUDE.md references `X` but that file is outside audit scope") and never read.

## Status

IN PROGRESS

### Progress

- [x] Design discussed in session 2026-04-21; scope and structure confirmed
- [x] Write this feature doc with ten success criteria
- [x] Write SKILL.md as self-contained instruction block
- [x] Pilot 2 cold-session invocation at `C:\Code\infrastructure\minecraft` on 2026-04-21. Budget PASS (13k of 15k target). Four skill weaknesses surfaced; recorded below as criteria 11-14 [BUG].
- [x] Criteria 11-14 all resolved 2026-04-21 in SKILL.md. Step 1 rewritten to anchor scope to CWD (not git root). Step 2 Q3 rewritten with tracker discovery. Step 2 Q2 gains "documented as done" caveat. "Do not" section prohibits out-of-scope reads even when referenced by in-scope files.
- [ ] NEXT: validate the fixes in a fresh cold session. Open Claude Code at a nested path (e.g. `C:\Code\infrastructure\minecraft`), invoke `/discovery-check`, confirm: (a) scope honors CWD not git root, (b) if the repo's CLAUDE.md declares an alternative tracker, the skill reads that tracker, (c) "done" output carries the caveat, (d) out-of-scope references are noted as findings not followed. User marks the four criteria PASS.

## Files

- global/skills/discovery-check/SKILL.md (skill entry point)
- global/skills/discovery-check/discovery-check.feature.md (this file)

## Scope

global/skills/discovery-check/**

## Honors

- decisions/0004 — Two-pool placement. Without 0004, this skill would have no global pool to live in; the two-pool distinction is what makes a framework-wide verification skill possible.
- decisions/0006 — Global-pool skills must discover, not hardcode. Without 0006, criterion 3's discovery-at-invocation would be optional rather than load-bearing; 0006 makes it the default posture.

## Notes

Out of scope for this feature:
- Integration with `/project-setup` (project-setup may invoke `/discovery-check` as a step in a later feature; not required now).
- Automated token counting inside the SKILL.md (Claude Code does not expose token counts mid-session; the skill asks Claude to estimate from file sizes, which is sufficient for the budget gate).
- Per-repo budget overrides. 15k is the framework default. If a repo needs a higher budget, that's a finding to report, not a configuration knob.
- Non-git repo support beyond the current-working-directory fallback in criterion 3.
