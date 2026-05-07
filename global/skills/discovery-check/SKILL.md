---
name: discovery-check
description: Verifies the discovery cost of the current repo by asking the four orient questions (what is this, what's done, what's broken, what's next) under a 15k-token budget. Reports which topic files are missing if over budget. Read-only; user marks PASS/FAIL.
---

# Discovery Check

You are running a discovery-cost verification against the repo in the current working directory. The goal is to answer four orient questions cold — reading only from files in this repo during this invocation, not from training knowledge or from any memory of prior work in this repo.

## Step 1: Anchor the scope

Your scope is the **current working directory**. Treat it as the effective repo root for this verification. Do not read files outside it.

Run `git rev-parse --show-toplevel` for context only — to note whether the CWD is the git root or a sub-project inside a larger git repo. Report the git root in your output if it differs from the CWD, but do not expand your scope to reach it.

Rationale: the user chose this directory deliberately when they invoked the skill. In nested project structures (e.g. `infrastructure/` is the git repo but `infrastructure/minecraft/` is the sub-project being audited), honoring CWD lets sub-project audits work. In flat repos, CWD and git root match and nothing changes.

If the CWD is clearly not a project root (you see only one source file, no docs, no top-level structure), note this as a finding and proceed anyway with what you can read.

## Step 2: Answer the four questions, in order

Answer each question from files you read now. Cite the file paths you consulted. Do not rely on training knowledge of common project types, and do not assume you remember anything about this repo from a prior session.

### 1. What is this repo?

One paragraph. What the repo is for, what problem it solves, who uses it. Purpose, not a feature list. Read `CLAUDE.md` or `README.md` if present; if neither exists, infer from top-level code and note the gap.

### 2. What is done?

Bulleted. Features, subsystems, or capabilities that are currently working.

Primary source: feature docs marked DONE or COMPLETE, plus progress checklists with closed entries.

**Caveat to include in your output:** this answer reflects what is **documented as done**, not necessarily everything that works. Repos with partial framework adoption (or no framework) have pre-adoption working code that has no feature doc and is invisible to this check. If the repo appears to have substantial undocumented functionality — e.g. Terraform modules, services, monitoring — say so explicitly. Undocumented "done" is a finding, not evidence of incompleteness.

### 3. What is broken?

Bulleted. Real known issues.

Discover the broken-items tracker from the adopted repo's own declaration. Check in this order:

1. Read `CLAUDE.md` for a declared tracker location. Look for phrases like "known issues", "risk register", "bug tracker", "active issues", or a line naming a specific file.
2. If CLAUDE.md declares a tracker (e.g. `docs/operations/risk-register.md` or a section in `memory/<project>.md`), read that file as the authoritative source.
3. If CLAUDE.md does not declare a tracker, fall back to `memory/KNOWN-ISSUES.md` (the claude-rails framework default).
4. Additionally, scan feature docs for `[BUG]` criteria or `DONE-WITH-BUGS` statuses regardless of where the main tracker lives.

If no tracker is declared AND no `memory/KNOWN-ISSUES.md` exists AND no `[BUG]` markers are found, report: "No broken-items tracker discovered; absence is a finding." Do NOT default to "nothing is broken" — the absence of a tracker is itself the signal.

### 4. What is next?

One sentence. The most load-bearing unfinished work you can identify. Read `.claude/current-feature` if present for the in-flight feature; also scan progress checklists for HANDOFF lines or unchecked boxes marked NEXT.

## Step 3: Report the budget

Estimate total tokens you read across the four answers. Approximate by summing the character counts of the files you consulted and dividing by 4 (conservative tokens-per-char approximation).

Report the estimate as one of:

- **Under 15k:** Discovery cost is within budget.
- **Over 15k:** Identify exactly one specific missing topic file that would have let you answer under budget. Name the file path you wanted and what it would have contained (e.g. "memory/HOOK-INVENTORY.md with a table of every hook, its trigger, and its parity status would have saved ~8k tokens of reading hook scripts directly"). Do not say "more docs would help." Be specific.

## Step 4: Handoff

End your output with this exact line, verbatim:

> PASS/FAIL is the user's call. Per MEMORY.md Hard Rule, Claude does not self-mark on discovery-cost verification.

## Do not

- Do not write any file, propose fixes, or recommend framework adoption. This is read-only verification.
- Do not assume the repo has adopted the claude-rails framework. If it has no `memory/`, no feature docs, or no `CLAUDE.md`, note the absence as a finding — do not unilaterally suggest adoption.
- Do not reorder, merge, or skip the four questions.
- Do not print the words "PASS" or "FAIL" yourself. The user marks the result.
- **Do not read files outside the CWD scope defined in Step 1, even when an in-scope file references them.** If `CLAUDE.md` or a feature doc inside your scope points at a file outside the CWD (e.g. a sibling directory under the git root), record that reference as a finding — "CLAUDE.md references `../terraform/main.tf` but that file is outside audit scope" — and move on. Out-of-scope files are never opened.
- Do not default to "nothing is broken" when you cannot find a tracker. Report the absence as the finding.
