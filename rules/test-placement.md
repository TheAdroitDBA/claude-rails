# Test Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where tests live and how they are organized, NOT how they are written.

## Invariants

- Tests live at `<project>/tests/<suite>/`. One directory per suite. A suite is a cohesive group of checks that verify one subject (a feature, a module, a hook, an API endpoint, a pipeline).
- Every suite has a colocated `*.feature.md` with numbered Success Criteria, a `## Status` block, and a `### Progress` checklist. Same discipline as hooks, skills, agents. A suite without a feature doc is a gap: the coverage promise is implicit and will drift.
- **Tests are features.** A test suite is a unit of work owned like any other. It gets promoted, reviewed, and retired under the same rules. "Just a quick test" is not a license to skip the feature doc.
- Suite filenames match the suite subject, not the thing being tested at the filename level: `tests/shortcuts/shortcuts.sh` beats `tests/shortcuts/shorthand-expand.test.sh`. The `tests/<suite>/` prefix already provides context.
- **No runner, assertion library, or framework is prescribed by this rule.** The project chooses its own tools. The rule governs where test files live and how they are documented, not how they are executed. Existing testing norms of the project's language/stack take precedence.
- **No network I/O. No git operations against the host repo** (no commits, branch changes, fetches, pushes). Scratch git repos inside the OS temp dir are OK when the suite needs to simulate a project context for the code under test. **No persistent writes outside the repo**; ephemeral scratch state under `$TMPDIR` / `%TEMP%` is OK if the suite cleans it up before exiting, pass or fail. A suite that reaches outside this boundary without cleanup is an integration probe, not a test; either move it out of `tests/` or sandbox it explicitly.
- Cross-OS parity: if the thing being tested must work on multiple operating systems, the harness must too. A suite testing cross-OS code has one implementation per supported OS (e.g., `suite.sh` + `suite.ps1`); they must produce equivalent PASS/FAIL on the same inputs. Single-OS code can have a single-OS harness; no parity required.

## How to Apply

- **Adding a suite:**
  1. Scaffold `tests/<suite>/<suite>.feature.md` first. Approve criteria before writing the harness.
  2. Write the harness using the project's normal test tooling. Place output files under `tests/<suite>/`.
  3. Resolve the repo root from the suite's own file location, never from a hardcoded path or current working directory. This lets the suite run from anywhere (IDE, shell, CI).
  4. Seed a `fixtures/` subdirectory if the suite uses fixture files. Document the fixture shape in a local README.
  5. If the suite has less than one week of use, do not extract shared helpers yet. Let two suites emerge before refactoring.
- **Promoting a suite:** when a check in one suite becomes valuable for a different subject, move the check into its own suite rather than coupling two subjects. A suite that verifies two unrelated things becomes unownable.
- **Retiring a suite:** when the feature it covered is deleted or absorbed, delete the suite. Do not leave green tests for dead code -- they rot into false confidence.
- **Shared helpers:** extract a helper (a bash function library, a Python module, a `tests/_lib/` directory) only after two concrete suites would use it. Never in anticipation. The cost of premature abstraction here is higher than duplication: harnesses are small, and a shared helper that changes once breaks every suite that uses it.

## Common Mistakes

- Writing the harness before the feature doc exists. You end up with a script whose coverage promise is "whatever the author remembered the day they wrote it." Re-reads will not tell you what it was supposed to prove.
- Putting tests at the repo root alongside production code (e.g., `run-tests.sh`, `check-config.sh`) because "it's just one script." The moment a second test lands, the root clutters. Start in `tests/<suite>/` from the first suite.
- Mirroring the source tree inside `tests/` (e.g., `tests/src/module/foo.test.ts`). This creates churn every time source moves. Organize by subject (what is being verified) instead: `tests/<suite-name>/`.
- Writing tests that require network access, a specific local service to be running, or real filesystem state outside the repo. Those are integration probes or smoke tests; they belong in a separately named directory (`probes/`, `smoke/`) with a clear README calling out the external dependencies.
- Skipping OS parity for cross-OS code. A `.sh`-only harness on a repo whose subject runs on Windows means the Windows users have no way to verify correctness locally. If the thing being tested has a parity invariant, the harness must match.
- Importing one suite's fixtures into another. Fixtures belong to their suite. If two suites need the same input, duplicate it and accept that one may drift -- the coupling cost is worse than the duplication cost.
