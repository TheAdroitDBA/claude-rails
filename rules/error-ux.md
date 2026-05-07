# Error UX -- Rules Template

Copy this file into your project's `.claude/rules/` directory and customize the error registry mechanism.

## Invariants

- The app must NEVER appear frozen to the user. If an operation blocks the UI for more than one frame, show a progress indicator BEFORE the blocking work begins.
- Users must NEVER see raw error codes, stack traces, or developer-facing text. Every error path that reaches the user must have a human-readable message.
- Errors that fire in production are captured in an error registry -- a deduplicated store with: feature, severity, message, occurrence count, first/last seen. The registry mechanism is project-specific (database table, log aggregator, file).
- Online-only actions must be visibly disabled when offline, not silently failing.
- Long operations (>2 seconds expected) show a progress bar. Short operations (<2 seconds) show a spinner. Neither shows nothing.

## How to Apply

- Before calling any function that could block the UI (network I/O, heavy computation, file I/O, GPU sync): evaluate whether it could exceed 16ms. If yes, show the indicator first, then dispatch the work.
- Every catch block that surfaces an error to the user must map the internal error to a friendly message. Log the internal details to the error registry, show the friendly text to the user.
- Review unresolved error registry entries as part of regular triage (e.g., the `w:` shorthand).

## Common Mistakes

- Showing a loading screen after the blocking work starts (user sees a freeze, then the spinner)
- Catching an error and showing the raw `.localizedDescription` to the user
- Suppressing errors silently (user taps a button, nothing happens, no feedback)
- Network calls with default 60-second timeouts that hang the UX when offline
