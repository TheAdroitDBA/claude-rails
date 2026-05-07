# Claude Rails

## Purpose

Claude-rails is a portable framework that eliminates three recurring problems when working across multiple projects with Claude Code:

1. **Token waste.** Every fresh session re-reads source code to rediscover context that could have been captured in a doc. On large codebases, thousands of tokens burn before any real work begins.
2. **Repetitive tasks.** The same setup, orient, and workflow instructions get re-explained every session. Hooks and slash commands should own the repetition.
3. **Inconsistent project shape.** Jumping between projects that each lay themselves out differently costs tokens just finding where things live. One framework applied everywhere means the same conventions, the same doc patterns, the same skills available in every repo.

## How It Works

Claude-rails solves these problems with five mechanisms:

- **Feature docs next to code** -- a `*.feature.md` file sitting next to the code it describes lets Claude load context via path proximity instead of scanning a global doc index.
- **Flow docs at entry points** -- a `*.flow.md` file next to a workflow's entry-point file traces the multi-file path so Claude reads one doc instead of N source files.
- **Token hierarchy** -- a strict read order (rules -> sibling docs -> memory -> source) keeps Claude out of source code until necessary.
- **Enforcement hooks** -- opt-in hooks block edits to code that has no feature doc, forcing "what does correct look like?" before every change.
- **Slash commands** -- single-character shortcuts (`/n`, `/f`, `/b`, `/t`, `/w`) prevent re-explaining workflows every session.
- **Domain-expert skills** -- portable architectural guidance (software architecture, security, testing, infrastructure) available in every session regardless of which repo you are in.

## Quick Start

### Prerequisites

- **Claude Code** installed and working (`claude --version` to verify). Install from https://claude.com/claude-code if needed.
- **Git** installed (`git --version` to verify).

### Step 1: Clone the repo (one-time)

Clone to wherever you keep repos on that machine. Substitute your actual path in all later steps.

```bash
# Mac
git clone https://github.com/TheAdroitDBA/claude-rails.git ~/claude-rails

# Linux
git clone https://github.com/TheAdroitDBA/claude-rails.git /code/claude-rails
```

```powershell
# Windows PowerShell
git clone https://github.com/TheAdroitDBA/claude-rails.git C:\Code\claude-rails
```

### Step 2: Link slash commands (one-time per machine)

This creates a symlink/junction so `~/.claude/commands/` points at `claude-rails/commands/`. Edits to the repo are instantly live in every session -- no re-run needed.

```bash
# Mac
bash ~/claude-rails/link-commands.sh

# Linux
bash /code/claude-rails/link-commands.sh
```

```powershell
# Windows PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Code\claude-rails\link-commands.ps1
```

The script prints a verification summary listing every `/` command it found.

### Step 3: Register the plugin (one-time)

Add claude-rails as a local plugin source in your user settings so it loads automatically in every session. Add this to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-rails": {
      "source": {
        "source": "directory",
        "path": "/path/to/claude-rails"
      }
    }
  },
  "enabledPlugins": {
    "claude-rails@claude-rails": true
  }
}
```

Replace `/path/to/claude-rails` with your actual clone path (e.g. `~/claude-rails` on Mac, `/code/claude-rails` on Linux, `C:\\Code\\claude-rails` on Windows -- note the double backslashes in JSON).

**Testing only**: to try the plugin without committing it to your settings, pass `--plugin-dir` on a single launch:

```bash
claude --plugin-dir ~/claude-rails
```

This is useful for testing a branch or validating a change before updating settings.

### Step 4: Verify

Start Claude Code in any repo and confirm:

- `/w` responds (slash commands are linked)
- `/project-setup` is available (plugin is loaded)
- `/software-architect` is available (domain-expert skills are discovered)

If any of these fail, check that Step 2 completed (symlink exists at `~/.claude/commands/`) and that Step 3 points at the correct path.

## Setting Up a New Repo

For a brand-new project that has no Claude Code structure yet:

1. Start Claude Code (the plugin loads automatically via `settings.json`).
2. Run `/project-setup` inside the repo. It will:
   - Audit the repo against five orientation questions (where am I, what's in flight, what's broken, what does done mean, how do pipelines work).
   - Scaffold `CLAUDE.md` with token hierarchy, build commands, and enforcement instructions.
   - Scaffold `README.md` with a troubleshooting runbook.
   - Create `MEMORY.md` as the project's canonical context file.
   - Create enforcement markers (`.claude/feature-doc-required`, `.claude/feature-doc-mode`).
   - Generate starter rules in `.claude/rules/` appropriate to the project's stack.
   - Create README files in `.claude/agents/`, `.claude/hooks/`, `.claude/skills/` explaining where project-specific extensions go.
3. Write your first feature doc: create a `<name>.feature.md` next to the code it describes, with numbered success criteria and a `## Status` line.
4. Set the current feature: `echo "<name>" > .claude/current-feature`.

Enforcement starts in `warn` mode by default. Switch to `block` in `.claude/feature-doc-mode` once the team is comfortable.

