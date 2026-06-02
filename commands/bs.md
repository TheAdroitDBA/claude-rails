---
description: Bug success -- cleanup and commit after a bug fix is verified. Moves `[BUG-NNNN]` entries to Resolved, cleans up failed fix attempts, and commits.
argument-hint: <BUG-NNNN>
---

INDEX-first; fallback to flat if absent.

Bug success -- close out the fix cleanly:

1. Remove the `[BUG-NNNN]` tag from the feature doc criterion. Keep the criterion text as a normal passing criterion so the fix is permanently testable. The `BUG-NNNN` ID itself is retired in the tracker (step 2), not reassigned.

2. **Move the entry directly to archive + update INDEX (INDEX present path).**
   - `memory/KNOWN-ISSUES.md`: cut the entry from its `### <area>` subsection under `## Active`. **Do NOT paste into `## Resolved`.** Closed-bug prose in KNOWN-ISSUES.md is dead weight on every full read of the file -- skip the staging step. If the `### <area>` subsection becomes empty, remove the heading.
   - `memory/KNOWN-ISSUES-ARCHIVE.md`: append the cut entry to the end (archive is oldest-first; new closures go at the bottom). Add ` | resolved: <today's date>` to the entry header. Create the archive file if it does not exist.
   - `memory/BUG-INDEX.md`: move the line from `## Active` to `## Recently Resolved (last 10)`. Change `active` to `resolved` and append ` -> <today's date>`. This INDEX line is the operationally-useful quick-reference; the prose lives in archive.

   The `BUG-NNNN` ID stays on the entry forever (never reused). Do NOT delete the entry.

   **Partial-state safety.** If any of the three writes fails after an earlier one succeeded, report: `partial state: completed <which files>, failed <which file> -- manual reconciliation required`. Order the writes so the archive append happens before the KNOWN-ISSUES.md cut -- a successful archive write is durable even if the cut fails, while the reverse strands prose with no destination.

   **Fallback (INDEX absent):** move the entry from `## Active` directly to `memory/KNOWN-ISSUES-ARCHIVE.md` (not `## Resolved`), appending ` | resolved: <today's date>`. Same rationale: avoid letting `## Resolved` accumulate.

3. **Trim Recently Resolved to 10 (INDEX present).** If `memory/BUG-INDEX.md` `## Recently Resolved` now has more than 10 entries, drop the oldest line from BUG-INDEX. Its prose is already in archive; no additional archive write needed at this step.

5. Dead code cleanup: remove any code from failed fix attempts made during this session.

6. Update flow docs if the fix changed the code path -- a fixed bug often reveals a gap in the flow doc's failure-modes section.

7. If the root cause was surprising or non-obvious: save a feedback memory before the session ends. Capture: (1) the error pattern, (2) the root cause, (3) what to do instead. A workaround without a memory means the next session hits the same wall.

8. Commit with a descriptive message. Include the `BUG-NNNN` id, the feature doc path, and criterion number in the message body.
