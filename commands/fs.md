---
description: Feature success -- full completion pipeline. Runs finalize, QA, UX review (if surface declared), dead code cleanup, doc updates, deviation summary, simplify pass, and commit.
---

Feature success -- run the full completion pipeline in order. Do not skip steps.

1. Run /f (finalize checklist): turn off debug, update ### Progress with commit hashes, mark feature COMPLETE.

2. QA: spawn the qa-tester agent against the feature's success criteria. Record any failures as [BUG] criteria before closing.

3. UX review (conditional): if the feature doc has a ## Surface section declaring user-facing touchpoints (CLI, UI, API humans call, error messages, docs), spawn the ux-reviewer agent with the feature doc path. Skip if no ## Surface section or it reads "none" or "internal".

4. Dead code cleanup: remove any code left over from failed approaches explored during this feature.

5. Update flow docs: ensure all *.flow.md files that cover the affected pipeline match the implemented architecture. If a flow step changed, update the table row.

6. Update memory files: add new gotchas, architecture changes, or conventions discovered during implementation.

7. Update feature doc: mark all success criteria checked, ensure ## Files section is current, verify ### Progress has an entry for every decision point.

8. Deviation summary: if the feature doc has a ## Deviation from conventions section, surface each deviation as one line in the closure output. Format: convention-name: one-line rationale. A bullet without a colon blocks closure -- fix it or add the rationale before continuing.

9. Run /simplify on all changed files.

10. Token optimization: verify that docs are current enough that a future session does not need to read source code to understand what this feature does.

11. Commit with a descriptive message that explains the "why", not just the "what".
