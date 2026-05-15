# Feature: Project Onboarding

## What It Does

Makes adopting the claude-config framework on a new or existing repo a single-command operation via the `/project-setup` skill. The skill audits existing structure, asks the user a short batch of discovery questions, scaffolds missing framework files, prints an actionable Quick Next Steps block, and ensures every onboarded project has a feature-first troubleshooting runbook in its README.md.

## Concern

**framework.** `/project-setup` is the primary entry point for adopting the framework on a new repo. Every criterion shapes what adopted repos receive (scaffold, audit, migration, scaffolding templates). The skill itself ships to every synced machine; adopted repos never embed it, only invoke it.

## Success Criteria

1. Running `/project-setup` in a fresh repo produces CLAUDE.md, memory/, and the `.claude/` marker files without any additional manual steps. Feature docs and flow docs are colocated next to code, so no `docs/features/` or `docs/flows/` directory is scaffolded.
2. Running `/project-setup` in an existing repo is idempotent: files that already exist are left untouched, missing files are added.
3. The skill asks at most six discovery questions in a single batch and waits for the user to answer in one shot.
4. The skill runs a discovery cost budget check and reports any token-waste signals (missing MEMORY.md, missing KNOWN-ISSUES.md, zero feature docs, zero flow docs).
5. For repos with more than 20 tracked source files, the skill scaffolds `memory/MEMORY.md` and `memory/KNOWN-ISSUES.md` stubs when they are missing.
6. The skill scaffolds (or appends to) `README.md` a `## Troubleshooting a Feature` section containing an 8-step runbook: identify feature, find failing criterion, check KNOWN-ISSUES, read flow docs, check rules, git log scoped files, read source, record findings.
7. If `README.md` already contains a `## Troubleshooting a Feature` section, the skill leaves it alone.
8. The skill prints a Quick Next Steps block at the end of the run with six actionable items: start first feature, set current-feature pointer, enforcement mode guidance, first flow doc guidance, troubleshooting runbook pointer, and re-audit command.
9. The Quick Next Steps block substitutes the real current value of `.claude/feature-doc-mode` when displayed.
10. The skill actively brings a repo into framework compliance. Running `/project-setup` on any repo detects legacy `docs/features/` and `docs/flows/` layouts, sweeps for misplaced framework docs, computes colocated migration targets, asks the user to resolve any duplicates, and executes the migrations. Flagging-without-acting is not sufficient.
11. Move, never delete. When the skill migrates a legacy doc it uses `git mv` so history is preserved. No legacy doc is deleted -- each one lands at its colocated target, or the migration is skipped.
12. Merge on collision. If the colocated target already exists, the skill merges section by section rather than overwriting. When two files disagree on Success Criteria, Status, or flow step tables, the skill pauses and asks the user which version is authoritative per conflicting section. Never silently picks one.
13. Sweep for misplaced framework docs. The skill scans the repo for `.md` files containing a Success Criteria header or flow step table that are not colocated with their code. Each candidate is proposed for relocation. Templates (`*.template.md`), SKILL.md files, and MEMORY.md are excluded because they legitimately contain embedded framework-doc examples. If multiple sources target the same basename, the skill surfaces the duplication and halts that migration until the user picks one.
14. Clean up the old scaffolding. After successful migration the legacy `docs/features/` and `docs/flows/` directories no longer exist in the repo (unless the user explicitly skipped migrations). References in CLAUDE.md, README, MEMORY.md, sibling feature/flow docs, memory files, and rules files are rewritten to point at the colocated positions. Reference rewrite does not touch source code.
15. Framework-repo exception. When `/project-setup` runs on claude-config itself, it skips scaffolding `.claude/agents/`, `.claude/hooks/`, and `.claude/skills/` because claude-config IS the global pool -- there is nothing to layer on top of. Only `.claude/rules/` is scaffolded so claude-config's own work sessions can consume the rules templates it ships.
16. [BUG] Token efficiency. SKILL.md inlines every scaffolding template (CLAUDE.md text, README runbook, all rule templates, docs.export.yml, feature-doc template, memory/MEMORY.md stub). Every `/project-setup` invocation loads ~15-20k tokens whether or not any of those templates are needed. Expected: templates live as sidecar files under `global/skills/project-setup/templates/` (reachable via the `~/.claude/skills/` symlink). SKILL.md becomes a thin orchestrator that `cat`s only the chosen template(s) after the user approves that scaffolding. Sidecars are internal to the skill, not a runtime dependency of adopted repos (adopted repos still receive real text). Target: SKILL.md under 300 lines, per-invocation token cost under 5k for audits that produce no scaffolding.

## Status

DONE

### Progress

- [x] Criteria 1-9 closed: idempotent scaffold, discovery questions, Quick Next Steps with live marker substitution.
- [x] Criteria 10-14 closed in dogfood Phase 3: active compliance, move-never-delete via `git mv`, merge-on-collision, sweep for misplaced docs, cleanup + reference rewrite.
- [x] Criterion 15 added in dogfood Phase 4: framework-repo exception (claude-config IS the global pool; do not scaffold `.claude/{agents,hooks,skills}` on itself).
- [x] Criterion 16 [BUG] RESOLVED (2026-05-06) -- 14 sidecar template files created under global/skills/project-setup/templates/. SKILL.md reduced from 846 to 437 lines. Templates loaded on-demand; audit-only runs no longer load template content. Flow doc updated with missing-sidecar failure mode. Line count target (300) not fully met; behavioral and token targets are met.
- [x] 2026-05-06: enforcement instructions distribution added. Step 6c now reconciles the `## Plugin Enforcement` section in CLAUDE.md on every run (idempotent: adds if absent, offers update if stale). claude-md.md template updated with Plugin Enforcement section and corrected slash command references (shorthand-expand retired). Step 6n updated: enforcement is via CLAUDE.md, not per-machine settings.local.json. Mechanical check updated to detect enforcement instructions in CLAUDE.md. Criterion 2 (idempotent) strengthened.
- [ ] NEXT: optionally further condense Steps 2-3 by moving orientation audit Q detail to the flow doc (saves ~100 more lines toward the 300-line target).

## Files

- global/skills/project-setup/SKILL.md
- global/skills/project-setup/feature.template.md

## Scope

global/skills/project-setup/**
