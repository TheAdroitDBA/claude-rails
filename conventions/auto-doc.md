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
   Live state has two sub-tiers with different update characteristics:

   1a. **Slow-moving facts** -- change on hardware swap, service
       deploy, or schema migration. Examples: disk serial, RAID
       layout, ZFS pool composition, exposed port, code symbol name.
       Generated into doc markers; queried at commit/build/audit time.

   1b. **Volatile facts** -- change every minute or faster. Examples:
       capacity used %, current connections, IOPS, scrub progress,
       error counters. **MUST NOT be written into markdown.** Volatile
       facts belong in telemetry (Prometheus, Grafana) and are
       referenced from docs by linking the panel, not by inlining the
       value. A markdown audit can never converge against live volatile
       data; trying produces noise that destroys signal.

2. **Structured data file.** Hand-authored once, consumed by
   generators. A single canonical record. Examples: `inventory.toml`
   for hosts/services, `storage_inventory.toml` keyed by surrogate ID,
   a manifest mapping app paths to storage IDs, an aggregation manifest
   for cross-repo doc pull. Every structured-data file MUST have a
   schema (JSON Schema, Pydantic model, or equivalent) and a
   `schema_version` field. The schema is the canonical contract; the
   markdown view is rendered from it.

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

### Render at build, do not store inherited columns

When a consumer doc references another doc's facts (e.g. a service doc
inheriting Tier/Redundancy/Backup attributes from a storage inventory
row), the consumer MUST NOT store the inherited values as text. The
consumer references the source by stable ID; inherited columns are
rendered at build time from the source.

Storing inherited columns creates an update-anomaly surface: when the
source row changes, every consumer's denormalized cells must be
updated in lockstep. The audit catches drift after the fact, but it
does not prevent the write storm. Render-at-build eliminates the
drift surface entirely rather than auditing it.

This applies to: storage attribute inheritance, host-attribute
inheritance, configuration-attribute inheritance -- any case where a
consumer doc would otherwise duplicate values from an authoritative
source. The cross-doc reference (link, transclusion) is sufficient;
the value flows from the source on every build.

### Surrogate IDs and labels

Identifier shapes that encode mutable attributes -- e.g. a storage ID
of `<host>.<share>.<protocol>` -- rot when any component is renamed.
Hosts get renamed; shares get moved; protocols get upgraded. Every
such rename forces a rewrite of every consumer reference.

The recommended shape: an opaque surrogate identifier (ULID, UUID,
content hash) plus a labels map carrying the human-readable
attributes. Renames touch labels; identity stays stable. Consumer
references the surrogate, not the labels.

Where a domain has a strong stability story for the natural key (e.g.
disk serial numbers do not change), the surrogate may be elided and
the natural key used directly -- with the caveat that renames then
require a coordinated migration.

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
- Frontmatter (required) — `owner`, `review-by` interval (e.g. `90d`),
  `last-reviewed` date. Audited; missing or overdue values fail the
  audit.
- `## What It Does` — hand-authored intent (tier 4, explanation mode).
- `## Reference (Criteria)` — numbered success criteria, structured
  for lookup. Each criterion is pass/fail testable from the outside.
  Generated facts MAY appear inside criteria text via inline markers
  (`<!-- gen:value capacity --> 17.7 TB <!-- gen:end -->`) where a
  criterion needs to assert a current measured value.
- `## Status` — single line: `NOT STARTED | IN PROGRESS | COMPLETE | PARKED`.
- `### Progress` — hand-authored checklist of the planned implementation
  steps. May reference generated sub-tables.
- `## Files` — list of code files this feature owns. Generators MAY emit
  this list when feature scope is path-glob-derived.
- `## Scope` — globs the feature controls.

The `## Reference (Criteria)` and `## What It Does` (explanation)
section labels are explicit Diátaxis-mode markers within one file.
This is a pragmatic split: criteria are reference, the rest is
explanation, and labelling them keeps both authors and readers honest
about which mode they are in.

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
site path. The published path namespace:

