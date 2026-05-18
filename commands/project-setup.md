---
description: Set up or audit a project's Claude Code enforcement structure (CLAUDE.md, hooks, skills, agents, rules, feature docs). Actively migrates legacy docs/features/ and docs/flows/ into colocated positions. Idempotent -- safe to re-run on new or existing projects.
---

# Project Setup

## Purpose

claude-rails exists to **reduce the feeling of being lost** -- for Claude on session start, and for the user when they open the repo cold. Every piece of the framework (CLAUDE.md, rules, memory, feature docs, flow docs, enforcement markers, README runbook) is there to answer one of five orientation questions:

1. **Where am I?** -- what does this repo do, what stack, what are the commands
2. **What's in flight?** -- what is the current session supposed to be working on
3. **What's broken?** -- what known issues should a session not rediscover
4. **What does "done" mean here?** -- where are the testable success criteria
5. **How does this pipeline work without reading all the source?** -- where are the flow docs

A file that exists but is not discoverable from the repo root does not count. A feature doc with no Status line does not answer question 2. A CLAUDE.md with no token hierarchy does not answer question 1. The audit below evaluates each question and reports the gaps that cause lostness -- not the slots that happen to be empty.

On top of the orientation audit, this skill **actively migrates** legacy `docs/features/` and `docs/flows/` layouts into the colocated convention (`*.feature.md` / `*.flow.md` next to code). It also **sweeps** for misplaced framework docs (files that look like feature or flow docs but sit in wrong locations) and proposes moves. All migrations preserve git history via `git mv`; nothing is deleted.

The steps below are the procedural form of that pipeline.

## Do not

- Do not run `ls` as the primary audit. `ls` tells you what exists; it does not tell you whether a cold session can orient. Read content.
- Do not scaffold files just because a slot is empty. Every proposed file must answer one of the five orientation questions, and the proposal must say which one.
- Do not silently guess what is in flight. Ask the user if the repo has no anchor.
- Do not `rm` legacy docs. Every migration uses `git mv`. History must be preserved.
- Do not overwrite existing content on collision. Merge interactively, asking the user which version is authoritative per conflicting section.
- Do not edit `.claude/settings.json` directly. If hook wiring is needed, print the lines and ask the user to add them.

## Step 1: Identify project and load existing state

```bash
git rev-parse --show-toplevel
```

Store as PROJECT_ROOT. Before asking any questions, read what already exists so you do not re-ask known information:

- `CLAUDE.md` if present
- `.claude/current-feature` if present
- `MEMORY.md` at repo root, `memory/MEMORY.md`, or `.claude/memory/MEMORY.md` if present (all three are valid locations; some repos put MEMORY.md at root so CLAUDE.md can point at it directly)
- `README.md` if present
- Top-level directory listing (one level) to see which layout conventions the repo uses

## Step 2: Orientation audit

Answer each of the five orientation questions by **reading content**, not checking existence. Produce one finding per question: PASS, WEAK, or FAIL, with the specific reason.

### Q1: Where am I?

- Is there a CLAUDE.md (or README.md) at the repo root?
- Does it state what the project does in 1-2 sentences?
- Does it list build and test commands?
- Does it reference a token optimization order or reading hierarchy?

A CLAUDE.md that exists but has no token hierarchy is WEAK, not PASS. A repo with no root-level entry point file is FAIL.

### Q2: What's in flight?

- Does `.claude/current-feature` exist?
- If so, does it point at a real feature doc (`<slug>.feature.md`)?
- Does that feature doc have a Status line and a Progress checklist?

No anchor file is FAIL. Anchor pointing at a non-existent or stale doc is FAIL. Anchor pointing at a doc with no Status is WEAK.

If FAIL, check recent git log (`git log --oneline -10`) for clues about what is actually in flight, and ask the user to confirm before writing the anchor.

### Q3: What's broken?

- Is there a known-issues tracker? Possible locations: `memory/KNOWN-ISSUES.md`, `.claude/memory/<project>-issues.md`, `docs/ISSUES.md`, or another project-specific file referenced from CLAUDE.md.
- Is it discoverable from the repo root (mentioned in CLAUDE.md or README)?
- Does it have entries dated within the last ~90 days, or a "last updated" marker? A tracker full of FIXED entries from a year ago is WEAK -- it has decayed into noise.

