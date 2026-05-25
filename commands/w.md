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

   **Sibling worktrees.** Run `git worktree list --porcelain` to enumerate worktrees of this repo. Skip this sub-step entirely if only one worktree exists. Otherwise, for each worktree whose path is not the current working directory:
   - Read `<worktree-path>/.claude/current-feature`. If missing or empty, skip silently.
   - Print a separator line `[worktree: <path> on <branch>]` followed by each stack frame as slug-only (indented by depth, last frame marked `[active here]`).
   - Do NOT read sibling feature docs for `## Status` or NEXT lines. Slugs only -- keep cross-worktree read cheap. Full detail requires `cd`-ing into that worktree and re-running `/w`.

   Example output with a migration pinned in a sibling worktree:

   ```
   bug-fix-x              IN PROGRESS  [active]
     -> next: add regression test

   [worktree: C:\Code\claude-rails-migration on migration/v2]
   schema-migration-v2    [active here]
   ```

2. **Managed-block drift check (read-only).** Locate the framework root (parent of the `commands/` folder this skill lives in). Read `<framework-root>/VERSION` -> `FRAMEWORK_VERSION`. Read `.claude/rails-version` in the current repo if it exists -> `REPO_VERSION`.

   Cases:
   - `.claude/feature-doc-required` absent: skip this step entirely.
   - `.claude/rails-version` missing AND `.claude/feature-doc-required` present: print one-line notice `rails-version file missing; framework version is v<FRAMEWORK_VERSION>` and continue. Do not warn.
   - `REPO_VERSION` == `FRAMEWORK_VERSION`: silent. Continue.
   - Minor or patch drift (`REPO_VERSION` < `FRAMEWORK_VERSION`, same major): one-line notice `rails-managed block is <N> versions behind; run /rails-sync`.
   - Major drift (`REPO_VERSION` major < `FRAMEWORK_VERSION` major): WARNING `rails-managed block is on v<X>; framework is on v<Y> -- major drift; run /rails-sync --major to acknowledge breaking changes`.
   - `REPO_VERSION` > `FRAMEWORK_VERSION`: WARNING `repo stamped at v<REPO_VERSION> but framework is v<FRAMEWORK_VERSION> -- framework may be stale; investigate before syncing`.

   This step is read-only. Never edit the managed block here; that is `/rails-sync`'s job.

3. **Bug surface from INDEX.** Read `memory/BUG-INDEX.md` if it exists. Group `## Active` entries by `<area>` and print one line per area: `<area> (N open)`. Do NOT read `memory/KNOWN-ISSUES.md` for the surface report -- the INDEX has everything needed.

   **Fallback (INDEX absent):** read the project's flat issues tracker (discovered from CLAUDE.md; fallback `memory/KNOWN-ISSUES.md`) and report total open count.

4. Gather feature statuses efficiently:
   - Use Grep (not an Explore agent) to extract "Status:" lines from all feature docs in one call.
   - Only Read individual feature docs if you need NEXT/handoff details for non-COMPLETE features.
   - NEVER spawn an Explore agent or read every feature doc individually just to extract status fields.

5. Report all open items grouped by category: `[BUG-NNNN]` criteria, tech debt, parked features (IN PROGRESS with no recent progress entry), NEXT handoff lines with no owner.

6. Flag anything that needs immediate attention: blocking bugs, features that are IN PROGRESS but stalled, or tracker entries with no feature doc tracking them.

7. **Tracker lifecycle scan on INDEX (INDEX present path):**
   - Flag `## Active` entries older than 30 days with no linked `[BUG-NNNN]` criterion in any feature doc (orphaned issues).
   - Flag `## Active` entries whose linked `[BUG-NNNN]` criterion has been removed from the feature doc (silently resolved -- should be in Resolved).
   - Flag `## Active` entries whose linked criterion's `### Progress` line is checked off (`[x]`) in the feature doc (shipped but tracker not updated -- recommend `/bs`).
   - If `memory/BUG-INDEX.md` `## Recently Resolved` has more than 10 entries, recommend trimming via `/f` or `/fs`. If `memory/KNOWN-ISSUES.md` `## Resolved` has more than 10 entries, recommend archiving the oldest to `memory/KNOWN-ISSUES-ARCHIVE.md`.

   **Fallback (INDEX absent):** same scan against the flat tracker.
