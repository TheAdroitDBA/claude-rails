# Skill Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where skills live and how Claude Code resolves between the two skill pools.

## Invariants

- Two pools exist: the **global pool** (shipped via the claude-rails plugin, lives in `claude-rails/global/skills/`) and the **project-local pool** at `<project>/.claude/skills/`. Both are visible when Claude Code runs inside a project; the project pool shadows the global pool by skill name.
- Global skills are one of two kinds: **framework-level** (universal workflows like `project-setup`, `docs-audit`, `troubleshoot`, `startup-audit`) or **domain-expert** (portable knowledge like `software-architect`, `security-expert`, `testing-expert`). Both kinds MUST work on any project without modification.
- Project skills are coupled to one project. They reference that project's databases, hostnames, file paths, conventions, deployment targets.
- **Prefix convention:** project skills use a `<project-slug>-<skill-name>/` directory name. Global skills have no prefix.
- A skill exists in **exactly one pool at a time**. No duplicates. A skill's presence in the global pool is a promise that it has no project coupling.
- Domain-expert skills MUST NOT contain project-specific sections.

## How to Apply

- **Placement litmus test:** grep the skill for proper nouns, absolute paths, IPs, hostnames, specific file references. If any appear and relate to one project -> project pool. If none -> global pool.
- **Promotion (project -> global):** rename the skill to drop the prefix when its content becomes fully portable. Update the skill's description and frontmatter accordingly.
- **Demotion (global -> project):** when a global skill gains project-specific content, split or move. Never leave a project-coupled skill in the global pool pretending to be portable.

## Common Mistakes

- Mixing project conventions into a domain-expert skill (e.g., a "UI expert" that hardcodes one project's component patterns).
- Keeping the project prefix on a skill that has become fully generic. Prefixes track coupling, not authorship.
- Adding a project-specific skill (with prefix) to the global pool and calling it a "domain expert".
- Creating a skill at `<project>/skills/<name>/` instead of `<project>/.claude/skills/<name>/`. Only `.claude/skills/` is loaded at project scope.