Missing is FAIL. Existing but undiscoverable is WEAK. Existing but stale is WEAK.

### Q4: What does "done" mean here?

- Are there feature docs? Scan colocated `*.feature.md` anywhere in the repo.
- Spot-check 3 feature docs (or all of them if fewer than 3). Each should have:
  - Numbered success criteria (not prose paragraphs)
  - A Status line (NOT STARTED / IN PROGRESS / COMPLETE / PARKED)
  - A Files or Scope section pointing at the code it owns

Zero feature docs in a repo with >20 source files is FAIL. Feature docs that exist but have no numbered criteria is WEAK. Feature docs that exist but have no Status is WEAK.

### Q5: How does this pipeline work?

- Are there flow docs? Scan colocated `*.flow.md` anywhere in the repo.
- Does the repo have pipelines complex enough to warrant them (build system, rendering pipeline, auth flow, data ingestion)? If yes and there are zero flow docs, that is a WEAK finding -- a session will have to read full source to trace anything.

A small CRUD app with no flow docs is PASS. A 50k-line app with Metal rendering, auth, and data sync and zero flow docs is FAIL.

### Q6: Do existing feature docs honor the framework conventions?

- Read `conventions/feature-conventions.md` from the claude-rails plugin directory.
- Spot-check up to 5 existing `*.feature.md` files in the repo. For
  each, flag any obvious convention violation: persistence that
  bypasses a Store seam (raw SQL or file paths in UI/notification
  code), web services without `/health` + metrics + DNS + proxy +
  backup, shared venvs, hardcoded secrets, silent-zero failure modes.
- For each violation, check whether the feature doc declares a
  matching `## Deviation from conventions` entry. An undeclared
  violation is a WEAK finding; a malformed deviation (missing the
  `convention-name: rationale` colon) is a FAIL.
- Zero feature docs OR zero violations = PASS. First-time adoption
  repos with no `## Deviation` sections anywhere are expected; conventions
  apply going forward, not retroactively (see
  `conventions/feature-conventions.md` conventions). Do not rewrite
  existing docs during audit; report the gap and move on.

### Mechanical existence check (secondary)

After the content audit, run a quick existence pass as a secondary check:

```bash
echo "=== Existence check (secondary) ==="
[ -f CLAUDE.md ] && echo "CLAUDE.md: yes" || echo "CLAUDE.md: NO"
[ -f README.md ] && echo "README.md: yes" || echo "README.md: NO"
[ -d .claude/rules ] && echo ".claude/rules/: yes ($(ls .claude/rules 2>/dev/null | wc -l | tr -d ' ') files)" || echo ".claude/rules/: NO"
[ -d .claude/agents ] && echo ".claude/agents/: yes ($(ls .claude/agents 2>/dev/null | wc -l | tr -d ' ') files)" || echo ".claude/agents/: NO"
[ -d .claude/hooks ] && echo ".claude/hooks/: yes ($(ls .claude/hooks 2>/dev/null | wc -l | tr -d ' ') files)" || echo ".claude/hooks/: NO"
[ -d .claude/skills ] && echo ".claude/skills/: yes ($(ls .claude/skills 2>/dev/null | wc -l | tr -d ' ') files)" || echo ".claude/skills/: NO"
[ -f .claude/current-feature ] && echo ".claude/current-feature: $(tail -n 1 .claude/current-feature) (stack depth $(grep -c . .claude/current-feature))" || echo ".claude/current-feature: NO"
[ -f .claude/feature-doc-required ] && echo ".claude/feature-doc-required: yes" || echo ".claude/feature-doc-required: NO"
[ -f .claude/feature-doc-mode ] && echo ".claude/feature-doc-mode: $(cat .claude/feature-doc-mode)" || echo ".claude/feature-doc-mode: NO"
grep -q "Plugin Enforcement" CLAUDE.md 2>/dev/null && echo "enforcement instructions: present" || echo "enforcement instructions: MISSING -- /project-setup will add them"

[ -f docs.export.yml ] && echo "docs.export.yml: yes" || echo "docs.export.yml: NO"

if find . -name '*.py' -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' -print -quit | grep -q .; then
  echo "--- Python project detected ---"
  [ -f requirements.txt ] && echo "requirements.txt: yes" || echo "requirements.txt: NO"
  [ -d .venv ] && echo ".venv/: yes" || echo ".venv/: NO"
fi
```

