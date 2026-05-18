# Feature: Bug Tracker Index + Area Sections

## What It Does

Adds `memory/BUG-INDEX.md` (terse one-line-per-bug index) alongside a sectioned `memory/KNOWN-ISSUES.md` (`### <area>` subsections inside `## Active`). Reads default to INDEX; full-context reads from KNOWN-ISSUES.md are area-scoped only. Eliminates full-file reads on every `/b`, `/t`, `/w`, `/f` -- critical above ~50 active bugs. New `/migrate-bugs` skill converts existing flat trackers; idempotent. Repos without INDEX keep working via fallback to today's flat-file behavior.

## Surface

- `/b <desc> [--area <slug>]` -- INDEX-first dedup + ID; writes both files
- `/t BUG-NNNN` -- INDEX lookup then area-scoped detail read
- `/bs BUG-NNNN` -- move entry + INDEX update + archive trim at 10
- `/f`, `/fs` -- hygiene scans on INDEX
- `/w` -- bug surface from INDEX, grouped by area with counts
- `/migrate-bugs` (new) -- one-shot flat -> sectioned conversion
- `/project-setup` -- creates empty INDEX for new opted-in repos

## Success Criteria

1. `memory/BUG-INDEX.md` format: `## Active` and `## Recently Resolved (last 10)`. Entry: `- BUG-NNNN | <active|resolved> | <area> | <desc> | <created>[ -> <resolved>]`.
2. `memory/KNOWN-ISSUES.md` `## Active` sub-grouped by `### <area>` (alpha-sorted). Entries carry inline `Repro:`, `Evidence:`, `First place to look:` lines. `## Resolved` stays flat.
3. `/b` reads INDEX for dedup + ID. INDEX absent -> fallback to today's grep unchanged.
4. `/b --area <slug>` writes to `### <slug>`. Without `--area`, prompts; unanswered -> `### uncategorized`.
5. `/b` updates both files; second-write failure reports partial state for manual cleanup.
6. `/t BUG-NNNN` resolves via INDEX, reads only the `### <area>` subsection. INDEX absent -> fallback unchanged.
7. `/bs BUG-NNNN` moves entry across both files; trims INDEX `## Recently Resolved` to 10 by archiving the oldest.
8. `/f` and `/fs` hygiene operate on INDEX. Same three flag rules (age 30d, missing criterion, criterion shipped).
9. `/w` bug surface from INDEX as `<area> (N open)`. No KNOWN-ISSUES.md read.
10. `/migrate-bugs` detects flat format, rewrites Active by area, generates INDEX. Idempotent: re-run on migrated repo no-ops.
11. Repos without INDEX continue via fallback. `/project-setup` creates empty INDEX (two headings, no entries) for new repos.
12. `docs/glossary.md` adds `BUG-INDEX file`, `area subsection`; updates `KNOWN-ISSUES.md` and `Bug ID` entries.
13. Each affected command file opens with a one-line "INDEX-first; fallback to flat if absent" note.
14. ~~CLAUDE.md "Development Principles"~~ -> MEMORY.md "Development Principles" adds a "Capture ideas before context shifts" entry (same shape as "Learn from failures"): when a design discussion produces future work, run `/i` before moving on -- capture is the cost of moving on, not a permission gate. Reason: the Development Principles section lives in MEMORY.md, not CLAUDE.md. (Progress 2026-05-17)

## Status

COMPLETE

### Progress

