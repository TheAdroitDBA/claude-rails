# Skill Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where skills live and how Claude Code resolves between the two skill pools.

## Invariants

- Two pools exist: the **global pool** at `~/.claude/skills/` (symlinked from `claude-config/global/skills/` by sync) and the **project-local pool** at `<project>/.claude/skills/`. Both are visible when Claude Code runs inside a project; the project pool shadows the global pool by skill name.
- Global skills are one of two kinds: **framework-level** (universal workflows like `project-setup`, `sync-config`, `docs-audit`, `troubleshoot`, `startup-audit`) or **domain-expert** (portable knowledge like `ui-expert`, `video-expert`, `minecraft`). Both kinds MUST work on any project without modification.
- Project skills are coupled to one project. They reference that project's databases, hostnames, file paths, conventions, deployment targets.
- **Prefix convention:** project skills use a `<project-slug>-<skill-name>/` directory name (`ydn-db-query`, `mv-errors`, `infra-pihole`, `adroitdba-website`). Global skills have no prefix.
- A skill exists in **exactly one pool at a time**. No duplicates. A skill's presence in the global pool is a promise that it has no project coupling.
- Domain-expert skills MUST NOT contain project-specific sections. A section titled "<ProjectName> Patterns" inside a supposedly-domain-expert skill is a violation.

## How to Apply

- **Placement litmus test:** grep the skill for proper nouns, absolute paths, IPs, hostnames, specific file references. If any appear and relate to one project -> project pool. If none -> global pool (and double-check the prefix: missing or wrong prefix is itself a bug).
- **Promotion (project -> global):** rename the skill to drop the prefix when its content becomes fully portable. `git mv global/skills/mv-video-expert global/skills/video-expert`. Update the skill's description and frontmatter accordingly.
- **Demotion (global -> project):** when a global skill gains project-specific content, **split or move**. Split: extract the portable parts into a new prefix-less global skill, extract the project parts into a new prefixed project skill. Move: relocate the whole skill to the project pool and add the prefix. Never leave a project-coupled skill in the global pool pretending to be portable.
- **Staging directory (`claude-config/migration/`):** used when skills have been identified as project-specific but have not yet been relocated to their owning project repos. Skills in `migration/` are read-only and not considered framework features.

## Common Mistakes

- Mixing project conventions into a domain-expert skill (e.g., a "UI expert" that hardcodes one project's Bootstrap component patterns, CSS class conventions, or API response shape).
- Keeping the project prefix on a skill that has become fully generic. If `mv-video-expert` no longer references MediaVortex, rename it to `video-expert`. Prefixes track coupling, not authorship.
- Adding a project-specific skill (with prefix) to the global pool and calling it a "domain expert". The prefix itself is the contradiction.
- Creating a skill at `<project>/skills/<name>/` instead of `<project>/.claude/skills/<name>/`. Only `.claude/skills/` is loaded at project scope.
- Duplicating a framework skill into a project's `.claude/skills/` to make minor customizations. Project skills shadow global skills by name -- the copy will drift, and you lose updates from the global pool.
