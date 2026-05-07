# 0004: Two-pool placement for skills, agents, and hooks

## Status

ACCEPTED — 2026-04-21

## Context

Some skills, agents, and hooks are universally useful — every project benefits from them (e.g. shorthand expansion, feature-doc enforcement, the troubleshoot skill). Others are project-specific — they hardcode IPs, hostnames, or deployment targets that only make sense in one repo (e.g. an infra skill that talks to a specific Proxmox cluster). A single global pool would accumulate project hardcodes and become unshippable. A single project pool would require every common skill to be re-cloned into every repo, which defeats the point of claude-config as an authoritative installer.

## Decision

Every unit of work (skill, agent, hook) lives in exactly one of two pools:

- **Global pool** (`claude-config/global/{skills,agents,hooks}/`) — framework-scoped, shipped to every machine via `sync`. Contents must be project-neutral: no hardcoded IPs, hostnames, or deployment targets for any specific project.
- **Project pool** (`<project>/.claude/{skills,agents,hooks}/`) — project-scoped, lives in the project repo. May reference project-specific targets freely.

The litmus test: if the artifact references a specific IP, hostname, or deployment target that only exists in one project, it belongs to that project's pool. Otherwise it belongs to the global pool.

## Consequences

- `sync` links `claude-config/global/{skills,agents,hooks}/` into `~/.claude/` via symlink (Unix) or junction (Windows). Every machine that clones claude-config gets the global pool automatically.
- Project pools are NOT synced by claude-config. They live in the project repo and are claimed by Claude Code's native per-project `.claude/` discovery.
- A naming collision between a global-pool skill and a project-pool skill resolves to the project pool (project-local wins). This is the project-override pattern — intentional, and a separate feature (`global-pool-namespace`) governs the naming convention.
- Promotion and demotion are explicit moves: a project-pool skill that proves universal is promoted to global (file move + generalization pass to strip project hardcodes). A global-pool skill that accumulates project references is demoted. Both moves touch git history and are reviewable.
- Three corresponding rules files document the pool model — one per unit: `rules/skill-placement.md`, `rules/agent-placement.md`, `rules/hook-placement.md`.

## Alternatives Considered

- **Single global pool with project-override subdirectories** — rejected. Project-specific content still lives in claude-config's git history, leaking one user's deployment details to every other cloner.
- **Single project pool; ship nothing globally** — rejected. Every repo would re-implement common skills independently, guaranteeing drift.
- **Three pools (global, org, project)** — rejected as premature. A middle "org" tier would be useful for multi-team orgs but adds complexity nobody has asked for; revisit if cross-team reuse becomes a real pattern.

## Affected Features

- rules/skill-placement.md
- rules/agent-placement.md
- rules/hook-placement.md
- global-pool-namespace.feature.md (naming convention for global-pool artifacts)
- sync.flow.md (linking step)
- global/skills/project-setup/SKILL.md (scaffolds `.claude/{skills,agents,hooks}/` shells into new repos)
- MEMORY.md (Rules Templates section distinguishing framework invariants from opinionated templates)
