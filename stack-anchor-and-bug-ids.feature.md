# Feature: Stack Anchor and Bug IDs

## What It Does

Three coupled framework upgrades that close known gaps in the session-lifecycle and bug-tracking model:

1. **Stack-shaped `.claude/current-feature`.** The anchor file becomes LIFO instead of scalar: append-on-push, pop-on-close, last line is the active feature. Survives interrupt pivots (blocker mid-feature) without losing parent context. Backward compatible -- existing single-line files are valid depth-1 stacks.

2. **Pivot protocol in the fix-or-record rule.** Adds a PIVOT case for blockers too large for inline fixes, and collapses the previously redundant "blocking+small" and "small+same-file" cases (both = fix inline) into a single FIX INLINE case. Net result: a clean three-way (FIX INLINE / RECORD / PIVOT). Sequence: tag the parent's blocked criterion with `[BLOCKED BY BUG-NNNN]`, commit a pause snapshot, `/n` the blocker. Resumes the parent automatically when `/f` or `/fs` pops the stack.

3. **Stable bug IDs.** `/b` assigns `BUG-NNNN` (zero-padded, globally unique, never reused) at creation time. ID appears in the tracker entry, the `[BUG-NNNN]` criterion tag in the feature doc, and any `[BLOCKED BY BUG-NNNN]` pivot reference. `/t` accepts the ID directly. One greppable token everywhere.

`/w` is extended to read the stack as an array and render a tree view: each frame nested by stack depth, followed by its unchecked-progress tail.

## Surface

- `/n` -- before push, requires clean tree; if dirty, creates a pause commit. Appends new slug. Writes `## Interrupts: <parent-slug>` in the child feature doc when stack depth was non-zero at push time.
- `/f` and `/fs` -- pop the last line of `.claude/current-feature`. If stack is non-empty after pop, print the new top-of-stack slug and its last unchecked progress entry.
- `/b` -- assigns `BUG-NNNN` at creation, threads it through the tracker entry and the feature doc criterion tag.
- `/t` -- accepts `BUG-NNNN` as `$ARGUMENTS` and resolves to the tracker entry by exact match.
- `/w` -- renders the stack hierarchically, each frame followed by its unchecked-progress tail.

## Success Criteria

1. `.claude/current-feature` is a multi-line file; the last line is the active feature.
2. `/n` appends a new slug. If the working tree is dirty before push, a pause commit is created first using the repo's established commit-message prefix (or `pause:` if none is established).
3. `/n` writes `## Interrupts: <parent-slug>` into the child feature doc when stack depth was non-zero at push time.
4. `/f` and `/fs` pop the last line of `.claude/current-feature`. If the stack is non-empty after pop, the command prints the new top-of-stack slug and that parent's last unchecked progress entry. Neither command auto-invokes another slash command.
5. Bugs created by `/b` receive an ID of form `BUG-NNNN`, zero-padded to 4 digits, computed as `max(existing IDs across the active tracker + memory/KNOWN-ISSUES-ARCHIVE.md + all *.feature.md) + 1`. The feature-doc sweep catches IDs that were stamped on a criterion tag even if the tracker entry was lost or never written. IDs are never reused, even after resolution.
6. The `[BUG]` criterion tag in feature docs becomes `[BUG-NNNN]`; the tracker entry begins with the same ID. Tracker line format: `- BUG-NNNN | <description> | area: <feature> | criterion: <feature-doc#criterion-number> | <date>`.
7. `/t` accepts `BUG-NNNN` as its argument and resolves directly to the tracker entry by exact match, bypassing fuzzy matching.
8. `[BLOCKED BY BUG-NNNN]` is documented in `conventions/feature-conventions.md` and used by the PIVOT case in the fix-or-record rule.
9. `/w` reads `.claude/current-feature` as an array and renders a tree: stack frames nested by stack depth, each frame followed by its unchecked-progress tail.
10. ~~MEMORY.md fix-or-record rule has a 4th case (PIVOT) with the pause-commit + tag + push sequence.~~ -> MEMORY.md fix-or-record rule is a clean three-way (FIX INLINE / RECORD / PIVOT); PIVOT carries the pause-commit + tag + push sequence. Reason: original framing redundantly split the inline-fix case in two; collapsed during alignment-pass cleanup. (Progress 2026-05-16)
11. Existing single-line `.claude/current-feature` files continue to work as depth-1 stacks. No migration step required.
12. `docs/glossary.md` `current-feature pointer` entry is updated to describe stack semantics; a new `Bug ID` entry is added.
13. `README.md` and the relevant `templates/project-setup/*.md` files describe the stack semantics for the anchor.

## Status

COMPLETE

### Progress

