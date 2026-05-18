---
description: Troubleshoot and fix a bug. Doc-first: ensures feature and flow docs exist before touching code so the fix is verifiable and the pipeline is protected against future regressions. Accepts a BUG-NNNN id for exact-match lookup.
argument-hint: <bug-description-or-BUG-NNNN>
---

INDEX-first; fallback to flat if absent.

Troubleshoot: $ARGUMENTS

Follow doc-first order. Do not read source code until step 5.

1. **Resolve the bug via INDEX.** Read `memory/BUG-INDEX.md` if it exists. If `$ARGUMENTS` matches `BUG-\d{4}`, look up the exact ID in the INDEX and extract its `<area>`. Otherwise, match by description against the INDEX `## Active` entries.

   Then read ONLY the matched `### <area>` subsection of `memory/KNOWN-ISSUES.md` -- do not read the whole file. The subsection contains Repro/Evidence/First-place-to-look for this bug.

   **Fallback (INDEX absent):** read the project's flat issues tracker (discovered from CLAUDE.md; fallback `memory/KNOWN-ISSUES.md`). If `$ARGUMENTS` matches `BUG-\d{4}`, grep the tracker (and archive) for that exact ID. Otherwise, match by description.

   If no entry exists (INDEX or flat), run `/b` first to record it (which assigns a `BUG-NNNN`), then resume here.

2. Read the feature doc for the affected feature. If no criterion matches this bug, add a `[BUG-NNNN]` criterion before proceeding -- the fix is not verifiable without one.

3. Read the flow doc for the affected pipeline. If no flow doc exists, create it before proceeding. The flow doc traces entry points, data steps, and failure modes so the next session does not start from zero.

4. Read relevant memory files (memory/KNOWN-ISSUES.md, memory/HOOK-INVENTORY.md, or equivalent) for prior known state.

5. Source code LAST -- only after docs exist and have been read.

6. Report root cause and evidence before writing any fix: name the layer, file, function, and the proof that this is the root cause rather than a symptom.

7. Fix the original issue. Verify the fix against the `[BUG-NNNN]` criterion from step 2 -- the criterion is the definition of "fixed".

8. Update the flow doc if the fix changed the pipeline (e.g. a failure mode that was undocumented is now handled).
