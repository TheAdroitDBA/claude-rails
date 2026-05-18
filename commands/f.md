---
description: Finalize current work. Turns off debug logging, updates the feature doc progress checklist, marks the feature COMPLETE, and reports git status.
---

INDEX-first; fallback to flat if absent.

Finalize the current feature. Work through these steps in order:

1. Turn off any debug logging, verbose flags, or temporary instrumentation added during development.

2. Update the feature doc ### Progress checklist: mark completed items with their commit hashes. Every decision point that happened during implementation should have a progress entry.

3. Mark the feature doc ## Status as COMPLETE.

4. **Move resolved bugs (INDEX present path).** For each bug verifiably fixed by this work:
   - `memory/KNOWN-ISSUES.md`: cut from its `### <area>` subsection in `## Active`, paste into `## Resolved` with ` | resolved: <today's date>`.
   - `memory/BUG-INDEX.md`: move the line from `## Active` to `## Recently Resolved (last 10)`, change `active` to `resolved`, append ` -> <today's date>`.

   The `BUG-NNNN` id stays on the entry forever. Do NOT delete entries.

   **Fallback (INDEX absent):** move from flat `## Active` to flat `## Resolved` with the same date suffix.

5. **Archive overflow.** If `memory/BUG-INDEX.md` `## Recently Resolved` exceeds 10 entries, drop the oldest from INDEX (the full entry remains in KNOWN-ISSUES.md). If `memory/KNOWN-ISSUES.md` `## Resolved` exceeds 10 entries, move the oldest to `memory/KNOWN-ISSUES-ARCHIVE.md` (create the archive file if it does not exist).

6. **Hygiene scan on INDEX (INDEX present path).** Read `memory/BUG-INDEX.md` `## Active`. Flag any entry that is:
   - older than 30 days,
   - whose linked `[BUG-NNNN]` criterion no longer exists in any feature doc, or
   - whose linked criterion's `### Progress` line is checked off (`[x]`) in the feature doc -- the fix shipped but the tracker was never updated. Recommend `/bs` on the entry.

   Report findings inline -- do not block finalization. Do NOT read full KNOWN-ISSUES.md to do this scan; INDEX has every active ID.

   **Fallback (INDEX absent):** same flag rules against flat tracker `## Active`.

7. Run git status and report the current state of the working tree.

8. **Pop the stack.** Drop the last line of `.claude/current-feature` (the slug just finalized). If the file would become empty, delete it instead of leaving a zero-byte file.
   - Shell: `sed '$d' .claude/current-feature > .claude/current-feature.tmp && { [ -s .claude/current-feature.tmp ] && mv .claude/current-feature.tmp .claude/current-feature || rm -f .claude/current-feature .claude/current-feature.tmp; }`
   - PowerShell: `$l = @(Get-Content .claude/current-feature); if ($l.Count -le 1) { Remove-Item .claude/current-feature } else { $l[0..($l.Count-2)] | Set-Content .claude/current-feature }`

   If a line remains after the pop, the parent feature is now active again -- read it and print:
   - `resuming <parent-slug>`
   - the last unchecked progress entry from that parent's feature doc (this is the parent's most recent NEXT/handoff line)

   Do NOT auto-invoke another slash command. The user runs `/w` themselves if they want a full re-orient.
