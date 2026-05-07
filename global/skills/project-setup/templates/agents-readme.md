# Project Agents

This directory holds agents specific to this project. They coexist with global agents provided by the claude-rails plugin.

## Resolution

If an agent in this directory shares a name with a global agent, the project version wins inside this repo. Same-name shadowing is an override -- use sparingly, not as a default pattern.

## Placement model

See `.claude/rules/agent-placement.md` for the authoritative placement model (litmus test, promotion/demotion rules, common mistakes).

## Framework-level agents (already global, do not copy here)

- `ux-reviewer` -- invoked by `/fs` when a feature doc declares `## Surface`.
- `qa-tester` -- invoked by `/fs` step 2 to check success criteria.
