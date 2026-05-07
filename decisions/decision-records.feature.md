# Feature: Decision Records

## What It Does

Adds a framework-level append-only stream of architectural decision records (ADRs) at `decisions/NNNN-slug.md`. Each record captures one cross-cutting choice the framework has made, the context that forced it, alternatives considered, and which features honor it. Supersession is explicit: a newer record flips an older one to `SUPERSEDED-BY` rather than silently replacing it. Fills the gap between the glossary (which names things) and progress checklists (which are session-scoped): decisions explain *why* the framework is shaped the way it is, and they survive across sessions, projects, and framework versions.

## Concern

both

- framework: the `decisions/` pattern, the file format, and the `## Honors` section are scaffolded into adopted repos by `/project-setup` so they can maintain their own local decision streams plus inherit framework-level decisions.
- dogfood: claude-rails seeds its own decisions (colocated-docs, tests-as-peer-feature, shell/PS parity, two-pool placement model, no-emojis) into `decisions/` and cites them from its own feature docs to prove the pattern before shipping it.

## Success Criteria

1. `decisions/` directory exists at claude-rails repo root with a `README.md` index and a `TEMPLATE.md` seed file. The index lists every decision by ID, title, and status (`ACCEPTED`, `SUPERSEDED`, `DEPRECATED`, `DRAFT`).
2. Every decision record file is named `NNNN-slug.md` where `NNNN` is a four-digit monotonically increasing integer (zero-padded) and `slug` is lowercase-hyphenated.
3. Every decision record contains these sections in order: `# NNNN: <title>`, `## Status`, `## Context`, `## Decision`, `## Consequences`, `## Alternatives Considered`, `## Affected Features`.
4. `## Status` contains exactly one of: `ACCEPTED — YYYY-MM-DD`, `SUPERSEDED-BY NNNN — YYYY-MM-DD`, `DEPRECATED — YYYY-MM-DD`, or `DRAFT`. A record is never silently removed; supersession is the only retirement path.
5. Feature docs may add a `## Honors` section listing decision IDs (e.g. `decisions/0001`). When a cited decision flips to `SUPERSEDED-BY` or `DEPRECATED`, a session that reads the feature doc must see the stale citation (out-of-scope for this feature: automated detection, which lives in a later enforcement-hook feature).
6. CLAUDE.md of any adopted repo may add a `## Honors Decisions` section listing the decision IDs that repo commits to. Scaffolded into the `/project-setup` CLAUDE.md heredoc template as an optional section.
7. At least 5 real past framework decisions are seeded as the initial corpus: colocated-docs, tests-as-peer-feature, shell/PS hook parity, two-pool placement (global vs project), and no-emojis in .md files. Each seed record cites the existing artifacts that implement it (rules file, feature doc, or CLAUDE.md rule).
8. Glossary update: `decisions/glossary-update.md` (or direct edit to `docs/glossary.md`) adds the canonical terms `decision record`, `decision ID`, `supersession`, and `honors` so the vocabulary stays tight.
9. The `decisions/README.md` index is maintained by hand for the initial rollout. Auto-generation of the index is out of scope for this feature (tracked as a follow-up skill, not a hook).

## Status

IN PROGRESS

### Progress

- [x] Draft feature doc with success criteria and scope
- [x] Create `decisions/` directory with `README.md` index and `TEMPLATE.md` seed
- [x] Seed `0001-colocated-sibling-docs.md` as the first real decision record (pilot shape)
- [x] User approved pilot shape (0001) and authorized remaining seeds
- [x] Seed remaining 4 decisions: 0002 tests-as-peer-features, 0003 shell/PS parity, 0004 two-pool placement, 0005 no-emojis
- [x] Update `decisions/README.md` index with all 5 entries
- [x] Add glossary entries for decision record, decision ID, supersession, honors (docs/glossary.md Documentation structure table)
- [x] Pilot `## Honors` citations in `colocated-docs.feature.md` (honors 0001, 0005) and `testing-convention.feature.md` (honors 0002, 0003, 0005)
- [ ] NEXT: user reviews the landed state; decide whether to pilot Honors in two more feature docs (framework-portability honors 0003, global-pool-namespace honors 0004) or move on to contracts
- [ ] Draft `/project-setup` integration (scaffold `decisions/README.md` + `TEMPLATE.md` heredocs, optional `## Honors Decisions` section in scaffolded CLAUDE.md)
- [ ] Supersession-check hook (separate follow-up feature, not this one): warn on feature docs citing `SUPERSEDED-BY` or `DEPRECATED` decisions
- [ ] Bump claude-rails VERSION once the `/project-setup` integration lands

## Files

- decisions/decision-records.feature.md (this file)
- decisions/README.md (index, manually maintained)
- decisions/TEMPLATE.md (seed template for new records)
- decisions/0001-colocated-sibling-docs.md (first seed record)
- decisions/0002-0005-*.md (four more seeds, after user review)
- docs/glossary.md (new canonical terms)
- global/skills/project-setup/SKILL.md (scaffold decisions/ into new adopted repos — later step)

## Scope

decisions/**

## Notes

Introducing the new canonical term "decision record" (and its neighbors: decision ID, supersession, honors). Per MEMORY.md Active Correction Policy rule 6, this needs explicit glossary addition before it's auto-referenced. That addition is itself a success criterion (9) of this feature, so the term is approved-in-context when the criteria are approved.

Deliberately NOT in this feature:
- Auto-generated index (manual hand-maintenance is enough for the first 20 records; automation pays for itself after that).
- Supersession-check hook (warn on feature docs citing superseded decisions). Tracked as a separate enforcement feature; this one only establishes the document pattern.
- Cross-repo contracts (`contracts/` layer). Separate feature. Contracts will likely cite decisions, so decisions should land first.
- Imports/Exports in feature docs. Separate feature. Independent of decisions.
