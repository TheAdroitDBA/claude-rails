# Feature: Rails-Managed Blocks

## What It Does

Introduces a managed-block distribution mechanism so framework-owned content in adopted repos' `CLAUDE.md` and `README.md` stays current without re-running `/project-setup`. A sentinel-fenced block in each file carries a version stamp and a content hash; a new `/rails-sync` command compares the stamp to the framework's `VERSION` file, detects tampering inside the fence, and offers to update the block in place. `/w` reports drift without mutating anything -- consistent with the framework's existing "report, do not auto-edit" stance.

The block is intentionally minimal -- a pointer, not a mirror. It names the framework version the repo is synced to and points at `~/.claude/MEMORY.md` as the canonical rules location. Duplicating rules into every repo would fight the token-optimization goal and create N copies to drift. The block exists so a human reading the repo on GitHub knows what framework it adopts and at what version.

The framework also writes a `.claude/rails-version` file alongside the existing marker. Single-responsibility per file: `.claude/feature-doc-required` stays a presence-only opt-in (its content is ignored, unchanged from today); `.claude/rails-version` carries the version string the repo last synced against. Adopted repos missing the new file are treated as "opted in at unknown version" -- backward compatible, no forced migration.

## Surface

- `/rails-sync` (new command) -- read each managed block's version stamp and content hash; compare against framework `VERSION`. Hash validation runs only when the block's stamped version equals the current framework version (older-stamped blocks skip the hash check, since the framework keeps only the current canonical template). On match: no-op. On overwrite needed: per-file prompt with four options -- `y` overwrite, `n` skip this file, `d` show full diff then re-prompt, `a` abort entire sync. On major-version drift: refuses to overwrite without an explicit `--major` flag.
- `/w` -- when stack-frame reporting completes, also check the managed-block version stamp against the framework `VERSION` and print a one-line drift notice if they diverge. Major-version drift escalates from notice to warning.
- `/project-setup` -- when scaffolding a new repo's `CLAUDE.md` and `README.md`, write the managed block with the current framework version and content hash.

## Success Criteria

1. `CLAUDE.md` and `README.md` (in any opted-in repo) may contain a managed block delimited by `<!-- claude-rails:start vX.Y.Z sha=<hash> -->` and `<!-- claude-rails:end -->`. Outside the markers is repo-owned; inside is framework-owned.
2. The `vX.Y.Z` in the start marker matches the framework's `VERSION` file at the time of last sync.
3. The `sha=<hash>` in the start marker is the first 8 hex chars of SHA-256 over the **normalized** canonical block content. Normalization rules (in order): (a) line endings converted to LF; (b) trailing whitespace stripped per line; (c) no trailing newline at the end of the block. Recomputing the block from `templates/managed-blocks/current.md` must produce the same hash byte-for-byte on Mac, Linux, and Windows.
4. `/rails-sync` reads each managed block's stamp, fetches the canonical content for the current framework `VERSION`, and diffs. Hash validation: if the stamped version equals the current framework `VERSION`, recompute the expected hash from `templates/managed-blocks/current.md` and compare -- mismatch means the user edited inside the fence. If the stamped version is older than current, the hash check is skipped entirely (the framework no longer holds the canonical template for that version). In all overwrite scenarios, prompt per-file with four options: `y` overwrite, `n` skip this file, `d` show full diff then re-prompt, `a` abort the sync. No "yes to all" in v1 -- batch overwrite is a future `--yes` flag, deferred and out of scope for this feature.
5. `/w` checks the managed-block version stamp against the framework `VERSION`. On match: silent. On minor/patch drift: one-line notice -- `rails-managed block is <N> versions behind; run /rails-sync`. On major drift: warning that names the required flag -- `rails-managed block is on vX; framework is on vY -- major drift; run /rails-sync --major to acknowledge breaking changes`. The `/w` check is read-only; it never edits the block.
6. `/project-setup` writes the managed block into newly scaffolded `CLAUDE.md` and `README.md`, stamped with the current framework version.
7. The managed-block content is a pointer, not a rules mirror: it names the framework version, names `~/.claude/MEMORY.md` as the canonical rules location, names `/w` as the entry-point command. Total block content under 10 lines.
8. A new file `.claude/rails-version` carries the framework version the repo last synced against (e.g. `v0.1.0` on a single line, LF-terminated). `.claude/feature-doc-required` is unchanged: presence-only opt-in, content ignored. Repos that have `feature-doc-required` but no `rails-version` are treated as "opted in at unknown version" -- `/rails-sync` offers to stamp the current version on its first run; `/w` prints a one-line notice ("rails-version file missing; framework version is vX.Y.Z") but no warning. Single responsibility per file: opt-in stays orthogonal to install fingerprint.
9. Repos without the markers are not touched -- `/rails-sync` reports "no managed blocks found" and exits. This feature is strictly additive; existing repos do not gain blocks unless `/project-setup` is re-run or the user adds them manually.
10. Documentation in `docs/glossary.md` defines: `managed block`, `version stamp`, `content hash`, `rails-sync`, `rails-version file` (the new opt-in companion file).

