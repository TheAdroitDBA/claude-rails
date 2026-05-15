---
name: team-meeting
description: 'Review team meeting transcripts to extract takeaways, assignments, followups, and provide Multiplier leadership coaching. Use when: reviewing meeting notes, analyzing team meeting transcripts, extracting action items from meetings, post-meeting review, leadership self-assessment on meeting behavior.'
argument-hint: 'Paste or reference your meeting transcript'
---

# Team Meeting Transcript Review

## Purpose
Analyze team meeting transcripts to extract actionable takeaways, identify assignments and followups, and provide Multiplier leadership coaching feedback on Jeremy's communication patterns.

## Trigger
User provides a meeting transcript (pasted text, file reference, or copied from Teams).

## Workflow

### 1. Ingest the Transcript
Accept transcript input in any format:
- Pasted text directly in chat
- File path reference (read the file)
- Teams transcript format (speaker labels with timestamps)

If the transcript is in Teams format, parse speaker names and timestamps. Normalize speaker names to first names for readability.

### 2. Extract Meeting Intelligence

Analyze the full transcript and produce these sections:

#### A. Decisions Made
Items where the team reached agreement or Jeremy made a call:
- What was decided
- Who was involved in the discussion
- Any conditions or caveats

#### B. Action Items & Assignments
For each action item identified:
- **What**: Clear description of the task
- **Who**: Person responsible (use name from transcript)
- **When**: Due date if mentioned, or "TBD"
- **Context**: Brief note on why/where this came up

Look for signals like:
- Direct assignments: "Can you...", "I need you to...", "Take a look at..."
- Commitments: "I will...", "I can do that...", "Let me..."
- Implied tasks: Questions left unanswered, problems raised without resolution
- Follow-up triggers: "Let's circle back on...", "We should check...", "I'll follow up..."

#### C. Items Requiring Jeremy's Follow-Up
Separate list of things Jeremy specifically needs to act on:
- Commitments Jeremy made during the meeting
- Questions directed at Jeremy that were deferred
- Escalations or approvals Jeremy needs to handle
- Information Jeremy promised to share or look up

#### D. Open Questions / Unresolved Topics
Issues that were raised but not resolved:
- Topics that were tabled or deferred
- Questions that went unanswered
- Disagreements that were not settled
- Items that need more information before deciding

#### E. Team Pulse (Optional -- include when signals are present)
Observations about team dynamics visible in the transcript:
- Who contributed most/least
- Topics that generated energy or resistance
- Signs of confusion or misalignment
- Positive moments (collaboration, ownership, initiative)

### 3. Multiplier Leadership Analysis

This is the coaching section. Review everything Jeremy said in the transcript and assess against the 5 Multiplier disciplines.

#### What to Look For in Jeremy's Words

**Talent Magnet signals:**
- Did Jeremy acknowledge or leverage specific people's strengths?
- Did he connect the right person to the right problem?
- Or did he assign work without considering native genius?

**Liberator signals:**
- Did Jeremy create space for others to share ideas?
- Did he ask questions before giving answers?
- Did he share a mistake or vulnerability?
- Or did he dominate discussion, shut down ideas, or project certainty on every topic?

**Challenger signals:**
- Did Jeremy pose questions that frame opportunities?
- Did he lay down a challenge that stretches the team?
- Or did he tell people what to do and how to do it (Know-It-All)?

**Debate Maker signals:**
- Did Jeremy facilitate productive debate?
- Did he ask for dissenting views or stress-test ideas?
- Or did he make decisions unilaterally or in a small circle?

**Investor signals:**
- When someone brought a problem, did Jeremy give it back?
- Did he let people struggle and own the solution?
- Or did he jump in and solve it himself (Rescuer)?

#### Accidental Diminisher Watch
Flag any instances of these common patterns:
- **Idea Fountain**: Jeremy shares too many ideas, team waits for his input
- **Always On**: Jeremy's energy overwhelms quieter voices
- **Rescuer**: Jeremy solves problems that team members should own
- **Pacesetter**: Jeremy sets a pace others can't match
- **Rapid Responder**: Jeremy answers immediately instead of letting others think
- **Optimist**: Jeremy glosses over legitimate challenges

#### Coaching Output Format

```
Multiplier Scorecard
====================

Strengths Observed:
- [Discipline]: [Specific example from transcript]

Growth Opportunities:
- [Discipline]: [Specific moment + what a Multiplier would do instead]

Accidental Diminisher Moments:
- [Pattern]: [Quote or paraphrase] -> [Alternative approach]

One Thing to Try Next Meeting:
- [Specific, actionable suggestion based on the patterns observed]
```

Be direct and specific. Quote or paraphrase actual statements from the transcript. Do not soften the feedback -- Jeremy wants honest coaching to grow as a Multiplier leader.

### 4. Offer Follow-Up Actions

After presenting the analysis, offer:

1. **Create tasks in Management DB** -- Insert action items as tasks
   - Use the `tasks` table in `c:\code\ClientSetup\DBALeadership\Management\app\data\dba_management.db`
   - Look up people by name from the `people` table
   - Set source = "Team Meeting", source_detail = meeting date
   - Default priority = MEDIUM unless urgency signals are present
   - Owner = person assigned, delegated_to_id if someone else executes

2. **Log coaching observation** -- Record a Multiplier coaching moment in the `coaching_observations` table

3. **Draft follow-up messages** -- Write Teams messages for items Jeremy needs to communicate

4. **Summarize for weekly report** -- Format key decisions and progress for Jeremy's weekly status report

## People Lookup Reference

When creating tasks, resolve names against the people table:
```python
import sqlite3
conn = sqlite3.connect(r'c:\code\ClientSetup\DBALeadership\Management\app\data\dba_management.db')
cur = conn.cursor()
cur.execute("SELECT id, name, current_role FROM people WHERE is_active = 1 ORDER BY name")
people = cur.fetchall()
```

Jeremy's person_id = 14 (use for tasks he owns).

## Task Insertion Template
```python
from datetime import datetime
cur.execute('''
    INSERT INTO tasks (request_title, description, source, source_detail,
                       intake_date, due_date, priority, owner_id, status,
                       notes, delegated_to_id, last_modified)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''', (title, description, 'Team Meeting', meeting_date,
      datetime.utcnow().isoformat(), due_date, priority, owner_id, 'NEW',
      notes, delegated_to_id, datetime.utcnow().isoformat()))
conn.commit()
```

## Output Formatting

Present the analysis in this order:
1. One-line meeting summary (topic, duration if known, attendees)
2. Decisions Made
3. Action Items & Assignments (table format)
4. Jeremy's Follow-Ups
5. Open Questions
6. Team Pulse (if applicable)
7. Multiplier Scorecard
8. Offer follow-up actions

Use tables for action items:

| # | Action Item | Owner | Due | Notes |
|---|-------------|-------|-----|-------|
| 1 | ... | ... | ... | ... |

## Best Practices
- When in doubt about whether something is an action item, include it -- better to capture and discard than miss something
- For ambiguous ownership, flag it and ask Jeremy to clarify
- Compare Jeremy's talk-time ratio to others as a rough Liberator metric
- Track patterns across meetings if the user reviews multiple transcripts in a session
- Do not sanitize the Multiplier feedback -- be specific and cite the transcript
