# Feature Conventions

Stack-agnostic principles every new feature in every claude-rails-synced
repo should follow. Loaded between `rules/` (invariants) and sibling
docs in the token hierarchy so sessions see them before writing any
feature doc.

Conventions are principles, not invariants. A feature that cannot honor
a convention declares a `## Deviation from conventions` section in its
feature doc with a one-line rationale. The `/n` command flags
violations at criteria time; the `/fs` command surfaces deviations in
the closure summary.

## Persistence behind a Store seam

Every feature that persists data accesses storage through a named
interface -- call it `Store`, `Repository`, `DAO`, whatever fits the
stack -- with typed dataclasses (or equivalent) at its boundary. The
seam lets the implementation swap from in-memory dict to flat JSON to
SQLite to Postgres without touching callers.

- No SQL, ORM objects, or file paths leak into scoring, notification,
  UI, or business-logic code. If a caller writes a `SELECT`, the seam
  is already broken.
- One writer contract and one reader contract per entity. Callers use
  them; they do not assemble queries.
- Schema lives next to the implementation, not scattered across
  consumers.

Litmus test: can you stand up a 10-line mock Store for unit tests
without rewriting the callers? If yes, the seam holds.

## UI reads the data layer, never owns persistence

Dashboards, digests, exports, and any other reader-shaped surface
reach the data through the Store. New sources show up in the UI
automatically because both sides talk to the same rows. Features that
add UI write zero source-side code; features that add sources write
zero UI code.

## Internal web apps default to the shared internal-apps server

New HTTP-serving features land as a service on the repo's existing
internal-apps host (typically one VM or LXC running a docker-compose
stack), fronted by the repo's existing reverse proxy and DNS. No new
VMs, no per-app systemd units on the host, no new Python/Node
installs on shared machines. The container is the feature's runtime;
the compose-file entry is its lifecycle management.

- One hostname per app, routed by the shared reverse proxy. Operators
  always reach apps by friendly URL on the standard public port (443
  for TLS-terminated sites); internal ports are implementation detail.
- The app's container carries all non-stdlib dependencies (browsers,
  system libraries, runtime versions). The host stays clean.
- Restart policy in the compose file replaces per-app systemd units.
  `restart: unless-stopped` is the common default.
- Shared state directories (SQLite files, cache, cookies, etc.)
  mount as named volumes, backed up by the host's existing backup
  job.

**Extraction path:** when an app outgrows shared hosting (CPU, memory,
or availability profile), move its compose-file entry to a dedicated
host and update DNS + the reverse-proxy upstream. Application code
does not change. The compose entry IS the extraction seam.

**When NOT to default to shared hosting:** apps with incompatible
runtime requirements (conflicting system libraries the container
cannot resolve), apps whose failure modes must not impact the shared
host's other services (high-memory OOM candidates, busy-looping risk),
or apps with regulatory/isolation requirements. Each exception goes in
the feature's `## Deviation from conventions` block with a one-line
rationale.

## Web-facing services ship observability and integration in-commit

Any HTTP-serving feature lands with, in the same commit:

- `/health` endpoint returning JSON; 200 on OK, 5xx on degraded.
- Metrics exported in a format the repo's existing monitoring stack
  already scrapes (e.g., Prometheus textfile collector).
- DNS entry (both primary and secondary resolvers if the repo runs
  them).
- Reverse-proxy route with TLS and whatever auth the repo standardizes
  on.
- A systemd unit, docker-compose service, or equivalent persistent-run
  wrapper.
- A backup entry for stateful data, added to the repo's backup runbook.

Shipping a service without one of these is a deviation that requires a
rationale. "We'll add it later" is not a rationale.

## Own runtime + pinned dependencies per feature

Each feature that runs code owns its own isolated runtime:

- Python: its own venv, its own pinned `requirements.txt`, never
  shared site-packages.
- Node: its own `node_modules/` via `package-lock.json`.
- Go / Rust / Swift: their own module, their own lockfile.

Setup steps (apt packages, `playwright install`, `rustup component add`,
etc.) are documented in the feature's README Setup section so a fresh
machine can reproduce without guessing.

## Secrets via `.env`, gitignored from commit zero

Real secret values never enter git. `.env.example` (or equivalent
template) is committed and enumerates every variable the feature
reads. `.env` is in the feature's `.gitignore` before the first commit
that introduces the feature, not after.

## Graceful named exceptions, not silent zeros

Every external-dependency failure mode gets a typed exception with a
specific name (`CaptchaGated`, `RateLimited`, `UpstreamUnavailable`).
Callers catch and surface; they do not return empty lists that look
like "no data today" when in fact the data source refused to answer.

## Dry-run fixture path on every external-data source

Every source module (API client, scraper, feed reader) ships alongside
a small built-in fixture so the pipeline can be exercised end-to-end
without live credentials or network. Makes `--dry-run` reliable for
local development and CI.

## Risk-register + sunset plan for stateful services

Any feature that stores user data, receives external traffic, or holds
credentials gets:

- A row added to the repo's risk register describing what's at stake
  if the service is compromised, corrupted, or fails.
- A short sunset runbook in the feature's README: stop service,
  remove DNS entry, remove proxy route, back up state, drop data.

Stateless tools (pure CLIs, one-shot scripts) are exempt from both.

## Forward-compatible config files

Config files that gate later slices ship with blocks for future
sub-features stubbed or commented, not absent. Keeps the file shape
stable across the feature's lifetime and prevents churn when Slice N
lands.

## Declaring a deviation

When a convention genuinely does not fit, the feature doc names it
explicitly:

```
## Deviation from conventions

- persistence.no-store: this feature is a one-shot CLI with no state;
  the Store seam would be ceremony for zero benefit.
- observability.skipped: offline batch run by hand; no monitoring
  endpoint needed.
```

**Required format:** each bullet is `convention-name: one-line rationale`.
The colon is load-bearing. A bullet without a colon has no rationale
and is rejected by `fs:` at closure. "We'll add it later" is not a
rationale; either address the convention now or state the genuine
reason it does not apply.

The `fs:` closure workflow surfaces each deviation in its commit
summary so reviewers see what was sidestepped without reading the
whole feature doc.

## Stack-specific starters

Conventions are stack-agnostic on purpose. Concrete per-stack templates
(scaffolded file layouts, framework picks, template code) live as
separate skills under `claude-rails/skills/starter-*` when a real
project drives one into existence. A project declares in its own
`CLAUDE.md` which starter it uses, if any. Starters are opt-in and
additive: the conventions above apply regardless of starter choice.
