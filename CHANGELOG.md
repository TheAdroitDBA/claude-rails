# Changelog

All notable changes to claude-rails will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While in `0.x`, breaking changes may land on a MINOR bump and will be marked **BREAKING** in the entry. The first commitment to deprecation discipline (one MINOR-release deprecation window before removal) lands at `1.0.0`.

## [Unreleased]

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
