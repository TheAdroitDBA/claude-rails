# Contributing

Working agreement for changes to claude-rails.

## Versioning + changelog

claude-rails follows [Semantic Versioning](https://semver.org/). See
`conventions/auto-doc.md` for the full versioning section, including
the breaking-change classification table.

**Every PR that changes `conventions/`, `commands/`, `templates/`, or
`.claude-plugin/hooks/` MUST include a `CHANGELOG.md` entry.**

The entry goes under `## [Unreleased]` and uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
categories: Added, Changed, Deprecated, Removed, Fixed, Security.

Each entry classifies its change:

- **PATCH** — fixes that don't change the contract (typos, clarified
  wording, corrected examples).
- **MINOR** — backwards-compatible additions (new optional field, new
  doc type, new optional generator hook).
- **MAJOR** — breaking changes (renamed marker, changed namespace,
  optional → required, removed value). In `0.x` these ride on MINOR
  bumps; the entry is tagged `**BREAKING**`.

When in doubt, classify per the table in `conventions/auto-doc.md`.

## Enforcing the changelog rule

Run the check manually before committing:

```bash
bash scripts/check-changelog.sh
```

It exits 0 if your staged changes don't touch surface files OR if
they do AND CHANGELOG.md is also staged. Exit 1 if you forgot.

To wire it as a git pre-commit hook (so you can't forget):

```bash
# from the claude-rails repo root
ln -sf "$(pwd)/scripts/check-changelog.sh" .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

PowerShell equivalent:

```powershell
# from the claude-rails repo root
$src = Join-Path (Get-Location) "scripts\check-changelog.sh"
$dst = ".git\hooks\pre-commit"
# Git on Windows runs hooks via Git Bash; the .sh file works directly.
Copy-Item $src $dst -Force
```

Repeat once per local clone.

## Releasing

1. Move `## [Unreleased]` entries into a dated version section:
   `## [0.2.0] - 2026-MM-DD`.
2. Update the `VERSION` file to match.
3. Commit: `release: vX.Y.Z`.
4. Tag annotated: `git tag -a vX.Y.Z -m "vX.Y.Z -- ..."`.
5. Push commit and tag.

The `## [Unreleased]` heading is restored at the top of `CHANGELOG.md`
in the next PR that touches a surface file.

## Code style

See `conventions/style-guide.md` for doc-writing voice and conventions.

## Testing

Where claude-rails ships executable scripts (`install.sh`, `install.ps1`,
`scripts/check-changelog.sh`), changes should be tested manually on
both Mac/Linux and Windows when feasible.

The framework itself is mostly markdown + slash commands; the
"tests" are:

1. Run `/hook-health` in a session after the change. It should pass.
2. Run `/check-conformance` from an adopting repo. It should report
   the new framework version and either pass or report specific
   actionable violations.

## What not to do

- Do not skip `CHANGELOG.md` "just for this one." Temporary becomes
  permanent.
- Do not hand-curate version stamps in places other than `VERSION`
  and `CHANGELOG.md`. Other places should read those two files.
- Do not add a hook, command, or convention without thinking through
  the breaking-change classification.
- Do not push a tag for a version that has no `CHANGELOG.md` entry.
