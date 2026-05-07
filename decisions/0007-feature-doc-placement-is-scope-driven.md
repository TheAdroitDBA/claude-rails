# 0007: Feature doc placement is scope-driven, not concern-driven

## Status

ACCEPTED — 2026-04-21

## Context

Decision 0001 established sibling colocation and the "nearest common ancestor" escape hatch for cross-cutting features. In practice, claude-rails's repo root accumulated twelve feature docs, creating visual sprawl and a recurring temptation to group them — by theme (a `dogfood/` folder for dogfood-labeled docs) or by concern (a `framework/` folder for framework-labeled docs). Both groupings look tidy at first glance and appear to match the two-concerns discipline. Both are, on inspection, the `docs/features/` anti-pattern that decision 0001 retired — organizing docs by category rather than by the code they cover. The trigger case for clarifying the rule: a session-local discussion proposed moving `dogfood-compliance.feature.md` into a `dogfood/` subdirectory purely because its concern label said "dogfood." That move would violate 0001 without breaking any hook, which is exactly the kind of quiet drift a written decision prevents.

## Decision

Feature doc placement is governed by the scope, not by the concern label and not by the theme. Specifically:

- A feature doc lives at the nearest common ancestor of the paths its `## Scope` globs resolve to. If every glob is contained within a single subdirectory, the doc belongs in that subdirectory. If the globs span two or more subdirectories (or include repo-root files like `sync.*`, `VERSION`, `settings*.json`, or root-level `*.feature.md`), the doc lives at the repo root.
- `Concern: framework` / `Concern: dogfood` / `Concern: both` is an orthogonal metadata label. It describes blast radius (ships to adopted repos, stays in claude-rails, or both). It does NOT determine where the file sits.
- Theme-based folders (`dogfood/`, `framework/`, `meta/`, `governance/`, etc.) are rejected. They reintroduce the `docs/features/` separation between docs and their code that decision 0001 was written to abandon.
- Single-file subdirectories are a smell. If only one doc would live in a theme folder, the folder is being created to organize concepts, not to match code layout — which is the violation this decision exists to prevent.

## Consequences

- The root-level claude-rails feature docs are correctly placed when their scopes span multiple directories, even if the list feels long. Ten root-level cross-cutting docs is not sprawl; it is an honest reflection of how many repo-wide concerns the framework governs.
- Narrow-scope root-level docs are drift and must be relocated. Specifically, `decision-records.feature.md` (scope = `decisions/**`) belongs at `decisions/decision-records.feature.md`. Any doc added in future whose scope fits inside one subdirectory moves there at creation time, not later.
- `dogfood-compliance.feature.md` can grow a new success criterion: for every root-level `*.feature.md`, its `## Scope` must span two or more subdirectories OR be sibling-colocated with a named root-level code file. A failing doc is relocated. This makes drift catchable by a mechanical audit rather than by memory.
- Concern labels stay useful for what they were designed for: blast radius, litmus tests when reviewing changes, and filtering in `/project-setup` scaffolding decisions. They never pull weight on the question of where a file lives.
- The rule composes cleanly with the umbrella-feature pattern (legitimate cross-cutting features at root with wide scopes): umbrella docs earn their root placement by scope, not by being umbrellas.

## Alternatives Considered

- **Theme-based folders (`dogfood/`, `framework/`).** Rejected. Reintroduces the `docs/features/` separation decision 0001 retired. Also creates the question "why this theme and not that one" — every root doc has a theme, so theme-based grouping cannot stop at one folder without arbitrariness.
- **Concern-based folders keyed on the `## Concern` label.** Rejected for the same reason as theme folders, plus the additional cost of forcing `Concern: both` docs into a third bucket (or arbitrarily assigning them to one side).
- **Leaving all cross-cutting docs at root with no written rule.** Rejected. Without a decision, the drift this session saw (moving files into `dogfood/` purely because the label says dogfood) keeps re-emerging. A written rule plus a mechanical criterion catches it.
- **Enforcing a hook that blocks feature docs whose scope is contained in a subdirectory from living at root.** Deferred. Sound idea but requires implementation; the dogfood-compliance criterion is the cheap first step. A hook can be added later if audits surface recurring violations.

## Affected Features

- decision-records.feature.md (narrow-scope violation; relocation to `decisions/` follows from this decision)
- dogfood-compliance.feature.md (gains the scope-driven-placement audit criterion)
- colocated-docs.feature.md (this decision is a direct extension of decision 0001's escape hatch)
- README.md (may reference this rule in any discussion of repo layout)
- docs/glossary.md (the terms "nearest common ancestor" and "narrow-scope doc" may want canonical entries)
