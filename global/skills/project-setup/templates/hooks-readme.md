# Project Hooks

This directory holds hook scripts that fire IN ADDITION to the global hooks synced from `claude-config/hooks/` into `~/.claude/hooks/`. Both sets run on the same Claude Code events -- project hooks layer on top, they do not replace globals.

## Wiring

Add hook entries to `.claude/settings.json` at this repo root, pointing at the scripts in this directory. Example entry shape is in Claude Code's hooks documentation. Keep in mind Claude Code merges hook arrays -- your entries add to the global entries, they do not override them.

## Shell / PowerShell parity

If this project runs on multiple operating systems, ship `.sh` and `.ps1` for every hook. If it only runs on one OS, shell-only is acceptable -- note the tradeoff in the hook's feature doc.

## Placement model

See `.claude/rules/hook-placement.md` for the authoritative placement model (litmus test, common mistakes like hardcoding project branches into global hooks).
