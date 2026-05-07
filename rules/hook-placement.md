# Hook Placement -- Rules Template

Copy this file into your project's `.claude/rules/` directory. Defines where hooks live, how Claude Code composes them, and how to avoid the most common trap: project-specific logic leaking into global hooks.

## Invariants

- Two pools exist: the **global pool** (prompt-type hooks in `claude-rails/.claude-plugin/hooks/hooks.json`, auto-wired by the plugin) and the **project-local pool** (hooks in `<project>/.claude/settings.json`). Both fire on the same Claude Code events. Project hooks **layer on top** of global hooks -- they do not replace them.
- Global hooks MUST have no project hardcodes. No references to specific project names, absolute paths, databases, or hostnames. A global hook's behavior depends only on: the file being edited, marker files in the current repo, and content of feature/flow docs in that repo.
- Project hooks are the right home for project-specific enforcement (Swift Codable safety, redraw-ordering anti-patterns, SQL migration guards, stack-specific conventions). They live in the project that cares about them.
- Use prompt-type handlers (`"type": "prompt"`) for enforcement logic that Claude can evaluate. Use command-type handlers (`"type": "command"`) only when you need to run external tools (formatters, linters, test runners).
- A hook exists in **exactly one pool**. Duplicating a hook into both pools guarantees it fires twice and drifts.

## How to Apply

- **Placement litmus test:** does the hook's logic depend on which project it is running in? If any decision references a specific project name, absolute path, or project-specific file structure -> project pool. If it works on any repo that has the appropriate marker file (e.g., `.claude/feature-doc-required`) -> global pool.
- **Promotion (project -> global):** rare. A project hook that becomes generic should be rewritten as a global hook in the plugin's `hooks/hooks.json` rather than moved, because the wiring conventions differ.
- **Demotion (global -> project):** when a global hook gains a project-specific condition, split it. Extract the project-specific logic into a new project hook in `<project>/.claude/settings.json`. Remove the condition from the global hook. The generic behavior stays global; the project behavior lives in the project.
- **Failure mode:** if a hook fails, Claude Code skips it and continues. Do not rely on hooks for correctness-critical enforcement; rely on them for guidance and optimization.

## Common Mistakes

- Adding a project-specific condition to a global hook to handle one project. The correct fix is to create a project hook.
- Writing a project hook that assumes the global hook will NOT fire for that event (trying to replace instead of layer). Claude Code fires both; project hook output does not cancel global hook output.
- Reading a specific project's skills, database files, or config from inside a global hook. If the hook needs project context, it should read the current repo's `.claude/` markers, not reach outside the repo.
- Invoking skills or agents from inside a hook. Hooks fire synchronously before/after tool calls; they are not an appropriate place to orchestrate multi-step work.
