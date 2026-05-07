---
description: What's next -- reads the issues tracker, reports open bugs and tech debt, and flags anything needing immediate attention.
---

Report what is open and what needs attention:

1. Read the project's issues tracker (discovered from CLAUDE.md; fallback memory/KNOWN-ISSUES.md).

2. Gather feature statuses efficiently:
   - Use Grep (not an Explore agent) to extract "Status:" lines from all feature docs in one call.
   - Only Read individual feature docs if you need NEXT/handoff details for non-COMPLETE features.
   - NEVER spawn an Explore agent or read every feature doc individually just to extract status fields.

3. Report all open items grouped by category: [BUG] criteria, tech debt, parked features (IN PROGRESS with no recent progress entry), NEXT handoff lines with no owner.

4. Flag anything that needs immediate attention: blocking bugs, features that are IN PROGRESS but stalled, or KNOWN-ISSUES entries with no feature doc tracking them.
