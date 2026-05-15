---
name: sync-config
description: Sync Claude Code config (skills + settings) across machines
---

# Sync Config

## Step 1: Detect state

```bash
cd ~/claude-config && git add -A && git fetch origin && LOCAL=$(git rev-parse HEAD) && REMOTE=$(git rev-parse origin/main) && BASE=$(git merge-base HEAD origin/main) && DIRTY=$(git status --porcelain) && if [ -n "$DIRTY" ] && [ "$LOCAL" != "$REMOTE" ] && [ "$LOCAL" != "$BASE" ] && [ "$REMOTE" != "$BASE" ]; then echo "DIVERGED_WITH_LOCAL"; elif [ -n "$DIRTY" ] && [ "$LOCAL" != "$REMOTE" ] && [ "$LOCAL" = "$BASE" ]; then echo "DIRTY_BEHIND"; elif [ -n "$DIRTY" ]; then echo "PUSH"; elif [ "$LOCAL" = "$REMOTE" ]; then echo "IN_SYNC"; elif [ "$LOCAL" = "$BASE" ]; then echo "PULL"; elif [ "$REMOTE" = "$BASE" ]; then echo "PUSH_COMMITTED"; else echo "DIVERGED"; fi
```

## Step 2: Act on result

- **IN_SYNC**: Tell user everything is up to date. Still run remaining steps.
- **PULL**: `cd ~/claude-config && git pull` -- fast-forward only, no conflicts possible.
- **PUSH**: Stage, commit with a short message describing changes, push.
- **PUSH_COMMITTED**: Just push.
- **DIRTY_BEHIND**: Local uncommitted changes AND remote has new commits. Do:
  1. `git stash`
  2. `git pull`
  3. `git stash pop`
  4. If stash pop is clean (additions only), commit and push.
  5. If stash pop has conflicts, go to conflict resolution below.
- **DIVERGED** or **DIVERGED_WITH_LOCAL**: Attempt `git pull --rebase`. If clean, push. If conflicts, go to conflict resolution.

## Step 3: Deploy to ~/.claude (CRITICAL on Windows)

After git sync completes, check if `~/.claude/skills` is a symlink:

```bash
if [ -L ~/.claude/skills ]; then echo "SYMLINKED"; else echo "COPIED"; fi
```

- **SYMLINKED**: No action needed, changes propagate automatically.
- **COPIED**: Run this to update the local copy:
  ```bash
  rm -rf ~/.claude/skills && cp -r ~/claude-config/skills ~/.claude/skills && touch ~/.claude/skills/.copied-from-repo && echo "Skills deployed"
  cp ~/claude-config/settings.json ~/.claude/settings.json && echo "Settings deployed"
  ```

**IMPORTANT**: After deploying copied files, tell the user:
> **You must close and relaunch Claude Code** for the changes to take effect. Skills and settings are loaded at startup.

## Conflict Resolution

When conflicts occur:

1. Run `git diff --name-only --diff-filter=U` to list conflicted files.
2. For each conflicted file, read it and show the user both versions side by side:
   - **LOCAL (yours)**: the version on this machine
   - **REMOTE (other machine)**: the version from the repo
3. Ask the user which to keep for each conflict using AskUserQuestion.
4. Apply their choice, mark resolved, commit, and push.

## Summary

After sync, summarize in one line what happened (e.g., "Pulled settings update", "Resolved conflict in settings.json", "Pushed local changes"). If files were copied (not symlinked), always remind: **close and relaunch Claude Code**.
