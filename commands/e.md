---
description: Fetch and display unresolved errors from the project's declared error source, grouped by severity.
---

Fetch error signatures:

1. Discover the project's error source from CLAUDE.md (e.g. telemetry system path, error log path, crash tracker URL). If no error source is declared, report the absence as a finding and stop -- do not guess at log locations.

2. Fetch unresolved errors from the discovered source.

3. Display grouped by severity (critical / error / warning). For each group, show: count, most recent occurrence, and representative stack or message.
