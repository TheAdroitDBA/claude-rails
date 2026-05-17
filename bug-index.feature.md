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

## Status

NOT STARTED

### Progress

- [x] Phase 0 (2026-05-16): PIVOT from rails-managed-blocks (paused end of Phase 1). Clean tree, no pause commit.
- [ ] Phase 1: write this repo's INDEX from its 1 active bug; migrate this repo's KNOWN-ISSUES.md to sectioned shape.
- [ ] Phase 2: `/migrate-bugs` skill
- [ ] Phase 3-7: update `/b`, `/t`, `/bs`, `/f`+`/fs`, `/w` per criteria 3-9, 13
- [ ] Phase 8: `/project-setup` update (empty INDEX on scaffold)
- [ ] Phase 9: glossary entries
- [ ] Phase 10: self-host smoke -- full pipeline against this repo
- [ ] Phase 11: deploy to user's other adopting repos
- [ ] NEXT: user approves criteria; on approval, begin Phase 1.

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

## Deviation from conventions

- No sibling `*.flow.md` -- surface is slash commands; their `.md` files serve as flow specs.
- `/w` touched here and in rails-managed-blocks Phase 4 -- this feature lands first; rails-managed-blocks' drift-check layers on top.
- Rewrites an existing per-repo data file (KNOWN-ISSUES.md). Mitigated by opt-in migration and INDEX-absent fallback.
