# Auto-Documentation Conventions

Stack-agnostic principles for keeping docs and reality in sync without
manual verification. Loaded between `rules/` (invariants) and sibling
docs in the token hierarchy.

Conventions are principles, not invariants. A doc that cannot honor a
convention declares a one-line deviation in its feature doc.

## The Source-of-Truth Rule

Every fact in a doc lives in exactly **one** source. Other places the
fact appears are *generated* from that source -- they are never
hand-typed values.

Pick the source from the highest tier that applies:

1. **Live system state.** Queryable at build/audit time: APIs, system
   commands, code AST, file metadata. Cannot drift; it IS the state.
   Examples: Proxmox API for VM config, `pct config <id>` for LXC
   mounts, `smartctl` for disk serials, `crontab` for backup schedules,
   `git log` for change history, AST parsers for code symbols.

2. **Structured data file.** Hand-authored once, consumed by
   generators. A single canonical record. Examples: `inventory.toml`
   for hosts/services, a manifest mapping app paths to storage IDs,
   an aggregation manifest for cross-repo doc pull.

3. **Generated docs.** Markdown blocks emitted into marker-bounded
   regions (see Marker Convention below) from tier-1 or tier-2
   sources. Re-emitted on every commit / build. Never edited by hand
   between the markers.

4. **Hand-authored prose.** Limited to *intent*, *judgment*, and
   *runbook sequencing*. Cannot encode facts that exist in tier 1, 2,
   or 3.

A fact that exists in tier 1 or 2 cannot also be hand-typed in tier 4.
The rule does not move with convenience; if you find yourself typing
a value, ask which tier owns it.

### What stays hand-authored

- Why a feature exists.
- What can break and what to do about it.
- Restore procedures and runbook steps in the order a human runs them.
- Open questions, decisions in flight.
- The structured manifests themselves (someone has to type the source
  once).

### What never stays hand-authored

- Capacity, sizes, IPs, VMIDs, mount paths, disk serials, RAID
  composition, ZFS pool layout.
- Backup destinations, schedules, retention values.
- Cross-references where a doc duplicates a value from another doc.
- Dependency lists, exposed ports, container/process inventories.
- Any value that has a stable query against a live system or a
  structured file.

## The Marker Convention

Generated content lives between marker pairs. The markers MUST appear
on their own lines. Generators replace the entire span between markers
on every run; hand-written content outside the markers is preserved
verbatim.

```markdown
<!-- generated:start -->
this content is overwritten on every build
<!-- generated:end -->
```

A document MAY contain multiple, non-overlapping marker pairs. Distinct
generated sections use distinct marker labels so partition-based
replacement of one never touches another:

```markdown
<!-- generated:diagram:start -->
... mermaid diagram ...
<!-- generated:diagram:end -->

<!-- generated:steps:start -->
... step table ...
<!-- generated:steps:end -->
```

Conflict rules:

- A generator MUST only write between markers it owns. Reading or
  modifying another generator's markers is a violation.
- A doc MAY mix generated and hand-authored content freely, as long as
  every generated value lives between markers.
- The opening marker is also the audit boundary -- audits read what is
  inside the markers and compare against the regenerated output.

## The Generator + Audit Pattern

For every fact-bearing doc, two artifacts exist:

- A **generator** that emits the doc's marker-bounded content from a
  source-of-truth. Idempotent. Side-effect free except for writing the
  target file. Supports `--dry-run` (print the proposed content
  without writing) and `--audit` (compare current file content to the
  proposed regeneration; exit non-zero if they differ).
- An **audit hook** that runs the generator's `--audit` mode in CI or
  pre-commit. Drift is a build failure, not a "noticed it later" bug.

Generators live in the repo whose docs they emit. The audit hook is
also repo-local. claude-rails defines the *pattern*; each repo writes
its own generators for its own systems.

```
<source>  →  generator <generator>.py
              ├── default mode: write between markers
              ├── --dry-run:    print proposed content
              └── --audit:      diff current vs proposed; exit 1 on drift
```

One generator can emit into multiple files; one file can contain
output from multiple generators (different marker labels).

## Doc-Type Shapes

### Feature docs (`*.feature.md`)

Sections in order:

- `# Feature: <name>` — title.
- `## What It Does` — hand-authored intent (tier 4).
- `## Success Criteria` — hand-authored numbered criteria (tier 4).
  Generated facts MAY appear inside criteria text via inline markers
  (`<!-- gen:value capacity --> 17.7 TB <!-- gen:end -->`) where a
  criterion needs to assert a current measured value.
