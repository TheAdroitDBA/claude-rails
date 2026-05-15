# Feature: Sync Config Skill

## What It Does

`/sync-config` reconciles the local `claude-config` checkout with `origin/main`, then deploys the result to `~/.claude/` on the current machine. Handles the full matrix of divergence states: clean pull, clean push, dirty-behind, fully diverged.

## Concern

**framework.** Global-pool skill synced to every machine. Project-coupled steps (manifest regeneration, SCP deploy) have been stripped; the skill now contains only portable git+deploy logic.

## Success Criteria

1. Running `/sync-config` in a clean repo (`LOCAL == REMOTE`, no dirty files) reports IN_SYNC and performs no git mutations.
2. Behind remote only (`LOCAL == BASE`, `REMOTE != BASE`): fast-forward pull, no prompt, no conflicts possible.
3. Local commits only (`REMOTE == BASE`, `LOCAL != BASE`, nothing dirty): push without prompting.
4. Dirty working tree, nothing remote: stage, commit with an auto-generated short message, push.
5. Dirty working tree AND remote ahead: stash -> pull -> stash pop. If pop is clean, commit and push. If pop conflicts, fall through to conflict resolution.
6. Fully diverged (local and remote both advanced): attempt `git pull --rebase`. If clean, push. If conflicts, fall through to conflict resolution.
7. Conflict resolution asks the user side-by-side for each conflicted file using `AskUserQuestion`. Never auto-resolves.
8. After git state is reconciled, deploys to `~/.claude/` correctly for the local link style: if `~/.claude/skills` is a symlink, no-op; if it is a copy, `rm -rf` and re-copy, then warn the user that Claude Code must be relaunched.
9. Skill body contains no project-specific glob, no hardcoded IP, no deploy target. Manifest maintenance and any infrastructure deploy are adopted-repo concerns, not framework-skill concerns.
10. [BUG] Skill #9 hardcoded the glob `~/claude-config/skills/ydn-*/SKILL.md` -- it only regenerated the manifest for YDN skills. Project-specific coupling inside a "framework" skill. Resolved 2026-04-21 via global-pool-purity.feature.md -- the manifest-regeneration step was removed from this skill entirely.
11. [BUG] Step 5 hardcoded `scp ... root@10.0.0.11:/mnt/claude-config/` -- a specific home-lab deployment target baked into a framework skill. Resolved 2026-04-21 via global-pool-purity.feature.md -- the SCP deploy step was removed from this skill entirely.

## Status

DONE

### Progress

- [x] Criteria 1-9 closed: divergence-state handling, conflict resolution, `~/.claude/` deploy, project-neutral body.
- [x] Criterion 10 [BUG] -- resolved 2026-04-21: manifest regeneration step stripped (global-pool-purity.feature.md).
- [x] Criterion 11 [BUG] -- resolved 2026-04-21: SCP deploy step stripped (global-pool-purity.feature.md).
- [x] NEXT: handoff line -- user runs `sync` on each machine to propagate purged skill.

## Files

- global/skills/sync-config/SKILL.md

## Scope

global/skills/sync-config/**

## Honors

- decisions/0006 -- Global-pool skills must discover, not hardcode. Without decision 0006, this feature would look different because the skill would have "generalized" the manifest glob and deploy target rather than stripping them outright -- decision 0006 establishes that project-specific workflows do not belong in framework-pool skills regardless of how portable they look after refactoring.
