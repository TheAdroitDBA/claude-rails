# Feature: Triage ServiceNow Skill

## What It Does

`/triage-servicenow` pulls the DBA team's unassigned ServiceNow ticket queue, matches each ticket against a library of common 5-minute solutions, and produces a distribution plan that assigns every remaining ticket evenly across the active team roster. Output is a grouped report (QUICK-FIX bucket with recommended steps, plus per-assignee assignment blocks). Optionally applies the assignments to ServiceNow when the user confirms.

See `triage-servicenow.flow.md` for the pipeline.

## Concern

**domain.** DBA operations skill for the NICE DBA queue. Lives in the global skill pool (machine-portable like triage-teams / triage-email); invokes the existing `servicenow-api` skill / PowerShell module for ticket fetch and update. Roster source is the manager-app DB.

## Ownership

**Phase 1 (current):** Jeremy owns triage as a bridge. Primary work in this phase is **inbound routing cleanup** -- making sure only correct tickets reach the DBA Operations queue in the first place. Triage is the symptom; misrouted tickets are the cause.

**Phase 2 (transition):** Ownership moves to a Lead/Senior once **inbound routing has been clean for 30 consecutive days**.

*Definition of "clean inbound":* 30 consecutive days during which no ticket reaching the DBA Operations queue needed to be reassigned out to another team (i.e., every ticket the queue receives is genuinely DBA work). When the streak hits 30, Phase 2 starts and Jeremy names the Lead/Senior who takes over operational triage.

*If the streak breaks:* counter resets to zero. The routing-fix work is not done; ownership stays in Phase 1.

*Where this is tracked:* the triage-servicenow run produces the data -- any run that surfaces a misrouted ticket (added to the report as a REROUTE bucket alongside QUICK-FIX and ASSIGN) breaks the streak. Streak state lives next to the solutions store.

## Success Criteria

1. **All tickets in the configured queue end the run with a disposition.** After the run completes (in apply mode), every ticket that was in the queue at fetch time has either an assignee from the active roster OR a QUICK-FIX recommendation rendered in the report. Zero tickets left in the "no decision made" state.

2. **Assignment spread across the active roster is <= 1.** Within the ASSIGN bucket of a single run, the difference between the most-assigned person and the least-assigned person is at most one ticket. (Verifiable: count assignments per person from the run output.)

3. **Quick-fix matching surfaces a documented solution.** When a ticket matches a common-solution pattern, the report shows the pattern that matched and the recommended steps inline -- the user does not need to open a separate KB to act on it.

4. **Common-solutions library grows with use.** Running the skill, applying a quick fix, and re-running on a similar new ticket results in the new ticket also being matched. (Verifiable: matched-count increases over runs as the library captures patterns.)

5. **Active roster reflects current state.** Marking a team member inactive in the manager-app DB (or out-of-office, if OOO is in scope) excludes them from the ASSIGN bucket on the next run. No hardcoded names in the skill.

6. **Dry-run is the default.** Running the skill without an explicit apply/confirm flag produces the full plan as a report but makes zero ServiceNow API writes. The user must opt in to apply.

7. **Auth / connectivity failures abort with a named error.** ServiceNow unreachable or token-expired produces a typed error (`ServiceNowUnreachable` / `ServiceNowAuthExpired`) and a clear remediation message; the skill does not silently produce an empty queue or skip writes.

8. **Misrouted tickets are surfaced as REROUTE, and the clean-inbound streak is tracked.** Any ticket the skill identifies as not-DBA-work lands in a REROUTE bucket in the report, with a recommended target assignment group when known. The skill maintains a persistent clean-inbound streak counter that increments on REROUTE-free days and resets to zero on any day a REROUTE is found. (This is the Phase 2 transition signal -- 30 = handoff.)

## Status

APPROVED -- criteria locked, scoping decisions made. Ready for scaffolding.