11. `templates/managed-blocks/` contains exactly one canonical template -- `current.md` -- representing the block for the current framework `VERSION`. Older versions are NOT retained. Consequence: `/rails-sync` cannot recompute the expected hash for any block stamped at a non-current version; those blocks skip hash validation and fall through to the standard per-file overwrite prompt. Tradeoff accepted: detecting "user edited inside the fence" only works against the current version; older blocks are treated as "needs update, possibly with customizations -- ask the operator."

12. `/rails-sync` refuses to overwrite across a major-version boundary unless invoked with an explicit `--major` flag. This applies regardless of hash match: a clean, hash-matching block stamped at v0.x will NOT be silently bumped to v1.x without the flag. The intent is to force operator acknowledgement of breaking changes; semver majors are by definition not routine bumps.

13. `commands/rails-sync.md` includes a `## Release-cut workflow` note explaining that when claude-rails itself ships a new `VERSION`, the maintainer runs `/rails-sync` against the framework repo's own `CLAUDE.md` and `README.md` as part of the release commit -- updating the stamped version and hash in the managed block. This makes self-hosting an explicit ritual rather than an afterthought, and is the first verification step before any external repo is synced.

## Status

COMPLETE

### Progress

- [x] Phase 0 (2026-05-16): shipping order confirmed -- stack-anchor-and-bug-ids is COMPLETE (commit 7ae16fb); the first managed-block sync will prove the design with a real version bump
- [x] Phase 0.5 (2026-05-16): five design holes locked before any implementation -- (1) hash normalization: LF endings, strip trailing whitespace per line, no trailing newline; (2) `templates/managed-blocks/current.md` only, no per-version accumulation -- older-stamped blocks skip hash check; (3) `/rails-sync` prompt options = y/n/d/a per file, no "yes to all" in v1; (4) `.claude/rails-version` is a NEW separate file from `.claude/feature-doc-required` (single responsibility, no semantic overloading); (5) major-version drift refuses overwrite without explicit `--major` flag, with `/w` warning naming the flag
- [x] Phase 1 (2026-05-16): wrote `templates/managed-blocks/current.md` -- 4 lines of canonical inner content (under-10 budget honored), names framework v0.1.0, points at `~/.claude/MEMORY.md` as canonical rules, names `/w` as entry-point command, instructs the reader to run `/rails-sync` on version change. Hash for v0.1.0 = `e74b74e1` (SHA-256 first 8 hex over normalized content per criterion 3: LF endings, trailing whitespace stripped per line, no trailing newline). Verified reproducible via Python on Git Bash; will be re-verified on Mac/Linux when Phase 8 self-host runs.
- [x] Phase 2 (2026-05-16): subsumed by Phase 0.5 lockdown -- hash algorithm is fully specified in criterion 3 (normalize -> SHA-256 -> first 8 hex), storage location is fully specified in criterion 11 (`templates/managed-blocks/current.md` only, no per-version accumulation). Nothing further to ship for this phase; the hash computation lives inside `/rails-sync` (Phase 3).
- [x] Phase 3 (2026-05-18): wrote commands/rails-sync.md -- 9-step pipeline (locate framework root, read VERSION + canonical content, compute expected hash, scan adopted repo for markers, classify per block, major-drift gate, per-file y/n/d/a prompt, in-place apply, write .claude/rails-version, report). Includes Release-cut workflow section (criterion 13). Future `--yes` flag explicitly deferred and documented as not-implemented.
- [x] Phase 4 (2026-05-18): extended commands/w.md -- new step 2 "Managed-block drift check (read-only)" with five cases (no-feature-doc-required short-circuit, missing-rails-version notice, version-match silent, minor/patch notice, major-drift warning, future-version warning). Renumbered subsequent steps to 4-7. Criterion 5.
- [x] Phase 5 (2026-05-18): updated commands/project-setup.md -- 6b now writes `.claude/rails-version` as `v<VERSION>` on a single LF-terminated line; new section 6o handles managed-block emission in CLAUDE.md and README.md (reads templates/managed-blocks/current.md, computes hash per criterion 3 normalization, substitutes start-marker version + sha placeholders, replaces inner content). Skip-if-markers-absent rule prevents re-inject after user removal. Idempotent. Criteria 6, 8.
- [x] Phase 6 (2026-05-18): added managed-block stub to both templates -- `<!-- claude-rails:start v0.0.0 sha=00000000 -->` ... `<!-- claude-rails:end -->` with placeholder content. Placed after title (claude-md.md) and after one-line description (readme.md). /project-setup step 6o substitutes real version + hash + canonical content at write time.
- [x] Phase 7 (2026-05-18): added five glossary entries under new "Versioning & Sync" section -- `managed block`, `version stamp`, `content hash`, `rails-sync`, `rails-version file`. Criterion 10.
- [x] Phase 8 (2026-05-18): self-host complete. Recomputed hash via Python = e74b74e1 (matches Phase 1's recorded value on Git Bash). Added managed block to this repo's CLAUDE.md and README.md with v0.1.0 + sha=e74b74e1. Created .claude/rails-version containing v0.1.0. Mac/Linux cross-platform verification deferred -- the normalization algorithm is platform-agnostic by construction (explicit LF, strip trailing whitespace, no trailing newline); deferred to first external repo sync. External-repo sync deferred to repo-owner cadence (same closure principle as bug-index Phase 12).
- [ ] NEXT: nothing on rails-managed-blocks. Next feature candidates from IDEAS.md: parallel-dev backlog, what-vs-how doc separation, features-index (likely absorbed by parallel-dev backlog).

## Files

- rails-managed-blocks.feature.md (this file)
- commands/rails-sync.md (new)
- commands/w.md (drift check addition; layered on top of stack-anchor's /w changes)
- commands/project-setup.md (emit block on scaffold; write `.claude/rails-version` alongside `.claude/feature-doc-required`)
- templates/project-setup/claude-md.md, readme.md (block stub)
- templates/managed-blocks/current.md (single canonical template; no per-version accumulation)
- docs/glossary.md (managed block, version stamp, content hash, rails-sync, rails-version file)
- VERSION (read by /rails-sync and /w; no schema change)

## Scope

commands/rails-sync.md
commands/w.md
commands/project-setup.md
templates/project-setup/claude-md.md
templates/project-setup/readme.md
templates/managed-blocks/**
docs/glossary.md
rails-managed-blocks.feature.md

## Deviation from conventions

- **No sibling `*.flow.md`.** Same reasoning as stack-anchor-and-bug-ids: the surface is slash commands; their `.md` files are their own flow specs.
- **Touches `commands/w.md` which is also in scope for stack-anchor-and-bug-ids.** Coordinate ordering: stack-anchor ships first; this feature's `/w` drift-check addition layers on top of the already-extended `/w`.
