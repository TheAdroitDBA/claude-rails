---
description: Bug success -- cleanup and commit after a bug fix is verified. Removes [BUG] tags, cleans up failed fix attempts, and commits.
---

Bug success -- close out the fix cleanly:

1. Remove the [BUG] tag from the feature doc criterion. Keep the criterion text as a normal passing criterion so the fix is permanently testable.

2. Remove the bug entry from the issues tracker (memory/KNOWN-ISSUES.md or declared tracker).

3. Dead code cleanup: remove any code from failed fix attempts made during this session.

4. Update flow docs if the fix changed the code path -- a fixed bug often reveals a gap in the flow doc's failure-modes section.

5. If the root cause was surprising or non-obvious: save a feedback memory before the session ends. Capture: (1) the error pattern, (2) the root cause, (3) what to do instead. A workaround without a memory means the next session hits the same wall.

6. Commit with a descriptive message. Include the feature doc path and criterion number in the message body.