## Step 3: Detect legacy layout and misplaced framework docs

This step makes the skill a compliance enforcer, not just an auditor.

### 3a: Legacy directories

```bash
echo "=== Legacy directories ==="
if [ -d docs/features ]; then
  echo "docs/features/:"
  ls docs/features/*.md 2>/dev/null | grep -vE '(README|TEMPLATE)' | sed 's/^/  /'
fi
if [ -d docs/flows ]; then
  echo "docs/flows/:"
  ls docs/flows/*.md 2>/dev/null | sed 's/^/  /'
fi
```

Every file in `docs/features/` or `docs/flows/` (excluding `README.md` and `TEMPLATE.md`) is a **migration candidate** -- it must be moved to colocated position in Step 7.

### 3b: Misplaced framework docs

Framework docs are `.md` files containing a Success Criteria header (feature-doc signature) or a step-table header (flow-doc signature) that sit somewhere other than colocated with their code:

```bash
echo "=== Misplaced framework docs ==="
find . -name "*.md" \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -not -path "./vendor/*" \
  -not -path "./.build/*" \
  -not -path "*/\.claude/*" \
  2>/dev/null | while read f; do
    base=$(basename "$f")
    # Skip non-framework files
    case "$base" in
      CLAUDE.md|README.md|CHANGELOG.md|LICENSE.md|MEMORY.md) continue ;;
      *.feature.md|*.flow.md) continue ;;
      # Templates and SKILL.md files contain EMBEDDED framework-doc examples, not actual framework docs
      *.template.md|SKILL.md|TEMPLATE.md) continue ;;
    esac
    case "$f" in
      */docs/features/*|*/docs/flows/*) continue ;;
    esac
    if grep -qi "^## Success Criteria" "$f" 2>/dev/null; then
      echo "FEATURE-LIKE: $f"
    fi
    if grep -qi "^## Steps\b\|^## Step Table\b\|^## Entry Point\b" "$f" 2>/dev/null; then
      echo "FLOW-LIKE: $f"
    fi
done
```

Exclusions explained:
- `.template.md` files ship embedded structure on purpose.
- `SKILL.md` files often contain multi-line code-fenced examples of feature docs, including `## Success Criteria` headers inside the fences -- these are not actual feature docs and must not be misread as such.
- `MEMORY.md` at repo root is a valid location for the project memory index; it is not a feature doc.
- Files in directories explicitly excluded by the sweep (`.git`, `node_modules`, `vendor`, `.build`) are skipped.

### 3c: Compute migration targets

For each migration candidate (legacy or misplaced):

1. Read the doc's `## Files` section and `## Scope` section if present.
2. The first file listed in `## Files` is the primary code. The colocated target becomes `<dir-of-primary-code>/<slug>.feature.md` (or `.flow.md`).
3. If `## Files` is absent or empty, try to infer the primary code from the doc's name (`login.md` -> search for `login.*` source files in the repo).
4. If primary code cannot be determined: mark as **unresolved**. Do not migrate. Report to user in Step 5.

### 3d: Detect duplicates

If two or more sources compute to the same colocated target basename: mark as **duplicate**. Example: `docs/features/login.md` and `docs/features/user-login.md` both target `src/auth/login.feature.md`. Duplicate halts that specific migration until resolved by user in Step 5.

### 3e: Detect collisions

If a proposed target already exists in the repo (e.g., someone partially migrated manually): mark as **collision**. Collisions do not halt -- they trigger merge-on-collision in Step 7.

### 3f: Detect stale scaffolded artifacts

