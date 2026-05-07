---
description: Capture an idea before it is lost. Appends a timestamped entry to the project's ideas file. No criteria, no investigation -- just capture it.
argument-hint: <idea>
---

Capture idea: $ARGUMENTS

1. Discover the ideas-capture location: check CLAUDE.md for a declaration (e.g. "Ideas file: <path>"). If none is declared, default to IDEAS.md at the repo root.

2. Create the ideas file at the discovered path if it does not exist. Header only: # Ideas

3. Append a new line: - YYYY-MM-DD | $ARGUMENTS

4. Confirm with the exact line that was added.
