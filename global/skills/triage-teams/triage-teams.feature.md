# Feature: Triage Teams Skill

## What It Does

`/triage-teams` fetches all unread Teams chats via `Get-UnreadTeamsMessages.ps1`, classifies each one (NEEDS MY REPLY / WAITING ON OTHERS / FYI ONLY / DELEGATABLE) by reading message content and applying classification rules, and presents a grouped summary showing where a response is needed.

## Concern

**domain.** DBA operations skill for Jeremy Allen's Teams inbox triage at NICE. Lives in the global pool for machine portability; references `DBALeadership\.graphtoken` and a Get-UnreadTeamsMessages.ps1 script.

## Success Criteria

1. Runs `Get-UnreadTeamsMessages.ps1` to fetch and pre-classify unread chats; output written to `DBALeadership/Management/Transcripts/adhoc/UnreadTriage_YYYY-MM-DD.md`.
2. Classifies each chat into one of four categories: NEEDS MY REPLY, WAITING ON OTHERS, FYI ONLY, DELEGATABLE.
3. Classification reads message content (questions, @mentions, action language) to refine the script's last-sender heuristic -- a question from the user to the other person does not mean the other person owes a reply.
4. Output is grouped by category; each entry is a one-line summary showing person/topic, chat type, and what action is needed.
5. Token refresh procedure documented; 401 errors direct user to Graph Explorer for a fresh token.
6. Script lives in `c:\code\ClientSetup\DBALeadership\Get-UnreadTeamsMessages.ps1`, alongside all other DBA companion scripts. Token loaded from `$PWD/.graphtoken`; output written to `$PWD/Management/Transcripts/adhoc/`. Run from DBALeadership.

## Status

DONE

### Progress

- [x] Criteria 1-6 closed: script invocation updated to `c:\code\ClientSetup\DBALeadership\Get-UnreadTeamsMessages.ps1`, four-category classification, content-reading refinement, grouped summary format, and token refresh procedure all documented in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. Update token refresh steps if Graph API auth method changes.

## Files

- global/skills/triage-teams/SKILL.md

## Scope

global/skills/triage-teams/**
