# Changelog

All notable changes to claude-rails will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While in `0.x`, breaking changes may land on a MINOR bump and will be marked **BREAKING** in the entry. The first commitment to deprecation discipline (one MINOR-release deprecation window before removal) lands at `1.0.0`.

## [Unreleased]

### Added

- `conventions/style-guide.md` — voice, tone, terminology, code-block,
  diagram, and editorial conventions for any doc published through the
  framework.
- `commands/check-conformance.md` — slash command (`/check-conformance`)
  that reconciles installed framework version against repo's
  last-validated version, runs conformance checks, and writes the repo's
  version stamp on a clean pass.
- `CONTRIBUTING.md` — working agreement for framework changes,
  including the changelog enforcement rule.
- `scripts/check-changelog.sh` — pre-commit-installable script that
  fails when surface files change without a `CHANGELOG.md` entry.
- SessionStart hook in `.claude-plugin/hooks/hooks.json` — emits a
  one-line banner when installed framework version differs from the
  repo's last-validated version. Fails closed across MAJOR boundaries.

### Changed

- `conventions/auto-doc.md` — substantial expansion folding in findings
  from documentation-, data-, observability-, and release-management-
  expert audits:
  - Tier 1 of the source-of-truth rule now splits into 1a (slow live
    state) and 1b (volatile live state). Volatile facts MUST go to
    telemetry, NOT markdown. **MINOR** (additive clarification of the
    rule).
  - Added "Render at build, do not store inherited columns" subsection.
    Consumer docs reference the source by ID; inherited columns flow
    from the source on every build. Eliminates the inheritance-pattern
    drift surface entirely. **MINOR**.
  - Added "Surrogate IDs and labels" subsection recommending opaque
    surrogate identifiers + labels map for entities whose natural keys
    encode mutable attributes. **MINOR** (recommendation, not mandate).
  - Tier 2 now requires every structured-data file to have a schema
    (JSON Schema, Pydantic, equivalent) with a `schema_version` field.
    **MINOR**.
  - Feature doc shape adds required `owner`, `review-by`, and
    `last-reviewed` frontmatter. In `0.x`, missing values are advisory
    (WARN); the framework commits to making them required at 1.0.0.
    **MINOR** (advisory in 0.x).
  - Feature doc shape renames `## What It Does` body framing to
    Diátaxis-explicit `## What It Does` (explanation) + `## Reference
    (Criteria)` (reference) labels. **MINOR**.
  - Cross-repo link namespace renamed from `/software/<reponame>/` to
    `/repos/<reponame>/`. **BREAKING** (path-namespace change). In
    0.1.0 this is a same-day rename with no production consumers; the
    convention now defines a deprecation path for future namespace
    changes.
  - Added "Transclusion" section defining `{{<source>:<key>:<attribute>}}`
    grammar for inlining facts from canonical sources into prose
    without forcing the entire prose into a marker block. **MINOR**.
  - Added "Versioning and Releases" section establishing SemVer for
    the framework and the breaking-change classification table.
    **MINOR** (formalizes existing 0.1.0 commitment).
  - Added "Deprecation Cycle" section: deprecated for at least one
    MINOR, removed at next MAJOR, every entry includes replacement +
    migration + removal version. **MINOR**.
  - Added "Generator Refusal on Major Mismatch" subsection. Generators
    MUST refuse to run across MAJOR drift to prevent silent corruption
    when markers are renamed or formats removed. **MINOR** (defines
    behavior; no current generator violates it).
  - Added "Conformance and Adoption" section documenting the
    `~/.claude/claude-rails-version` install stamp, the per-repo
    `.claude/claude-rails-version` validation stamp, and the
    `/check-conformance` workflow. **MINOR**.

## [0.1.0] - 2026-05-09

Initial versioned release. Captures conventions, commands, and templates as of this tag. Subsequent changes will be classified per the breaking-change rules in `conventions/auto-doc.md`.

### Added

- `VERSION` file at repo root. `install.sh` and `install.ps1` write this value to `~/.claude/claude-rails-version` so adopting repos can record the framework version they were last validated against.
- `CHANGELOG.md` (this file). Required entry for every PR that changes `conventions/`, `commands/`, `templates/`, or `.claude-plugin/hooks/`.
- `commands/documentation-expert.md` — Diátaxis, doc-as-code, single-source-of-truth, content design, audit/freshness.
- `commands/data-expert.md` — schema design, indexing, query optimization, migrations, transactions, lifecycle.
- `commands/observability-expert.md` — telemetry, SLIs/SLOs, alerting, log structure, metric design, dashboards.
- `commands/release-management-expert.md` — versioning, changelogs, deprecation, breaking-change handling, cross-repo coordination.
- `conventions/auto-doc.md` — four-tier source-of-truth rule, marker convention, generator+audit pattern, flow-doc shape (mermaid as source), feature-doc shape, cross-repo link convention, repo aggregation contract.

### Changed

- `README.md` — Domain-Expert Commands table extended with the four new experts above.

[Unreleased]: https://github.com/TheAdroitDBA/claude-rails/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/TheAdroitDBA/claude-rails/releases/tag/v0.1.0
