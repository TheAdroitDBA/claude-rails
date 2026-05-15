# Flow: Project Setup

## Entry Point

User invokes `/project-setup` inside any git repository. The skill orchestrates onboarding that repo into the claude-config framework (or auditing and bringing an already-adopted repo into compliance).

## Object Matrix

claude-config ships framework content via two pools. Project-setup's core job is deciding, per object type, which pool owns what and scaffolding the project side idempotently. Every row below is a decision project-setup must make during every run.

| Object | Global pool | Project pool | How Claude Code loads | Project-setup responsibility |
|---|---|---|---|---|
| Memory | (none -- memory is inherently project-scoped) | `<project>/memory/MEMORY.md` + topic files | Auto-loaded per-project | Scaffold `memory/` + `MEMORY.md` stub if missing. Never overwrite existing files. If repo uses `.claude/memory/` instead, recognize that and do not create a parallel `memory/`. |
| Hooks | `~/.claude/hooks/` (symlinked from `claude-config/hooks/` by sync) | `<project>/.claude/hooks/` | Both fire; project settings.json hook entries layer on top of global `~/.claude/settings.json` | Scaffold `<project>/.claude/hooks/` directory + `README.md` explaining the layered model. Never clobber existing hooks on re-run. |
| Skills | `~/.claude/skills/` (symlinked from `claude-config/skills/` by sync) | `<project>/.claude/skills/` | Both visible; project shadows global by skill name | Scaffold `<project>/.claude/skills/` + `README.md` if the repo has or wants project-specific skills. Never clobber. |
| Agents | `~/.claude/agents/` (symlinked from `claude-config/agents/` by sync) | `<project>/.claude/agents/` | Both visible; project shadows global by agent name | Scaffold `<project>/.claude/agents/` + `README.md`. Never clobber. |
| Memory-snippet | `claude-config/memory-snippet.md` | n/a -- the snippet IS project content once injected | Injected into `<project>/memory/MEMORY.md` by sync step 4, between `claude-config:framework-start`/`-end` markers | Ensure the project has a consent signal (marker file). Sync consults that signal; project-setup never writes the snippet directly. |
| Rules templates | `claude-config/rules/*.md` (authoring source for claude-config's own use) | `<project>/.claude/rules/*.md` (project-owned; project writes its own) | Project-only | Do NOT copy framework invariants (placement rules) into adopted repos. Those live only in claude-config. Framework essentials are inlined into the adopted repo's CLAUDE.md at scaffold time. Opinionated domain templates (`error-ux`, `data-integrity`) are written inline from SKILL.md heredocs when user approves -- no source lookup. |
| Framework markers | n/a | `<project>/.claude/feature-doc-required`, `<project>/.claude/feature-doc-mode`, `<project>/.claude/current-feature` | Read by hooks on each invocation | Create the marker file if missing (on approval). Default mode to `warn` for new repos; never silently loosen an existing mode. `current-feature` is only set on explicit confirmation. |
| Feature docs | n/a -- feature docs are colocated, never global | `<slug>.feature.md` next to primary code, anywhere in the repo | Loaded by `require-feature-doc` hook and sessions that open the file | Do not create feature docs. Detect and migrate legacy `docs/features/*.md` to colocated positions. Flag duplicates and missing docs. |
| Flow docs | n/a -- colocated, never global | `<slug>.flow.md` next to entry-point file | Loaded on demand by sessions | Do not create flow docs. Detect and migrate legacy `docs/flows/*.md`. |
| docs.export.yml | n/a | `<project>/docs.export.yml` | Consumed by the docs-export pipeline (separate feature) | Scaffold a stub manifest if the repo has a `repo_url`. Never overwrite. |

## Pipeline

| Phase | Step | Action | Halt condition |
|---|---|---|---|
| 1 Audit | 1 | `git rev-parse --show-toplevel` -> PROJECT_ROOT | not a git repo |
| 1 Audit | 2 | Read existing state: `CLAUDE.md`, `.claude/*`, `memory/` or `.claude/memory/`, `README.md`, top-level directory listing | -- |
| 1 Audit | 3 | Detect legacy layouts: presence of `docs/features/` or `docs/flows/` directories | -- |
| 1 Audit | 4 | Sweep for misplaced `.md` framework docs: any file containing `## Success Criteria` or a flow-doc step table that is NOT colocated with its code | -- |
| 1 Audit | 5 | Detect duplicates: two or more files that would become the same colocated target basename | found duplicate -> Phase 3 ASK before proceeding |
| 1 Audit | 6 | Run orientation audit (Q1-Q5) reading content, not just existence. PASS / WEAK / FAIL per question | -- |
| 2 Decide | 7 | For each Object Matrix row, compute the action: scaffold / migrate / copy / no-op | -- |
| 2 Decide | 8 | For each legacy doc and misplaced `.md`, compute target colocated path | unresolvable target (ambiguous primary code) -> Phase 3 ASK |
| 2 Decide | 9 | For each collision (target exists with different content), compute merge plan (which sections converge, which diverge) | diverging Success Criteria or Status -> Phase 3 ASK |
| 3 Ask | 10 | Batch prompt: present audit findings (Q1-Q5), proposed scaffolds, proposed migrations, proposed copies, proposed merges. Group by Object Matrix row. Ask user "all / pick by number / skip" | -- |
| 3 Ask | 11 | For each collision flagged in step 9, show diff side-by-side and ask which version is authoritative per conflicting section | user declines to resolve -> skip that migration, continue with the rest |
| 3 Ask | 12 | For each duplicate flagged in step 5, show the two (or more) candidate sources and ask which to keep | user declines to resolve -> halt migration; the rest of the pipeline still runs for non-duplicated items |
| 4 Execute | 13 | Scaffold missing directories (idempotent `mkdir -p`) | -- |
| 4 Execute | 14 | Scaffold missing markers and stubs (CLAUDE.md, README.md Troubleshooting runbook, memory/MEMORY.md stub, etc.) -- only write if file does not already exist | -- |
| 4 Execute | 15 | Migrate legacy docs: for each, `git mv <legacy> <colocated>`. Never `rm`. If `git mv` cannot preserve history (different worktree, etc.), fall back to `cp` + `git rm <old>` + `git add <new>` but only after warning the user | git mv fails -> report, skip that doc, continue |
| 4 Execute | 16 | Merge on collision: apply the section-by-section resolution from step 11. Preserve git history via `git mv`. | -- |
| 4 Execute | 17 | Rewrite references: grep the repo for the old paths; update each hit. Limit to CLAUDE.md, README.md, MEMORY.md, other `*.feature.md`/`*.flow.md`, rules files. | no hits -> no-op |
| 4 Execute | 18 | Copy approved rules templates from `~/.claude/rules/` to `<project>/.claude/rules/`. Only write if destination does not already exist. | -- |
| 4 Execute | 19 | Remove emptied `docs/features/` and `docs/flows/` directories | -- |
| 5 Verify | 20 | Re-run orientation audit from step 6. Every WEAK or FAIL from step 6 should now be PASS. | any remaining WEAK or FAIL -> report it explicitly, do not silently pass |
| 5 Verify | 21 | Print Quick Next Steps block with actual values (`.claude/feature-doc-mode` current setting, named primary feature if any, concrete next actions) | -- |

## Migration Sub-Pipeline (legacy docs/features + docs/flows)

Handled inline above in steps 3, 4, 8, 9, 11, 15, 16, 17, 19. This sub-pipeline exists because the legacy layout is the single largest compliance gap for existing repos.

### Move semantics

- `git mv`, never `rm`. History must be preserved.
- If a file at the colocated target already exists: do not overwrite. Enter merge-on-collision (step 16).
- If two or more legacy files would land at the same target basename: halt and ask (step 12). Example: `docs/features/login.md` and `docs/features/auth-login.md` both proposed for `src/auth/login.feature.md`.

### Merge-on-collision rules

- **Success Criteria list**: union by text similarity. Identical or trivially-different lines merge silently. Semantically different lines ask the user which is authoritative and whether to keep both, keep one, or rewrite.
- **Status line**: if both say DONE, keep DONE. If they disagree, ask.
- **Progress checklist**: merge by commit hash -- union both sets of entries in chronological order.
- **What It Does / What It Does Not**: concatenate both, ask user to trim.
- **Files / Scope**: union both lists.
- **Flow doc step table**: if both describe the same pipeline, ask user which to keep. If they describe different pipelines under the same filename, this is a bug in one of them -- ask the user to rename one and keep both.

### Reference rewrite patterns

After a legacy file moves, every hit for the old path must be rewritten:

- `[link text](docs/features/foo.md)` -> `[link text](<new-colocated-path>)`
- Bare text `docs/features/foo.md` -> `<new-colocated-path>`
- Glob or find commands that include `docs/features/` -> update or remove the glob

## Per-Object Scaffolding Details

### Memory

- If `<project>/memory/MEMORY.md` and `<project>/.claude/memory/MEMORY.md` both missing: scaffold `memory/` unless user explicitly wants `.claude/memory/`.
- If one exists: leave it alone. Do not create the other.
- MEMORY.md stub content: project name header, Framework link to `~/claude-config/MEMORY.md`, empty Reference files section, Known issues pointer, Token hierarchy list.

### Hooks (.claude/hooks/)

- Scaffold empty directory + `.claude/hooks/README.md` with this content:

    Layered hook model. Global hooks come from claude-config via sync:
    settings.json files in `~/.claude/` wire them to Claude Code events.
    Project-local hooks live in this directory AND must be wired in this
    repo's `.claude/settings.json`. Project hook entries layer on top of
    the global hook chain for the same event. Never edit the global hooks
    from this directory.

- Do not scaffold hook scripts. Users add them explicitly.

### Skills (.claude/skills/)

- Scaffold empty directory + `.claude/skills/README.md` with:

    Project-local skills. Shadow the global skill by name. Keep the
    `<project-prefix>-<skill-name>/` convention (e.g., `ydn-db-query/`,
    `mv-errors/`) so skill names never collide with the global pool.

### Agents (.claude/agents/)

- Scaffold empty directory + `.claude/agents/README.md` with the two-pool explanation and a pointer to `rules/agent-placement.md` (in Phase 2.5).

### Rules templates

- On approval, copy each selected template from `~/.claude/rules/` to `<project>/.claude/rules/<same-filename>`.
- If destination exists: skip and report.
- Templates expected: `agent-placement.md`, `skill-placement.md`, `hook-placement.md`, `test-placement.md`, `error-ux.md`, `data-integrity.md`, `feature-criteria.md`, `flow-docs.md`.

### docs.export.yml

- If `git remote get-url origin` returns a URL AND `docs.export.yml` does not already exist: scaffold with `project:`, `repo_url:`, `branch: main`, and a stub `nav:` pointing at README.md only.
- User adds real docs to `nav:` as they create them.

## Failure Modes

- **Not a git repo**: `git rev-parse --show-toplevel` fails. Skill exits with instruction to `git init` first. No files written.
- **User aborts mid-scaffold**: idempotent design means a partial run is safe. Re-running `/project-setup` resumes: what was scaffolded stays, what was not gets proposed again.
- **Collision with pre-existing custom file**: never overwrite. Skip and report; user decides out-of-band whether to integrate manually.
- **Missing global template**: if a requested rule template is missing from `~/.claude/rules/`, skip it and warn the user. Do not fail the whole run.
- **Missing sidecar template**: if a file under `~/.claude/skills/project-setup/templates/` is missing when scaffolding is requested, report the specific missing path and instruct the user to run `/sync-config` to restore it. Skip that scaffold item and continue with the rest. Do not fail the whole run.
- **Settings.json merge conflict**: project-setup does not edit `.claude/settings.json`. If hook wiring is needed at the project level, skill prints the lines to add and asks the user to add them manually (avoids clobbering user-authored settings).
- **git mv fails**: report the specific error, skip that migration, continue with the rest. Never fall back to destructive operations silently.
- **Two feature docs for the same unit of work surface during sweep**: halt migration for that unit until the user resolves. The rest of the pipeline continues.
- **Re-run during active feature work**: `.claude/current-feature` exists and points at a real in-progress feature. Skill detects this and skips any proposal that would rewrite references in that feature's files without explicit confirmation.

## Cross-OS Matrix

Project-setup is a skill (procedural markdown), so it has no shell/PowerShell parity concern -- Claude follows the same SKILL.md steps on every OS. The shell commands embedded in those steps must be portable. Specifically:

| Concern | Mac/Linux | Windows (Git Bash) |
|---|---|---|
| Repo root | `git rev-parse --show-toplevel` | same (Git Bash provides posix paths) |
| Directory creation | `mkdir -p` | same |
| File existence check | `[ -f ... ]` | same |
| Symlink vs copy detection | `[ -L ~/.claude/skills ]` | same (Git Bash honors the link) |
| Venv activation (Python stacks) | `source .venv/bin/activate` | `source .venv/Scripts/activate` |
| venv creation | `python3 -m venv .venv` | `py -m venv .venv` |

Anything `project-setup` emits in its Quick Next Steps block MUST use the right variant for the detected OS.

## Files Involved

- global/skills/project-setup/SKILL.md (the procedural definition)
- global/skills/project-setup/project-onboarding.feature.md (success criteria, including 10-14 this flow implements)
- global/skills/project-setup/feature.template.md (used during scaffolding)
- rules/ (source of truth for rules templates; Phase 2.5 adds three more)
- memory-snippet.md (consulted by sync, not written by project-setup; but project-setup sets up the consent signal)
