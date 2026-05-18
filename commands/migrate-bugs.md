---
description: One-shot conversion of a repo's flat KNOWN-ISSUES.md to the sectioned-by-area shape and generates memory/BUG-INDEX.md. Idempotent -- re-running on a migrated repo no-ops. Run once per repo when adopting the bug-index pattern.
---

Migrate this repo's bug tracker to the sectioned + INDEX format.

INDEX-first; fallback to flat if absent does not apply here -- this skill produces the INDEX.

1. **Locate the tracker.** Discover from CLAUDE.md; fallback `memory/KNOWN-ISSUES.md`. If the tracker file does not exist, report `no tracker -- nothing to migrate` and stop.

2. **Idempotency check.** Read the tracker. If `## Active` already contains one or more `### <area>` subsections AND `memory/BUG-INDEX.md` exists with both `## Active` and `## Recently Resolved (last 10)` headings, report `already migrated -- no changes` and stop. Re-running on a migrated repo MUST be a no-op.

3. **Parse Active entries.** Each entry is a single line starting with `- `. Extract:
   - `BUG-NNNN` if present (search the line for `BUG-\d+`).
   - `area` slug: prefer an explicit `area: <slug>` field in the entry; else derive from the path-like segment after the description; else `uncategorized`. Normalize: lowercase, slash to dash, no spaces.
   - description, created date.

4. **Mint missing IDs.** For entries without `BUG-NNNN`: compute the next available ID using the same algorithm as `/b` step 2 -- `max(existing IDs across tracker + archive + all *.feature.md) + 1`, zero-padded to 4 digits. Assign in document order. IDs are never reused.

5. **Rewrite Active by area.** Group parsed entries by area, alpha-sort the areas, then write the Active section as:
   ```
   ## Active

   ### <area-1>

   - BUG-NNNN | <description> | <created-date>
     Repro: <if known from existing entry, else TBD>
     Evidence: <if known, else TBD>
     First place to look: <if known, else TBD>

   ### <area-2>
   ...
   ```
   Preserve all existing context. If the legacy entry lacked Repro/Evidence/First-place-to-look detail, write `TBD` as a placeholder so the gap is visible. Do NOT fabricate evidence.

6. **Preserve Resolved.** The `## Resolved` section stays flat -- do not subsection it. Copy entries verbatim. If absent, create `## Resolved` with `- (none yet)`.

7. **Generate memory/BUG-INDEX.md.** Format:
   ```
   # Bug Index

   ## Active

   - BUG-NNNN | active | <area> | <description> | <created>

   ## Recently Resolved (last 10)

   - BUG-NNNN | resolved | <area> | <description> | <created> -> <resolved>
   ```
   Sort Active by BUG-NNNN ascending. Recently Resolved: most recent 10 from `## Resolved`, sorted by resolved date descending. Older resolved entries stay in `memory/KNOWN-ISSUES.md` (and archive per `/f` step 5).

8. **Report.** Print: count of entries migrated, count of IDs newly minted (with the range, e.g. `BUG-0003..BUG-0005`), and a one-line note if any entries got `TBD` placeholders so the user knows where to fill in detail.

Do NOT auto-invoke another slash command. The user runs `/w` or `/b` themselves after migration.
