# Flow: Triage ServiceNow Ticket Queue

One pipeline: pull the unassigned DBA ticket queue, classify each ticket as quick-fix or assignable, and produce a distribution plan that leaves zero unassigned tickets.

## Entry point

`/triage-servicenow` skill (SKILL.md in this directory). Human-invoked, on demand. No scheduler.

## Step table

| # | Step | Input | Output |
|---|------|-------|--------|
| 1 | Fetch queue | Assignment group(s) in scope | List of unassigned/new tickets with number, short description, opened-at, requester |
| 2 | Load active roster | Manager-app DB (people table, is_active=1, in DBA team) | Ordered list of assignees with current ticket count for fairness math |
| 3 | Load common-solutions library | Solutions store (file under DBALeadership) | List of pattern -> resolution-steps entries |
| 4 | Per-ticket match | One ticket + solutions library | Match (pattern id + recommended steps) or no-match |
| 5 | Bucket tickets | All tickets + match results | Three buckets: QUICK-FIX (matched, <=5 min), REROUTE (does not belong to DBA Operations), ASSIGN (real DBA work) |
| 6 | Distribute ASSIGN bucket | ASSIGN bucket + active roster + current load | Per-ticket assignee such that the max-min spread across the run is <= 1 |
| 7 | Render plan | Buckets + assignments | Markdown report grouped by QUICK-FIX, REROUTE (with target group per ticket), and per-assignee blocks |
| 8 | Apply (optional) | Plan + confirm flag | ServiceNow updates: assignment_group (for REROUTE), assigned_to (for ASSIGN), work_notes; or dry-run only |
| 9 | Capture new solutions | Tickets resolved during run | Append entry to solutions store with pattern + steps for future matching |
| 10 | Update clean-inbound streak | REROUTE bucket count for this run | If REROUTE count > 0, reset streak to 0; otherwise increment streak by 1 day (per unique calendar day, not per run). Persist to streak file alongside solutions store. |

## Failure modes

| Step | Failure | System response |
|------|---------|-----------------|
| 1 | ServiceNow API unreachable / 401 | Surface named error (`ServiceNowUnreachable` / `ServiceNowAuthExpired`); abort run; direct user to refresh credentials. Do not silently produce empty queue. |
| 1 | Queue is empty | Report "queue is empty, nothing to triage"; exit clean. Not an error. |
| 2 | Roster query returns zero active members | Abort; report "no active assignees available". Do not assign to anyone. |
| 3 | Solutions store missing | Treat as empty library; report "no common solutions loaded -- all tickets go to ASSIGN bucket"; continue. |
| 4 | Ticket short description is empty / ambiguous | Skip match attempt; ticket falls through to ASSIGN bucket. Do not guess. |
| 5 | REROUTE target group unknown | Surface in report as REROUTE-UNKNOWN; ticket still counts against the clean-inbound streak; user must specify the target group manually before apply. |
| 6 | More tickets than assignees by a large margin (e.g., >5x) | Still distribute, but flag in the report that current load may exceed the team's capacity. |
| 8 | ServiceNow rejects an update mid-batch | Stop applying; report which tickets succeeded and which did not; preserve dry-run summary so user can retry the failed ones. |
| 9 | User did not resolve any tickets during run | Skip solutions capture step; no error. |
| 10 | Streak file missing or corrupt | Treat current run as streak start (day 1) if zero REROUTEs, or stay at 0 if any. Log a warning; do not abort. |

## What this flow does NOT do

- Does not decide who *should* run it. That is an ownership question for the feature doc, not the pipeline.
- Does not auto-resolve QUICK-FIX tickets. The skill surfaces the recommended steps; a human applies them and confirms.
- Does not modify ticket priority, category, or any field other than assignment + work notes.
- Does not change ServiceNow data outside the configured assignment group(s).
