---
name: weekly-manager-meeting
description: "Prep Jeremy's weekly peer meeting with Justin's managers (group setting, not 1:1). Pulls the latest weekly report, surfaces highlight candidates with correct attribution, flags ownership gaps and post-mortem items, drafts a peer-appropriate agenda. Use when: prepping for weekly manager meeting, weekly peer meeting with Justin and peers, group manager meeting, what to share in front of peers."
---

# Weekly Manager Meeting Prep (Peer Setting)

## Purpose
Help Jeremy walk into his weekly group meeting with Justin and peer managers with a tight, honest agenda built from the most recent DBA Operations weekly report. This is a **peer setting** -- everything proposed here should be appropriate to say in front of other managers, not private 1:1 material.

For Justin-only conversations (personal coaching, sensitive people topics, air-cover asks, peer-team observations Jeremy can't say publicly), use the `weekly-1on1-justin` skill instead.

## Trigger
User asks about prepping for the weekly manager meeting, peer meeting with Justin and his managers, group manager meeting, "what should I share in front of peers", "what should I bring to the manager meeting", etc.

If the user mentions "1:1" or "one-on-one" with Justin specifically, route to `weekly-1on1-justin` instead.

## Inputs (where the data lives)

**Weekly report files:**
- Manager-facing summary: `DBALeadership\WeeklyReports\ReportForJustin_<date-range>.md`
- Detailed per-CHG table: `DBALeadership\WeeklyReports\DetailedReportForDBA_<date-range>.md`
- Raw ServiceNow export with Deployer field: `DBALeadership\WeeklyReports\WeeklyChanges_<date-range>.csv`

Always read the CSV in addition to the markdown reports -- the markdown summaries omit the Deployer column, which is essential for attribution.

**Manager app DB** (`DBALeadership\Management\app\data\dba_management.db`):
- **`coaching_observations`** with `share_upstream = 1` -- observations cleared for peer/upward visibility. These are the legitimate highlight candidates.
- **`decision_log`** with `was_precedent_setting = 1` or `was_escalated = 1` -- decisions worth peer awareness.
- **`tasks`** with cross-team impact -- followups peers should know about.
- **`people`** -- roster lookup (do not use `Team.md`).

Do not pull `share_upstream = 0` observations or private `employee_notes` into peer-meeting prep -- those belong in `weekly-1on1-justin`.

## Workflow

### 1. Pull the latest weekly report
Find the most recent `ReportForJustin_*.md` and its matching CSV. Read both. If multiple weeks exist, default to the latest unless the user names a different range.

### 2. Build the highlight candidate list

For each engineer who appears in the Deployer column:
- Count their CHGs.
- Note close codes (Success / Success with Issues / Failed).
- Tag each change by risk class (see rules below).

Then identify the **process owner / principal engineer** for any major campaign that appears in the week (SQL 2022 upgrade campaign, PCI masking, global server setup, etc.). Campaign credit goes to the owner; per-change implementers are named underneath.

### 3. Build the ownership-gap section

Surface known ownership gaps that may be worth raising with Justin -- especially any that came up in recent incidents or recurring problems. Don't manufacture gaps; only flag real ones with current evidence.

### 4. Build the post-mortem section
List every Failed and Success-with-Issues CHG from the week. For each, draft the question worth asking Justin (e.g., "do we have a runbook fix planned", "is this a campaign-level lesson", "do we need to invest in tooling").

### 5. Output the agenda

Present in this order:
1. **Highlight** -- ownership story first, implementers underneath
2. **Ownership / structural questions** -- gaps to raise with Justin
3. **Post-mortem** -- failures and issues to surface
4. **Open questions / air cover** -- anything Jeremy needs Justin's input on

Keep each section to 2-4 lines. Justin's time is short.

## Attribution rules (learned the hard way)

These are non-negotiable. Get them wrong and the highlight story is wrong.

### Rule 1: Deployer = implementer
The Deployer / assigned / closing engineer on a ServiceNow CHG **did the work**. This team's process treats the assigned engineer as owning the change end-to-end, not just "the person on shift during the window." Attribute credit directly. Do not hedge with "could just be shift coverage."

### Rule 2: For runbook-driven campaigns, credit the process owner first
Some changes are individual ad-hoc work; others are executions of a repeatable runbook owned by a principal engineer. For runbook-driven campaigns, the campaign-level story belongs to the **process owner**, with implementers named underneath.

Known process owners:
- **SQL 2022 upgrade campaign** -- owner: **Shawn Noker** (principal). Even when Godwin runs a BIT upgrade or Carter runs a COR upgrade, the campaign progress narrative goes to Shawn.

For any other repeatable campaign, **ask Jeremy who the principal/process owner is before naming a highlight.** Don't infer from Deployer counts alone.

### Rule 3: Not all CHGs are equal in risk
BIT and COR upgrades are not the same difficulty -- COR is the customer-facing OLTP layer, BIT is the smaller secondary side. Two clean COR upgrades is a stronger story than three clean BIT upgrades. Always note the risk mix when describing volume.

Other known risk distinctions:
- Emergency CHG > Normal/Standard
- Global server / replication work > single-cluster work
- Sovereign cloud clusters (OS-series, UK Sov) > standard clusters

### Rule 4: Framing template
When writing the highlight for Justin, use this structure:

> **{Owner}** drove the {campaign} this week as process owner -- {N} {units} completed ({list}) across {scope}. **{Implementer A}** implemented {X count of subtype} ({clean / with issues}). **{Implementer B}** implemented {Y count of subtype} ({clean / with issues}). {One-line on issues if any.}

Example:

> **Shawn Noker** drove the SQL 2022 upgrade campaign this week as process owner -- five clusters completed (A31, A33, A35, J33, OS26) across both BIT and COR roles. **Godwin Izekor** implemented three BIT upgrades (A31, A33, A35), all clean. **Carter Cordingley** implemented two COR upgrades (J33 clean, A33 Success-with-Issues -- feeding back into the runbook). One Success-with-Issues to review, no failures on the campaign.

## Known ownership gaps to consider raising

Pull from memory at prep time -- do not hard-code the list here, it changes. As of this writing, the recurring one is:

- **COR -> DWA ETL pipeline** -- destination owned by Karla's reporting team (under Snehal), source owned by ACD COR R&D, transit is unowned. Worth raising when there's a recent incident touching the ETL (e.g., the John Young CC-in-disposition-notes triage).

When surfacing a gap to Justin, frame it as a specific question, not a generic "we should talk about ownership." Example: *"Who does he want to call the owner of the COR -> DWA ETL, and does he want us to make a play for it?"*

## Open questions to ask Jeremy before finalizing

Before producing the final agenda, check:
1. **Is there a process owner I should know about** for any campaign that appears in the report and isn't already in my memory? (If yes, save it -- next week I won't have to ask.)
2. **Anything Jeremy needs air cover on** that won't be visible in the report -- escalations, blocked decisions, people issues?
3. **Length preference** -- is this a 15-min slot or a longer 1:1? Trim agenda accordingly.

## What NOT to do
- **Don't include 1:1 material.** Anything private (specific people's performance issues, peer-team criticism Jeremy can't say in front of them, career conversations, air-cover asks that would embarrass someone if aired) belongs in the `weekly-1on1-justin` skill, not here.
- Don't manufacture highlight stories. If the week was light, say so. A short honest agenda beats a padded one.
- Don't recommend highlighting someone purely on CHG count without checking risk mix and process ownership.
- Don't propose action items that assign work to teams that can't accept it (e.g., proposing ETL changes to Karla's team -- they own destination, not transit).
- Don't pull from `Team.md` or `TeamEmails.md` for team roster -- query the manager app DB (`DBALeadership/Management/app/data/dba_management.db`, `people` table). See `team_roster_source_of_truth` memory.

## Related memories to check at prep time
- `shawn_sql2022_upgrade_owner` -- Shawn owns the SQL 2022 upgrade campaign
- `servicenow_deployer_is_implementer` -- Deployer field is authoritative for credit
- `cor_dwa_etl_ownership_gap` -- recurring structural gap worth raising
- `team_roster_source_of_truth` -- where to look up people
- `leadership_three_lenses` -- pattern/growth/mirror lenses for any people decision that comes out of the meeting