- [x] Phase 0: decisions captured -- pause-commit prefix is `chore(pause): <feature> blocked by <bug-id>` (matches repo's Conventional Commits trend in git log); `## Interrupts: <parent-slug>` section in child feature docs = YES; anchor pointer set to `stack-anchor-and-bug-ids` in `.claude/current-feature`
- [x] Phase 2: MEMORY.md edits -- Hard Rules 7 (stack semantics) and 8 (Bug ID) added; Session Lifecycle steps 1+5 updated; fix-or-record rule expanded to 4 cases including PIVOT
- [x] Phase 3a: commands/n.md -- stack pre-flight (step 2) checks clean tree, creates `chore(pause):` commit if dirty; step 7 writes `## Interrupts: <parent-slug>` on PIVOT; step 13 appends slug to stack (cross-platform shell + PowerShell)
- [x] Phase 3b: commands/f.md (new step 8) and commands/fs.md (new step 12) pop the stack, print resume info; fs.md cross-checks `## Interrupts:` against the new top-of-stack
- [x] Phase 3c: commands/b.md -- step 2 assigns BUG-NNNN via grep across tracker+archive+all *.feature.md; tracker entry format updated; criterion tag becomes `[BUG-NNNN]`
- [x] Phase 3d: commands/t.md accepts `BUG-NNNN` as exact-match argument (regex `BUG-\d{4}`) bypassing fuzzy matching
- [x] Phase 3e: commands/w.md -- step 1 reads stack as array, renders tree with indented frames + each frame's unchecked-progress tail; bs.md updated for ID retention semantics
- [x] Phase 4a: conventions/feature-conventions.md -- new sections "Bug IDs" (assignment algorithm) and "Interrupt tags" (`[BLOCKED BY BUG-NNNN]` + `## Interrupts:`)
- [x] Phase 4b: docs/glossary.md -- current-feature pointer entry rewritten for stack semantics; added entries for stack frame, PIVOT, pause commit, Bug ID, interrupt tag; fix-or-record rule entry updated to four-way
- [x] Phase 4c: README.md step 4 + templates/project-setup/{claude-md.md, readme.md, quick-next-steps.md} describe stack semantics with cross-platform examples
- [x] Phase 4d: commands/project-setup.md uses `tail -n 1` for active slug and reports stack depth; commands/discovery-check.md reads last line for "What is next"
- [x] Phase 5: verify -- grep BUG- shows no stray non-padded IDs (only `BUG-NNNN`/`BUG-\d{4}`/`BUG-[0-9]+` regexes); remaining `[BUG]` references are intentional (CHANGELOG history + this feature doc's migration-description criterion); stack file smoke-test: depth 1, last line = `stack-anchor-and-bug-ids`, backward-compat PASS
- [x] Phase 6: alignment cleanup (2026-05-16) -- `/n` step 13 made idempotent via last-line dedup (Hard Rule 3 gap closed); `/f` step 8 and `/fs` step 12 received explicit shell + PowerShell pop scripts (no more "truncate the last line" prose); fix-or-record collapsed from four cases to clean three-way (FIX INLINE / RECORD / PIVOT) in MEMORY.md, docs/glossary.md, templates/project-setup/claude-md.md; criterion 10 reconciled per strikethrough convention; criterion 5 reconciled earlier to match `commands/b.md` impl scope (tracker + archive + all *.feature.md); added `## Test Plan` smoke-test recipe covering criteria 1-5, 7, 11
- [x] User approved all 13 criteria as IMPLEMENTED (2026-05-16). Stack popped (depth 1 -> 0; anchor file deleted). `/n rails-managed-blocks` is now unblocked.

## Test Plan

Manual smoke test from a clean state in any repo with `.claude/feature-doc-required`. Covers criteria 1-5, 7, 11.

1. **Push (depth 0 -> 1).** `rm -f .claude/current-feature`, then `/n foo`. EXPECT: `.claude/current-feature` contains one line `foo`. (Criteria 1, 2.)
2. **Idempotent re-push.** Run `/n foo` again immediately. EXPECT: file still has one line `foo` -- the push is a no-op, not duplicated. (Hard Rule 3, criterion 2.)
3. **Pivot push (depth 1 -> 2) with dirty tree.** Modify a tracked file so `git status --porcelain` returns output. Run `/n bar`. EXPECT: a `chore(pause): foo blocked by bar` commit appears in `git log`; stack reads `foo\nbar`; `bar.feature.md` contains a `## Interrupts: foo` section. (Criteria 2, 3.)
4. **Pop (depth 2 -> 1).** Close `bar` with `/fs`. EXPECT: stack reads `foo`; command output mentions `resuming foo` and surfaces `foo`'s last unchecked progress entry. (Criterion 4.)
5. **Pop to empty (depth 1 -> 0).** Close `foo` with `/fs`. EXPECT: `.claude/current-feature` is deleted entirely, not left as a zero-byte file. (Criterion 4.)
6. **Backward compatibility.** `printf 'legacy' > .claude/current-feature` (no trailing newline). Run `/w`. EXPECT: tree renders `legacy [active]` with no errors -- a single-line file is a valid depth-1 stack. (Criterion 11.)
7. **Bug ID uniqueness.** From a clean tracker: `/b "test bug A"` -> EXPECT `BUG-0001`. `/b "test bug B"` -> EXPECT `BUG-0002`. Resolve both via `/bs`. `/b "test bug C"` -> EXPECT `BUG-0003` (never reuses 0001). (Criterion 5.)
8. **Exact-match `/t`.** Run `/t BUG-0002`. EXPECT: resolves directly to the BUG-0002 tracker entry, bypassing fuzzy match. (Criterion 7.)

## Files

- stack-anchor-and-bug-ids.feature.md (this file)
- MEMORY.md (Hard Rules, Session Lifecycle, fix-or-record rule)
- commands/n.md, commands/f.md, commands/fs.md, commands/b.md, commands/t.md, commands/w.md
- commands/project-setup.md, commands/discovery-check.md (audit for last-line reads)
- conventions/feature-conventions.md (Bug IDs + Interrupt tags sections)
- docs/glossary.md (current-feature pointer update, Bug ID entry)
- README.md (stack semantics mention)
- templates/project-setup/claude-md.md, readme.md, quick-next-steps.md (stack semantics)

## Scope

MEMORY.md
README.md
commands/**
conventions/feature-conventions.md
docs/glossary.md
templates/project-setup/**
stack-anchor-and-bug-ids.feature.md

## Deviation from conventions

- **No sibling `*.flow.md`.** This feature's surface is six slash commands; the command `.md` files in `commands/` serve as their own flow specs. The repo has no per-command flow-doc pattern today (only `global/hooks/hook-lifecycle.flow.md`). Introducing per-command flow docs is its own scope and would balloon this feature.
