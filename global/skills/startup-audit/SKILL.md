---
name: startup-audit
description: Comprehensive startup performance audit for any application. Identifies duplicate work, unnecessary delays, ordering issues, and optimization opportunities.
---

# Startup Flow Audit

Comprehensive startup performance audit for any application. Identifies duplicate work, unnecessary delays, ordering issues, and optimization opportunities.

## When to Use
Invoke when analyzing app launch performance, diagnosing slow startup, or before adding new work to the launch sequence.

## Process

### Phase 1: Map the Entry Points

Identify every initialization trigger in order:
1. **Process entry** -- main(), AppDelegate, Application.onCreate, server bootstrap
2. **Framework callbacks** -- lifecycle methods, dependency injection, module init
3. **First render** -- initial view/route/response ready for the user
4. **Fully interactive** -- all background work complete

For each entry point, document:
- Is it synchronous or async?
- Does anything wait for it to complete?
- What does it block?

### Phase 2: Trace Every Operation

For each operation that runs between process start and fully interactive:

```
| Operation | Trigger | Sync/Async | Depends On | Duration | Blocks UI? |
```

Classify each as:
- **Critical path** -- user cannot see/use the app until this completes
- **Required background** -- must happen but doesn't block UI
- **Deferrable** -- can wait until after the user is interactive

### Phase 3: Build the Waterfall

Create an ASCII timeline showing:
- Actual execution order (not intended order)
- Parallel vs sequential operations
- Where the critical path is (longest chain of blocking operations)
- Idle gaps where the CPU/network is waiting

Format:
```
T0    [Operation A]                    ~Xms  (blocking)
T50   [Operation B]                    ~Xms  (async, fire-and-forget)
      [Operation C]                    ~Xms  (parallel with B)
T200  [Operation D - BLOCKS ON B+C]   ~Xms  (critical path)
```

### Phase 4: Identify Problems

Check for these patterns:

**Duplicate work:**
- Same data fetched from multiple sources (API + cache + bundled)
- Same function called from multiple code paths during startup
- Data computed/parsed, then thrown away and recomputed

**Wrong timing:**
- Work that runs before its dependencies are ready
- Blocking operations that could be async
- Async operations that should be awaited but aren't (race conditions)
- Work on the critical path that could be deferred

**Every-resume work:**
- Operations in foreground/resume handlers that should only run once
- No TTL/freshness check before re-fetching data
- No guard against re-execution if already complete

**Missing guards:**
- No check for "already initialized" before re-initializing
- No check for auth state before making authenticated calls
- No debounce on operations triggered by rapid state changes

**Wasted network:**
- API calls whose data was already returned in a previous response
- Multiple calls to the same endpoint with no cache
- Calls made before auth is ready (will fail and retry)

### Phase 5: Measure Impact

For each problem found, estimate:
- **Time cost** -- how many ms does this add to startup?
- **Frequency** -- launch only, every foreground, every state change?
- **Fix complexity** -- one-line guard, refactor, architecture change?

Sort by: `(time_cost * frequency) / fix_complexity` -- highest value first.

### Phase 6: Recommend Fixes

For each fix, specify:
- Exact file and function to change
- What the guard/check should be
- What the before/after behavior is
- Whether it affects other code paths

Group into:
1. **Quick wins** -- simple guards, TTL checks, removing dead code
2. **Consolidation** -- merging duplicate paths into one
3. **Architecture** -- restructuring initialization order

## Output Format

Deliver three artifacts:
1. **Waterfall diagram** -- ASCII timeline of actual startup sequence
2. **Problem table** -- each issue with timing impact, frequency, and fix
3. **Fix list** -- ordered by impact, with exact code locations

## Rules
- Trace actual execution, not intended execution (read the code, don't trust comments)
- Measure from process start to user-interactive, not just "init complete"
- Check every foreground/resume handler -- these fire far more often than launch
- An operation that takes 50ms but runs 100x/day matters more than one that takes 500ms once
- Always check: "was this data already available from a previous step?"