```
[link text](/repos/<reponame>/features/<feature>/)
[link text](/repos/<reponame>/flows/<flow>/)
[link text](/hardware/<section>/)
[link text](/operations/<section>/)
```

`/repos/<reponame>/` is the canonical aggregation namespace. Aggregated
content lives under one `Repos` nav bucket and one URL prefix, not as
top-level peers of the host site's IA. (Earlier drafts used
`/software/<reponame>/`; renamed to `/repos/` because "software" is a
vacuous bucket label.)

### Long-term target — IA-by-mode-and-audience

Treating "the repo that authored a doc" as a navigation concept is an
authorship-model leak into the audience-facing IA. An operator looking
up "how do I deploy a mediavortex worker" is asking a how-to question
about a service, not "show me everything from the mediavortex git repo."

The long-term direction is to route aggregated docs into the host
site's IA buckets by declared **mode** (Diátaxis: how-to / reference /
explanation / tutorial) and **target section** (Operations / Hardware /
Services / etc.), eliminating `Repos` as a nav bucket. A mediavortex
runbook would land under Operations alongside other runbooks; a
mediavortex architecture explanation would land alongside other
architecture explanations.

This requires:

- `docs.export.yml` (or equivalent per-repo manifest) declares `mode`
  and `target_section` per file, not just a flat `nav` tree.
- The aggregator becomes routing-aware: it consults the host site's IA
  schema and slots each aggregated file into the correct destination.
- Cross-repo links use mode/section paths (`/operations/<doc>/`,
  `/services/<service>/<doc>/`) and a build-time redirect map keeps
  `/repos/<reponame>/<doc>/` working until consumers migrate.

Until that lands, all aggregated content stays under `/repos/<reponame>/`
so the convention has exactly one stable namespace to redirect from.
The migration when the routing-aware aggregator ships will be a MAJOR
bump per this convention's breaking-change classification (path
namespace change), with a deprecation cycle: `/repos/<reponame>/<doc>/`
keeps redirecting to the routed path for at least one MINOR before
removal. Bookmarks survive.

### In-repo links

In-repo links between docs in the same repo stay relative to the file
so they work without a server (e.g. local `mkdocs serve` against a
single repo, or simple GitHub rendering).

The aggregator script (in the repo that publishes the site) rewrites
relative links to absolute `/repos/<reponame>/...` paths during the
build. Authors never type a `/repos/...` path for a doc in their
own repo.

## Transclusion (Inline Cross-Doc Facts)

Procedures and runbooks need to inline specific values from canonical
sources without forcing the entire prose to live inside a marker.
Transclusion handles this:

```
SSH to {{host:brain:ip}} and run `pct config 206`.
The disk's grown-defect count is {{risk-register:3:status}}.
```

At build time, transclusion references resolve from the cited source.
A reference of the form `{{<source>:<key>:<attribute>}}` means: fetch
the named attribute of the keyed entity from the named source, replace
the reference with that value, fail the build if the entity or
attribute is missing.

Sources MUST be registered (a small mapping in the repo's docs config
declaring `host` resolves from `inventory.toml`, `risk-register`
resolves from `docs/operations/risk-register.md`, etc.). Unregistered
sources fail the audit.

Transclusion is what lets prose like "ssh to {{host:brain:ip}}" stay
readable AND keep the IP single-sourced. Without it, every runbook
either hard-codes IPs (drift) or wraps every value in a marker block
(unreadable).

## Versioning and Releases

