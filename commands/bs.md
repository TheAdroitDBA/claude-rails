---
description: Bug success -- cleanup and commit after a bug fix is verified. Moves `[BUG-NNNN]` entries to Resolved, cleans up failed fix attempts, and commits.
argument-hint: <BUG-NNNN>
---

INDEX-first; fallback to flat if absent.

Bug success -- close out the fix cleanly:

1. Remove the `[BUG-NNNN]` tag from the feature doc criterion. Keep the criterion text as a normal passing criterion so the fix is permanently testable. The `BUG-NNNN` ID itself is retired in the tracker (step 2), not reassigned.

2. **Move the entry across both files (INDEX present path).**
   - `memory/KNOWN-ISSUES.md`: cut the entry from its `### <area>` subsection under `## Active`. Paste into `## Resolved` (which stays flat -- no area subsections) with ` | resolved: <today's date>` appended. If the `### <area>` subsection becomes empty, remove the heading.
   - `memory/BUG-INDEX.md`: move the line from `## Active` to `## Recently Resolved (last 10)`. Change `active` to `resolved` and append ` -> <today's date>`.

   The `BUG-NNNN` ID stays on the entry forever (never reused). Do NOT delete the entry.

   **Partial-state safety.** If the first write succeeds and the second fails, report: `partial state: moved in <which file>, failed <which file> -- manual reconciliation required`.

   **Fallback (INDEX absent):** move the entry from `## Active` to `## Resolved` in the flat tracker, appending ` | resolved: <today's date>`.

3. **Trim Recently Resolved to 10 (INDEX present).** If `memory/BUG-INDEX.md` `## Recently Resolved` now has more than 10 entries, archive the oldest by removing it from BUG-INDEX. The full entry remains in `memory/KNOWN-ISSUES.md` `## Resolved` until step 4 archives it from there too.

4. If `memory/KNOWN-ISSUES.md` `## Resolved` has more than 10 entries, move the oldest resolved entries to `memory/KNOWN-ISSUES-ARCHIVE.md` (create the archive file if it does not exist).

5. Dead code cleanup: remove any code from failed fix attempts made during this session.

6. Update flow docs if the fix changed the code path -- a fixed bug often reveals a gap in the flow doc's failure-modes section.

7. If the root cause was surprising or non-obvious: save a feedback memory before the session ends. Capture: (1) the error pattern, (2) the root cause, (3) what to do instead. A workaround without a memory means the next session hits the same wall.

8. Commit with a descriptive message. Include the `BUG-NNNN` id, the feature doc path, and criterion number in the message body.
