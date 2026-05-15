---
name: my-tasks
description: 'Show Jeremy''s open tasks from the manager app, bucketed by overdue / due today / due this week, then drive a selected task to completion. Use when: "what''s on my plate", "what''s due today", "my tasks", "what should I work on", "any overdue items", "pick up where I left off", "next task".'
argument-hint: 'Optional: "overdue", "today", "week", or a task ID (e.g. "42") to jump straight to one'
---

# My Tasks

Read Jeremy's assigned tasks from the manager-app DB, surface what's due today (plus overdue), let him pick one, then work it to completion: load full context, set status to IN_PROGRESS, walk the success criteria, and update the task as work lands.

## Identity and source of truth

- **"My" / "me" = Jeremy Allen, person_id `14`** in the manager-app `people` table (email `jeremy.allen@nice.com`).
- **DB:** SQLite at `C:\code\ClientSetup\DBALeadership\Management\app\data\dba_management.db`
- **API base:** `http://127.0.0.1:8080/api/v1` (FastAPI; CORS open)
- **Frontend equivalent:** `http://127.0.0.1:8080/tasks?filter=mine` -- the skill reads the same data the page does.

## Prerequisites

The manager-app server must be running. Check first:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

If it fails with a connection error, **do NOT auto-start it** (see `memory/feedback_no_starting_dev_servers.md`). Tell Jeremy:

> Manager-app server is not reachable on 127.0.0.1:8080. Restart it (`Management\start.ps1`) and re-run this.

Stop. Resume the skill after he confirms it's up.

## Step 1: Pull Jeremy's open tasks

Fetch all open tasks owned by Jeremy, sorted by priority then due date (the API already orders this way):

```powershell
$tasks = Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/?owner_id=14&exclude_complete=true&limit=500"
```

The response is a list of `TaskResponse` objects. Useful fields per task:

| Field | Use |
|-------|-----|
| `id` | Task ID for follow-up calls |
| `request_title` | Display title |
| `priority_display` | "CRITICAL" / "HIGH" / "MEDIUM" / "LOW" |
| `status_display` | "NEW" / "ASSIGNED" / "IN_PROGRESS" / "BLOCKED" |
| `due_date` | ISO date or null |
| `criteria_completed` / `criteria_total` | Progress signal |
| `subtask_count`, `link_count` | Indicators of depth |
| `source`, `source_detail` | Where the task came from |
| `meeting_category_display` | If it's tied to a recurring meeting |

## Step 2: Bucket and present

Compute today's date (Mountain Time -- Jeremy's tz). Bucket tasks into:

| Bucket | Filter | Why this bucket |
|--------|--------|-----------------|
| Overdue | `due_date != null AND due_date < today` | These need triage first |
| Due today | `due_date == today` | The "what's due today" answer |
| Due this week | `today < due_date <= today + 6 days` | Heads-up so nothing slips |
| No due date | `due_date is null` AND `status_id == 3` (IN_PROGRESS) | Actively in-flight, no deadline |

Skip the "no due date / NEW" bucket -- that's a backlog, not today's queue.

Present as a numbered table. Use one index counter across all buckets so the user can pick by number:

```
OVERDUE (3)
[1] CRITICAL  due 2026-05-10 (4d)  Get-LocalAdminsExpanded follow-up        2/5 criteria  #TASK-42
[2] HIGH      due 2026-05-12 (2d)  Karla COR->DWA ETL ownership decision    0/3 criteria  #TASK-58
[3] MEDIUM    due 2026-05-13 (1d)  Approve SOV on-call week ending 5/9     no criteria   #TASK-71

DUE TODAY (2)
[4] HIGH      due 2026-05-14       Confluence onboarding page review        1/4 criteria  #TASK-80
[5] MEDIUM    due 2026-05-14       1:1 follow-up: Karla SQL2022 readiness   0/2 criteria  #TASK-83

DUE THIS WEEK (1)
[6] LOW       due 2026-05-16 (2d)  Update _quickreference.md                no criteria   #TASK-91

IN PROGRESS, no due date (1)
[7] HIGH      —                    DBA team operating plan v2 draft         3/8 criteria  #TASK-19
```

Sort within each bucket by priority (CRITICAL > HIGH > MEDIUM > LOW), then due date ascending.

End the message with:

> Which one do you want to work on? (number, or `skip` to just see the list)

## Step 3: Load full context for the chosen task

When Jeremy picks a number, resolve it to a task ID and pull the full record + criteria + links:

```powershell
$task = Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/$id"
$criteria = Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/$id/criteria"
$links = Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/$id/links"
```

Present the full task in this shape:

```
TASK $id: $title
Status: $status_display   Priority: $priority_display   Due: $due_date
Owner: Jeremy (assigned by $owner_assigned_by if set)
Source: $source / $source_detail
Meeting: $meeting_category_display (if any)

Description:
$description

Outcome expected:
$outcome_expected

Success criteria (n/N met):
  [x] Criterion 1 (done 2026-05-12)
  [ ] Criterion 2  -- note: blocked on Karla
  [ ] Criterion 3
  [-] Criterion 4  (removed: out of scope)

Links:
  SNOW INC INC1234567  https://...
  Confluence Page "DBA Onboarding"  https://...

Notes:
$notes
```

## Step 4: Set status to IN_PROGRESS (if it isn't already)

If the task's `status_id` is 1 (NEW) or 2 (ASSIGNED), bump it to 3 (IN_PROGRESS) before doing any work:

```powershell
$body = @{ status_id = 3 } | ConvertTo-Json
Invoke-RestMethod -Method Patch -Uri "http://127.0.0.1:8080/api/v1/tasks/$id" `
  -Body $body -ContentType "application/json"
