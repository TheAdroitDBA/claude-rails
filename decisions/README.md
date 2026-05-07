# Decisions

Append-only stream of framework-level architectural decision records (ADRs).

One file per decision. Filename: `NNNN-slug.md`. Numbers are monotonic and never reused. Decisions are retired only by supersession — a newer record flips the older one to `SUPERSEDED-BY NNNN`. Nothing is deleted.

See `TEMPLATE.md` for the starter shape.

## How to Cite a Decision

From a feature doc:

```
## Honors
decisions/0001
decisions/0004
```

From a CLAUDE.md (adopted repo):

```
## Honors Decisions
- decisions/0001 — Colocated sibling docs
- decisions/0004 — Two-pool placement
```

## Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| 0001 | Colocated sibling docs (feature.md + flow.md next to code) | ACCEPTED | 2026-04-21 |
| 0002 | Tests are peer features, not colocated leaves | ACCEPTED | 2026-04-21 |
| 0004 | Two-pool placement for skills, agents, and hooks | ACCEPTED | 2026-04-21 |
| 0005 | No emojis or graphical characters in .md files | ACCEPTED | 2026-04-21 |
| 0006 | Global-pool skills must discover, not hardcode | ACCEPTED | 2026-04-21 |
| 0007 | Feature doc placement is scope-driven, not concern-driven | ACCEPTED | 2026-04-21 |

## Status Values

- **DRAFT** — proposed, not yet in force. May be edited.
- **ACCEPTED** — in force. Edits only via errata or supersession.
- **SUPERSEDED-BY NNNN** — replaced by a later decision. Keep the file; it is history.
- **DEPRECATED** — no longer in force, with no replacement (rare — usually a decision is superseded, not deprecated).
