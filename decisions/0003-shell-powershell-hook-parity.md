# 0003: Shell and PowerShell hook parity

## Status

ACCEPTED — 2026-04-21

## Context

Claude Code hooks execute as shell commands. The user base spans Windows, macOS, and Linux: on Windows the natural hook language is PowerShell; on macOS and Linux it is bash. A single implementation in one language would either (a) exclude half the user base, (b) require a cross-platform runtime like Node or Python as a hook dependency, or (c) force WSL adoption on Windows users who otherwise do not need it. None of those options are acceptable for a framework whose `sync` script must produce identical behavior on every machine that clones it.

## Decision

Every hook ships as two sibling files: `<name>.sh` and `<name>.ps1`. Both implementations share the same behavior, the same exit codes, the same stderr/stdout contracts, and the same side effects. The shell script and the PowerShell script are the same hook, not two hooks. `sync` copies both into `~/.claude/hooks/` and the OS-specific settings file wires the correct one into each hook event.

## Consequences

- Doubled maintenance: every hook change touches two files and must be tested on at least one machine of each family (or covered by a cross-OS parity test suite).
- Parity bugs are a known failure mode — the `tests/shortcuts/` suite exercises both implementations against a shared fixture set to catch divergence. New hooks get parity tests as a criterion, not an afterthought.
- Hook scripts stay simple. A hook that would require complex logic in both shells is a signal to extract the logic into a small CLI tool (Node, Python, Go) that both implementations invoke; the hook stays a thin wrapper. This has not been necessary yet but is the documented escape hatch.
- No runtime dependency beyond what each OS ships (bash on Unix, PowerShell on Windows). The framework installs nothing beyond its own files.
- New contributors must be comfortable editing both languages — a real friction point. Mitigated by the parity test suite (red tests = obvious divergence) and by keeping hook logic small.

## Alternatives Considered

- **Bash only + WSL on Windows** — rejected. WSL is an opt-in OS feature, not universal; forcing it excludes Windows-native users whose `cmd.exe` or `PowerShell.exe` shells are already configured.
- **PowerShell only (PowerShell Core is cross-platform)** — rejected. PowerShell Core is not pre-installed on macOS or most Linux distros, making `sync` require a package install step that is not idempotent and varies per distro.
- **Node.js or Python hooks** — rejected. Adds a runtime dependency the framework does not otherwise need, and hooks would become slow to spin up on every event.
- **Single language + wrapper shim per OS** — rejected. The wrapper shim would itself be in bash or PowerShell, returning the problem one level down.

## Affected Features

- framework-portability.feature.md
- rules/hook-placement.md
- global/hooks/** (every hook pair)
- global/hooks/hook-lifecycle.flow.md
- tests/shortcuts/shortcuts.feature.md (parity test suite)
- sync.flow.md (copies both script pairs)
- settings.windows.json / settings.mac.json / settings.linux.json (each wires the correct script)
