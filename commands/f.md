---
description: Finalize current work. Turns off debug logging, updates the feature doc progress checklist, marks the feature COMPLETE, and reports git status.
---

Finalize the current feature. Work through these steps in order:

1. Turn off any debug logging, verbose flags, or temporary instrumentation added during development.

2. Update the feature doc ### Progress checklist: mark completed items with their commit hashes. Every decision point that happened during implementation should have a progress entry.

3. Mark the feature doc ## Status as COMPLETE.

4. Move resolved bugs from **Active** to **Resolved** in the issues tracker (memory/KNOWN-ISSUES.md or the declared tracker). Append ` | resolved: <today's date>` to each entry. The `BUG-NNNN` id stays on the entry forever. Only move entries that are verifiably fixed by this work. Do NOT delete entries.

5. If the **Resolved** section has more than 10 entries, move the oldest resolved entries to `memory/KNOWN-ISSUES-ARCHIVE.md` (create the archive file if it does not exist).

6. Quick tracker hygiene (while the tracker is open): scan **Active** entries. Flag any that are:
   - older than 30 days,
   - whose linked `[BUG-NNNN]` criterion no longer exists in the feature doc, or
   - whose linked criterion's `### Progress` line is checked off (`[x]`) in the feature doc -- the fix shipped but the tracker was never updated. Recommend `/bs` on the entry.

   Report findings inline -- do not block finalization.

7. Run git status and report the current state of the working tree.

8. **Pop the stack.** Drop the last line of `.claude/current-feature` (the slug just finalized). If the file would become empty, delete it instead of leaving a zero-byte file.
   - Shell: `sed '$d' .claude/current-feature > .claude/current-feature.tmp && { [ -s .claude/current-feature.tmp ] && mv .claude/current-feature.tmp .claude/current-feature || rm -f .claude/current-feature .claude/current-feature.tmp; }`
   - PowerShell: `$l = @(Get-Content .claude/current-feature); if ($l.Count -le 1) { Remove-Item .claude/current-feature } else { $l[0..($l.Count-2)] | Set-Content .claude/current-feature }`

   If a line remains after the pop, the parent feature is now active again -- read it and print:
   - `resuming <parent-slug>`
   - the last unchecked progress entry from that parent's feature doc (this is the parent's most recent NEXT/handoff line)

   Do NOT auto-invoke another slash command. The user runs `/w` themselves if they want a full re-orient.
