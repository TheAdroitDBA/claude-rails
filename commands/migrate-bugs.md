---
description: Bring this repo's bug tracker into compliance with claude-rails. Audits the current tracker shape, proposes an explicit migration plan including renames and deletions, asks for confirmation, then executes. Idempotent. Run once per adopting repo.
---

Bring this repo's bug tracker into claude-rails compliance.

Target shape:
- `memory/BUG-INDEX.md` -- terse one-line-per-bug index with `## Active` and `## Recently Resolved (last 10)`.
- `memory/KNOWN-ISSUES.md` -- `## Active` sub-grouped by `### <area>` subsections (alpha-sorted), each entry carrying `Repro:`, `Evidence:`, `First place to look:` lines. `## Resolved` stays flat.

This skill never executes without confirmation. It works as audit -> propose -> confirm -> execute.

## Step 1: Audit current state

Read these files if they exist; record what was found:

1. `memory/KNOWN-ISSUES.md`:
   - **Active heading**: `## Active`, `## Current`, `## Open`, or other. Note the exact heading found.
   - **Active entries**: classify each line that starts with `- ` directly under the active heading:
     - **real bug**: has `BUG-NNNN` id, or has an `area:` field, or fits `<description> | ... | <date>` shape.
     - **prose tracking note**: free-form paragraph; no BUG id, no structured fields, no date.
     - **placeholder**: `- (none yet)` and equivalents.
   - **Resolved section**: present? heading exact text? entries count?
   - **Boilerplate sections**: any extra headings like `## How to use`, `## How to Use This File`, `## Format`. Note them; they are usually harmless and preserved.

2. `memory/BUG-INDEX.md`:
   - Exists with both `## Active` and `## Recently Resolved (last 10)` headings? -> already partially compliant.
   - Missing -> will be created.

3. `memory/KNOWN-ISSUES-ARCHIVE.md`:
   - Exists -> never touch it. Note presence in the audit.

## Step 2: Idempotency short-circuit

If ALL of the following hold, report `already compliant -- no changes` and stop:
- `memory/KNOWN-ISSUES.md` has `## Active` (exact heading) AND at least one `### <area>` subsection under it (or `- (none yet)` placeholder).
- `memory/KNOWN-ISSUES.md` has `## Resolved` section.
- `memory/BUG-INDEX.md` exists with both required headings.

Re-running on a compliant repo MUST be a no-op.

## Step 3: Propose plan

Print an audit summary followed by a numbered change list. Use this shape:

```
=== Audit ===
memory/KNOWN-ISSUES.md         found
  Active heading:              ## Current  (will rename -> ## Active)
  Active entries:               1 real bug, 2 prose notes, 0 placeholders
  Resolved section:             missing (will add)
  Boilerplate:                  "## How to Use This File" (will preserve)
memory/BUG-INDEX.md             missing (will create)
memory/KNOWN-ISSUES-ARCHIVE.md  exists (will not touch)

=== Proposed changes ===
1. Rename heading: ## Current -> ## Active
2. Restructure ## Active to sectioned shape:
   - BUG-0001 (porky boot) -> ### porky-boot
3. Move 2 prose entries -- they are not bugs. Options per entry:
   (a) memory/MEMORY.md topic file
   (b) new memory/TECH-DEBT.md
   (c) convert to a bug (mint BUG-NNNN)
   (d) delete
4. Add ## Resolved section with `- (none yet)`
5. Create memory/BUG-INDEX.md with BUG-0001 in ## Active

=== Items requiring per-entry decision ===
Prose entry 1: "homelab-recovery-usb.flow.md still hand-authored..."
Prose entry 2: "MediaVortex not enrolled in flow-doc generation..."

=== Items to delete ===
(none in this run)

Confirm plan? (yes / no / change <number>)
```

The audit columns align so the user can scan it. The proposed-changes list is numbered so the user can override individual steps. The decisions block lists every per-entry choice; do not assume defaults.

## Step 4: Resolve decisions

For each prose entry, ask the user which destination (a/b/c/d). For (c), mint a `BUG-NNNN` using the same algorithm as `/b` step 3: `max(existing IDs across tracker + archive + all *.feature.md) + 1`, zero-padded.

If the user picks (d) delete: confirm again ("delete <one-line preview>? yes/no") -- destruction requires explicit double-confirm.

## Step 5: Execute

Only after confirmation. Apply changes in order:

1. **Rename headings.** Edit `memory/KNOWN-ISSUES.md` in place. Use `Edit` tool, not rewriting the whole file.

2. **Restructure Active.** For each real bug, place under `### <area>` subsection. Alpha-sort the subsections. Add `Repro:`, `Evidence:`, `First place to look:` lines below each entry; write `TBD` as placeholder if the legacy entry lacked detail. Never fabricate evidence.

3. **Handle prose entries** per the user's per-entry decision from step 4.

4. **Add ## Resolved section** if missing. Use `- (none yet)` for empty.

5. **Create memory/BUG-INDEX.md** with one line per real bug (sorted by BUG-NNNN ascending) and an empty `## Recently Resolved (last 10)`.

6. **Partial-state safety.** If any file write fails mid-execution, report what completed and what is pending. Do not retry automatically; the user resolves manually before re-running.

## Step 6: Verify

Re-run Step 2 (idempotency check). All three conditions must now pass. If any fails, report which and why.

## Step 7: Report

Print: count of bugs migrated, count of IDs newly minted (with range, e.g. `BUG-0003..BUG-0005`), count of prose entries relocated (with destinations), count of items deleted, count of `TBD` placeholders requiring user follow-up.

## Empty-tracker scaffold

If `memory/KNOWN-ISSUES.md` does NOT exist at all:
- Offer to scaffold the empty pair (same shape as `/project-setup` step 6h).
- Confirm with user before creating; some repos intentionally have no tracker.
- If confirmed, write both files with the empty skeleton (`## Active` and `## Resolved` with `- (none yet)`; `## Active` and `## Recently Resolved (last 10)` for INDEX).

## Notes

- Never `rm` the tracker file. Edits are in-place.
- Archive file is never touched.
- Re-running is always safe (Step 2 short-circuits compliant repos).
- The skill is read-mostly until Step 5. The user can cancel at any prompt without partial damage.

Do NOT auto-invoke another slash command. The user runs `/w` or `/b` themselves after migration completes.
