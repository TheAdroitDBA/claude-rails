# Feature: Review Skills Skill

## What It Does

`/review-skills` audits every skill file in a discovered pool (project or global) for token efficiency, correctness, completeness, redundancy with agents, and identifies workflows that deserve a skill but do not have one. Produces a per-skill report with status and suggestions, plus lists of missing skills and agent/skill overlap.

## Concern

**framework.** Global-pool skill synced to every machine. Path discovery uses `git rev-parse --show-toplevel` (project pool) or `$HOME/.claude/` (global pool) -- no absolute user path, no project name.

## Success Criteria

1. For each skill file, the report emits Status (good / needs improvement / needs rewrite), Issues, Suggestions.
2. Token-efficiency evaluation flags bloated instructions, missing backtick command injection, redundant steps, and non-parallelized sequential work.
3. Correctness evaluation verifies command paths, file paths, and pattern matches against the actual project structure.
4. Completeness evaluation checks whether each skill covers its full workflow and handles edge cases and error paths.
5. Redundancy check identifies overlap between a skill and an existing agent; suggests delegation patterns or conversions where appropriate.
6. The report ends with a prioritized list of recommended changes for discussion -- never auto-applied.
7. [BUG] The "What to read" block hardcoded `/Users/jeremyallen/Documents/code/YouDrawNextClean/.claude/skills/*/SKILL.md` -- an absolute Mac path to one specific project. Resolved 2026-04-21 via global-pool-purity.feature.md -- discovery now uses `git rev-parse --show-toplevel` + `.claude/skills/` for project-pool audits and `$HOME/.claude/skills/` for global-pool audits, with no project name baked in.

## Status

DONE

### Progress

- [x] Criteria 1-6 closed.
- [x] Criterion 7 [BUG] -- resolved 2026-04-21: hardcoded Mac YDN path replaced with `git rev-parse --show-toplevel` + `.claude/skills/` discovery and `$HOME/.claude/skills/` fallback (global-pool-purity.feature.md).
- [x] NEXT: handoff line -- user runs `sync` on each machine to propagate generalized skill.

## Files

- global/skills/review-skills/SKILL.md

## Scope

global/skills/review-skills/**

## Honors

- decisions/0006 -- Global-pool skills must discover, not hardcode. Without decision 0006, this feature would look different because the skill would have substituted another absolute path (e.g. the machine's current project) rather than deriving paths from `git rev-parse` and `$HOME` -- decision 0006 establishes that anchors are the right discovery pattern for filesystem work in framework-pool skills.
