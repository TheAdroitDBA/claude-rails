# Claude-Rails Framework

## Framework Authority

claude-rails is the portable framework that eliminates token waste, repetitive tasks, and inconsistent project shape across every repo. See [README.md](README.md) for the full purpose statement. All framework artifacts (hooks, skills, agents, commands, conventions, rules) serve those three goals.

## Hard Rules

1. No emojis or graphical characters in .md files (plain text only).
2. Prefer editing existing files over creating new ones.
3. All operations must be idempotent (safe to re-run).
4. Hooks are opt-in per repo via a marker file (`.claude/feature-doc-required`).
5. Every feature doc must have a `### Progress` checklist under `## Status`. Update it at every decision point during the session -- not just at the end. A decision point is: starting a step, completing a step, rejecting an approach, or changing a criterion. Write the checklist entry BEFORE the code so intent survives a crash. Add the commit hash after. The last entry should always say what to do NEXT (the session handoff line).

## Token Hierarchy

Rules -> conventions (stack-agnostic principles; `conventions/`) -> sibling docs (`*.feature.md`, `*.flow.md`) -> memory/ -> source code. Stop when you have enough context.

Conventions are principles, not invariants. A feature that cannot honor a convention declares a `## Deviation from conventions` section in its feature doc with a one-line rationale.

## Development Principles

- **Build vertically.** Complete slices through the entire stack per feature. Keeps reversal cost low because each feature is self-contained.
- **Criteria before code.** Write success criteria and get them approved before implementation begins.
- **Outside-in for user-facing work.** When the feature has a user-visible surface (CLI, UI, API, error message, docs page), work in this order: flow doc -> feature doc -> criteria. Features with no user-visible surface go directly from rules and criteria to code.
- **Docs before fix.** When troubleshooting (`/t`), ensure the feature doc has a [BUG] criterion and a flow doc covers the affected pipeline BEFORE reading source code or writing a fix.
- **Learn from failures.** When a tool call, command, or approach fails and you find the fix, save a feedback memory BEFORE moving on: (1) the error pattern, (2) the root cause, (3) the prevention.
- **Bugs found during feature work: fix or record, never both halfway.** Three-way decision:
  1. BLOCKING -- the current feature cannot work without a fix. Fix inline, note in progress checklist.
  2. SMALL + SAME FILE -- fix is under ~10 lines in code you are already touching. Fix inline, note in progress checklist.
  3. EVERYTHING ELSE -- record it (`/b`) and move on. Do not investigate, do not expand scope.

## Session Lifecycle

Every work session follows this sequence. If you feel lost, find where you are in this list.

1. **ORIENT** -- `/w` to see what is open. Pick a task. Or read `.claude/current-feature` to resume where you left off.
2. **LOAD CONTEXT** -- Read the feature doc's progress checklist. The last entry tells you what to do next. If starting a new feature: `/n` to create the doc and criteria first. No code until criteria are approved.
3. **WORK** -- Implement against criteria. Update the progress checklist at every decision point (before the code, not after). Fix-or-record rule for discovered bugs. If stuck for more than 3 queries, see the stuck protocol below.
4. **VERIFY** -- Run the test plan table in the feature doc. Fix failures.
5. **CLOSE** -- `/f` to finalize, or `/fs` if the feature is done. The last progress checklist entry must be a handoff line: what you would do next if you had 5 more minutes. Update `.claude/current-feature` if switching features.

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

Hooks ship via `hooks/hooks.json` in the plugin. They auto-wire when the plugin loads -- no per-machine `settings.local.json` wiring needed. The hooks use prompt-type handlers (Claude evaluates enforcement logic directly), making them fully cross-platform with no shell scripts.

Three enforcement hooks:
- **PreToolUse** (Edit/Write/MultiEdit/NotebookEdit): feature-doc coverage check -- blocks edits to files not covered by a feature doc.
- **PreToolUse** (Edit/Write/MultiEdit/NotebookEdit): flow-doc presence check -- warns when editing a feature doc with `## Surface` but no sibling flow doc.
- **Stop**: stale feature-doc check -- warns if touched feature docs are missing `## Success Criteria` or `## Status`.

## Shorthand Contract

Slash commands are native Claude Code commands. Source files live in `commands/` at the repo root. Invoke them as `/n`, `/f`, `/fs`, `/b`, `/bs`, `/t`, `/w`, `/r`, `/e`, `/i`.

Distribution: run `link-commands.sh` (Mac/Linux) or `link-commands.ps1` (Windows) once per machine. This symlinks/junctions `commands/` into `~/.claude/commands/`, making all shortcuts available globally. Edits to the repo are live immediately.

## Topic Files

| File | Purpose |
|------|---------|
| memory/KNOWN-ISSUES.md | Current broken or incomplete framework state |
