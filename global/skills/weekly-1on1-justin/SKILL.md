---
name: weekly-1on1-justin
description: "Prep Jeremy's private weekly 1:1 with Justin (manager-only, no peers). Surfaces topics that don't belong in the peer meeting -- personal coaching, sensitive people topics, cross-team observations Jeremy can't say publicly, air-cover asks, career conversations, real-talk on team morale. Use when: prepping for 1:1 with Justin, weekly one-on-one, private meeting with manager, what to bring to my 1:1."
---

# Weekly 1:1 with Justin Prep (Manager-Only)

## Purpose
Help Jeremy prep for his private weekly 1:1 with Justin. This is the place for everything that **doesn't** belong in the peer manager meeting -- private conversations about people, peer-team observations, career topics, air-cover asks, and honest morale/sentiment checks.

For peer-meeting prep (group setting with other managers), use the `weekly-manager-meeting` skill instead.

## Trigger
User asks about prepping for 1:1 with Justin, weekly one-on-one, private manager meeting, "what should I bring to my 1:1 with Justin", etc.

If the user mentions a group/peer meeting, route to `weekly-manager-meeting` instead.

## What goes in a 1:1 (and not in the peer meeting)

The peer meeting is for celebrating team wins and surfacing cross-team work. The 1:1 is for everything Jeremy can't or shouldn't say with peers in the room.

### 1. People topics (private)
- Specific team members who are struggling, plateauing, or growing into more
- Performance concerns Jeremy is tracking but isn't ready to act on
- Development plans for individual reports
- Promotion/comp conversations that are coming
- Conflict between team members
- Anyone he's worried about losing

Apply the three lenses (pattern / growth / mirror -- see `leadership_three_lenses` memory) before bringing a person up. Don't grade them against a checklist.

### 2. Cross-team observations Jeremy can't air publicly
- Peer-team behavior that's affecting the DBA team (slow handoffs, unclear ownership, accountability gaps)
- Observations about peer managers' teams Jeremy wouldn't say in front of them
- Political dynamics he wants Justin's read on
- Ownership gaps he wants to make a play for vs. accept

The `cor_dwa_etl_ownership_gap` is the canonical example -- in the peer meeting, frame as a structural question; in the 1:1, ask Justin's real read on whether to push for ownership or let it sit.

### 3. Air-cover asks
- Decisions Jeremy made that he wants Justin to back if it comes up
- Hard pushbacks he's planning (to peer teams, R&D, customers) where he wants Justin aware
- Resource asks Justin would need to defend upward (headcount, tools budget, schedule relief)
- Things he's saying "no" to and wants Justin's air cover for

### 4. Career and development for Jeremy himself
- Skills he's trying to grow (leadership, technical, political)
- Feedback he wants from Justin
- Stretch opportunities he's interested in
- Things he's struggling with as a manager
- Multiplier self-assessment moments worth raising

### 5. Real-talk / sentiment check
- How Jeremy is actually doing (burnout signals, focus issues, energy)
- Team morale read that's too candid for the peer room
- Stuff bothering him that doesn't have a clean ask attached
- Wins he doesn't want to brag about in front of peers

### 6. Action items from prior 1:1s
- Things Justin said he'd come back on
- Decisions Jeremy is waiting on
- Followups Jeremy committed to from last week

### 7. Operational rot Jeremy or the team is working around

Same audience as air-cover asks, different shape. If something on the team has been a quiet workaround for more than a couple weeks -- broken automation, missing documentation, scripts that don't fit a new naming convention, manual surgery on a build pipeline, an undocumented "just ask X" pattern -- that is structural rot, not operational pain. The diagnostic is duration: operational pain that becomes routine over weeks is no longer operational; it has crossed into structure.

In the 1:1, surface these as: *"We've been working around X for Y weeks. Is it worth a structural fix or an ownership push, or do we keep patching?"* Justin's answer routes it onto a roadmap, a peer-team ask, or a "yes keep patching, not worth it yet" -- but it stops being invisible.

**Apply the same question downward** in Jeremy's 1:1s with his leads (Manny, Shawn, etc.): *"Anything you're working around that you'd want fixed?"* Catches the same pattern one layer down. Leads describe friction; Jeremy decides whether it's operational (theirs) or structural (his to escalate). The LO200 / GGID duplicate issue (May 2026) was a build-pipeline rot Manny had been patching for a month -- it surfaced in writing on 2026-04-15 in the Cluster Build chat with Carolyn Hatcher, but Jeremy was not in that chat and the structural framing never came up his chain. This question, asked weekly in 1:1s, would have caught it.

Source: 2026-05-15 LO200 retrospective. See `LO200-Root-Cause-Findings.md` in `DBALeadership/` for the artifact.

## Persistence: the manager app DB

All 1:1 prep state lives in `DBALeadership\Management\app\data\dba_management.db`. Do not write parallel tracking files. Relevant tables (verify schema at prep time -- the app is actively evolving):

- **`one_on_one_topics`** -- topics to discuss, keyed on `person_id`. For Justin's 1:1, filter where `person_id` = Justin's person_id and `status = 'To Discuss'`. Columns include `topic`, `details`, `priority`, `status`, `discussion_date`, `response`, `action_items`, `parked_at`, `parked_reason`.
- **`employee_notes`** -- private per-person observations from prior meetings. Use to surface patterns when raising a team member.
- **`coaching_observations`** -- Multiplier coaching tracking. Note the `share_upstream` flag -- observations with `share_upstream = 0` belong in the 1:1 (private); `share_upstream = 1` can go in the peer meeting.
- **`tasks`** -- followups Jeremy owes Justin or Justin owes Jeremy. Filter by source/owner appropriately.
- **`decision_log`** -- decisions made, including `was_escalated` flag for things that may need Justin's awareness.
- **`people`** -- roster lookup.

