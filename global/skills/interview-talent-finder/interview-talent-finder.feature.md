# Feature: Interview Talent Finder Skill

## What It Does

`/interview-talent-finder` evaluates DBA candidates using role-level expectations and the Multiplier framework. Reads the role doc for the position before generating tailored questions, writes all output to files (never to chat), asks clarifying questions before producing a post-interview assessment, and covers all required Scorecard Fields and Winning@NICE competencies.

## Concern

**domain.** DBA hiring skill for the NICE CXone DBA team. Lives in the global pool for machine portability; references `DBALeadership/Interview/` docs, `DBALeadership/Roles/` role docs, and `DBALeadership/Management/app/data/dba_management.db`.

## Success Criteria

1. Reads the role doc matching the position level from `DBALeadership/Roles/` before generating questions or evaluating a candidate.
2. All output goes to files, not to chat: pre-interview questions to `DBALeadership/Interview/<ActiveReqFolder>/Interview_Questions_<CandidateName>.md`.
3. Post-interview assessment written to `DBALeadership/Interview/<ActiveReqFolder>/<CandidateName>_Assessment.md`.
4. When the user supplies completed interview notes, asks targeted clarifying questions before writing the assessment -- does not proceed with blank or vague fields.
5. Assessment covers all Scorecard Fields: SQL Server mission-critical, T-SQL, replication, Availability Groups, cross-functional communication, and five Winning@NICE competencies. Fields with no evidence are marked "Not covered -- ask in next round."
6. Scores on two axes: Technical Fit (Strong Yes / Yes / No / Definitely Not) and Multiplier Fit (Strong Multiplier / Likely Multiplier / Neutral / Diminisher Risk).
7. For UK SOV roles, asks NPPV L3 clearance eligibility questions and documents eligibility status.
8. Rejected candidates: copies CV and assessment to `Archive/YYYY-MM_ReqName/`. When a req closes, moves the entire active-req folder to a dated archive subfolder.
9. Chat summary after file writes is one or two sentences: candidate name, recommendation, file path. No full content in chat.
10. Step 2 does not reference a hardcoded path to the multiplier-leadership skill; the plugin system provides it.

## Status

DONE

### Progress

- [x] Criteria 1-10 closed: role-doc loading, file-only output, clarification-before-assessment, scorecard coverage, two-axis scoring, NPPV L3 flag, archive workflow all documented in SKILL.md. Stale copilot path removed from Step 2.
- [x] NEXT: handoff line -- maintenance-only. Update DBALeadership/Roles/ references if a new role level is added.

## Files

- global/skills/interview-talent-finder/SKILL.md

## Scope

global/skills/interview-talent-finder/**
