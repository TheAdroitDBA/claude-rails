# Claude-Rails Framework

## Framework Authority

claude-rails is the portable framework that eliminates token waste, repetitive tasks, and inconsistent project shape across every repo. See [README.md](README.md) for the full purpose statement. All framework artifacts (hooks, skills, agents, commands, conventions, rules) serve those three goals.

## Hard Rules

1. No emojis or graphical characters in .md files (plain text only).
2. Match file granularity to concern granularity. Add to an existing file when the work belongs to that file's responsibility. Create a new file when the work is a genuinely separate concern with its own success criteria, scope, or lifecycle. Avoid both failure modes: splintering one concern across many files (sprawl) and stuffing multiple concerns into one file (concern bleed). When unsure, ask: could a reader find this with one read, and could it be deleted as a unit?
3. All operations must be idempotent (safe to re-run).
4. Hooks are opt-in per repo via a marker file (`.claude/feature-doc-required`).
5. Every feature doc must have a `### Progress` checklist under `## Status`. Update it at every decision point during the session -- not just at the end. A decision point is: starting a step, completing a step, rejecting an approach, or changing a criterion. Write the checklist entry BEFORE the code so intent survives a crash. Add the commit hash after. The last entry should always say what to do NEXT (the session handoff line).
6. When a success criterion changes mid-feature, reconcile in place using the strikethrough convention (see `conventions/feature-conventions.md` "Reconciling changed criteria"): `~~original~~ -> replacement. Reason: <why it failed>. (Progress <date>)`. Never silently rewrite a criterion; never tick a stale criterion at `/fs`.
7. `.claude/current-feature` is a LIFO stack, one slug per line. The **last line** is the active feature. `/n` appends (push); `/f` and `/fs` truncate the last line (pop). A single-line file is a valid depth-1 stack. Never overwrite the file wholesale.
8. Bugs receive a stable ID at `/b` time of the form `BUG-NNNN` (zero-padded to 4 digits, globally unique, never reused). The ID appears in the tracker entry, in the `[BUG-NNNN]` criterion tag in the feature doc, and in any `[BLOCKED BY BUG-NNNN]` pivot reference. See `conventions/feature-conventions.md` "Bug IDs".
9. Output discipline. Feature docs are terse: each criterion is one line where possible; `## Test Plan` is a smoke recipe (one line per step naming the criterion verified), not a re-statement of criteria; `## What It Does` is 1-2 short paragraphs. Target ~80 lines per feature doc, hard cap ~120. Commit messages are 3 lines plus `Co-Authored-By`, not multi-paragraph essays. End-of-session handoff prose is forbidden -- the Progress checklist's NEXT line IS the handoff; trust it. Verbosity in any of these costs every future session that has to read it to orient.

## Token Hierarchy

Rules -> conventions (stack-agnostic principles; `conventions/`) -> sibling docs (`*.feature.md`, `*.flow.md`) -> memory/ -> source code. Stop when you have enough context.

Conventions are principles, not invariants. A feature that cannot honor a convention declares a `## Deviation from conventions` section in its feature doc with a one-line rationale.

## Development Principles

- **Build vertically.** Complete slices through the entire stack per feature. Keeps reversal cost low because each feature is self-contained.
- **Criteria before code.** Write success criteria and get them approved before implementation begins.
- **Outside-in for user-facing work.** When the feature has a user-visible surface (CLI, UI, API, error message, docs page), work in this order: flow doc -> feature doc -> criteria. Features with no user-visible surface go directly from rules and criteria to code.
- **Docs before fix.** When troubleshooting (`/t`), ensure the feature doc has a `[BUG-NNNN]` criterion and a flow doc covers the affected pipeline BEFORE reading source code or writing a fix.
- **Learn from failures.** When a tool call, command, or approach fails and you find the fix, save a feedback memory BEFORE moving on: (1) the error pattern, (2) the root cause, (3) the prevention.
- **Capture ideas before context shifts.** When a design discussion produces future work (a feature, refactor, or principle worth doing later), run `/i` BEFORE returning to current work. Capture is the cost of moving on, not a permission gate. Conversation context is volatile; the ideas file is durable.
- **Bugs found during feature work: fix or record, never both halfway.** Three-way decision -- two questions, three outcomes. Q1: is the fix under ~10 lines AND in code you are already touching? Q2 (only if Q1 = no): is it blocking?
  1. FIX INLINE -- Q1 = yes. Just fix it and note in the progress checklist. Whether or not it is strictly blocking; if it is that cheap, the choice is forced when blocking and opportunistic when not.
  2. RECORD (`/b`) -- Q1 = no, Q2 = no. Record with `/b` (mints `BUG-NNNN`) and move on. Do not investigate, do not expand scope.
  3. PIVOT -- Q1 = no, Q2 = yes. Run `/b <description>` to mint `BUG-NNNN`, tag the parent criterion `[BLOCKED BY BUG-NNNN]`, commit a pause snapshot with `chore(pause): <parent-slug> blocked by BUG-NNNN`, then `/n <blocker-fix>` to push the blocker onto the stack. `/fs` on the blocker pops the stack and resumes the parent.

