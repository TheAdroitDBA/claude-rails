# 0001: Colocated sibling docs (feature.md + flow.md next to code)

## Status

ACCEPTED — 2026-04-21

## Context

Before this decision, Claude sessions burned tokens walking `docs/features/` and `docs/flows/` trees to map documentation back to the code it described. The separation forced every reader to maintain a mental index: "the deploy flow lives in docs/flows/deploy.md, the code lives in tools/deploy.sh, the feature doc lives in docs/features/deploy.md." Three files, three locations, one concept. Renames, moves, and deletions routinely orphaned one leg of the triangle without anyone noticing. Discovery cost for a fresh session regularly exceeded 15k tokens just to answer "what is this and where does it live."

## Decision

Feature docs and flow docs are colocated with the code they describe. A `<name>.feature.md` sits as a sibling of the primary code file it governs. A `<name>.flow.md` sits as a sibling of the entry-point file for the pipeline it traces. Legacy `docs/features/` and `docs/flows/` trees are left alone in already-adopted repos (not batch-migrated) but are not the target convention for new work.

## Consequences

- Feature scope is declared via `## Scope` globs inside the feature doc itself. A feature's `## Scope` must match the files that live alongside (or beneath) the doc; scope overlap between features creates ownership ambiguity.
- When code moves, its feature doc and flow doc move with it. Renames touch three files, not one — but the relationship is visible, and the next session finds all three.
- For cross-cutting features whose scope spans multiple directories (framework-portability, dogfood, colocated-docs itself), the feature doc lives at the nearest common ancestor (usually repo root). This is the implicit escape hatch when sibling placement is impossible.
- A feature doc without a `## Scope` section is "unscoped" and is treated as covering everything inside its enforcement scope. This is fine for small repos but becomes a liability as features multiply.
- Discovery cost drops: a fresh session answering "how does sleep-wake work" reads the feature doc and flow doc in the same directory as the code, not three directories apart.

## Alternatives Considered

- **Central `docs/` tree with strict naming mirror** (e.g. `docs/features/api/sleep-wake.md`) — rejected because the mirror always drifts from the code tree and mirror rot is silent.
- **One monorepo-wide README.md per capability at the top level** — rejected because it collapses flow and feature into one doc, losing the "what vs how" distinction.
- **No doc convention at all; rely on code comments and git log** — rejected because comments do not capture pipeline shape and git log does not capture user-visible behavior.

## Affected Features

- colocated-docs.feature.md
- global/hooks/require-feature-doc.sh / .ps1 (enforcement)
- global/hooks/stale-feature-check.sh / .ps1
- global/skills/project-setup/SKILL.md (scaffolds the pattern into new repos)
- MEMORY.md (Hard Rules, Token Hierarchy, Project Structure sections)
- docs/glossary.md (defines feature doc, flow doc, token hierarchy)