Older versions of `/project-setup` copied framework invariant rules into adopted repos (`agent-placement.md`, `skill-placement.md`, `hook-placement.md`). Under the current design these are NOT distributed -- they describe claude-rails's own discipline. If any are found, list as **stale scaffold**, propose removal in Step 5, execute in Step 7.

```bash
echo "=== Stale scaffolded artifacts ==="
for f in .claude/rules/agent-placement.md .claude/rules/skill-placement.md .claude/rules/hook-placement.md; do
  [ -f "$f" ] && echo "STALE: $f (copy of a framework invariant rule; no longer distributed)"
done
```

A per-version migration catalog may replace this hardcoded list in a future framework version.

## Step 4: Ask only the questions content does not answer

After Steps 2 and 3, you should know most of what you need. Only ask the user for things content did not answer. Skip everything CLAUDE.md or recent commits already tell you.

Common residual questions:
1. If Q2 failed and git log is ambiguous: "What feature is in flight right now, if any?"
2. If CLAUDE.md is missing and you cannot infer stack from files: "What's the primary stack?"
3. If CLAUDE.md is missing and you cannot infer build command: "What's the build command?"
4. If the user has strong preferences not yet captured: "Any preferences I should bake in (emoji policy, commit style, logging)?"
5. If Step 3d found duplicates: "These two docs both target `<target>`. Which is authoritative? (1 / 2 / both-merged / skip)"
6. If Step 3c found unresolved targets: "This doc has no primary code reference. Provide a target path or skip?"

Wait for answers before scaffolding or migrating anything.

## Step 5: Present findings and migration plan

Present the audit as five lines, one per orientation question, each labeled PASS / WEAK / FAIL. Then list proposed changes grouped by which question each change closes, followed by a migration section if Step 3 found anything.

Example output shape:

```
=== Orientation Audit ===
Q1 Where am I?              PASS   CLAUDE.md has token hierarchy and build commands
Q2 What's in flight?        FAIL   No .claude/current-feature anchor
Q3 What's broken?           WEAK   memory/KNOWN-ISSUES.md exists but not mentioned in README
Q4 What does done mean?     PASS   39 colocated *.feature.md files, all have Status and criteria
Q5 How do pipelines work?   PASS   6 colocated *.flow.md files cover the major pipelines
Q6 Honor conventions?       PASS   No visible convention violations; 1 deviation declared with rationale

=== Proposed scaffolding ===
Close Q2 (What's in flight?):
  1. Create .claude/current-feature pointing at <slug>  (asks user first)

Close Q3 (What's broken?):
  2. Update README.md "Start here" section to reference memory/KNOWN-ISSUES.md

Optional (enforcement):
  3. Create .claude/hooks/ with README pointing at hook-placement.md
  4. Create .claude/skills/ with README pointing at skill-placement.md
  5. Copy rules templates (agent-placement, skill-placement, hook-placement) into .claude/rules/

=== Migrations (legacy -> colocated) ===
docs/features/login.md           -> src/auth/login.feature.md           (clean move)
docs/features/billing.md         -> src/billing/billing.feature.md      (MERGE: target exists, 2 divergent criteria)
docs/flows/checkout.md           -> src/checkout/checkout.flow.md       (clean move)

=== Misplaced framework docs ===
memory/auth-spec.md              -> src/auth/auth.feature.md             (clean move)

=== Duplicates requiring user input ===
docs/features/user-onboarding.md AND docs/features/onboarding-flow.md
  both target src/users/onboarding.feature.md.

=== Unresolved targets ===
docs/features/deployment-pipeline.md -- no matching code file found.
  (skill will skip; user resolves manually)

Which of these should I execute? (all / pick by number / skip)
```

Every proposed scaffolding change names the question it closes. Migrations are shown separately so the user can approve scaffolding and migrations independently.

## Step 6: Create only what was approved (scaffolding)

All creation is idempotent. Never overwrite existing files. For each approved change, load the relevant template from the framework's `templates/project-setup/` directory and customize it as described below.

### 6a: Directories

```bash
mkdir -p .claude/rules .claude/agents .claude/hooks .claude/skills
```

