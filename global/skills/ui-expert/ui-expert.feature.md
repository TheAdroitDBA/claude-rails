# Feature: UI Expert Skill

## What It Does

`/ui-expert` is a domain expert for data-heavy Bootstrap 5 + jQuery web applications. Analyzes page layouts, information density, visual hierarchy, table and list design, and workflow efficiency. Delivers impact-ranked recommendations (High / Medium / Low) with the specific Bootstrap classes and HTML patterns needed to implement each.

## Concern

**framework.** Global-pool skill. Contains only portable Bootstrap 5 + data-table UX knowledge; project conventions live in project-pool splits.

## Success Criteria

1. Loads and reads the target template file before issuing any recommendation (never guesses).
2. Identifies the primary user goal on the analyzed page and evaluates the UI against that goal.
3. Evaluation axes: information hierarchy, workflow efficiency (click count), wasted space, data presentation, responsive behavior.
4. Every recommendation is delivered as What / Why / How: the specific change, the UX principle it serves, the Bootstrap/HTML pattern to implement it.
5. Recommendations are ranked by impact, not alphabetized or grouped by section.
6. Never recommends breaking the existing stack (no proposals to swap Bootstrap for Tailwind, jQuery for React, etc.).
7. [BUG] The skill declared itself a domain expert but contained a dedicated "MediaVortex UI Patterns" section that hardcoded MV-specific conventions (PascalCase everything, `showToastAlert`, `{ Success, ErrorMessage, Data }` API shape, spinner-div toggling via `style.display`). Resolved 2026-04-21 via global-pool-purity.feature.md -- the MV-specific block was extracted verbatim to `migration/mv-ui-patterns/SKILL.md`; the framework-level ui-expert retains only portable Bootstrap 5 + data-table design knowledge.

## Status

DONE

### Progress

- [x] Criteria 1-6 closed.
- [x] Criterion 7 [BUG] -- resolved 2026-04-21: MediaVortex section extracted to `migration/mv-ui-patterns/SKILL.md`; global ui-expert retains only portable content (global-pool-purity.feature.md).
- [x] NEXT: handoff line -- user runs `sync` on each machine to propagate purged skill.

## Files

- global/skills/ui-expert/SKILL.md
- migration/mv-ui-patterns/SKILL.md (extracted MV content, staged for MediaVortex's `.claude/skills/`)

## Scope

global/skills/ui-expert/**

## Honors

- decisions/0006 -- Global-pool skills must discover, not hardcode. Without decision 0006, this feature would look different because the MediaVortex block would have been "generalized" into a set of optional conventions with placeholder names, rather than extracted wholesale -- decision 0006 establishes that domain conventions belong with their domain, not in the framework pool.
