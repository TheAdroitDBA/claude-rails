# Glossary

Canonical vocabulary for the claude-rails framework. Use these terms precisely in docs, code comments, and conversation.

## Core Mechanics

| Term | Definition |
|------|-----------|
| **framework** | The whole claude-rails pattern: plugin manifest, hooks, feature-doc conventions, enforcement rules, skills, agents, and slash commands. |
| **plugin install** | Registering claude-rails in `~/.claude/settings.json` or running Claude Code with `--plugin-dir /path/to/claude-rails`. Loads global-pool skills, agents, and hooks for the session. |
| **commands link** | The one-time symlink/junction created by `link-commands.sh` (Mac/Linux) or `link-commands.ps1` (Windows) that makes `~/.claude/commands/` point at `claude-rails/commands/`. |

## Units of Work

| Term | Definition |
|------|-----------|
| **skill** | A custom slash command defined by a `SKILL.md` file in a skill directory. Invoked in chat as `/<skill-name>`. Lives under `global/skills/<name>/` for framework skills or `.claude/skills/<name>/` for project-specific skills. |
| **slash command** | The invocation form (`/<name>`) of a skill or command. Source files live in `commands/` (for short workflow commands) or `global/skills/<name>/SKILL.md` (for full skills). |
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
| **current-feature pointer** | `.claude/current-feature` -- a file containing the slug of the feature currently being worked on. Helps sessions resume without re-orienting. |
| **incremental adoption** | The recommended approach: start with enforcement mode `warn`, let the team build feature docs organically, switch to `block` once comfortable. |

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
| **fix-or-record rule** | Three-way decision for bugs found during feature work: (1) blocking = fix inline, (2) small + same file = fix inline, (3) everything else = record with `/b` and move on. |
| **discovery cost** | The token cost of a cold session orienting to a repo. Measured by asking four questions: what is this, what's done, what's broken, what's next. Budget: under 15k tokens. |
