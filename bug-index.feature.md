# Feature: Bug Tracker Index + Area Sections

## What It Does

Restructures the framework's bug tracker for scale. Three problems with today's `memory/KNOWN-ISSUES.md`:

1. **Full-file read on every operation.** `/b` dedup, `/t` fuzzy match, `/w` and `/f` hygiene scans all load the entire tracker. At ~200 active bugs the file is ~50k tokens; routine commands burn tokens reading bugs they do not care about.
2. **No area partitioning.** `/b` dedup compares against every active bug regardless of area. With 200 bugs across 20 areas, 95% of the dedup work is irrelevant.
3. **Bug ID assignment requires scanning every `*.feature.md`.** The algorithm is correct but expensive as the feature-doc surface grows.

This feature introduces a two-file tracker:

- **`memory/BUG-INDEX.md`** -- terse, one-line-per-bug index. Always cheap to read. The fast-scan path for `/b` dedup, `/t` lookup, `/w` surface, and `/f` hygiene.
- **`memory/KNOWN-ISSUES.md`** -- sectioned by `### <area>` for human readability. Full context (Repro, Evidence, First place to look) inline below each bug entry.

Reads default to INDEX. Full-context reads from KNOWN-ISSUES.md only when needed (e.g., `/t` loading repro context for a specific bug, scoped to one `### <area>` subsection). Writes update both files atomically.

A new `/migrate-bugs` skill converts an existing flat `KNOWN-ISSUES.md` to the new shape. Idempotent. Repos that have not migrated keep working -- the new behavior is opt-in by INDEX presence.

## Surface

- `/b <description> [--area <slug>]` -- reads INDEX for dedup + ID assignment (skips the all-feature-docs grep when INDEX is present). With `--area`, writes directly to the area subsection. Without, asks the user. Updates INDEX and KNOWN-ISSUES.md as a pair.
- `/t BUG-NNNN` -- reads INDEX to confirm the bug exists and find its area, then reads only the relevant `### <area>` subsection of KNOWN-ISSUES.md for full context.
- `/bs BUG-NNNN` -- moves the entry from `## Active / ### <area>` to `## Resolved` in KNOWN-ISSUES.md; updates INDEX accordingly; trims to 10 most-recent resolved.
- `/f` and `/fs` -- tracker hygiene scans operate on INDEX, not the full KNOWN-ISSUES.md.
- `/w` -- bug surface comes from INDEX, rendered as `area (N open)` groups.
- `/migrate-bugs` (new) -- one-shot, idempotent conversion of flat KNOWN-ISSUES.md to sectioned + INDEX.
- `/project-setup` -- on scaffolding a new opted-in repo, creates an empty `BUG-INDEX.md` alongside the existing `KNOWN-ISSUES.md`.

## Success Criteria

1. `memory/BUG-INDEX.md` has exactly two sections: `## Active` and `## Recently Resolved (last 10)`. Each entry is one line: `- BUG-NNNN | <status> | <area> | <one-line desc> | <created date>[ -> <resolved date>]`. `<status>` is literally `active` or `resolved`. Resolved entries have the ` -> <resolved date>` suffix.

2. `memory/KNOWN-ISSUES.md` `## Active` section is sub-grouped by `### <area>` headings (one per area, sorted alphabetically). Each bug entry uses the format `- BUG-NNNN | <one-line desc> | criterion: <feature-doc>#<n> | <created date>`. Optional indented context lines may follow: `  Repro: ...`, `  Evidence: ...`, `  First place to look: ...`. `## Resolved` section remains flat (no area subgrouping) for simpler archive trimming.

3. `/b <description>` reads `memory/BUG-INDEX.md` first. ID assignment: `max(extract BUG-NNNN from INDEX) + 1`. Dedup: string-similarity match against INDEX one-liners. If INDEX is absent, falls back to today's all-feature-docs grep behavior with no functional change.

4. `/b --area <slug>` writes the new entry to `## Active / ### <slug>` in KNOWN-ISSUES.md, creating the subsection if absent. Without `--area`, `/b` prompts the user for the area. If the user cannot answer, the entry is written to `### uncategorized` and INDEX records `<area>` as `uncategorized` -- this is recoverable later via `/t` re-categorization.

5. `/b` updates both files atomically: INDEX entry first, then KNOWN-ISSUES entry. On the second write failing, the command reports the partial-write state and instructs the user to manually reconcile. Full transactional rollback is not required for v1 (acceptable failure mode).

6. `/t BUG-NNNN` resolves via INDEX: read INDEX, locate the BUG-NNNN line, extract the area, then read only that `### <area>` subsection of KNOWN-ISSUES.md for full context. If INDEX is absent, falls back to today's grep behavior.

