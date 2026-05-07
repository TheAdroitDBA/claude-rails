# 0007: Feature doc placement is scope-driven, not concern-driven

## Status

ACCEPTED -- 2026-04-21

## Context

Decision 0001 established sibling colocation and the "nearest common ancestor" escape hatch for cross-cutting features. In practice, repos accumulate feature docs at the root, creating visual sprawl and a recurring temptation to group them -- by theme (a `meta/` folder for framework docs) or by category (a `governance/` folder for process docs). Both groupings look tidy at first glance. Both are, on inspection, the `docs/features/` anti-pattern that decision 0001 retired -- organizing docs by category rather than by the code they cover. The drift happens quietly: someone proposes moving a doc into a themed folder purely because of its label, violating 0001 without breaking any hook.

## Decision

Feature doc placement is governed by the scope, not by any label and not by the theme. Specifically:

- A feature doc lives at the nearest common ancestor of the paths its `## Scope` globs resolve to. If every glob is contained within a single subdirectory, the doc belongs in that subdirectory. If the globs span two or more subdirectories or include repo-root files, the doc lives at the repo root.
- Theme-based folders (`meta/`, `governance/`, `internal/`, etc.) are rejected. They reintroduce the `docs/features/` separation between docs and their code that decision 0001 was written to abandon.
- Single-file subdirectories are a smell. If only one doc would live in a theme folder, the folder is being created to organize concepts, not to match code layout -- which is the violation this decision exists to prevent.

## Consequences

- Root-level feature docs are correctly placed when their scopes span multiple directories, even if the list feels long. Ten root-level cross-cutting docs is not sprawl; it is an honest reflection of how many repo-wide concerns the project governs.
- Narrow-scope root-level docs are drift and must be relocated. Any doc whose scope fits inside one subdirectory moves there at creation time, not later.
- The rule composes cleanly with the umbrella-feature pattern (legitimate cross-cutting features at root with wide scopes): umbrella docs earn their root placement by scope, not by being umbrellas.

## Alternatives Considered

- **Theme-based folders.** Rejected. Reintroduces the `docs/features/` separation decision 0001 retired. Also creates the question "why this theme and not that one" -- every root doc has a theme, so theme-based grouping cannot stop at one folder without arbitrariness.
- **Category-based folders keyed on a metadata label.** Rejected for the same reason as theme folders, plus the additional cost of forcing multi-category docs into a third bucket or arbitrarily assigning them to one side.
- **Leaving all cross-cutting docs at root with no written rule.** Rejected. Without a decision, the drift (moving files into themed folders) keeps re-emerging. A written rule catches it.
- **Enforcing a hook that blocks feature docs whose scope is contained in a subdirectory from living at root.** Deferred. Sound idea but requires implementation; a mechanical audit is the cheap first step. A hook can be added later if audits surface recurring violations.

## Affected Features

- README.md (may reference this rule in any discussion of repo layout)
- docs/glossary.md (the terms "nearest common ancestor" and "narrow-scope doc" may want canonical entries)
