---
description: What's next -- renders the active feature stack as a tree, reports open bugs and tech debt, and flags anything needing immediate attention.
---

INDEX-first; fallback to flat if absent.

Report what is open and what needs attention:

1. **Render the active feature stack.** Read `.claude/current-feature` as an array of lines (each line is one stack frame; last line = active feature). For each frame in order, print:
   - the slug, indented by stack depth (root = 0 indent, each pivot adds 2 spaces)
   - on the next line, the slug's `## Status` value and -- if not COMPLETE -- the last unchecked progress entry from its feature doc (the NEXT/handoff line)
   - mark the last (deepest) frame `[active]`

   Example output for a depth-2 stack (parent paused, blocker active):

   ```
   feature-a              IN PROGRESS
     -> next: wire up the retry path
     +-- bug-blocker-x    IN PROGRESS  [active]
         -> next: reproduce against fixture 03
   ```

   If `.claude/current-feature` does not exist or is empty, print `no active feature (stack empty)` and continue.

2. **Bug surface from INDEX.** Read `memory/BUG-INDEX.md` if it exists. Group `## Active` entries by `<area>` and print one line per area: `<area> (N open)`. Do NOT read `memory/KNOWN-ISSUES.md` for the surface report -- the INDEX has everything needed.

   **Fallback (INDEX absent):** read the project's flat issues tracker (discovered from CLAUDE.md; fallback `memory/KNOWN-ISSUES.md`) and report total open count.

3. Gather feature statuses efficiently:
   - Use Grep (not an Explore agent) to extract "Status:" lines from all feature docs in one call.
   - Only Read individual feature docs if you need NEXT/handoff details for non-COMPLETE features.
   - NEVER spawn an Explore agent or read every feature doc individually just to extract status fields.

4. Report all open items grouped by category: `[BUG-NNNN]` criteria, tech debt, parked features (IN PROGRESS with no recent progress entry), NEXT handoff lines with no owner.

5. Flag anything that needs immediate attention: blocking bugs, features that are IN PROGRESS but stalled, or tracker entries with no feature doc tracking them.

6. **Tracker lifecycle scan on INDEX (INDEX present path):**
   - Flag `## Active` entries older than 30 days with no linked `[BUG-NNNN]` criterion in any feature doc (orphaned issues).
   - Flag `## Active` entries whose linked `[BUG-NNNN]` criterion has been removed from the feature doc (silently resolved -- should be in Resolved).
   - Flag `## Active` entries whose linked criterion's `### Progress` line is checked off (`[x]`) in the feature doc (shipped but tracker not updated -- recommend `/bs`).
   - If `memory/BUG-INDEX.md` `## Recently Resolved` has more than 10 entries, recommend trimming via `/f` or `/fs`. If `memory/KNOWN-ISSUES.md` `## Resolved` has more than 10 entries, recommend archiving the oldest to `memory/KNOWN-ISSUES-ARCHIVE.md`.

   **Fallback (INDEX absent):** same scan against the flat tracker.
