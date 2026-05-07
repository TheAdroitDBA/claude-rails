# Claude-Rails

## Repo Purpose

See [README.md](README.md) for the canonical purpose statement. One sentence summary: a portable framework that eliminates token waste, repetitive tasks, and inconsistent project shape across every repo you work on.

## Token Optimization

ALWAYS read MEMORY.md first. It is the single canonical description of the framework. Then consult topic files in memory/ on demand. Do not read hook source -- read `global/hooks/hook-lifecycle.flow.md` instead.

## Build & Test

No compiled build. Distribution is via Claude Code's native plugin system: register in `~/.claude/settings.json` (one-time). Pass `claude --plugin-dir /path/to/claude-rails` only for testing without committing to settings. See README.md Quick Start. Slash commands are wired via `link-commands.sh` / `link-commands.ps1` (one-time per machine). Edits to the repo are live immediately.

## Conventions

- Plain-text .md only (no emojis).
- Framework skills and domain-expert commands live in `commands/`, delivered via the `link-commands` junction. Global-pool hooks live under global/hooks/; agents under global/agents/. The plugin delivers hooks and agents; commands are available in every session via the junction.

## Do Not

- Do not hardcode paths to specific projects in hooks.
- Do not inject project-specific content into adopted-repo CLAUDE.md scaffolding.
- Do not add emojis to any .md file.

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
