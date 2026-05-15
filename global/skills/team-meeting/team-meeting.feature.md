# Feature: Team Meeting Skill

## What It Does

`/team-meeting` reviews DBA team meeting transcripts to extract decisions, action items, and open questions, then provides Multiplier leadership coaching on Jeremy's communication patterns. Offers four follow-up actions: insert tasks to the Management DB, log a coaching observation, draft Teams messages, or summarize for the weekly report.

## Concern

**domain.** DBA leadership skill for post-meeting analysis and Multiplier coaching. Lives in the global pool for machine portability; references `DBALeadership/Management/app/data/dba_management.db` and `DBALeadership/Management/Transcripts/`.

## Success Criteria

1. Accepts transcripts as pasted text, file path, or Teams speaker-label format with timestamps. Normalizes speaker names to first names.
2. Extracts and presents five sections in fixed output order: Decisions Made, Action Items (table with #/Action/Owner/Due/Notes columns), Jeremy's Follow-Ups, Open Questions, Team Pulse (when signals are present).
3. Multiplier Scorecard names specific Strengths Observed, Growth Opportunities, and Accidental Diminisher Moments with direct quotes or paraphrases from the transcript. Feedback is not softened.
4. Coaching output covers all 5 Multiplier disciplines and all 6 Accidental Diminisher patterns; omits only those with no evidence in the transcript.
5. Offers follow-up actions after presenting analysis: (a) create tasks in Management DB, (b) log coaching observation, (c) draft Teams messages, (d) summarize for weekly report.
6. Task insertion resolves names to `people` table IDs via SQLite query before inserting; uses `source = 'Team Meeting'` and `source_detail = meeting date`.

## Status

DONE

### Progress

- [x] Criteria 1-6 closed: transcript ingestion, five-section output, Multiplier Scorecard with direct quotes, discipline/diminisher coverage, four follow-up offers, and SQLite task insertion all documented in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. If Jeremy's person_id changes in the Management DB, update the hardcoded `person_id = 14` reference in the task insertion section.

## Files

- global/skills/team-meeting/SKILL.md

## Scope

global/skills/team-meeting/**
