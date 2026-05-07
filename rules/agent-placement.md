# Agent Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where agents live and how Claude Code resolves between the two agent pools.

## Invariants

- Two pools exist: the **global pool** at `~/.claude/agents/` (symlinked from `claude-config/global/agents/` by sync) and the **project-local pool** at `<project>/.claude/agents/`. Both are loaded when Claude Code runs inside a project; the project pool shadows the global pool by agent name.
- Global agents contain **portable knowledge only** (domain expertise like DNS, video, UX review) or **framework mechanics** (agents that read feature docs, generic code review). They MUST NOT reference specific project skills, hostnames, file paths, databases, or repo names.
- Project agents are coupled to one project. They live in that project's `.claude/agents/`, never in the global pool.
- An agent exists in **exactly one pool at a time**. Never duplicated across global and project. Two copies means drift is guaranteed.
- Agents at `<project>/agents/` (without the `.claude/` prefix) are NOT loaded by Claude Code. If you find one there, either move it to `<project>/.claude/agents/` or delete it. There is no legitimate home outside those two paths.

## How to Apply

- **Placement litmus test:** does the agent reference a specific project's skills, hostnames, IPs, file paths, repo structure, database names, or brand? If yes -> project pool. If no -> global pool. If unsure, read the agent file and grep it for proper nouns.
- **Promotion (project -> global):** when an agent's content becomes fully portable (all project references stripped), move it to `claude-config/global/agents/` via `git mv`. Commit both sides.
- **Demotion (global -> project):** when an agent gains project-specific content, either (a) remove the project references to keep it global, or (b) move it to `<project>/.claude/agents/` via `git mv`. Never leave a project-coupled agent sitting in the global pool.
- **Re-running `/project-setup`** never clobbers existing agents in either pool. Scaffolding is additive.
- **When a user asks "why isn't my agent firing?"** check: (1) is it under `.claude/agents/`? (2) does a same-named agent in the global pool shadow it unintentionally? (3) is the frontmatter valid?

## Common Mistakes

- Leaving an agent in the global pool after it gains project-specific references (e.g., an "expert" agent that hardcodes specific skill names like `infra-pihole` or `mv-db-query`).
- Creating an agent at `<project>/agents/<name>.md` instead of `<project>/.claude/agents/<name>.md`. Claude Code silently skips the first location.
- Keeping both a global and project copy of the "same" agent. Even if the content is byte-identical today, it will diverge.
- Writing a "domain expert" agent that includes a project-specific section (stack-specific patterns, naming conventions for one codebase). That is not domain expertise; it is project coupling dressed up.
