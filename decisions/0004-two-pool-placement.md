# 0004: Two-pool placement for skills, agents, and hooks

## Status

ACCEPTED -- 2026-04-21

## Context

Some skills, agents, and hooks are universally useful -- every project benefits from them (e.g. feature-doc enforcement, the troubleshoot skill). Others are project-specific -- they hardcode IPs, hostnames, or deployment targets that only make sense in one repo. A single global pool would accumulate project hardcodes and become unshippable. A single project pool would require every common skill to be re-cloned into every repo.

## Decision

Every unit of work (skill, agent, hook) lives in exactly one of two pools:

- **Global pool** (shipped via the claude-rails plugin) -- framework-scoped, available in every session that loads the plugin. Contents must be project-neutral: no hardcoded IPs, hostnames, or deployment targets for any specific project. Skills and agents live in `claude-rails/global/{skills,agents}/`. Hooks live in `claude-rails/.claude-plugin/hooks/hooks.json`.
- **Project pool** (`<project>/.claude/{skills,agents}/` and `<project>/.claude/settings.json` for hooks) -- project-scoped, lives in the project repo. May reference project-specific targets freely.

The litmus test: if the artifact references a specific IP, hostname, or deployment target that only exists in one project, it belongs to that project's pool. Otherwise it belongs to the global pool.

## Consequences

- Loading the plugin makes the global pool available automatically. No per-machine sync, symlinks, or junctions needed for skills and agents.
- Global hooks auto-wire via the plugin's `hooks/hooks.json`. Project hooks are wired in `<project>/.claude/settings.json`. Both fire on the same events; project hooks layer on top, they do not replace globals.
- A naming collision between a global-pool skill and a project-pool skill resolves to the project pool (project-local wins).
- Promotion and demotion are explicit moves: a project-pool skill that proves universal is promoted to global (generalization pass to strip project hardcodes). A global-pool skill that accumulates project references is demoted.
- Three corresponding rules files document the pool model -- one per unit: `rules/skill-placement.md`, `rules/agent-placement.md`, `rules/hook-placement.md`.

## Alternatives Considered

- **Single global pool with project-override subdirectories** -- rejected. Project-specific content still lives in claude-rails's git history, leaking one user's deployment details to every cloner.
- **Single project pool; ship nothing globally** -- rejected. Every repo would re-implement common skills independently, guaranteeing drift.
- **Three pools (global, org, project)** -- rejected as premature. A middle "org" tier adds complexity nobody has asked for; revisit if cross-team reuse becomes a real pattern.
