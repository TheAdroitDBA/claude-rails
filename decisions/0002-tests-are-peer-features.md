# 0002: Tests are peer features, not colocated leaves

## Status

ACCEPTED — 2026-04-21

## Context

A strict DDD-style vertical slice would place tests inside the same directory as the code they cover — `api/sleep-wake/{feature.md, flow.md, idle-manager.js, sleep-wake.test.js}`. That layout maximizes locality for single-feature unit tests but penalizes integration tests that legitimately span multiple features (a test that exercises sleep-wake AND server-lifecycle has no natural home in either folder). It also multiplies runner configuration across every vertical and pushes harness boilerplate into folders that otherwise hold one narrow concern.

## Decision

Tests live in `tests/<suite>/` at the repo root. Each suite is a directory containing its harness scripts, a `<suite>.feature.md` with numbered success criteria, and an optional `fixtures/` subdirectory. Tests are themselves features — they follow the same feature-doc discipline as any other work unit. A test suite MAY cover one code feature or many; the suite's `## Scope` declares exactly what code it exercises.

## Consequences

- Tests get their own criteria, their own progress checklist, their own test plan. Test work is first-class, not an appendix to code work.
- Test-to-feature indexing becomes a convention, not a lookup: to find "which tests cover sleep-wake" a session walks `tests/*/*.feature.md` looking for matching `## Scope` globs. Acceptable for small repos; becomes a scaling drag as suites multiply — tracked as a follow-up via a "reverse index" field or an auto-generated map.
- Integration tests have a natural home — they live in their own suite with scope covering multiple code features.
- Per-language runner config stays consolidated in `tests/` rather than scattered across vertical folders.
- Cost: deleting a code feature does not atomically delete its tests. The tests' feature doc must be retired separately, either by shrinking its scope or by marking the suite itself PARKED/DEPRECATED.

## Alternatives Considered

- **Colocated tests (DDD-strict vertical)** — rejected. Noise in code directories, no home for integration tests that span features, per-vertical runner duplication.
- **No test convention; let each repo choose** — rejected. Leads to test layouts that differ per repo, making cross-repo test discipline inconsistent and defeating the framework's "same shape everywhere" principle.
- **Single `tests/` directory with flat file layout (no per-suite subdirs)** — rejected. Fixtures and harnesses intermingle; no room for feature docs per suite.

## Affected Features

- rules/test-placement.md
- MEMORY.md (Rules Templates section listing test-placement.md as opinionated template)
- global/skills/project-setup/SKILL.md (scaffolds tests/ into new repos)
