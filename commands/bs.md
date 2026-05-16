---
description: Bug success -- cleanup and commit after a bug fix is verified. Moves `[BUG-NNNN]` entries to Resolved, cleans up failed fix attempts, and commits.
---

Bug success -- close out the fix cleanly:

1. Remove the `[BUG-NNNN]` tag from the feature doc criterion. Keep the criterion text as a normal passing criterion so the fix is permanently testable. The `BUG-NNNN` ID itself is retired in the tracker (step 2), not reassigned.

2. Move the bug entry from **Active** to **Resolved** in the issues tracker (memory/KNOWN-ISSUES.md or declared tracker). Append ` | resolved: <today's date>` to the entry. The `BUG-NNNN` ID stays on the entry forever (never reused). Do NOT delete the entry.

3. If the **Resolved** section has more than 10 entries, move the oldest resolved entries to `memory/KNOWN-ISSUES-ARCHIVE.md` (create the archive file if it does not exist).

4. Dead code cleanup: remove any code from failed fix attempts made during this session.

5. Update flow docs if the fix changed the code path -- a fixed bug often reveals a gap in the flow doc's failure-modes section.

6. If the root cause was surprising or non-obvious: save a feedback memory before the session ends. Capture: (1) the error pattern, (2) the root cause, (3) what to do instead. A workaround without a memory means the next session hits the same wall.

7. Commit with a descriptive message. Include the `BUG-NNNN` id, the feature doc path, and criterion number in the message body.
