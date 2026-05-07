# Feature: Decision Records

## What It Does

Adds a framework-level append-only stream of architectural decision records (ADRs) at `decisions/NNNN-slug.md`. Each record captures one cross-cutting choice the framework has made, the context that forced it, alternatives considered, and which features honor it. Supersession is explicit: a newer record flips an older one to `SUPERSEDED-BY` rather than silently replacing it. Fills the gap between the glossary (which names things) and progress checklists (which are session-scoped): decisions explain *why* the framework is shaped the way it is, and they survive across sessions, projects, and framework versions.

## Success Criteria

1. `decisions/` directory exists at claude-rails repo root with a `README.md` index and a `TEMPLATE.md` seed file. The index lists every decision by ID, title, and status (`ACCEPTED`, `SUPERSEDED`, `DEPRECATED`, `DRAFT`).
2. Every decision record file is named `NNNN-slug.md` where `NNNN` is a four-digit monotonically increasing integer (zero-padded) and `slug` is lowercase-hyphenated.
3. Every decision record contains these sections in order: `# NNNN: <title>`, `## Status`, `## Context`, `## Decision`, `## Consequences`, `## Alternatives Considered`, `## Affected Features`.
4. `## Status` contains exactly one of: `ACCEPTED -- YYYY-MM-DD`, `SUPERSEDED-BY NNNN -- YYYY-MM-DD`, `DEPRECATED -- YYYY-MM-DD`, or `DRAFT`. A record is never silently removed; supersession is the only retirement path.
5. Feature docs may add a `## Honors` section listing decision IDs (e.g. `decisions/0001`). When a cited decision flips to `SUPERSEDED-BY` or `DEPRECATED`, a session that reads the feature doc must see the stale citation.
6. CLAUDE.md of any adopted repo may add a `## Honors Decisions` section listing the decision IDs that repo commits to. Scaffolded into the `/project-setup` CLAUDE.md template as an optional section.
7. At least 5 real framework decisions are seeded as the initial corpus: colocated-docs, tests-as-peer-features, two-pool placement, no-emojis, discover-not-hardcode, and scope-driven-placement. Each seed record cites the existing artifacts that implement it.
8. Glossary update: `docs/glossary.md` includes the canonical terms `decision record`, `decision ID`, `supersession`, and `honors`.
9. The `decisions/README.md` index is maintained by hand for the initial rollout.

## Status

DONE

### Progress

- [x] Create `decisions/` directory with `README.md` index and `TEMPLATE.md` seed
- [x] Seed 6 decision records (0001, 0002, 0004, 0005, 0006, 0007)
- [x] Update `decisions/README.md` index with all entries
- [x] Add glossary entries for decision record, decision ID, supersession, honors

## Files

- decisions/decision-records.feature.md (this file)
- decisions/README.md (index, manually maintained)
- decisions/TEMPLATE.md (seed template for new records)
- decisions/0001-0007 (seed records)
- docs/glossary.md (canonical terms)

## Scope

decisions/**
