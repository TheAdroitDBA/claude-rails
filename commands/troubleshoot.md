---
description: Expert error troubleshooting skill. Always moves forward. Never repeats failed attempts.
---

# Troubleshoot

Expert error troubleshooting skill. Always moves forward. Never repeats failed attempts.

## When to Use
Invoke via `/t` with or without a description.

## Discovering the Bug Tracker

Before any `/t` work, discover the adopted repo's bug tracker path. The path is NOT hardcoded -- it is declared by the repo.

1. Get the repo root: `git rev-parse --show-toplevel`
2. Look for a `bug-tracker:` or `issue-tracker:` declaration in the repo's `CLAUDE.md`, or a `## Bug Tracker` / `## Issue Tracker` section that names a file path.
3. If not found, check `memory/MEMORY.md` for the same declaration.
4. If still not found, STOP and emit this error:
   > No bug tracker declared for this repo. Run `/project-setup` to scaffold one (it adds a `bug-tracker:` line to CLAUDE.md pointing at `memory/<repo>-issues.md`). Until then, `/t` cannot run.

The declared path is relative to the repo root. Read it for bug entries; write new entries to it.

## Bare `/t` -- Show Bug List

If no description is provided:
1. Discover the tracker (above). If discovery fails, emit the error and stop.
2. Read the declared tracker file.
3. Present the bug list grouped by severity (HIGH first, then MEDIUM, then LOW).
4. User picks one to investigate.
5. Proceed to Step 1 below with the selected bug.

## `/t <desc>` -- Troubleshoot a Specific Bug

### Step 0: Load Bug Context
1. Discover and read the tracker (above). If discovery fails, emit the error and stop.
2. Match `<desc>` against existing entries.
3. **If no entry found OR entry has no linked feature docs:**
   - Tell user: "No bug report found, recording bug first"
   - Run the repo's bug-report skill (`/b`) to deduplicate, identify features, create/update feature docs with `[BUG]` criteria.
   - Resume here with the newly created context.
4. Follow links to feature doc(s) -- load success criteria and any `[BUG]` tagged criteria.
5. If flow docs exist for the area (`*.flow.md` near entry points), load those too.

### Step 1: Document the Problem
Before attempting any fix:
- **Error message**: exact text, error codes, stack traces
- **Context**: what operation was happening, what state the system was in
- **Reproduction**: what steps led to this error
- **Failing criteria**: which `[BUG]` tagged success criteria from the feature doc(s) are violated

### Step 2: Check Documentation First (Token-Efficient)
Before reading source code, check existing docs in this order:
1. **Feature doc** (`*.feature.md` near the code) -- already loaded in Step 0. The bug is a violated criterion.
2. **Memory files** (`memory/*.md`) -- check for technical reference (constants, architecture, known gotchas) via MEMORY.md index.
3. **Flow docs** (`*.flow.md` near entry points) -- if the issue spans multiple files, check for an existing flow doc before tracing code.
4. **Previous failure patterns** -- check relevant reference files for domain-specific gotchas.
- If a fix was already tried and failed, DO NOT try it again.
- List ALL previous attempts with results.
- Only read source code for the specific functions/areas the docs point to.

### Step 3: Research the Root Cause
- Look up the exact error code in official framework documentation (web search if needed, max 2 searches).
- Read the source code at the exact function where the error occurs (use function names from docs, not line numbers).
- Trace data flow: what values are being passed, what state are objects in.
- Add diagnostic logging if the cause isn't obvious from existing logs.

### Step 4: Identify the SINGLE Root Cause
State it clearly in one sentence before writing any code. Format:
> **Root cause:** [exact technical reason]
> **Evidence:** [log line or code that proves it]
> **Fix:** [exact change needed]

### Step 5: Apply the Fix
- Make the minimum change to fix the root cause.
- Do NOT refactor, clean up, or "improve" surrounding code.
- Build and verify zero errors.

### Step 6: Document the Solution
- Update the feature doc: remove `[BUG]` tag from the criterion or mark it passing.
- Add the failure pattern to the appropriate memory/reference file so it's never repeated:
  - Error code + what it means
  - What caused it
  - What fixed it
  - What NOT to do

## Retry Tracking
Maintain a visible retry count. Format:
```
RETRY LOG:
Attempt 1: [what was tried] -> [result]
Attempt 2: [what was tried] -> [result]
```
At attempt 3 with no progress: STOP. Research from official docs or engage specialist agent.
At attempt 4: Ask user how to proceed. Do not continue guessing.

## Rules
- NEVER guess. If you don't know the cause, add logging first.
- NEVER try the same fix twice. Check history.
- NEVER make multiple speculative changes. One change, one build, one test.
- Always trace from the error backward to the cause, not from assumptions forward to a fix.
- If a fix doesn't work after 3 attempts, STOP and research from official documentation.
