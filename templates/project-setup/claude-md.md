# [Project Name] -- Claude Code Instructions

## What this project is
[One to two sentences. This answers Q1.]

## Build & test
- Build: `[user's build command]`
- Test: `[user's test command]`
- Fix all compiler errors and warnings before considering a task complete.

## Token optimization (reading order)
Stop when you have enough context:
1. `.claude/rules/` -- invariants that never change
2. Sibling docs (`*.feature.md`, `*.flow.md`) next to the file being edited
3. `memory/` or `.claude/memory/` -- on-demand topic files
4. Source code -- last resort, read targeted files only

## Where things live
- Feature docs: colocated `*.feature.md` next to primary code
- Flow docs: colocated `*.flow.md` next to entry-point files
- Known issues: [actual path to issue tracker]
- Current feature anchor: `.claude/current-feature` -- LIFO stack, one slug per line, last line is the active feature. `/n` pushes; `/f` and `/fs` pop.
- Project-specific hooks/skills/agents: under `.claude/` (each directory has a README when populated)

## Framework essentials
- **Hard rules:** no emojis in .md files (plain text only); match file granularity to concern granularity (avoid both sprawl and concern bleed); hooks are opt-in per repo via `.claude/feature-doc-required`; all operations idempotent.
- **Outside-in design:** for features with a user-facing surface, write the flow doc first, then feature doc + criteria. Feature criteria must map to flow steps; they own the no-breaking-changes contract.
- **Progress checklist:** every in-progress feature doc has a `### Progress` checklist under `## Status`. Update it at every decision point BEFORE the code. Last entry names what to do NEXT.
- **Fix-or-record rule:** a bug found mid-feature has three cases: FIX INLINE (small + same file -- just fix it), RECORD (non-blocking + larger -- `/b` mints `BUG-NNNN`, move on, do not expand scope), or PIVOT (blocking + larger -- `/b` mints `BUG-NNNN`, tag parent criterion `[BLOCKED BY BUG-NNNN]`, `chore(pause):` commit, `/n` the blocker fix to push onto the stack).
- **Slash commands:** `/n` new feature, `/f` finalize, `/fs` finalize + full pipeline, `/b` bug record, `/bs` bug success, `/t` troubleshoot, `/w` what's open. Available via the claude-rails plugin (`claude --plugin-dir ~/claude-rails`).

## Plugin Enforcement

These instructions activate only in repos that have opted in via `.claude/feature-doc-required`. Skip all checks if that marker is absent.

### Feature-doc coverage (before any Edit / Write / MultiEdit / NotebookEdit)

1. Skip if the file path contains `/docs/`, `test`, `spec`, ends in `.json`, `.yml`, `.yaml`, `.toml`, `.md`, or the filename segment starts with `.`.
2. Walk up from the file's directory looking for `.claude/feature-doc-required`. If not found up to the repo root, skip.
3. Read `.claude/feature-doc-mode` at the scope root (default: `block`). `off` = skip; `warn` = allow but print a warning; `block` = refuse and explain.
4. Walk up from the file's directory to the repo root collecting all `*.feature.md` files.
5. For each feature doc: if it has a `## Scope` section, check whether the file's repo-relative path matches a scope glob. If it has no `## Scope`, it covers its directory and all descendants.
6. If a feature doc covers the file, proceed. If none do: apply mode decision -- in `block` mode, refuse and explain which feature doc to create or which `## Scope` to extend.

### Stale feature-doc check (at session end)

If `.claude/feature-doc-required` is present, review any `*.feature.md` files touched or read this session. Warn if any are missing a `## Success Criteria` or `## Status` section.

### Flow-doc presence check (when finishing a feature doc)

When completing a `*.feature.md` that has a `## Surface` section with non-trivial content: verify a `*.flow.md` exists within the feature's scope directory. If absent, warn before stopping: "Feature has a `## Surface` declaration but no `*.flow.md` -- create one to document entry points and failure modes."

## Conventions
[Stack-specific: naming, linting, testing framework]

<!-- PYTHON: For Python projects, append the section below to the Conventions section. -->
## Python environment
- Create venv: `py -m venv .venv` (Windows) or `python3 -m venv .venv` (Mac/Linux)
- Activate: `source .venv/Scripts/activate` (Windows/Git Bash) or `source .venv/bin/activate` (Mac/Linux)
- After activation, `python` and `pip` work on all platforms.
- All dependencies in `requirements.txt`. Install: `pip install -r requirements.txt`
- Never install packages globally or ad-hoc outside requirements.txt.
- `.venv/` must be in `.gitignore`.
