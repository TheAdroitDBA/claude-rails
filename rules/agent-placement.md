# Agent Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where agents live and how Claude Code resolves between the two agent pools.

## Invariants

- Two pools exist: the **global pool** (shipped via the claude-rails plugin, lives in `claude-rails/global/agents/`) and the **project-local pool** at `<project>/.claude/agents/`. Both are loaded when Claude Code runs inside a project; the project pool shadows the global pool by agent name.
- Global agents contain **portable knowledge only** (domain expertise like DNS, video, UX review) or **framework mechanics** (agents that read feature docs, generic code review). They MUST NOT reference specific project skills, hostnames, file paths, databases, or repo names.
- Project agents are coupled to one project. They live in that project's `.claude/agents/`, never in the global pool.
- An agent exists in **exactly one pool at a time**. Never duplicated across global and project. Two copies means drift is guaranteed.
- Agents at `<project>/agents/` (without the `.claude/` prefix) are NOT loaded by Claude Code. If you find one there, either move it to `<project>/.claude/agents/` or delete it.

## How to Apply

- **Placement litmus test:** does the agent reference a specific project's skills, hostnames, IPs, file paths, repo structure, database names, or brand? If yes -> project pool. If no -> global pool.
- **Promotion (project -> global):** when an agent's content becomes fully portable (all project references stripped), move it to `claude-rails/global/agents/`.
- **Demotion (global -> project):** when an agent gains project-specific content, either remove the project references to keep it global, or move it to `<project>/.claude/agents/`.
- **Re-running `/project-setup`** never clobbers existing agents in either pool. Scaffolding is additive.

## Common Mistakes

- Leaving an agent in the global pool after it gains project-specific references.
- Creating an agent at `<project>/agents/<name>.md` instead of `<project>/.claude/agents/<name>.md`. Claude Code silently skips the first location.
- Keeping both a global and project copy of the "same" agent. Even if identical today, they will diverge.
- Writing a "domain expert" agent that includes a project-specific section. That is project coupling, not domain expertise.
