---
description: Feature success -- full completion pipeline. Runs finalize, QA, UX review (if surface declared), dead code cleanup, doc updates, deviation summary, simplify pass, and commit.
---

INDEX-first; fallback to flat if absent (inherited from /f hygiene step).

Feature success -- run the full completion pipeline in order. Do not skip steps.

1. Run /f (finalize checklist): turn off debug, update ### Progress with commit hashes, mark feature COMPLETE.

2. QA: spawn the qa-tester agent against the feature's success criteria. Record any failures as `[BUG-NNNN]` criteria before closing (use `/b` to assign each ID).

3. UX review (conditional): if the feature doc has a ## Surface section declaring user-facing touchpoints (CLI, UI, API humans call, error messages, docs), spawn the ux-reviewer agent with the feature doc path. Skip if no ## Surface section or it reads "none" or "internal".

4. Dead code cleanup: remove any code left over from failed approaches explored during this feature.

5. Update flow docs: ensure all *.flow.md files that cover the affected pipeline match the implemented architecture. If a flow step changed, update the table row.

6. Update memory files: add new gotchas, architecture changes, or conventions discovered during implementation.

7. Update feature doc: ensure ## Files section is current, verify ### Progress has an entry for every decision point, then reconcile success criteria. For each criterion: if Progress shows the approach changed, rejected, or was dropped, apply the strikethrough convention from feature-conventions.md ("Reconciling changed criteria") -- strike the original, append the replacement and the reason it failed, link the Progress entry. Only after reconciliation: mark surviving criteria checked. Do not tick a criterion whose Progress trail shows divergence.

8. Deviation summary: if the feature doc has a ## Deviation from conventions section, surface each deviation as one line in the closure output. Format: convention-name: one-line rationale. A bullet without a colon blocks closure -- fix it or add the rationale before continuing.

9. Run /simplify on all changed files.

10. Token optimization: verify that docs are current enough that a future session does not need to read source code to understand what this feature does.

11. Commit with a descriptive message that explains the "why", not just the "what".

12. **Pop the stack.** Drop the last line of `.claude/current-feature` (the slug just closed). If the file would become empty, delete it instead of leaving a zero-byte file.
    - Shell: `sed '$d' .claude/current-feature > .claude/current-feature.tmp && { [ -s .claude/current-feature.tmp ] && mv .claude/current-feature.tmp .claude/current-feature || rm -f .claude/current-feature .claude/current-feature.tmp; }`
    - PowerShell: `$l = @(Get-Content .claude/current-feature); if ($l.Count -le 1) { Remove-Item .claude/current-feature } else { $l[0..($l.Count-2)] | Set-Content .claude/current-feature }`

    If a line remains after the pop, the parent feature is now active again -- read it and print:
    - `resuming <parent-slug>`
    - the last unchecked progress entry from that parent's feature doc

    If the closed feature's doc had a `## Interrupts: <parent-slug>` section, confirm that slug matches the new top-of-stack. If they diverge, surface the mismatch as a warning -- the stack and the doc disagree on parentage.

    Do NOT auto-invoke another slash command. The user runs `/w` themselves if they want a full re-orient.
