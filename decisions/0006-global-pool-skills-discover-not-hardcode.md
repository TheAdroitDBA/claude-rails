# 0006: Global-pool skills must discover, not hardcode

## Status

ACCEPTED — 2026-04-21

## Context

Decision 0004 established the two-pool placement model: global-pool artifacts must be project-neutral. In practice, several global-pool skills accumulated project-specific hardcodes over time — a YDN-only skill glob in sync-config, a MediaVortex-only bug-tracker path in troubleshoot, an absolute Mac path in review-skills, MV API conventions embedded in ui-expert, a fully MV-specific video-expert in the global pool. The rule "be project-neutral" was clear, but the operational question — "what do I do instead of hardcoding?" — was not. Skills took shortcuts because the alternative wasn't spelled out, and the litmus test in 0004 (does it reference a specific project, IP, or path) was checked only at placement time, not at each edit. The criterion 7 discovery-cost verification surfaced all five violations in one pass; without an operational rule, they would re-emerge.

## Decision

Global-pool skills must discover project context at invocation time rather than hardcoding it. Specifically:

- **Paths are discovered, not declared.** Use `git rev-parse --show-toplevel` for the adopted-repo root, `$HOME/.claude/` for the user's global Claude directory, and relative paths from those anchors. Never embed an absolute path that names a specific user or project.
- **Project state is read, not assumed.** When a skill needs a tracker path, a deployment target, or a domain convention, it reads that value from the adopted repo's `CLAUDE.md`, `memory/MEMORY.md`, or a scaffolded `.claude/` file. It does not assume the value. If the adopted repo has not declared it, the skill fails loudly with a message pointing at `/project-setup`.
- **Domain conventions stay with their domain.** When a skill embeds a specific project's API shape, naming scheme, or tooling, that content belongs in that project's `.claude/skills/`, not the global pool. Domain-expert skills (ui-expert, video-expert) contain portable knowledge only; project-specific conventions live in project-pool splits.
- **Exemptions are explicit.** A global-pool skill that genuinely must reference a specific tool or format (e.g. a skill that wraps ffmpeg may name ffmpeg) documents the exemption in its own feature doc's `## Notes`. The exemption covers tooling, never a project.

## Consequences

- Every global-pool skill can run in any adopted repo without modification. The "stamp" promise of the framework holds.
- Discovery calls add per-invocation overhead (one `git rev-parse`, one CLAUDE.md read). Negligible in practice.
- When an adopted repo has not declared the state a skill needs, the skill fails with a helpful error rather than silently operating on the wrong path. This is the intended behavior: a broken discovery call is a signal to run `/project-setup`, not a bug in the skill.
- This rule is enforceable by grep on `global/skills/**` for known anti-patterns (absolute user paths, project-name strings, hardcoded IPs). The enforcement grep is a criterion of `global-pool-purity.feature.md` and becomes an ongoing check.
- Adding a new global-pool skill now carries a visible obligation: if the skill hardcodes, it gets rejected or demoted at review time. The rule is declarative, so the review bar is clear.

## Alternatives Considered

- **Rely on decision 0004's placement rule alone.** Rejected. 0004 says global-pool content must be project-neutral but does not say *how* to achieve project neutrality. The operational "discover, don't hardcode" pattern is what closes the gap between intent and practice.
- **Allow hardcodes if they are in one designated "config" section at the top of a skill.** Rejected. That section rots — later edits bury project references elsewhere in the file, and the designated-section pattern provides false reassurance. Discovery in code is the only durable mechanism.
- **Generate skills per-machine with the local project values baked in at sync time.** Rejected. Defeats the purpose of a shared framework: two machines running the same skill would diverge by machine state, and the "sync pulls a canonical version" guarantee breaks.

## Affected Features

- global-pool-purity.feature.md (the first enforcement pass of this rule)
- global/skills/sync-config/sync-config.feature.md
- global/skills/troubleshoot/troubleshoot.feature.md
- global/skills/review-skills/review-skills.feature.md
- global/skills/ui-expert/ui-expert.feature.md
- global/skills/mv-video-expert/mv-video-expert.feature.md (demoted by global-pool-purity)
- rules/skill-placement.md (likely amended to reference this decision for the "how" of project-neutrality)
- memory/KNOWN-ISSUES.md (five hardcode entries are the evidence for why this decision was needed)