After the 1:1, update topic `status`, add `response`, populate `action_items`, set `discussed_at`. Park topics that didn't fit instead of losing them.

## Workflow

### 1. Pull recent context
- Open topics from `one_on_one_topics` where `person_id = Justin` and `status = 'To Discuss'`, sorted by priority
- Recent `employee_notes` for any team member Jeremy is tracking
- Recent `coaching_observations` with `share_upstream = 0` (private)
- Tasks linked to Justin or flagged for his awareness
- Latest weekly report (`DBALeadership\WeeklyReports\ReportForJustin_*.md`) -- for situational awareness, not for re-reporting numbers
- Recent Teams chat with Justin if relevant (`triage-teams` or stored exports)

### 2. Ask Jeremy what's live
Before drafting an agenda, ask 2-3 focused questions to surface what's actually on his mind:

1. **Anyone on the team you're worried about, or someone you want to invest in more?**
2. **Anything happening with peer teams that's bugging you but you can't say publicly?**
3. **Anything you need Justin's air cover or input on?**
4. **Anything you or the team have been working around for more than a couple weeks?** (Structural rot detector -- the pattern that surfaced 2026-05-15 from LO200. Catches operational pain that has quietly become structure.)

These map to the four categories that drive most 1:1 value (people, peers, asks, structural rot). Career and sentiment topics tend to come out as side conversations once those are open.

### 3. Surface candidates from data + memory
After Jeremy answers, suggest topics he might not have surfaced:

- **People**: anyone in the weekly report whose pattern stands out (positive or concerning) -- e.g., one engineer absorbing too much oncall, someone consistently picking up the harder changes, a quiet performer not getting credit
- **Failures / Success-with-Issues**: the post-mortem framing for 1:1 is different than peer meeting -- here it's "what's this telling me about the team / the runbook / a specific person"
- **Ownership gaps**: from memory, currently `cor_dwa_etl_ownership_gap` and any newer entries -- frame as "do we make a play for this"
- **Open Justin questions from last 1:1**: if Jeremy tracks these somewhere, surface

### 4. Draft the agenda

Order matters. Lead with what's hottest for Jeremy. Suggested default order:

1. **Followups from last 1:1** (close the loop)
2. **People** (1-2 specific names with the lens and the question)
3. **Air-cover / asks** (specific, with what Jeremy needs from Justin)
4. **Peer-team / political observations** (read-check with Justin)
5. **Career / development** (one topic, not every week)
6. **Sentiment / how am I doing** (last 5 min, often unstructured)

Keep each item to one or two sentences with a clear ask: *"X situation -- I want your read on whether to do Y, or let it sit."* Don't bring problems without a position.

## Sensitivity rules

### Rule 1: 1:1 stays in the 1:1
Anything in this skill is meant to stay between Jeremy and Justin. If it would embarrass a team member or peer to be aired publicly, it doesn't go in the peer meeting -- even if Jeremy wants Justin's input.

### Rule 2: Name the person, name the lens
When raising a team member, apply the three lenses (pattern / growth / mirror) and name which lens. Don't grade against an expectations checklist. See `leadership_three_lenses`.

### Rule 3: Bring a position, not a problem
For asks and observations, draft Jeremy's current position before the meeting. *"I'm leaning toward X because Y. Want your read."* Justin's time is better spent stress-testing a position than diagnosing from scratch.

### Rule 4: No manufactured topics
If the week was quiet and there's nothing real to raise, say so. A short 1:1 that ends early is better than padding with theater. Justin gets enough of that elsewhere.

### Rule 5: Don't bring peer-meeting material
Numbers, campaign stats, success rates, change counts -- those belong in the peer meeting. The 1:1 is for what the numbers *mean* and what Jeremy wants to do about it.

## What NOT to do
- Don't re-report the weekly report numbers. Justin already saw them.
- Don't bring anonymized hypotheticals when the situation has a real name. Use names with Justin -- that's why it's a 1:1.
- Don't write a status update. Write a list of decisions Jeremy wants help with.
- Don't pull from `Team.md` or `TeamEmails.md` for roster -- query the manager app DB (`DBALeadership/Management/app/data/dba_management.db`, `people` table). See `team_roster_source_of_truth`.
- Don't recommend bringing every concern at once. Pick the 2-3 things that matter most this week.

## Related memories to check at prep time
- `leadership_three_lenses` -- pattern/growth/mirror lenses for any people topic
- `team_roster_source_of_truth` -- where to look up people
- `cor_dwa_etl_ownership_gap` -- recurring structural question worth surfacing
- `shawn_sql2022_upgrade_owner` -- process ownership context
- `feedback_no_manufactured_gaps` -- don't invent things to discuss
- Any newer memories tagged `type: project` or `type: feedback` that suggest active topics

## Open: what to learn over time
This skill's category list (people, peers, asks, career, sentiment, followups) is a v1 default. As Jeremy uses it, watch for:
- Which categories he actually uses each week vs. which sit empty
- Any recurring topic that deserves its own section
- His preference on length (10 min agenda vs. 30 min)
- Schema additions to the manager app that change what's available (e.g., a dedicated 1:1 sessions table, peer-vs-1:1 flag on topics) -- adapt to the schema in place rather than hard-coding

Save patterns as feedback memories when they emerge.
