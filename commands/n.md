---
description: Start a new feature. Reads issues tracker, handles flow-doc-first for user-facing work, creates a feature doc with criteria and progress checklist. Pushes the new slug onto the `.claude/current-feature` stack. No code until criteria are approved.
argument-hint: <feature-name>
---

New feature: $ARGUMENTS

Follow these steps in order. Do not skip steps or begin implementation before step 14.

1. Read the project's issues tracker (discovered from CLAUDE.md; fallback memory/KNOWN-ISSUES.md) for related bugs or prior work on this topic.

2. **Stack pre-flight (pivot safety).** Read `.claude/current-feature` if it exists.
   - If the file exists and has any content, this `/n` is a PIVOT: a new feature is being pushed on top of one already in flight.
   - If the working tree is dirty (`git status --porcelain` returns any output), commit a pause snapshot first: `git add -A && git commit -m "chore(pause): <top-of-stack-slug> blocked by $ARGUMENTS"`. This keeps the parent's in-progress work recoverable on any machine and makes the pivot reversible.
   - The clean-tree check is required whether or not the repo has `.claude/feature-doc-required`. The pause commit only happens if the tree is actually dirty.

3. Decide: does this feature have a user-visible surface (CLI, UI, API humans call, error message, docs page)? If NO, skip to step 6.

4. User-facing path: check for an existing *.flow.md near the relevant entry point. The flow captures what the user expects to see -- it is the contract that feature criteria must be traceable to.

5. User-facing path: if no flow doc exists, or the existing one does not cover this feature, draft or update the flow doc FIRST. Name the entry point, write the step table, and define failure modes before any feature doc work.

6. Check for an existing *.feature.md near the code (informed by the flow doc if one exists).

7. Create $ARGUMENTS.feature.md next to the primary code file if none exists. Include: ## What It Does, ## Success Criteria, ## Status, ### Progress, ## Scope, ## Files. If step 2 detected a PIVOT, also include `## Interrupts: <parent-slug>` (the slug that was last-line of `.claude/current-feature` before this push) so the child doc knows it was born as an interrupt.

8. Include a ### Progress checklist under ## Status with the planned implementation steps.

9. Write success criteria that make each flow step verifiable (user-facing features) or each rule/invariant testable (internal features). Each criterion must be testable pass/fail from the outside.

10. Validate drafted criteria against conventions (~/.claude/conventions/feature-conventions.md). Flag any criterion or ## Files entry that violates a convention. Do not move forward until each violation is either fixed or an explicit ## Deviation from conventions section with a one-line rationale is added to the feature doc.

11. Fill doc gaps in the same pass: memory files, additional flow docs if the feature spans multiple pipelines.

12. If new issues surface during this process: use /b to record them. Do NOT expand the scope of this feature.

13. **Push onto the stack (idempotent).** Re-running `/n` on the same slug must be a no-op -- if the current last line of `.claude/current-feature` is already `$ARGUMENTS`, do nothing. Otherwise append `$ARGUMENTS` as a new last line (create the file if it does not exist). Never overwrite existing content.
   - Shell: `LAST=$(tail -n 1 .claude/current-feature 2>/dev/null); [ "$LAST" = "$ARGUMENTS" ] || printf '%s\n' "$ARGUMENTS" >> .claude/current-feature`
   - PowerShell: `if (-not (Test-Path .claude/current-feature) -or ((Get-Content .claude/current-feature | Select-Object -Last 1) -ne "$ARGUMENTS")) { Add-Content -Path .claude/current-feature -Value "$ARGUMENTS" }`

14. Report the feature doc as ready for review. If step 2 detected a PIVOT, also tell the user which parent slug is paused below in the stack. NO code until criteria are explicitly approved.