## Session Lifecycle

Every work session follows this sequence. If you feel lost, find where you are in this list.

1. **ORIENT** -- `/w` to see what is open. Pick a task. Or read the **last line** of `.claude/current-feature` to resume the active feature (top of stack).
2. **LOAD CONTEXT** -- Read the feature doc's progress checklist. The last entry tells you what to do next. If starting a new feature: `/n` to create the doc and criteria first (appends to the stack). No code until criteria are approved.
3. **WORK** -- Implement against criteria. Update the progress checklist at every decision point (before the code, not after). Fix-or-record rule for discovered bugs (four-way decision: BLOCKING+SMALL, SMALL+SAME-FILE, NON-BLOCKING, or PIVOT). If stuck for more than 3 queries, see the stuck protocol below.
4. **VERIFY** -- Run the test plan table in the feature doc. Fix failures.
5. **CLOSE** -- `/f` to finalize, or `/fs` if the feature is done. The last progress checklist entry must be a handoff line: what you would do next if you had 5 more minutes. `/f` and `/fs` pop the top-of-stack automatically; if a parent remains, they print the resume slug and its last unchecked progress entry.

## Stuck Protocol

When you have been searching or trying things for more than 3 queries without progress:

1. **STOP.** Do not try another variation of the same approach.
2. **Read the feature doc.** The success criteria tell you what "done" looks like. Are you solving the right problem?
3. **Read the flow doc.** Does the architecture support what you are trying to do? Or are you fighting it?
4. **Check the progress checklist.** Has this approach already been REJECTED? Are you re-litigating a settled decision?
5. **If still stuck: ask the user.** They often know exactly which file to look at. One question is cheaper than 10 more queries.

## Enforcement Model

Three knobs control enforcement per repo:

1. **Marker file** (`.claude/feature-doc-required`) -- opt-in switch. If absent, all enforcement is skipped.
2. **Enforcement mode** (`.claude/feature-doc-mode`) -- `off`, `warn`, or `block` (default: `block`).
3. **Feature scope** -- `## Scope` globs in feature docs determine which files each feature doc covers. No `## Scope` means the doc covers its directory and all descendants.

Hooks ship via `hooks/hooks.json` in the plugin. They auto-wire when the plugin loads. The hooks use prompt-type handlers (Claude evaluates enforcement logic directly), making them fully cross-platform.

Three enforcement hooks:
- **PreToolUse** (Edit/Write/MultiEdit/NotebookEdit): feature-doc coverage check -- blocks edits to files not covered by a feature doc.
- **PreToolUse** (Edit/Write/MultiEdit/NotebookEdit): flow-doc presence check -- warns when editing a feature doc with `## Surface` but no sibling flow doc.
- **Stop**: stale feature-doc check -- warns if touched feature docs are missing `## Success Criteria` or `## Status`.

## Shorthand Contract

All slash commands -- both workflow shortcuts and framework skills -- are native Claude Code commands. Source files live in `commands/` at the repo root. Workflow shortcuts: `/n`, `/f`, `/fs`, `/b`, `/bs`, `/t`, `/w`, `/r`, `/e`, `/i`. Framework skills: `/project-setup`, `/docs-audit`, `/discovery-check`, `/hook-health`, `/startup-audit`, `/troubleshoot`. Domain experts: `/software-architect`, `/security-expert`, `/testing-expert`, `/systems-expert`.

Distribution: run `install.sh` (Mac/Linux) or `install.ps1` (Windows) once per machine. This symlinks/junctions `commands/` into `~/.claude/commands/` and registers the plugin in `~/.claude/settings.json`, making all shortcuts, hooks, and agents available globally. Edits to the repo are live immediately.

## Topic Files

| File | Purpose |
|------|---------|
| memory/KNOWN-ISSUES.md | Current broken or incomplete framework state |
