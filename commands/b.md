---
description: Record a bug without investigating it. Use when a bug is found during feature work that is not blocking and not a small same-file fix. Captures context at peak freshness; the fix happens later via /t. Assigns a stable BUG-NNNN ID.
argument-hint: <bug-description> [--area <slug>]
---

INDEX-first; fallback to flat if absent.

Record bug: $ARGUMENTS

Do NOT investigate, fix, or expand scope. Capture context only -- these steps preserve the bug at peak freshness so a dedicated session can fix it efficiently.

1. **Dedup via INDEX.** Read `memory/BUG-INDEX.md` if it exists. Scan `## Active` entries for a match against the description. If matched, add any new context to the existing entry in `memory/KNOWN-ISSUES.md` (in its `### <area>` subsection) and stop -- report the existing `BUG-NNNN` to the user.

   **Fallback (INDEX absent):** read the project's flat issues tracker (discovered from CLAUDE.md; fallback `memory/KNOWN-ISSUES.md`). Same dedup logic against the flat list.

2. **Resolve area.** Parse `--area <slug>` from $ARGUMENTS. If not provided, prompt the user for an area slug. If the user declines or does not answer, use `uncategorized`. Normalize: lowercase, slash-to-dash, no spaces.

3. **Assign a stable Bug ID.** Compute `BUG-NNNN` as `max(existing IDs) + 1`, zero-padded to 4 digits.

   **INDEX-first:** read `memory/BUG-INDEX.md`, take the highest `BUG-\d+` across both `## Active` and `## Recently Resolved` sections.

   **Fallback (INDEX absent):** search across all tracker surfaces:
   - the active tracker file from step 1
   - `memory/KNOWN-ISSUES-ARCHIVE.md` if it exists
   - all `*.feature.md` files in the repo (criterion tags)

   Shell: `grep -hoE 'BUG-[0-9]+' <files> | sort -u | sort -rV | head -1`. PowerShell: `Select-String -Path <files> -Pattern 'BUG-\d+' | ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | Select-Object -Last 1`.

   If no IDs exist anywhere, start at `BUG-0001`. IDs are NEVER reused, even after resolution or archival.

4. Identify which feature doc(s) this bug violates. A bug always violates at least one success criterion.

5. Check that a feature doc exists for each affected feature. Document this in the bug if it does not exist.

6. Add a `[BUG-NNNN]`-tagged criterion to the relevant feature doc(s). The criterion should be testable: describe what "fixed" looks like, not just what is broken. Example: `- [ ] [BUG-0042] Retry handler must not double-charge when upstream returns 409.`

7. Check whether a flow doc covers the affected pipeline. If none exists, flag the gap -- `/t` will create the flow doc before fixing.

8. **Write to both files (INDEX present path).**
   - `memory/KNOWN-ISSUES.md`: in `## Active`, under `### <area>` (create the subsection if absent, keep `### <area>` subsections alpha-sorted). Entry format:
     ```
     - BUG-NNNN | <description> | criterion: <feature-doc#criterion-number> | <today's date>
       Repro: <how to reproduce>
       Evidence: <what's wrong / observed behavior>
       First place to look: <file/function>
     ```
   - `memory/BUG-INDEX.md`: append to `## Active`:
     ```
     - BUG-NNNN | active | <area> | <description> | <today's date>
     ```
     Sort `## Active` by BUG-NNNN ascending.

   **Partial-state safety.** If the first write succeeds and the second fails, report: `partial state: wrote <which file>, failed <which file> -- manual reconciliation required`. Do not retry automatically; the user resolves it before continuing.

   **Fallback (INDEX absent):** write a single flat entry to the existing tracker using the legacy format: `- BUG-NNNN | <description> | area: <slug> | criterion: <feature-doc#criterion-number> | <today's date>`.

9. If the tracker has a **Resolved** section with more than 10 entries, move the oldest resolved entries to `memory/KNOWN-ISSUES-ARCHIVE.md` (create the archive file if it does not exist).

10. Report: the assigned `BUG-NNNN` and `use /t BUG-NNNN to investigate and fix in a dedicated session`.

Report back to the user: done <action taken> -- assigned BUG-NNNN
