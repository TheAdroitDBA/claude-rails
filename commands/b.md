---
description: Record a bug without investigating it. Use when a bug is found during feature work that is not blocking and not a small same-file fix. Captures context at peak freshness; the fix happens later via /t. Assigns a stable BUG-NNNN ID.
argument-hint: <bug-description>
---

Record bug: $ARGUMENTS

Do NOT investigate, fix, or expand scope. Capture context only -- these steps preserve the bug at peak freshness so a dedicated session can fix it efficiently.

1. Read the project's issues tracker (discovered from CLAUDE.md; fallback memory/KNOWN-ISSUES.md). Deduplicate: if this bug is already recorded, add any new context to the existing entry and stop. Report the existing `BUG-NNNN` to the user.

2. **Assign a stable Bug ID.** Compute `BUG-NNNN` as `max(existing IDs) + 1`, zero-padded to 4 digits. Search for existing IDs across all tracker surfaces:
   - the active tracker file from step 1
   - `memory/KNOWN-ISSUES-ARCHIVE.md` if it exists
   - all `*.feature.md` files in the repo (criterion tags)

   Shell: `grep -hoE 'BUG-[0-9]+' <files> | sort -u | sort -rV | head -1`. PowerShell: `Select-String -Path <files> -Pattern 'BUG-\d+' | ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | Select-Object -Last 1`.

   If no IDs exist anywhere, start at `BUG-0001`. IDs are NEVER reused, even after resolution or archival.

3. Identify which feature doc(s) this bug violates. A bug always violates at least one success criterion.

4. Check that a feature doc exists for each affected feature. Document this in the bug if it does not exist.

5. Add a `[BUG-NNNN]`-tagged criterion to the relevant feature doc(s). The criterion should be testable: describe what "fixed" looks like, not just what is broken. Example: `- [ ] [BUG-0042] Retry handler must not double-charge when upstream returns 409.`

6. Check whether a flow doc covers the affected pipeline. If none exists, flag the gap -- /t will create the flow doc before fixing.

7. Write an entry in the **Active** section of the issues tracker using this format: `- BUG-NNNN | <description> | area: <feature/area> | criterion: <feature-doc#criterion-number> | <today's date>`. Include what breaks and what file/function to look at first.

8. If the tracker has a **Resolved** section with more than 10 entries, move the oldest resolved entries to `memory/KNOWN-ISSUES-ARCHIVE.md` (create the archive file if it does not exist).

9. Report: the assigned `BUG-NNNN` and `use /t BUG-NNNN to investigate and fix in a dedicated session`.

Report back to the user: done <action taken> -- assigned BUG-NNNN