7. `/bs BUG-NNNN` (a) moves the KNOWN-ISSUES entry from `## Active / ### <area>` to `## Resolved` with ` | resolved: <today's date>` appended; (b) updates INDEX: changes the entry's status from `active` to `resolved`, moves it from `## Active` to `## Recently Resolved (last 10)`, appends ` -> <today's date>`; (c) if `## Recently Resolved` then exceeds 10 entries, the oldest is moved to `memory/KNOWN-ISSUES-ARCHIVE.md` (existing archive lifecycle).

8. `/f` and `/fs` tracker hygiene operate on INDEX. Same three flag rules apply: entries older than 30 days; entries whose linked `[BUG-NNNN]` criterion no longer exists in the feature doc; entries whose linked criterion is `[x]` shipped (recommend `/bs`). Hygiene reads INDEX only -- no full-file scan of KNOWN-ISSUES.md.

9. `/w` reads INDEX and renders the bug surface as `### Open bugs` followed by lines `<area> (N open)`. The bug tree is grouped by area; counts come from INDEX. `/w` does not read full KNOWN-ISSUES.md.

10. `/migrate-bugs` (new skill at `commands/migrate-bugs.md`) detects flat-format `KNOWN-ISSUES.md` by the absence of `### <area>` subheadings inside `## Active`. Migration steps: (a) parse each Active entry, extract the `area:` field; (b) rewrite `## Active` with entries grouped under `### <area>` headings (sorted alphabetically); (c) generate `memory/BUG-INDEX.md` from the migrated entries; (d) leave `## Resolved` flat. Idempotent: detects already-migrated state (presence of `### <area>` subheadings) and no-ops with `"already migrated -- nothing to do"`.

11. Repos without `memory/BUG-INDEX.md` continue to function via fallback to today's flat-file behavior across all affected commands. Migration is never forced. `/project-setup` creates an empty `memory/BUG-INDEX.md` (just the two section headings, no entries) for newly scaffolded opted-in repos.

12. `docs/glossary.md` gains entries: `BUG-INDEX file`, `area subsection`. The existing `KNOWN-ISSUES.md` entry is updated to describe the sectioned shape and its relationship to BUG-INDEX. The existing `Bug ID` entry is updated to note that INDEX is now the canonical source for max-ID computation (when present).

13. Each affected command file (`commands/b.md`, `commands/t.md`, `commands/bs.md`, `commands/f.md`, `commands/fs.md`, `commands/w.md`) opens its step list with an "INDEX-first read path; fallback to flat KNOWN-ISSUES.md if INDEX is absent" note, so the dual-mode behavior is visible without reading the whole command.

## Status

NOT STARTED

### Progress

- [x] Phase 0 (2026-05-16): pivot decision recorded -- pushed onto the stack on top of rails-managed-blocks. Justification: user reports active scaling pain in other adopted repos; rails-managed-blocks is paused cleanly at end of Phase 1 with a sharp handoff line. Working tree was clean before push, so no pause commit needed (per `/n` step 2 dirty-tree check).
- [ ] Phase 1: write the worked-example `memory/BUG-INDEX.md` for this repo (1 active bug today; small migration; serves as the canonical sample for criteria 1 and 11). Also migrate this repo's `memory/KNOWN-ISSUES.md` to the sectioned shape per criterion 2.
- [ ] Phase 2: implement `/migrate-bugs` skill at `commands/migrate-bugs.md` (criterion 10).
- [ ] Phase 3: update `commands/b.md` -- INDEX-first read; ID assignment from INDEX; `--area` flag; atomic two-file write (criteria 3-5, 13).
- [ ] Phase 4: update `commands/t.md` -- INDEX-first lookup; area-scoped detail read (criteria 6, 13).
- [ ] Phase 5: update `commands/bs.md` -- two-file move; archive trim (criteria 7, 13).
- [ ] Phase 6: update `commands/f.md` and `commands/fs.md` -- hygiene on INDEX (criteria 8, 13).
- [ ] Phase 7: update `commands/w.md` -- bug surface grouped by area with counts (criteria 9, 13).
- [ ] Phase 8: update `commands/project-setup.md` -- create empty INDEX on scaffold (criterion 11).
- [ ] Phase 9: glossary entries -- BUG-INDEX file, area subsection, updated KNOWN-ISSUES.md and Bug ID entries (criterion 12).
- [ ] Phase 10: self-host verification -- `/b "smoke test"` against this repo to exercise the full pipeline (INDEX update + KNOWN-ISSUES write + `/t BUG-NNNN` lookup + `/bs` close), then run `/migrate-bugs` against this repo to verify the idempotent re-run case.
- [ ] Phase 11: deploy to user's other adopting repos -- run `/migrate-bugs` per repo, verify INDEX generation, verify `/b` / `/t` / `/w` token costs against the prior baseline.
- [ ] NEXT: user reviews + approves 13 success criteria; on approval, begin Phase 1 (write worked-example INDEX from this repo's single active bug + migrate this repo's KNOWN-ISSUES.md to sectioned shape).

## Interrupts: rails-managed-blocks

## Test Plan

Manual smoke test from a clean opted-in repo (covers criteria 3-11). Each step names the criterion it verifies.

