# Claude-Rails

<!-- claude-rails:start v0.1.0 sha=e74b74e1 -->
This repository follows the [claude-rails](https://github.com/TheAdroitDBA/claude-rails) framework (v0.1.0).
Canonical rules: `~/.claude/MEMORY.md`.
Entry point: run `/w` for "what's next" (open features, bugs, stack state).
Update this block with `/rails-sync` when the framework version changes.
<!-- claude-rails:end -->

## Repo Purpose

See [README.md](README.md) for the canonical purpose statement. One sentence summary: a portable framework that eliminates token waste, repetitive tasks, and inconsistent project shape across every repo you work on.

## Token Optimization

ALWAYS read MEMORY.md first. It is the single canonical description of the framework. Then consult topic files in memory/ on demand. Do not read hook source -- read `global/hooks/hook-lifecycle.flow.md` instead.

## Build & Test

No compiled build. Run `install.sh` (Mac/Linux) or `install.ps1` (Windows) from this directory -- it links commands and registers the plugin in one step. Pass `claude --plugin-dir /path/to/claude-rails` only for testing without committing to settings. Edits to the repo are live immediately.

## Framework Health

If slash commands are not responding or enforcement hooks are not firing, diagnose and fix:

1. Commands: verify `~/.claude/commands/` points at this repo's `commands/`. If not, run the install script or create the junction manually.
2. Plugin: verify `~/.claude/settings.json` has `claude-rails` in `extraKnownMarketplaces`. If not, read the file, add the registration keys, and write it back.
3. Per-repo enforcement: verify `.claude/feature-doc-required` exists in the target repo. If absent, enforcement is inactive by design -- run `/project-setup` to opt in.

## Conventions

- Plain-text .md only (no emojis).
- Framework skills and domain-expert commands live in `commands/`, delivered via the install-script junction. Global-pool hooks live under global/hooks/; agents under global/agents/. The plugin delivers hooks and agents; commands are available in every session via the junction.

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
