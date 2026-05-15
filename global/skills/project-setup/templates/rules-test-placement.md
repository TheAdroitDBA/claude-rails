# Test Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where tests live and how they are organized, NOT how they are written.

## Invariants

- Tests live at `<project>/tests/<suite>/`. One directory per suite. A suite is a cohesive group of checks that verify one subject.
- Every suite has a colocated `*.feature.md` with numbered Success Criteria, a `## Status` block, and a `### Progress` checklist.
- **Tests are features.** A test suite is a unit of work owned like any other. No "just a quick test" exemption from the feature doc.
- Suite filenames match the suite subject, not the thing being tested (`tests/shortcuts/shortcuts.sh`, not `tests/shortcuts/shorthand-expand.test.sh`).
- **No runner, assertion library, or framework is prescribed by this rule.** The project keeps its own established test tools. The rule governs layout and documentation, not execution.
- **No network I/O. No git operations against the host repo.** Scratch git repos inside the OS temp dir are OK when simulating project context. **No persistent writes outside the repo**; ephemeral scratch state under `$TMPDIR` / `%TEMP%` is OK if the suite cleans it up on exit.
- Cross-OS parity: if the subject runs on multiple OSes, the harness does too. Single-OS subjects can have a single-OS harness.

## How to Apply

- Scaffold `tests/<suite>/<suite>.feature.md` first. Approve criteria before writing the harness.
- Resolve the repo root from the suite's own file location, never from a hardcoded path or CWD.
- Extract a shared helper only after two concrete suites would use it. Never in anticipation.
- Retire a suite when the feature it covered is deleted. Do not leave green tests for dead code.

## Common Mistakes

- Writing the harness before the feature doc exists.
- Putting tests at the repo root "just this once" -- the moment a second suite lands, root clutters.
- Mirroring the source tree inside `tests/` -- organize by subject, not by file path.
- Tests that require network access, a running service, or filesystem state outside the repo. Those are integration probes; put them in `probes/` or `smoke/` with a README calling out the external dependencies.
- Skipping OS parity for cross-OS code.
- Importing one suite's fixtures into another -- duplicate instead; coupling cost is worse than duplication cost.
