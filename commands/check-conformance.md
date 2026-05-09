---
description: Check this repo's conformance against the installed claude-rails version. Reports framework version, repo's last-validated version, and any conformance violations. Exits non-zero on violations.
argument-hint: <none>
---

You are running the claude-rails conformance check for the current
repo. This is the slash command operators run after upgrading their
local claude-rails install or after onboarding a new repo.

## What this command does

Reconciles three things:

1. **Installed framework version** — the claude-rails version on this
   machine, recorded at `~/.claude/claude-rails-version` by `install.sh`
   or `install.ps1`.
2. **Repo's last-validated version** — the version this repo last
   passed conformance against, recorded at
   `<repo>/.claude/claude-rails-version`.
3. **Current repo state** — files that should match the installed
   version's conventions.

Reports differences. Exits non-zero on conformance violations.

## Steps

Execute these in order. Use Bash/PowerShell as appropriate to the
host OS.

### Step 1 — read installed version

```
cat ~/.claude/claude-rails-version
```

If the file does not exist, the user has never installed claude-rails
on this machine. Tell them to run the appropriate `install.sh` or
`install.ps1` from the claude-rails repo and re-run this command.

### Step 2 — read repo version

```
cat <repo-root>/.claude/claude-rails-version
```

If the file does not exist, this repo has never been validated. That
is fine for a fresh adoption; treat the repo's version as "0.0.0"
(strictly less than any released framework version) and proceed.

### Step 3 — compare versions

Parse both as `MAJOR.MINOR.PATCH`. Compute the relationship:

- **Equal** — no upgrade needed; conformance is current. Continue
  to Step 4 to verify the repo still actually conforms (in case the
  repo was edited by hand since last validation).
- **`installed > repo`, same MAJOR** — upgrade pending. One-line
  notice: "claude-rails {installed} installed; this repo last
  validated against {repo}. Run conformance checks below."
  Continue to Step 4.
- **`installed > repo`, across MAJOR** — loud warning: "MAJOR-VERSION
  MISMATCH: framework moved from {repo MAJOR}.x to {installed MAJOR}.x
  since this repo was validated. Migration may be required. See
  CHANGELOG.md in the framework repo for breaking changes." Continue
  to Step 4 with strict mode.
- **`installed < repo`** — warn that the local install is older than
  what the repo expects. Tell the user to update their claude-rails
  clone (`git pull` in the framework repo, then re-run `install.sh`).
  Stop without running the conformance checks; running an older
  framework against a newer repo can produce false positives.

### Step 4 — run conformance checks

For each check below: report PASS / FAIL with file:line citations on
failures. Aggregate results; exit non-zero if any check fails.

**Check 4a — feature/flow doc presence frontmatter (MAJOR ≥ 1).**

Find every `*.feature.md` and `*.flow.md` in the repo. For each,
verify the frontmatter has `owner`, `review-by`, and `last-reviewed`.

Note: in `0.x` this check is advisory; report missing frontmatter
as WARN, not FAIL. The framework has not committed to making this
required until 1.0.0.

**Check 4b — marker pair integrity.**

For every `*.md` file in the repo: every `<!-- generated:start -->`
or `<!-- generated:<label>:start -->` MUST have a matching `*:end`
on the same level. Orphan markers fail.

**Check 4c — Status line presence in feature docs.**

Every `*.feature.md` must have a `## Status` section with a single
line value of `NOT STARTED`, `IN PROGRESS`, `COMPLETE`, or `PARKED`.
Other values fail.

**Check 4d — flow doc shape.**

Every `*.flow.md` must contain a `flowchart` mermaid block. (Step
table generation is not required to be wired yet -- the convention
allows `0.x` repos to author the mermaid before the auto-generated
table exists.)

**Check 4e — cross-repo link namespace.**

Scan all `*.md` for absolute paths starting with `/software/`. The
namespace was renamed to `/repos/` in 0.1.0. Any remaining `/software/`
links fail. (In a future MAJOR bump, this becomes an error in 0.x
deprecation period; for 0.1.0, treat as FAIL with a migration hint.)

**Check 4f — temporal qualifier scan (advisory).**

Grep for "currently", "as of now", "recently", "soon" in `*.md`
under `docs/`. Report as WARN with file:line; these are style-guide
violations but not contract violations. Do not FAIL the check.

### Step 5 — write the result

If all checks pass: write the installed version to
`<repo-root>/.claude/claude-rails-version`. This is the "I have
re-validated this repo" record.

If any check FAILS: do not update the file. Report the violations and
exit non-zero. The user fixes the violations and re-runs the command.

If only WARNs: report them, prompt the user to confirm, and update
the version file on confirmation.

## Output format

```
claude-rails conformance report
================================

Installed:    {version}
Repo:         {version} (or 0.0.0 if never validated)
Relationship: {equal | within-major | cross-major | repo-newer}

Checks:
  4a feature-doc frontmatter   {PASS | WARN | FAIL}
  4b marker pair integrity     {PASS | FAIL}
  4c feature-doc Status line   {PASS | FAIL}
  4d flow doc shape            {PASS | FAIL}
  4e cross-repo link namespace {PASS | FAIL}
  4f temporal qualifiers       {PASS | WARN} (advisory)

{If FAIL: list violations with file:line citations}

{If PASS or WARN-only with confirmation: write repo version}

Exit code: 0 if PASS or confirmed WARN, 1 otherwise.
```

## Notes

- This is read-only on the user's repo files except for one write to
  `<repo>/.claude/claude-rails-version` after a clean check.
- The check is intentionally not exhaustive against every convention
  rule. It targets the rules whose violation produces visible breakage
  (markers, Status lines, namespace) plus advisories for style.
- Conformance is the contract the framework offers adopting repos.
  When new convention rules land in `conventions/auto-doc.md`, the
  corresponding check is added to this command. Older versions of
  `/check-conformance` will not run the new check; that's the point
  of the version reconciliation in Step 3.