- [x] Phase 0 (2026-05-16): PIVOT from rails-managed-blocks (paused end of Phase 1). Clean tree, no pause commit.
- [x] Phase 1 (2026-05-17): wrote memory/BUG-INDEX.md (BUG-0001 minted from existing entry); migrated memory/KNOWN-ISSUES.md to sectioned shape with `### project-setup` subsection and Repro/Evidence/First-place-to-look lines.
- [x] Phase 2 (2026-05-17): created commands/migrate-bugs.md -- idempotent flat-to-sectioned conversion, mints missing IDs, generates BUG-INDEX, preserves Resolved flat.
- [x] Phase 3 (2026-05-17): updated commands/b.md -- INDEX-first dedup + ID, --area flag with prompt fallback, dual-write with partial-state error, INDEX-absent fallback to flat behavior. Criteria 3, 4, 5, 13.
- [x] Phase 4 (2026-05-17): updated commands/t.md -- INDEX lookup for ID or description, then read only the matched `### <area>` subsection. Fallback unchanged. Criteria 6, 13.
- [x] Phase 5 (2026-05-17): updated commands/bs.md -- dual-file move with partial-state safety, trim INDEX Recently Resolved to 10, fallback to flat. Criteria 7, 13.
- [x] Phase 6 (2026-05-17): updated commands/f.md and commands/fs.md -- hygiene scan operates on INDEX, dual-file resolve move, archive overflow trim. Criteria 8, 13.
- [x] Phase 7 (2026-05-17): updated commands/w.md -- bug surface from INDEX as `<area> (N open)`, no full KNOWN-ISSUES read, lifecycle scan on INDEX. Criteria 9, 13.
- [x] Phase 8 (2026-05-17): updated commands/project-setup.md -- step 6h creates empty BUG-INDEX.md alongside KNOWN-ISSUES.md on scaffold. Criterion 11.
- [x] Phase 9 (2026-05-17): updated docs/glossary.md -- added BUG-INDEX file, area subsection, KNOWN-ISSUES.md entries; updated Bug ID to reference both surfaces. Criterion 12.
- [x] Phase 10 (2026-05-17): updated MEMORY.md (reconciled from CLAUDE.md per Hard Rule 6) -- added "Capture ideas before context shifts" to Development Principles. Criterion 14.
- [x] Phase 11 (2026-05-17): self-host smoke -- all 7 affected commands carry the INDEX-first note; BUG-INDEX + KNOWN-ISSUES agree on BUG-0001; INDEX has required two headings; KNOWN-ISSUES has `### project-setup` subsection; /migrate-bugs idempotency holds.
- [ ] Phase 12 (out of session scope): deploy to user's other adopting repos -- requires running /migrate-bugs in each repo on next visit.
- [ ] NEXT: on next visit to each adopting repo, run `/migrate-bugs` once. Then pick up `features-index` from IDEAS.md as the next feature.

## Interrupts: rails-managed-blocks

## Test Plan

Smoke recipe; each step names the criterion verified.

1. Fresh `/project-setup` -> empty INDEX + empty KNOWN-ISSUES with section headings. (1, 11)
2. `/b "A"` prompts area=`auth`. INDEX gets BUG-0001; KNOWN-ISSUES gets `### auth`. (3-5)
3. `/b "B" --area billing` no prompt; BUG-0002; `### billing`. (4)
4. `/b "A"` again -- dedup via INDEX, returns BUG-0001, no mint. (3)
5. `/t BUG-0001` reads INDEX then only `### auth` subsection. (6)
6. `/bs BUG-0001` moves entry to Resolved in both files; INDEX gets ` -> <date>`. (7)
7. Resolve 11 -> oldest archives; INDEX `## Recently Resolved` shows 10. (7)
8. `/w` reports `auth (0 open)`, `billing (1 open)` from INDEX only. (9)
9. `/migrate-bugs` on a flat fixture rewrites to sectioned + generates INDEX. Re-run no-ops. (10)
10. Backward compat: delete INDEX, `/b "C"` falls back to grep, writes flat-format. (11)

## Files

- bug-index.feature.md
- memory/BUG-INDEX.md (new file shape; this repo's own created Phase 1)
- memory/KNOWN-ISSUES.md (Phase 1 migration)
- commands/b.md, t.md, bs.md, f.md, fs.md, w.md
- commands/migrate-bugs.md (new)
- commands/project-setup.md
- docs/glossary.md
- MEMORY.md (criterion 14 principle)

## Scope

bug-index.feature.md
memory/BUG-INDEX.md
memory/KNOWN-ISSUES.md
commands/b.md
commands/t.md
commands/bs.md
commands/f.md
commands/fs.md
commands/w.md
commands/migrate-bugs.md
commands/project-setup.md
docs/glossary.md
MEMORY.md

## Deviation from conventions

- No sibling `*.flow.md` -- surface is slash commands; their `.md` files serve as flow specs.
- `/w` touched here and in rails-managed-blocks Phase 4 -- this feature lands first; rails-managed-blocks' drift-check layers on top.
- Rewrites an existing per-repo data file (KNOWN-ISSUES.md). Mitigated by opt-in migration and INDEX-absent fallback.