1. **Fresh repo bootstrap.** `/project-setup` creates `memory/BUG-INDEX.md` with `## Active` and `## Recently Resolved (last 10)` headings (empty); creates `memory/KNOWN-ISSUES.md` with `## Active` and `## Resolved` headings (empty). (Criteria 1, 11.)
2. **`/b` without --area.** `/b "test bug A"` -- prompts for area, accept `auth`. EXPECT: INDEX line `- BUG-0001 | active | auth | test bug A | 2026-05-16`; KNOWN-ISSUES.md gains `## Active / ### auth` with corresponding entry. (Criteria 3, 4, 5.)
3. **`/b --area` shortcut.** `/b "test bug B" --area billing`. EXPECT: no prompt; INDEX entry `BUG-0002 | active | billing | ...`; KNOWN-ISSUES gains `### billing`. (Criterion 4.)
4. **Dedup detection.** `/b "test bug A"` again. EXPECT: detects existing BUG-0001 via INDEX string match, reports the existing ID, does not mint BUG-0003. (Criterion 3.)
5. **`/t BUG-0001`.** EXPECT: reads INDEX, sees `auth`, reads only the `### auth` subsection of KNOWN-ISSUES.md (verified by Read-tool offset/limit usage matching the area's line range). (Criterion 6.)
6. **`/bs BUG-0001`.** EXPECT: KNOWN-ISSUES entry moves `### auth` -> `## Resolved` with ` | resolved: 2026-05-16`; INDEX entry moves `## Active` -> `## Recently Resolved (last 10)` with ` -> 2026-05-16`. (Criterion 7.)
7. **Archive trim.** Create and resolve 11 bugs in sequence. EXPECT: oldest resolved is moved to `memory/KNOWN-ISSUES-ARCHIVE.md`; INDEX `## Recently Resolved (last 10)` contains exactly 10 entries. (Criterion 7.)
8. **`/w` bug surface.** With 2 open bugs (auth, billing), `/w` reports `### Open bugs` followed by `auth (1 open)` and `billing (1 open)`. No read of KNOWN-ISSUES.md verified via tool-call log. (Criterion 9.)
9. **`/f` hygiene.** Manually edit INDEX to add an entry created 31 days ago (`2026-04-15`). Run `/f`. EXPECT: hygiene flag surfaces the stale entry; the flag references only INDEX data. (Criterion 8.)
10. **`/migrate-bugs` from flat.** Pre-create a flat `KNOWN-ISSUES.md` with 3 entries (each with an `area:` field). Run `/migrate-bugs`. EXPECT: KNOWN-ISSUES.md rewritten with `### auth` / `### billing` / etc.; `BUG-INDEX.md` generated with 3 active-section entries. (Criterion 10.)
11. **Migration idempotency.** Run `/migrate-bugs` again. EXPECT: reports `already migrated -- nothing to do`, no file modifications. (Criterion 10.)
12. **Backward-compat fallback.** Delete `memory/BUG-INDEX.md`. Run `/b "test bug C"`. EXPECT: `/b` falls back to today's all-feature-docs grep; entry is written to KNOWN-ISSUES.md flat-format; no errors; no INDEX is recreated. (Criterion 11.)

## Files

- bug-index.feature.md (this file)
- memory/BUG-INDEX.md (new file shape; the framework's own INDEX gets created in Phase 1 as the worked example)
- memory/KNOWN-ISSUES.md (rewritten in Phase 1 to the sectioned shape; framework's own single active bug is the migration test case)
- commands/b.md (Phase 3)
- commands/t.md (Phase 4)
- commands/bs.md (Phase 5)
- commands/f.md (Phase 6)
- commands/fs.md (Phase 6)
- commands/w.md (Phase 7)
- commands/migrate-bugs.md (Phase 2, new)
- commands/project-setup.md (Phase 8 -- create empty INDEX on scaffold)
- docs/glossary.md (Phase 9)

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

- **No sibling `*.flow.md`.** Same reasoning as stack-anchor-and-bug-ids and rails-managed-blocks: the surface is slash commands; their `.md` files are their own flow specs. The framework has no per-command flow-doc pattern today.
- **`/w` is touched here AND in rails-managed-blocks Phase 4 (the drift-check addition).** Coordination: this feature ships first (PIVOT priority). When the stack pops back to rails-managed-blocks, its Phase 4 layers a drift-check call on top of this feature's INDEX-based `/w` rendering. Both changes are additive and compose cleanly -- the drift check is one line of output, independent of bug-surface rendering.
- **Migrating a per-repo data file (`memory/KNOWN-ISSUES.md`) is unusual for the framework.** Most framework changes are additive and leave existing files alone. This one rewrites the shape of an existing per-repo data file. Two safeguards: `/migrate-bugs` is opt-in (user runs it explicitly per repo, never automatic); the new commands fall back gracefully if INDEX is absent (criterion 11), so un-migrated repos keep working indefinitely.