Only create `memory/` if the project does not already use `.claude/memory/` for the same purpose. Do not create `docs/features/` or `docs/flows/` -- feature and flow docs are colocated next to the code they describe.

**Exception: the framework repo itself.** If `PROJECT_ROOT` contains a `.claude-plugin/plugin.json` with `"name": "claude-rails"`, skip `.claude/agents/`, `.claude/hooks/`, and `.claude/skills/`. Claude-rails IS the global pool -- it has nothing to layer on top of itself. Only `.claude/rules/` is valid in claude-rails. This rule does NOT apply to any other repo.

### 6b: Enforcement markers (only if missing)

```bash
[ -f .claude/feature-doc-required ] || : > .claude/feature-doc-required
[ -f .claude/feature-doc-mode ] || printf 'warn' > .claude/feature-doc-mode
```

Default is `warn`, not `block`. Never loosen an existing mode without asking.

**Also write `.claude/rails-version`** (only if missing). Read the framework's `VERSION` file (parent of this skill's `commands/` directory) and write `v<contents>` to `.claude/rails-version` as a single line, LF-terminated. Example: framework `VERSION` reads `0.1.0` -> file contents become `v0.1.0\n`.

`.claude/feature-doc-required` stays presence-only (its content is still ignored). `.claude/rails-version` is a separate, single-responsibility companion -- the repo's install fingerprint. Existing repos with `feature-doc-required` but no `rails-version` are valid -- `/w` and `/rails-sync` handle that "opted in at unknown version" case explicitly.

### 6c: CLAUDE.md (create or reconcile)

**If missing:** read the framework's `templates/project-setup/claude-md.md` and customize the placeholders before writing:
- `[Project Name]`: repo name from git
- `[user's build command]`, `[user's test command]`: from Step 4 answers
- `[actual path to issue tracker]`: from Q3 audit result
- `[Stack-specific: ...]`: replace with the project's actual conventions

If Python detected: include the `## Python environment` section from the template (marked with `<!-- PYTHON: ... -->`). Remove the comment line itself before writing the file.

**If already exists (re-run / reconcile):** check for the `## Plugin Enforcement` section. If absent, append the section verbatim from the template. If present, compare to the template version and offer to update if different. This is the idempotency guarantee: re-running `/project-setup` always brings enforcement instructions up to date without touching the rest of the file.

### 6d: README.md with "Start here" and Troubleshooting runbook (only if missing)

Read the framework's `templates/project-setup/readme.md` and customize:
- `[Project Name]`: repo name
- `[One-line description...]`: one sentence from CLAUDE.md or user input
- `[actual path to issue tracker]`: from Q3 audit result

If README already contains a `## Troubleshooting a Feature` section, leave it alone.

### 6e: .claude/current-feature (only if missing, and only with confirmation)

Never guess. Ask the user. If they confirm a slug, write it as the first line of the stack (the file is a LIFO stack -- one slug per line, last line is active):

```bash
printf '%s\n' '<slug>' > .claude/current-feature
```

### 6f: MEMORY.md (only if missing AND the repo has no MEMORY.md in any valid location)

Valid locations (in order of preference): `<root>/MEMORY.md`, `<root>/memory/MEMORY.md`, `<root>/.claude/memory/MEMORY.md`. Scaffold at `memory/MEMORY.md` by default. Only choose root-level if the repo's CLAUDE.md explicitly points at root MEMORY.md.

Read the framework's `templates/project-setup/memory.md` and customize:
- `[Project Name]`: repo name
- `[path to issue tracker]`: from Q3 audit result

### 6g: Feature doc template

Read the canonical feature doc template from the framework's `templates/project-setup/` directory. Store at `memory/FEATURE-TEMPLATE.md` (or `.claude/memory/FEATURE-TEMPLATE.md` if the repo uses that layout). Copy as-is -- the placeholders are meant for the project team to fill in when creating feature docs.

### 6h: Known issues tracker (only if Q3 was FAIL AND the repo has no existing tracker)

If the repo already has a tracker at a non-standard path, do NOT create a parallel `memory/KNOWN-ISSUES.md`. Instead, close Q3 by pointing at the existing file from CLAUDE.md and README.