The framework adopts [Semantic Versioning](https://semver.org/) at the
whole-framework level. One version applies to all `conventions/`,
`commands/`, `templates/`, and `.claude-plugin/hooks/` content.

`MAJOR.MINOR.PATCH`:

- **MAJOR** — breaking changes (see classification below). In `0.x`,
  breaking changes ride on MINOR bumps and are explicitly tagged
  `**BREAKING**` in the changelog entry.
- **MINOR** — backwards-compatible additions: new optional frontmatter
  field, new doc type, new convention section that does not invalidate
  existing docs.
- **PATCH** — fixes that do not change the contract: typos, clarified
  wording, corrected examples.

Stay in `0.x` until the conventions stabilize across at least two
adopting repos. Move to `1.0.0` only when committing to deprecation
discipline (one MINOR-release deprecation window before removal at the
next MAJOR).

### Breaking Change Classification

Apply this table on every PR that touches `conventions/`, `commands/`,
`templates/`, or `.claude-plugin/hooks/`. The classification appears in
the changelog entry.

| Change | Classification | Why |
|--------|----------------|-----|
| Add an optional frontmatter field | MINOR | Existing docs still parse and render. |
| Add a new doc type (e.g. tutorial) | MINOR | Pure addition; repos that don't author it are unaffected. |
| Add a new optional generator hook | MINOR | Existing generators continue to satisfy the contract. |
| Rename a marker pair (e.g. `<!-- generated:start -->` → `<!-- gen:start -->`) | **MAJOR** | Every existing generated block stops being recognized; every generator stops writing the right region. |
| Change a path namespace (e.g. `/software/` → `/repos/`) | **MAJOR** | Every cross-repo link 404s; aggregator nav assembly breaks. |
| Make an optional field required (e.g. `owner` becomes mandatory) | **MAJOR** | Existing docs without the field fail validation. |
| Remove a previously-supported value (e.g. drop `Status: PARKED`) | **MAJOR** | Existing docs using the value fail. |
| Change a generator's audit semantics (e.g. add a stricter check) | **MINOR** if pre-existing docs continue to pass; **MAJOR** if it would fail any compliant doc. |
| Tighten a regex or schema such that previously-accepted input fails | **MAJOR** | Same as removing a value. |
| Loosen a regex or schema such that previously-rejected input now passes | MINOR | Strictly additive. |

When in doubt: ask "would an adopting repo need to change anything to
keep its current `--audit` clean?" If yes, MAJOR. If no, MINOR.

### Deprecation Cycle

A deprecated element keeps working for at least **one MINOR release**
before removal at the next MAJOR. Each deprecation entry in the
changelog includes:

```
### Deprecated in 0.4.0, removed in 0.6.0
- `<element>` — what is deprecated.
- Replacement: `<new-element>` — what to use instead.
- Migration: `<codemod-or-manual-steps>` — how adopting repos migrate.
- Removal version target: `<version>`.
```

If automation is feasible, claude-rails ships a `migrate` codemod
under `commands/migrate-<element>.md`. Manual migrations document
explicit steps in the deprecation entry.

The deprecated element stays callable until the removal version --
generators continue to emit; audits continue to accept; the only
change is the deprecation banner at session start (see
"Conformance and Adoption" below).

### Generator Refusal on Major Mismatch

A generator MUST refuse to run when the framework version installed
on the machine and the version the repo was last validated against
disagree across a MAJOR boundary. Refusal looks like:

```
[FAIL] claude-rails major-version mismatch:
  installed:           0.4.x
  repo last validated: 0.3.x
  Run /check-conformance and update the repo's
  .claude/claude-rails-version after migrating.
```

Within-MAJOR mismatches warn but proceed. The default-deny posture on
MAJOR drift exists because a generator that writes to a renamed marker
or emits in a removed format produces silent corruption -- the worst
failure mode.

## Conformance and Adoption

Each adopting repo records the framework version it was last validated
against in `.claude/claude-rails-version`. The framework writes
`~/.claude/claude-rails-version` at install time (the *installed*
version on the machine).

`/check-conformance` is the slash command that reconciles them:

- Reports installed version, repo's last-validated version, and any
  conformance violations against the installed version's conventions.
- Exits non-zero on violations.
- Updates `.claude/claude-rails-version` only after the user
  acknowledges any violations and the repo passes.

Session-start banner behavior:

- `installed > repo`, same MAJOR — one-line banner: "claude-rails
  X.Y.Z installed; this repo last validated against X.Y0.Z0. Run
  /check-conformance."
- `installed > repo`, across MAJOR — loud warning + audit refusal
  until `/check-conformance` runs and the repo is updated.
- `installed < repo` — warn that the local install is older than what
  the repo expects. Continue, but flag features the repo uses that
  the older claude-rails doesn't ship.

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
