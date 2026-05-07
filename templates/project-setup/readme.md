# [Project Name]

[One-line description of what this project does.]

## Start here

- **What's in flight:** see `.claude/current-feature`
- **How I work here:** see `CLAUDE.md`
- **What's broken:** see [actual path to issue tracker]
- **Feature specs:** colocated `*.feature.md` files next to primary code

## Troubleshooting a feature

When something is broken, walk the framework top-down before reading source:

1. **Identify which feature is affected.** Check `.claude/current-feature`, or find the nearest feature doc to the misbehaving code.
2. **Read that feature's success criteria.** Name the specific criterion that is failing. If none match, the feature doc is incomplete -- add the missing criterion first.
3. **Check the issue tracker.** Known broken state lives there. Do not rediscover it.
4. **Read the flow docs the feature references.** Flow docs list entry points, step tables, and failure modes.
5. **Check `.claude/rules/` for invariants.** Rules are the fastest way to catch a regression.
6. **Check recent git history scoped to the feature.**
7. **Only now read source code.** Start from the step in the flow doc that matches the failing criterion.
8. **Record what you find.** Fixable: fix it and update the feature doc's Status. Not fixable: add an entry to the issue tracker.