If there is no tracker at all: read the framework's `templates/project-setup/known-issues.md` and write to `memory/KNOWN-ISSUES.md` as-is. ALSO create an empty `memory/BUG-INDEX.md` with the two-heading shape (no entries):

```
# Bug Index

## Active

## Recently Resolved (last 10)
```

This pairs the sectioned tracker with its INDEX from day one. If the repo already has `memory/KNOWN-ISSUES.md` in flat shape (no `### <area>` subsections in `## Active`), recommend running `/migrate-bugs` to convert it -- do NOT auto-convert during `/project-setup`.

### 6i: Rules templates (in .claude/rules/, only if approved)

Framework invariants (where agents/skills/hooks live across the two pools) are captured inline in the scaffolded CLAUDE.md (see Step 6c). Adopted repos do NOT get copies of `agent-placement.md`, `skill-placement.md`, or `hook-placement.md` -- those describe claude-rails's own discipline, not a per-project convention.

**Domain rule templates** -- when approved, read the sidecar and write to `<project>/.claude/rules/<name>.md` (skip if destination already exists):
- `error-ux.md`: read the framework's `templates/project-setup/rules-error-ux.md`
- `data-integrity.md`: read the framework's `templates/project-setup/rules-data-integrity.md`
- `test-placement.md`: read the framework's `templates/project-setup/rules-test-placement.md`

