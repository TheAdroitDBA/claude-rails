# Feature: Delegate Task Skill

## What It Does

`/delegate-task` guides a manager through proper delegation using Multiplier Investor principles. Reads the assignee's role doc, produces role-appropriate framing (Principal / Lead / Senior / Mid-Level), generates a ServiceNow ticket description, waits for the ticket number, then delivers a paste-ready Teams message.

## Concern

**domain.** DBA leadership skill for managing the NICE CXone DBA team. Lives in the global pool for machine portability; references DBALeadership/Roles/ docs and the Microsoft Graph token workflow.

## Success Criteria

1. Gathers context before drafting: task outcome (not steps), assignee, timeline, and ticket system.
2. Reads the assignee's role doc from `DBALeadership/Roles/` before selecting a framing template.
3. Produces role-appropriate delegation framing for all four levels: Principal, Lead, Senior, Mid-Level. Does not apply the wrong level's framing.
4. Generates a ServiceNow ticket description (Title + Description + Deliverables + Priority + Due + Assigned To), then waits for the user to supply the ticket number before completing the Teams message.
5. Final Teams message is delivered in a fenced code block so it can be pasted cleanly without markdown artifacts.
6. Applies Multiplier Investor discipline: transfers outcome ownership; does not prescribe how unless the assignee is Mid-Level.
7. Optionally sends the message via PowerShell Graph API using HTML `contentType` and `<a href="">` tags when the user wants automated delivery.

## Status

DONE

### Progress

- [x] Criteria 1-7 closed: context-gathering, role-doc loading, four-level framing templates, ticket-wait pattern, code-block delivery, and Graph API send option all documented in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. If a new role level is added to DBALeadership/Roles/, add a corresponding framing template to SKILL.md.

## Files

- global/skills/delegate-task/SKILL.md

## Scope

global/skills/delegate-task/**
