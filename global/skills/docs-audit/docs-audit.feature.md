# Feature: Docs Audit Skill

## What It Does

`/docs-audit` scans every markdown file in the current project for sprawl, staleness, duplication, broken references, and wrong-location files. Produces a categorized report (BROKEN / STALE / DUPLICATE / ORPHANED / OVERSIZED / SPRAWL / HEALTHY) and asks the user before making any changes.

## Concern

**framework.** Global-pool skill synced to every machine's `~/.claude/skills/`. Works on any adopted repo without modification (criterion 1 pins this: uses `git rev-parse --show-toplevel`, no hardcoded paths).

## Success Criteria

1. Uses `git rev-parse --show-toplevel` (or `pwd` as fallback) to find project root -- no hardcoded paths.
2. Scans every `.md` file under the project root, excluding `.git/`, `node_modules/`, `vendor/`, `.build/`, `Pods/`.
3. Detects broken relative links by resolving `[text](path)` targets against each file's directory.
4. Detects stale code references: file:line patterns, function names in backticks, claimed locations that no longer exist.
5. Detects duplication between CLAUDE.md and memory, memory and agent specs, feature docs and memory, and across memory files.
6. Detects orphaned memory files (not indexed in MEMORY.md) and orphaned feature/flow docs (code they describe no longer exists).
7. Flags oversized docs: CLAUDE.md > 150 lines, MEMORY.md > 200 lines (truncation boundary), individual memory files > 100 lines.
8. Flags sprawl: standalone `.md` files in non-standard locations outside `docs/`, `memory/`, `.claude/`.
9. Groups proposed actions as DELETE / MERGE / MOVE / UPDATE / TRIM and asks the user which to execute via a single prompt.
10. Never modifies CLAUDE.md content or rules; only fixes broken file-path references when explicitly approved.
11. Never deletes memory files of `feedback` or `user` types. Borderline cases are flagged as REVIEW rather than DELETE.
12. Re-runs the broken-link check after executing approved actions to confirm the cleanup introduced no new breakage.

## Status

DONE

### Progress

- [x] Criteria 1-12 closed. Skill uses repo-relative detection, produces categorized reports, asks before modifying, never auto-deletes feedback/user memory.
- [x] NEXT: handoff line -- maintenance-only. If a new detection category is added, extend criterion 8 before writing the detection code.

## Files

- global/skills/docs-audit/SKILL.md

## Scope

global/skills/docs-audit/**
