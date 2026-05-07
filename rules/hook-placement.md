# Hook Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where hook scripts live, how Claude Code composes them, and how to avoid the most common dogfood trap: project-specific code leaking into global hooks.

## Invariants

- Two pools exist: the **global pool** at `~/.claude/hooks/` (symlinked from `claude-config/global/hooks/` by sync) + `~/.claude/settings.json` wiring, and the **project-local pool** at `<project>/.claude/hooks/` + `<project>/.claude/settings.json` wiring. Both are invoked on the same Claude Code events. Project hooks **layer on top** of global hooks -- they do not replace them.
- Global hooks MUST have no project hardcodes. No `case "$REPO_ROOT" in */SpecificProject)` branches. No absolute paths like `/Users/<name>/code/<project>/...`. No references to specific skills, databases, or hostnames. A global hook's behavior depends only on: the file being edited, marker files in the current repo, and content of feature/flow docs in that repo.
- Project hooks are the right home for project-specific enforcement (Swift Codable safety, redraw-ordering anti-patterns, SQL migration guards, stack-specific linters). They live in the project that cares about them.
- **Shell/PowerShell parity is required for global hooks.** A global hook without a `.ps1` companion breaks the cross-OS contract. Project hooks may be shell-only if the project only runs on one OS, but that is a tradeoff, not a default.
- Hook wiring is split. Global hooks are wired in `claude-config/settings.*.json`. Project hooks are wired in `<project>/.claude/settings.json`. Never mix: a global hook should never be listed only in a project's settings, and vice versa.
- A hook exists in **exactly one pool**. Duplicating a hook into both pools guarantees they fire twice and drift.

## How to Apply

- **Placement litmus test:** does the hook's logic depend on which project it is running in? Read the hook script. If any decision branches on a specific project name, absolute path, or project-specific file structure -> project pool. If it works on any repo that has the appropriate marker file (e.g., `.claude/feature-doc-required`) -> global pool.
- **Promotion (project -> global):** rare. A project hook that becomes generic probably should just be rewritten as a global hook rather than moved, because the wiring and conventions differ.
- **Demotion (global -> project):** common. When a global hook gains a project-specific branch, split it. Extract the project-specific logic into a new project hook at `<project>/.claude/hooks/<name>.sh` and wire it in the project's `.claude/settings.json`. Remove the branch from the global hook. The generic behavior stays global; the project behavior lives in the project.
- **Hook parity:** when writing a new global hook, write both `.sh` and `.ps1` in the same change. When modifying a global hook, modify both. The two must produce semantically equivalent output for the same input.
- **Failure mode:** if a hook fails (non-zero exit, malformed output), Claude Code skips it and continues. Do not rely on hooks for correctness-critical enforcement; rely on them for guidance and optimization.

## Common Mistakes

- Adding a `case "$REPO_ROOT" in */<ProjectName>)` branch to a global hook to handle one project. The correct fix is to move that branch into a project hook.
- Writing a global hook in bash only, with no PowerShell companion. Breaks on Windows.
- Writing a project hook that assumes the global hook will NOT fire for that event (trying to replace instead of layer). Claude Code fires both; project hook output does not cancel global hook output.
- Reading a specific project's skills, database files, or config from inside a global hook. If the hook needs project context, it should read the current repo's `.claude/` markers, not reach outside the repo.
- Invoking skills or agents from inside a hook. Hooks fire synchronously before/after tool calls; they are not an appropriate place to orchestrate multi-step work.