```

Status IDs: `1=NEW, 2=ASSIGNED, 3=IN_PROGRESS, 4=BLOCKED, 5=COMPLETE`

If `status_id` is 4 (BLOCKED), ask Jeremy what changed before bumping it -- the block reason may still be live.

## Step 5: Do the work

The task description and criteria dictate what "doing the work" means. Common shapes:

| Task shape | What "work" looks like |
|------------|-----------------------|
| Email draft / approval | Compose the reply in chat, ask for tweaks, send via Outlook COM if needed |
| SQL query / data pull | Read the SOW, draft + run the query, return results |
| Doc update | Edit the file directly, then check the Confluence sync flow |
| CHG ticket review | Pull the implementation/rollback scripts, use `tsql-script-review` skill |
| Decision needing input | Use `team-decisions` framework, log if precedent-setting |
| 1:1 follow-up | Use `weekly-1on1-justin` or read meeting transcript |
| Stretch assignment | Honor it as a Multiplier challenge -- don't take it back; coach instead |

**Honor existing skills.** If the task title or notes name a domain another skill owns (Confluence, email triage, decisions, 1:1 prep, T-SQL review, incident investigation, data triage), invoke that skill rather than reimplementing.

## Step 6: Check criteria off as they're met

Each criterion is a checkable item. When work satisfies one, mark it complete:

```powershell
$body = @{ is_completed = $true; notes = "Met by PR #123" } | ConvertTo-Json
Invoke-RestMethod -Method Patch `
  -Uri "http://127.0.0.1:8080/api/v1/tasks/$id/criteria/$criterion_id" `
  -Body $body -ContentType "application/json"
```

Add a one-line `notes` value pointing to the evidence (commit SHA, ticket, page title, etc.). The notes field is what future-Jeremy reads when reviewing the completion summary.

If a criterion is no longer in scope, **remove it instead of skipping**:

```powershell
$body = @{ removal_reason = "..." } | ConvertTo-Json
Invoke-RestMethod -Method Delete `
  -Uri "http://127.0.0.1:8080/api/v1/tasks/$id/criteria/$criterion_id" `
  -Body $body -ContentType "application/json"
```

This is a soft delete -- the criterion stays on the task with `is_removed=true` and a reason. That trail matters; never just delete the row.

## Step 7: Close the task when all active criteria are met

When every non-removed criterion is checked, ask Jeremy if the task is done. If yes:

```powershell
$body = @{ status_id = 5 } | ConvertTo-Json   # COMPLETE
Invoke-RestMethod -Method Patch -Uri "http://127.0.0.1:8080/api/v1/tasks/$id" `
  -Body $body -ContentType "application/json"
```

The API auto-populates `completion_date` and generates a `completion_summary` from the title, owner, source, links, and criteria. No need to write that summary by hand.

If a criterion is unmet but the task is being closed anyway, that's a hint -- ask whether the criterion should be removed (with reason) or whether the task is closing early. Don't silently complete around it.

## Direct entry: pick by ID

If Jeremy invokes the skill with a task ID argument (e.g. `/my-tasks 42`), skip Steps 1-2 and go straight to Step 3 for that ID.

If he passes `overdue`, `today`, or `week`, show only that single bucket in Step 2.

## Edge cases

- **No open tasks for Jeremy** -- say "No open tasks assigned to you. Inbox zero on the task side." and stop. Do not invent work.
- **Task is delegated** (`delegated_to_id != null`) -- mention who it's delegated to, but it stays on Jeremy's list until they complete it. Honor Multiplier: don't take it back; coach the assignee instead.
- **Task is a parent** (`subtask_count > 0`) -- fetch subtasks via `/api/v1/tasks/$id/subtasks` and present them. The parent usually completes when all children do.
- **Task has a `meeting_category`** -- mention the meeting (e.g. "tied to Weekly DBA Sync"). The task may be best discussed there rather than handled async.
- **`source_topic_id` set** -- this task came out of a 1:1. Pull context from the one_on_one_topics table if it matters to the work.

## What this skill is NOT

- Not a goals tracker -- goals live in a separate API (`/api/v1/goals`). Different skill (`/today`-style summary) handles those.
- Not a decision logger -- precedent-setting decisions go through `team-decisions`.
- Not for delegating work -- use `delegate-task` to assign new work to the team.
- Not for browsing the team's tasks -- that's `workload_report.py` or the `/team` page. This skill is Jeremy's personal queue only.

## Quick reference

```powershell
# All open tasks for Jeremy, ordered by priority then due date
Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/?owner_id=14&exclude_complete=true&limit=500"

# Overdue only
Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/?owner_id=14&overdue_only=true"

# Specific task + criteria + links
$id = 42
Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/$id"
Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/$id/criteria"
Invoke-RestMethod "http://127.0.0.1:8080/api/v1/tasks/$id/links"

# Bump status
Invoke-RestMethod -Method Patch -Uri "http://127.0.0.1:8080/api/v1/tasks/$id" `
  -Body (@{status_id=3} | ConvertTo-Json) -ContentType "application/json"

# Check off a criterion
Invoke-RestMethod -Method Patch `
  -Uri "http://127.0.0.1:8080/api/v1/tasks/$id/criteria/$cid" `
  -Body (@{is_completed=$true; notes="..."} | ConvertTo-Json) `
  -ContentType "application/json"
```

Status IDs: `1=NEW, 2=ASSIGNED, 3=IN_PROGRESS, 4=BLOCKED, 5=COMPLETE`
Priority sort order (low number = higher priority): `1=CRITICAL, 2=HIGH, 4=MEDIUM, 5=LOW`
