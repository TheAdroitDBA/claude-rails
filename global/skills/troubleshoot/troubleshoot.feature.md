# Feature: Troubleshoot Skill

## What It Does

`/troubleshoot` (`t:`) is the expert error-triage workflow. Docs-first: feature doc and flow doc must exist before any source is read, so every fix is verifiable against a `[BUG]` criterion and every pipeline is protected by a flow doc against future regressions. Forbids retrying identical failed attempts; demands a root-cause statement before any code change.

## Concern

**framework.** Global-pool skill synced to every machine. The bug-tracker path is discovered from the adopted repo at invocation time, not hardcoded.

## Success Criteria

1. Bare `t:` presents the current bug list grouped by severity and lets the user pick one.
2. `t: <desc>` matches `<desc>` against the issue tracker. If no entry exists or the entry has no linked feature docs, the skill chains into the repo's bug-report workflow first and resumes with the new context.
3. The skill reads the feature doc's `[BUG]` criteria BEFORE reading source. If no criterion matches the bug, the skill adds one before proceeding.
4. The skill reads the flow doc for the affected pipeline BEFORE reading source. If none exists, the skill creates it before proceeding.
5. The skill loads relevant memory files before source code.
6. Source code is read LAST, only after docs exist and have been read.
7. Before writing any fix, the skill emits a one-sentence root-cause statement with evidence (log line or code) and the proposed minimum change.
8. The skill maintains a visible retry log. At three failed attempts with no progress, it stops and researches from official documentation or engages a specialist. At four, it asks the user how to proceed and does not guess.
9. After the fix, the skill removes the `[BUG]` tag from the criterion and adds a memory entry if the root cause was surprising. Updates the flow doc if the pipeline changed.
10. [BUG] The skill hardcoded `memory/ydn-issues.md` as the bug tracker path. Only worked on YDN. Resolved 2026-04-21 via global-pool-purity.feature.md -- the skill now discovers the tracker path from the adopted repo's CLAUDE.md or memory/MEMORY.md (a `bug-tracker:` declaration or `## Bug Tracker` section naming a file), and fails loudly with a message pointing at `/project-setup` if no tracker is declared.

## Status

DONE

### Progress

- [x] Criteria 1-9 closed: docs-first, root-cause statement, retry log, flow-doc guarantee.
- [x] Criterion 10 [BUG] -- resolved 2026-04-21: tracker-path discovery replaces the YDN hardcode (global-pool-purity.feature.md).
- [x] NEXT: handoff line -- user runs `sync` on each machine to propagate generalized skill.

## Files

- global/skills/troubleshoot/SKILL.md

## Scope

global/skills/troubleshoot/**

## Honors

- decisions/0006 -- Global-pool skills must discover, not hardcode. Without decision 0006, this feature would look different because the tracker path would have been renamed to a generic default (e.g. `memory/issues.md`) rather than being discovered -- decision 0006 establishes that discovery at invocation time (read the repo's CLAUDE.md) is the durable pattern, not another hardcode with a more neutral name.
