# Feature: Startup Audit Skill

## What It Does

`/startup-audit` traces an application's initialization sequence from process entry to fully-interactive, classifies each operation (critical path / required background / deferrable), produces a waterfall timeline, and surfaces specific startup anti-patterns (duplicate work, wrong timing, every-resume work, missing guards, wasted network). Outputs a prioritized fix list with exact code locations.

## Concern

**framework.** Global-pool skill synced to every machine. Criterion 9 pins "no project hardcodes" -- works on any iOS/Android/Swift/Python/web-server codebase with a discoverable entry point.

## Success Criteria

1. Phase 1 identifies every initialization trigger in order: process entry, framework callbacks, first render, fully interactive.
2. Phase 2 produces a per-operation table with columns: Operation, Trigger, Sync/Async, Depends On, Duration, Blocks UI.
3. Phase 3 produces an ASCII waterfall showing actual (not intended) execution order with parallel vs sequential operations marked and the critical path highlighted.
4. Phase 4 scans for at least these anti-pattern categories: duplicate work, wrong timing, every-resume work, missing guards, wasted network. Each finding cites the specific file and function.
5. Phase 5 assigns each finding a priority score combining time cost, frequency, and fix complexity. Sort order: highest value first.
6. Phase 6 groups fixes into Quick Wins / Consolidation / Architecture with exact file, function, before/after, and side-effect notes.
7. The skill reads code, not comments, when reconstructing actual execution. Comments are suspect; code is authoritative.
8. The skill measures from process start to user-interactive, not just "init complete". Background work that blocks UI is on the critical path regardless of how it is labeled.
9. The skill has no project hardcodes. Works on any iOS, Android, Swift, Python, or web-server codebase with a discoverable entry point.

## Status

DONE

### Progress

- [x] All 9 criteria closed. Six-phase pipeline, portable entry-point detection, prioritized fix list.
- [x] NEXT: handoff line -- maintenance-only. New anti-pattern categories require extending criterion 4 first.

## Files

- global/skills/startup-audit/SKILL.md

## Scope

global/skills/startup-audit/**