- `## Status` — single line: `NOT STARTED | IN PROGRESS | COMPLETE | PARKED`.
- `### Progress` — hand-authored checklist of the planned implementation
  steps. May reference generated sub-tables.
- `## Files` — list of code files this feature owns. Generators MAY emit
  this list when feature scope is path-glob-derived.
- `## Scope` — globs the feature controls.

Anything that names a system fact (capacity, IP, count) inside a
feature doc must come from a generated marker, not be typed inline.

### Flow docs (`*.flow.md`)

Single source: a `flowchart` mermaid block. Authors edit the mermaid;
both the published rendering and the AI-readable step table are
derived from it.

```markdown
# Flow: <name>

## Diagram

\```mermaid
flowchart LR
  src[Source] --> proc[Process]
  proc --> sink[Sink]
\```

<!-- generated:steps:start -->
| # | Step | What it does |
|---|------|--------------|
| 1 | Source | … |
| 2 | Process | … |
| 3 | Sink | … |
<!-- generated:steps:end -->

## Failure Modes

(hand-authored prose)
```

The mermaid block is the source of truth. The step table is generated
from the mermaid AST: each node becomes one row in document order; node
labels become step names; edge labels (where present) flow into the
"What it does" column. claude-rails ships the generator. Authors do
not edit the table.

Restrictions on the mermaid block:

- Type MUST be `flowchart` (LR, TB, RL, BT all permitted).
- Each node MUST have a stable id.
- Subgraphs are permitted; they nest the rows.
- Decisions (conditional edges) are permitted; the table renders them
  as numbered branch rows.

## Cross-Repo Link Convention

When a doc in one repo references a doc in another, use the published
site path:

```
[link text](/software/<reponame>/features/<feature>/)
[link text](/software/<reponame>/flows/<flow>/)
[link text](/hardware/<section>/)
```

In-repo links between docs in the same repo stay relative to the file
so they work without a server (e.g. local `mkdocs serve` against a
single repo, or simple GitHub rendering).

The aggregator script (in the repo that publishes the site) rewrites
relative links to absolute `/software/<reponame>/...` paths during the
build. Authors never type a `/software/...` path for a doc in their
own repo.

## Repo Aggregation Contract

A repo opts into being aggregated by another repo's site by satisfying
this contract. Adopting claude-rails already gives you most of it:

- All `*.feature.md` and `*.flow.md` files anywhere in the repo are
  eligible for publishing.
- Their path inside the repo (relative to repo root, with `.feature.md`
  or `.flow.md` stripped) becomes their path under
  `/software/<reponame>/` on the publishing site.
- Each file declares enough hand-authored intent (tier 4) to be useful
  on its own. Generated sections MAY render to "no data yet" if the
  generator has not been wired.
- The repo MUST NOT depend on the aggregator's existence to function
  locally. `mkdocs serve` (or any single-repo doc server) over the
  repo's docs MUST work standalone.

The aggregating site (one per home lab / org) provides:

- A manifest listing the repos to pull and their refs.
- A pull step that shallow-clones each enrolled repo at build time.
- A nav assembly step that places each repo's docs under the
  `/software/<reponame>/` namespace.
- Validation that cross-repo links resolve.

## Adoption Litmus Tests

Before merging a doc change, ask:

1. **Did I type any value that exists somewhere on a system?** If yes,
   that value belongs in a generator block. Move it.
2. **Did I duplicate a value that already appears in another doc?** If
   yes, the second doc should pull it via cross-reference (link or
   inherited generator), not copy.
3. **Could I run the audit right now and have it pass?** If you do not
   know, the audit is not in CI yet. Wire it before next commit.
4. **Is there a hand-authored claim that requires "go check the system
   to verify"?** If yes, either the generator is missing or the claim
   should be deleted. Verification is the audit's job, not the
   reader's.

## Common Mistakes

- Hand-typing a value "just for now" with a TODO to generate it later.
  The generator is the cheapest piece to write; do it now.
- Adding a generator that emits to a file that has no audit hook.
  Generators without audits are gloves without hands -- they prevent
  initial drift but not subsequent drift.
- Multiple sources for the same fact, with a "single source of truth"
  comment in each one. The comment is not the rule; one of the
  locations must be deleted or generated from the other.
- Authoring both the mermaid AND the step table in a flow doc. Pick
  one source; generate the rest.
- Treating the audit as advisory. Audit failure = build failure =
  commit blocked.