**Scoping decisions (2026-05-14):**
- Ownership: Phase 1 = Jeremy, with routing cleanup as the bridge work. Phase 2 transition criteria TBD.
- Assignment group: **DBA Operations** (single group, all regions).
- Common-solutions library: starts empty; populated by capture as quick fixes are applied.
- Solutions store path: `C:\code\ClientSetup\DBALeadership\Management\ServiceNowSolutions\` (file: `common-solutions.json`).

### Progress

- [x] Flow doc drafted (`triage-servicenow.flow.md`)
- [x] Feature doc drafted with criteria
- [x] Ownership decision (Phase 1 = Jeremy + routing cleanup; Phase 2 transition criteria still owed)
- [x] Assignment group confirmed: DBA Operations
- [x] Common-solutions library: starts empty
- [x] Solutions store path: `DBALeadership\Management\ServiceNowSolutions\common-solutions.json`
- [x] Phase 2 transition trigger locked: 30 consecutive days of clean inbound (no REROUTE found)
- [x] SKILL.md scaffolded with 10-step procedure, REROUTE bucket, streak tracking, seam interface
- [x] `people.servicenow_sys_id` column added; skill resolves and caches sys_ids on first use (self-healing)
- [ ] NEXT: first dry-run against the live DBA Operations queue to validate fetch, classification heuristics, and sys_id resolution
- [ ] Build out REROUTE heuristics over time as misrouted patterns emerge
- [ ] Wire to existing `servicenow-api` skill / PS module; reuse, do not duplicate, the auth path
- [ ] First-run validation against the live queue in dry-run mode
- [ ] Phase 2 transition criteria documented before handoff

## Scope

- `C:\Users\jeremya\.claude\skills\triage-servicenow\**`
- Solutions store: `C:\code\ClientSetup\DBALeadership\Management\ServiceNowSolutions\common-solutions.json`
- Reads from: manager-app DB (`dba_management.db` people table, including `servicenow_sys_id`), ServiceNow queue via `servicenow-api`
- Writes to: ServiceNow assignment fields (apply mode only), solutions store file, streak file, `people.servicenow_sys_id` cache on first resolve per person

**Out of scope for v1:**
- Auto-resolving QUICK-FIX tickets (skill recommends; human applies)
- Modifying ticket priority, category, or any field other than assignment + work notes
- Cross-team assignment (only DBA team roster)
- Scheduled / unattended runs

## Files

- `C:\Users\jeremya\.claude\skills\triage-servicenow\SKILL.md` (to create)
- `C:\Users\jeremya\.claude\skills\triage-servicenow\triage-servicenow.flow.md` (drafted)
- `C:\Users\jeremya\.claude\skills\triage-servicenow\triage-servicenow.feature.md` (this file)
- `C:\code\ClientSetup\DBALeadership\Management\ServiceNowSolutions\common-solutions.json` (to create on first capture)
- Existing reuse: `servicenow-api` skill, manager-app DB roster query

## Convention check

- **Persistence behind a Store seam:** common-solutions library is persisted state. Will be accessed through a small read/write seam (load_solutions / append_solution), not direct file I/O from match logic. Holds.
- **Graceful named exceptions:** declared in criterion 7. Holds.
- **Dry-run fixture:** declared in criterion 6 (dry-run as default). Holds.
- **Own runtime + pinned deps:** skill reuses `servicenow-api` runtime; no new Python venv. Holds.
- **Secrets via .env:** ServiceNow credentials inherited from `servicenow-api` skill's existing auth path; no new secrets introduced. Holds.
- **Risk register / sunset:** the skill is stateless aside from the solutions JSON; it does not receive external traffic or hold credentials directly. Exempt per the convention's stateless-CLI carve-out.
- **Forward-compatible config:** if a config file is introduced for assignment-group scope, it will stub fields for future filters (OOO awareness, priority weighting) so the shape stays stable.

No deviations needed at draft time.