## Setting Up an Existing Repo

For a project that already has code, docs, or a previous Claude Code setup:

1. Start Claude Code (the plugin loads automatically via `settings.json`).
2. Run `/project-setup` inside the repo. It is idempotent -- safe to re-run. It will:
   - Read existing `CLAUDE.md`, `README.md`, and `MEMORY.md` before asking questions, so it does not re-ask what it can already see.
   - Audit all five orientation questions and report PASS / WEAK / FAIL for each.
   - Detect legacy layouts (`docs/features/`, `docs/flows/`) and propose migrations to colocated positions (`*.feature.md` next to code) using `git mv` to preserve history.
   - Detect misplaced framework docs (files that look like feature or flow docs but sit in the wrong location) and propose moves.
   - Detect stale scaffolded artifacts from older framework versions and propose cleanup.
   - Present all proposed changes grouped by which orientation question they close. Nothing executes until you approve.
3. Review the migration plan. You can approve all, pick by number, or skip.
4. After approval, `/project-setup` executes migrations, rewrites references in docs (never in source code), and re-runs the audit to confirm everything is PASS.
5. If you have existing feature docs without `## Status` or numbered criteria, add those sections incrementally. The framework enforces going forward, not retroactively.

### Enforcement hooks

Enforcement hooks ship with the plugin and auto-wire when it loads. They use prompt-type handlers (Claude evaluates the enforcement logic directly), so they work identically on Mac, Windows, and Linux.

The hooks are globally active but only enforce in repos that have opted in. When `/project-setup` creates the `.claude/feature-doc-required` marker, that repo comes under enforcement. Repos without the marker are unaffected.

## What Ships

### Slash Commands

| Command | Purpose |
|---------|---------|
| `/n` | Start a new feature. Creates feature doc with criteria before any code |
| `/f` | Finalize current work. Updates progress, marks complete, reports status |
| `/fs` | Feature success -- full completion pipeline (QA, UX review, cleanup, commit) |
| `/t` | Troubleshoot an error or bug |
| `/b` | Record a bug without investigating it (context capture at peak freshness) |
| `/bs` | Bug success -- cleanup and commit after a bug fix is verified |
| `/w` | What's next -- check open issues and tech debt |
| `/r` | Review recently changed code for quality and reuse |
| `/e` | Fetch and display unresolved errors from the project's error source |
| `/i` | Capture an idea before it is lost |

### Framework Skills

| Skill | Purpose |
|-------|---------|
| `/project-setup` | Scaffold or audit a repo's Claude Code structure |
| `/docs-audit` | Audit docs for staleness, duplication, broken references |
| `/discovery-check` | Verify a repo's orientation cost is under budget |
| `/startup-audit` | Audit application startup performance |
| `/hook-health` | Verify enforcement hooks are wired correctly |
| `/troubleshoot` | Expert error troubleshooting |

### Domain-Expert Skills

| Skill | Purpose |
|-------|---------|
| `/software-architect` | Clean Architecture, SOLID, dependency direction, API contracts |
| `/security-expert` | Data classification, auth patterns, OWASP, secrets management |
| `/testing-expert` | Test pyramid, mock discipline, coverage philosophy |
| `/systems-expert` | Deployment, CI/CD, networking, monitoring, backups |

### Agents

| Agent | Purpose |
|-------|---------|
| `qa-tester` | Verifies feature success criteria against actual code |
| `ux-reviewer` | Reviews features from end-user perspective for friction |

## Key Terms

| Term | Means |
|------|-------|
| **feature doc** | `*.feature.md` colocated next to the code it describes. Numbered success criteria, status line, progress checklist |
| **flow doc** | `*.flow.md` colocated next to a workflow's entry-point file. Step table and failure modes |
| **token hierarchy** | Read order: rules -> sibling docs (feature/flow) -> memory -> source. Stop when you have enough context |
| **enforcement scope** | The directory tree controlled by a `.claude/feature-doc-required` marker file |
| **feature scope** | Which files a feature doc covers, determined by its `## Scope` globs or directory position |
| **enforcement mode** | Value in `.claude/feature-doc-mode`: `off`, `warn`, or `block` (default: `block`) |
| **marker file** | `.claude/feature-doc-required` -- empty file that opts a directory tree into enforcement |

## Repo Structure

```
claude-rails/
  .claude-plugin/             Plugin manifest (loaded via --plugin-dir)
    plugin.json
  commands/                   Slash command source files (linked to ~/.claude/commands)
  conventions/                Stack-agnostic principles
  decisions/                  Architecture decision records
  rules/                     Framework invariant rules (claude-rails' own discipline)
  global/                    Global pool: discovered by the plugin
    skills/                  Framework + domain-expert skills
    agents/                  Global agents
    hooks/                   hook-lifecycle.flow.md (hook definitions in .claude-plugin/hooks/hooks.json)
  link-commands.sh           One-time symlink setup (Mac/Linux)
  link-commands.ps1          One-time junction setup (Windows)
```