**Universal rules** (always suggest; generate from the framework's `templates/project-setup/rules-shape.md`):
- `feature-criteria.md` -- 5 litmus tests for valid success criteria (Rename, Outsider, Rewrite, Negation, Stability)
- `flow-docs.md` -- one pipeline per doc; features reference flows, not the reverse

**Stack-specific rules** (generate from `rules-shape.md`, sized ~20 lines each):
- iOS/Swift: `codable-safety.md`, `metal-rendering.md`, `swiftui-state.md`
- Python/FastAPI: `python-environment.md` (read the framework's `templates/project-setup/rules-python-environment.md`), `models.md`, `routers.md`, `migrations.md`
- React/TypeScript: `components.md`, `state-management.md`, `api-layer.md`
- Go: `interfaces.md`, `errors.md`, `concurrency.md`
- Rust: `ownership.md`, `error-handling.md`, `modules.md`

### 6j: .claude/agents/ README

Scaffold `.claude/agents/README.md` if missing. Read the framework's `templates/project-setup/agents-readme.md` and write as-is. Do not scaffold any agent files.

### 6k: .claude/hooks/ README

Scaffold `.claude/hooks/README.md` if missing. Read the framework's `templates/project-setup/hooks-readme.md` and write as-is. Do not scaffold any hook scripts.

### 6l: .claude/skills/ README

Scaffold `.claude/skills/README.md` if missing. Read the framework's `templates/project-setup/skills-readme.md` and write as-is. Do not scaffold any skill files.

### 6m: docs.export.yml (only if missing)

If the repo has a `repo_url` (check `git remote get-url origin`): read the framework's `templates/project-setup/docs-export.yml`, substitute `[Project Name]` and `[origin URL]`, and write to `docs.export.yml`. Leave `nav:` as a stub.

### 6o: Managed-block emission (CLAUDE.md and README.md)

After 6c (CLAUDE.md) and 6d (README.md) are written or reconciled, emit the rails-managed block into each. The templates carry the block markers as placeholders (`<!-- claude-rails:start vPLACEHOLDER sha=PLACEHOLDER -->` ... `<!-- claude-rails:end -->`); this step fills them in with real values at write time.

For each of `CLAUDE.md` and `README.md`:

1. Find the start marker `<!-- claude-rails:start ` and end marker `<!-- claude-rails:end -->`. If neither is present, skip this file -- the user may have intentionally removed the block, do not re-inject.
2. Read the framework's `templates/managed-blocks/current.md` -> `CANONICAL_CONTENT` (the inner-block content).
3. Read the framework's `VERSION` -> `FRAMEWORK_VERSION` (e.g. `0.1.0`).
4. Normalize `CANONICAL_CONTENT` per criterion 3 of `rails-managed-blocks.feature.md`: LF line endings, strip trailing whitespace per line, no trailing newline. Compute SHA-256, take first 8 hex chars -> `EXPECTED_HASH`.
5. Replace the start marker line with: `<!-- claude-rails:start v<FRAMEWORK_VERSION> sha=<EXPECTED_HASH> -->`.
6. Replace the content between the markers with `CANONICAL_CONTENT`.
7. Leave everything outside the markers byte-for-byte unchanged.

Idempotent: re-running on a repo with the block already in place will replace the block with itself (if it matches the current canonical) or update it (if the framework version has moved since the last `/project-setup`). For non-trivial drift, prefer `/rails-sync` -- it has the per-file y/n/d/a confirmation flow. This step is for fresh scaffold; surface a hint after writing: `managed block written/refreshed in CLAUDE.md and README.md. Run /rails-sync on future version bumps.`

### 6n: Enforcement instructions (always reconcile)

Enforcement is distributed two ways: (1) the `## Plugin Enforcement` section in CLAUDE.md provides instruction-based enforcement, and (2) the claude-rails plugin's `hooks/hooks.json` provides prompt-type hooks that auto-wire on plugin load. Both layers work together. No per-project hook wiring or shell scripts are needed.

## Step 7: Execute migrations

Only runs if the user approved migrations in Step 5. The full move semantics, merge-on-collision rules, and reference rewrite patterns are documented in `project-setup.flow.md` (Migration Sub-Pipeline section). Summary:

**7a: Clean move.** `git mv "<legacy-path>" "<colocated-target-dir>/<slug>.feature.md"`. Create target directory first (`mkdir -p`). If `git mv` fails: report, skip that migration, continue. Never fall back to rm.

**7b: Merge on collision (target already exists).** Read both files. Sections that agree or where one is a strict superset: merge silently. Sections that diverge semantically (Success Criteria, Status, flow steps): ask the user which version is authoritative. Build merged content and execute `git mv <legacy> <legacy>.tmp && write-merged-to <target> && git rm <legacy>.tmp`.

**7c: Rewrite references.** After all moves, grep CLAUDE.md, README.md, sibling `*.feature.md` / `*.flow.md`, memory files, and rules files for old paths; rewrite each hit. Never touch source code.

**7d: Cleanup.** Remove emptied `docs/features/`, `docs/flows/`, `docs/` directories. Remove stale scaffolded artifacts from Step 3f if user approved.

**7e: Report.** Print: Moved, Merged (sections interactively resolved), References rewritten in (with hit counts), Skipped (with reason), Emptied directories removed.

## Step 8: Verify

Re-run the orientation audit from Step 2. Every question that was WEAK or FAIL should now be PASS. If any is still not PASS, say so and explain why (e.g., "Q2 still WEAK -- user declined to set current-feature anchor").

Also re-run Step 3 (legacy detection + misplaced-doc sweep). It must report:
- Zero legacy files under `docs/features/` or `docs/flows/` (unless the user explicitly skipped them).
- Zero misplaced framework docs.

Any remaining items mean a migration did not complete cleanly -- list them explicitly.

## Step 9: Quick next steps

Read the framework's `templates/project-setup/quick-next-steps.md`. Substitute the real value of `.claude/feature-doc-mode` for `<enforcement-mode>`. Print the block.

## Reminders

- If CLAUDE.md was created: tell the user to add project-specific rules to it as they discover them.
- If rules were generated: they are starter templates -- refine as real invariants surface.
- If enforcement instructions are missing from CLAUDE.md: re-run `/project-setup` -- Step 6c reconciles them automatically.
- If migrations were skipped (unresolved targets, unresolved duplicates): the user resolves manually and re-runs `/project-setup`. The skill is idempotent; unfinished work stays on the proposal list.
- If project-specific hooks, skills, or agents already exist under `<project>/.claude/`: never overwrite them. The scaffolding only creates missing files.
- If a template is missing: ensure the claude-rails clone is intact and the plugin path is correct.
