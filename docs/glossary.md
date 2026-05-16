# Glossary

Canonical vocabulary for the claude-rails framework. Use these terms precisely in docs, code comments, and conversation.

## Core Mechanics

| Term | Definition |
|------|-----------|
| **framework** | The whole claude-rails pattern: plugin manifest, hooks, feature-doc conventions, enforcement rules, skills, agents, and slash commands. |
| **plugin install** | Running `install.sh` (Mac/Linux) or `install.ps1` (Windows), which registers claude-rails in `~/.claude/settings.json` and links commands in one step. Loads global-pool agents and hooks for the session. Skills are delivered as commands via the install-script junction, not via the plugin. |
| **commands link** | The symlink/junction created by the install script that makes `~/.claude/commands/` point at `claude-rails/commands/`. |

## Units of Work

| Term | Definition |
|------|-----------|
| **skill** | A slash command providing domain expertise or framework functionality. Invoked in chat as `/<skill-name>`. Framework skills live in `commands/` alongside workflow shortcuts. Project-specific skills live in `.claude/skills/<name>/` within the project repo. |
| **slash command** | The invocation form (`/<name>`) of a command. All source files -- both workflow shortcuts and framework skills -- live in `commands/`. |
| **agent** | A specialized Claude persona defined by a markdown file. Lives under `global/agents/` for framework agents or `.claude/agents/` for project-specific agents. |
| **hook** | A rule that fires automatically on a Claude Code event. Defined in `hooks/hooks.json` within the plugin. Uses prompt-type handlers (Claude evaluates enforcement logic directly). |
| **hook event** | The Claude Code lifecycle point where a hook fires: `PreToolUse` (before a tool runs), `PostToolUse` (after a tool runs), `Stop` (when the session ends). |

## Documentation Structure

| Term | Definition |
|------|-----------|
| **feature doc** | A `*.feature.md` file colocated next to the code it describes. Contains numbered success criteria, a `## Status` section with a `### Progress` checklist, and optionally a `## Scope` section with glob patterns. |
| **flow doc** | A `*.flow.md` file colocated next to a workflow's entry-point file. Contains a step table tracing the multi-file path and a failure-modes section. |
| **success criterion** | A numbered, testable statement in a feature doc's `## Success Criteria` section. Each criterion describes one observable behavior that can be verified. |
| **progress checklist** | The `### Progress` section under `## Status` in a feature doc. Entries are written at every decision point BEFORE the code. The last entry is always the session handoff line. |
| **rules file** | A markdown file in `.claude/rules/` that declares an invariant or convention. Rules are the highest-priority context in the token hierarchy. |
| **MEMORY.md** | The single canonical description of the framework. Read first in every session. Lives at the repo root. |
| **topic file** | A focused markdown file in `memory/` covering one subject (known issues, hook inventory, etc.). Read on demand, not by default. |
| **token hierarchy** | The strict read order: rules -> conventions -> sibling docs (feature/flow) -> memory/ -> source code. Stop when you have enough context. |
| **decision record** | An architecture decision record (ADR) in `decisions/`. Documents a decision, its context, alternatives considered, and consequences. |

## Enforcement

| Term | Definition |
|------|-----------|
| **marker file** | `.claude/feature-doc-required` -- an empty file that opts a directory tree into enforcement. If absent, all enforcement hooks are no-ops. |
| **enforcement scope** | The directory tree controlled by a marker file. Determined by walking up from any file to find the nearest `.claude/feature-doc-required`. |
| **enforcement mode** | The value inside `.claude/feature-doc-mode`: `off` (skip enforcement), `warn` (allow but print warning), or `block` (refuse and explain). Default if file is absent: `block`. |
| **feature scope** | Which files a feature doc covers. Resolved by: (a) explicit `## Scope` glob patterns, or (b) the feature doc's directory and all descendants if no `## Scope` exists. |
| **scoped feature doc** | A feature doc with an explicit `## Scope` section containing glob patterns that define exactly which files it covers. |
| **unscoped feature doc** | A feature doc without a `## Scope` section. It covers its own directory and all descendants by default. |
| **current-feature pointer** | `.claude/current-feature` -- a LIFO stack file, one slug per line, **last line = active feature**. `/n` appends (push); `/f` and `/fs` truncate the last line (pop). Single-line files are valid depth-1 stacks. Supports interrupt pivots without losing parent context. |
| **incremental adoption** | The recommended approach: start with enforcement mode `warn`, let the team build feature docs organically, switch to `block` once comfortable. |
| **stack frame** | One line in `.claude/current-feature`. The last line is the active frame; lines above are paused parents waiting for their children to close. |
| **PIVOT** | The third case of the fix-or-record rule: a blocking bug too large for an inline fix triggers a `/b` (assigns `BUG-NNNN`), a `[BLOCKED BY BUG-NNNN]` tag on the parent criterion, a `chore(pause):` commit of the working tree, and `/n` to push a blocker-fix feature onto the stack. |
| **pause commit** | A `chore(pause): <parent-slug> blocked by BUG-NNNN` commit created automatically by `/n` when the working tree is dirty at PIVOT time. Makes the parent's in-progress state recoverable on any machine. |
| **Bug ID** | A stable identifier of the form `BUG-NNNN` (zero-padded to 4 digits) assigned by `/b` at creation. Globally unique across tracker + archive + all feature docs; never reused. Appears in the tracker entry, the `[BUG-NNNN]` criterion tag, and any `[BLOCKED BY BUG-NNNN]` pivot reference. |
| **interrupt tag** | The `[BLOCKED BY BUG-NNNN]` prefix on a parent's success criterion indicating that criterion is paused pending a blocker fix pushed onto the stack. Pairs with the child feature doc's `## Interrupts: <parent-slug>` section. |

**Disambiguation: "scope" has three meanings in the framework. Always qualify:**
- **enforcement scope** = the directory tree where the framework applies (controlled by the marker file)
- **feature scope** = which files a feature doc covers (controlled by `## Scope` globs or directory position)
- **`## Scope` section** = the literal heading in a feature doc that contains glob patterns

## Quality

| Term | Definition |
|------|-----------|
| **session lifecycle** | The five-step sequence every work session follows: ORIENT, LOAD CONTEXT, WORK, VERIFY, CLOSE. See MEMORY.md. |
| **session handoff line** | The last entry in a progress checklist. Describes what to do next if you had 5 more minutes. Ensures the next session can resume without re-orienting. |
| **stuck protocol** | The procedure when spinning for more than 3 queries without progress: stop, re-read feature doc, re-read flow doc, check progress checklist for rejected approaches, ask the user. |
| **decision point** | A moment during implementation where intent should be recorded in the progress checklist BEFORE the code: starting a step, completing a step, rejecting an approach, or changing a criterion. |
| **vertical development** | Building complete slices through the entire stack per feature rather than building layers horizontally. Keeps reversal cost low. |
| **fix-or-record rule** | Three-way decision for bugs found during feature work: (1) FIX INLINE = under ~10 lines in code you are already touching, just fix it; (2) RECORD = non-blocking and doesn't fit case 1, use `/b` (mints `BUG-NNNN`) and move on; (3) PIVOT = blocking and doesn't fit case 1 (see PIVOT entry). |
| **discovery cost** | The token cost of a cold session orienting to a repo. Measured by asking four questions: what is this, what's done, what's broken, what's next. Budget: under 15k tokens. |
