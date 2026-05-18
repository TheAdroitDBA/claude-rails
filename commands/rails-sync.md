---
description: Sync the rails-managed block in this repo's CLAUDE.md and README.md against the current claude-rails framework version. Read-only by default until per-file confirmation. Refuses major-version drift without --major.
argument-hint: [--major]
---

Sync rails-managed blocks against the framework's current `VERSION`.

The managed block in `CLAUDE.md` and `README.md` is framework-owned content delimited by:
- start: `<!-- claude-rails:start vX.Y.Z sha=<hash> -->`
- end: `<!-- claude-rails:end -->`

Outside the markers is repo-owned and never touched.

## Step 1: Locate framework root

The framework directory is the parent of the `commands/` folder this skill file lives in. From the skill's resolved path (follow junction/symlink), the framework root contains `VERSION` and `templates/managed-blocks/current.md`. Confirm both exist; abort with a clear message if either is missing.

## Step 2: Read framework state

- `VERSION` -> `FRAMEWORK_VERSION` (e.g. `0.1.0`).
- `templates/managed-blocks/current.md` -> `CANONICAL_CONTENT` (the inner-block content, NOT including the markers).
- Compute `EXPECTED_HASH`: normalize CANONICAL_CONTENT (LF line endings, strip trailing whitespace per line, no trailing newline), SHA-256, take first 8 hex chars.

Cross-platform hash recipe (any of these must produce the same value):
- Python: `import hashlib, re; n = '\n'.join(l.rstrip() for l in content.splitlines()); print(hashlib.sha256(n.encode()).hexdigest()[:8])`
- PowerShell: read file, replace `\r\n` -> `\n`, rstrip per line, join with `\n`, no trailing newline, then `Get-FileHash -Algorithm SHA256` on a temp file or `[System.Security.Cryptography.SHA256]` over the byte stream; take first 8 hex chars.

If `EXPECTED_HASH` differs across platforms, normalization has drifted -- abort and surface the bug.

## Step 3: Scan adopted repo for managed blocks

Look for the start/end markers in `CLAUDE.md` and `README.md` at the repo root. For each match:
- Parse `vX.Y.Z` from start marker -> `STAMPED_VERSION`.
- Parse `sha=<hash>` from start marker -> `STAMPED_HASH`.
- Extract the content between the markers (exclusive) -> `BLOCK_CONTENT`.

If neither file has the markers, print `no managed blocks found; nothing to sync` and exit. Repos must opt in via `/project-setup` or by manually adding the markers -- this command is strictly additive.

## Step 4: Classify each block

For each managed block found:

| Condition | Classification | Action |
|---|---|---|
| `STAMPED_VERSION` == `FRAMEWORK_VERSION` AND `STAMPED_HASH` == hash of `BLOCK_CONTENT` | clean | no-op for this file |
| `STAMPED_VERSION` == `FRAMEWORK_VERSION` AND `STAMPED_HASH` != hash of `BLOCK_CONTENT` | tampered | prompt to overwrite (user edited inside the fence) |
| `STAMPED_VERSION` < `FRAMEWORK_VERSION`, same major | drift (minor/patch) | prompt to overwrite (hash check skipped per criterion 11) |
| `STAMPED_VERSION` major < `FRAMEWORK_VERSION` major | major-drift | refuse unless `--major` flag was passed |
| `STAMPED_VERSION` > `FRAMEWORK_VERSION` | future-version | abort with a clear message; do not touch the block |

## Step 5: Major-drift gate

If any block is classified `major-drift` and `--major` was NOT passed: print one line per affected file:

```
<file>: managed block stamped vX.Y.Z; framework is vA.B.C -- major drift. Re-run with --major to acknowledge breaking changes.
```

Exit without prompting and without writing. The user explicitly opts in to major bumps.

## Step 6: Per-file prompt

For each `tampered` / `drift` / `major-drift` (with `--major`) block, prompt:

```
<file>: managed block update needed
  current stamp: vX.Y.Z sha=<old>
  target stamp:  vA.B.C sha=<new>
  reason:        <tampered | drift vX.Y.Z -> vA.B.C | major drift vX -> vA>

[y] overwrite this file    [n] skip this file    [d] show full diff    [a] abort sync
```

- `y` -> apply (Step 7).
- `n` -> leave the file unchanged; continue with remaining files.
- `d` -> render unified diff (`CANONICAL_CONTENT` vs `BLOCK_CONTENT`) and re-prompt.
- `a` -> abort the entire sync; do not write any pending file.

No "yes to all" in v1. Each file gets its own decision. (Future flag: `--yes` for batch overwrite, deferred -- not implemented.)

## Step 7: Apply the update

For each approved file:
1. Replace `BLOCK_CONTENT` (between the markers) with `CANONICAL_CONTENT`.
2. Replace the start marker's `vX.Y.Z` with `vFRAMEWORK_VERSION` and `sha=<old>` with `sha=<EXPECTED_HASH>`.
3. Write the file back. Preserve the rest of the file byte-for-byte.

## Step 8: Update .claude/rails-version

After at least one file is updated (or if the user opts to stamp without changes), write `FRAMEWORK_VERSION` to `.claude/rails-version` (overwrite; single line, LF-terminated). If the file did not exist before this run, print: `stamped repo at vX.Y.Z (was: unknown version)`.

If `.claude/feature-doc-required` exists but `.claude/rails-version` did not, this is the "opted in at unknown version" case (criterion 8). Treat as eligible for sync; `/rails-sync`'s first run creates `rails-version`. Do not touch `feature-doc-required` -- it is a presence-only opt-in.

## Step 9: Report

Print a summary:

```
Synced: N files updated (CLAUDE.md, README.md)
Skipped: M files
Aborted: 0
.claude/rails-version: v0.1.0 (was: v0.0.9)
```

## Release-cut workflow

When claude-rails itself ships a new `VERSION`, the framework maintainer runs `/rails-sync` against the framework repo's own `CLAUDE.md` and `README.md` as part of the release commit. This:

1. Updates the stamped version and hash in claude-rails' own managed block.
2. Self-hosts the change first -- the framework repo is the canonical first consumer.
3. Surfaces any normalization-bug or platform-divergence before any external repo is asked to sync.

Procedure:
1. Bump `VERSION` to the new version.
2. If the canonical block content changed, edit `templates/managed-blocks/current.md` accordingly.
3. Run `/rails-sync` in the claude-rails repo. Confirm the managed blocks in this repo's own `CLAUDE.md` and `README.md` update cleanly.
4. Commit `VERSION`, `templates/managed-blocks/current.md` (if changed), the two managed-block updates, and `.claude/rails-version` in one release commit.
5. Push. Other adopted repos sync on their own schedule via `/rails-sync`.

Self-hosting first is non-negotiable: if the framework cannot sync its own block, it cannot sync anyone else's.

## Notes

- This skill is read-only until the user explicitly answers `y` to a prompt. Cancelling at any prompt leaves the working tree untouched.
- Never `rm` the block. Edits are in-place between the markers.
- Markers themselves are never modified except to update the stamped version and hash on the start marker.
- Repos without markers are not eligible -- run `/project-setup` to scaffold them, or add the markers manually.
