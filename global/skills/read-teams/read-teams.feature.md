# Feature: Read Teams Skill

## What It Does

`/read-teams` exports Teams chat history via Microsoft Graph API. `Monitor-TeamsChats.ps1` handles systematic daily monitoring of all configured team members; `Export-TeamsChatHistory.ps1` handles one-off exports by topic, chat ID, URL, or message content search. The skill distinguishes `@thread.v2` chats from `@thread.skype` channel threads and routes to the correct API.

## Concern

**domain.** DBA operations skill for Jeremy Allen's Teams monitoring at NICE. Lives in the global pool for machine portability; references `c:\code\ClientSetup\DBALeadership\` scripts and `DBALeadership\Management\Transcripts\` output conventions.

## Success Criteria

1. `Monitor-TeamsChats.ps1` exports recent 1:1 messages from all configured stakeholders to `Transcripts/chats/{FirstLast}_{YYYY-MM-DD}.md`; one file per person per run, overwritten on re-export same day.
2. `Export-TeamsChatHistory.ps1` handles targeted exports via `-SearchTopic`, `-ChatId`, `-ChatUrl`, and `-SearchContent` parameters.
3. Skill identifies URL type from the `@thread.v2` vs. `@thread.skype` marker before deciding which tool to use. Never passes a `@thread.skype` URL to the export script.
4. Channel threads (`@thread.skype`) are read via the Graph API directly: `teams/{teamId}/channels/{channelId}/messages/{messageId}` for the root and `.../replies` for the thread.
5. Output follows the `Transcripts/` subdirectory convention: chats/ for Monitor exports, meetings/ for .docx transcripts, adhoc/ for one-off exports.
6. People lookup resolves team member names to Management DB IDs via SQLite query on `dba_management.db`.
7. Token refresh procedure documented; 401 errors direct user to Graph Explorer.

## Status

DONE

### Progress

- [x] Criteria 1-7 closed: Monitor script, Export script parameters, thread-type disambiguation, channel-thread Graph API pattern, Transcripts/ organization, SQLite people lookup, and token refresh procedure all documented in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. Update the Team Member Quick Reference table in SKILL.md when team roster changes.

## Files

- global/skills/read-teams/SKILL.md

## Scope

global/skills/read-teams/**
