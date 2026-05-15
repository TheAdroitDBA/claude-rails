---
name: triage-teams
description: 'Triage unread Teams messages: fetch all unread chats, classify as direct/group, determine who needs to respond. Use when: checking unread Teams messages, triaging Teams inbox, finding what needs a reply, morning Teams review, who is waiting on me.'
---

# Triage Unread Teams Messages

Fetch all unread Teams chats, classify each one, and determine if a response is needed.

## Prerequisites

- Token file: `DBALeadership\.graphtoken` (same as read-teams skill)
- Required Graph permissions: `Chat.Read`, `Chat.ReadBasic`
- Script: `c:\code\ClientSetup\DBALeadership\Get-UnreadTeamsMessages.ps1`

## Procedure

### Step 1: Run the Export Script

```powershell
cd c:\code\ClientSetup\DBALeadership
.\Get-UnreadTeamsMessages.ps1
```

**Parameters:**
- `-MaxChats 10` -- limit to N most recent unread chats (default 50)
- `-DirectOnly` -- only show 1:1 chats (skip group/meeting chats)
- `-OutFile "path.md"` -- custom output location

**Output:** Writes to `DBALeadership\Management\Transcripts\adhoc\UnreadTriage_YYYY-MM-DD.md`

### Step 2: Read the Output File

Read the generated triage report. Each chat section contains:
- Type (DIRECT 1:1, GROUP, MEETING CHAT)
- Whether it's direct to the user
- Other members (for group chats)
- The unread messages with sender and timestamp
- Initial "ball with" assessment based on who sent the last message

### Step 3: Triage Each Chat

For each unread chat, classify into one of these categories:

| Category | Criteria | Action |
|----------|----------|--------|
| NEEDS MY REPLY | Direct 1:1 where other person sent last message, OR group where someone asked me something directly | Flag for response |
| WAITING ON OTHERS | I sent the last message, or the thread is waiting on someone else | No action needed |
| FYI ONLY | Meeting chat system messages, announcements, threads where I'm CC'd but not addressed | Mark as read or skip |
| DELEGATABLE | Someone asking about something my team handles | Consider delegating |

### Classification Rules

**NEEDS MY REPLY when:**
- Chat is 1:1 (direct) AND last message is from the other person
- Last message contains a question mark directed at me
- Last message contains: "can you", "could you", "please", "when will", "any update", "thoughts?"
- Someone @mentioned me (look for my name in message content)

**WAITING ON OTHERS when:**
- I sent the last message (awaiting their response)
- Last message is directed at someone else by name
- Thread is between others and I'm just in the group

**FYI ONLY when:**
- Meeting chat with only system messages (member added/removed)
- Last message is a general announcement
- Thread is informational with no action item
- Old meeting chats with stale unread counts

### Step 4: Present Summary

Present results in this format:

```
## NEEDS MY REPLY (X chats)
1. [Person/Topic] - [1:1/Group] - [Preview of what they need]
2. ...

## WAITING ON OTHERS (X chats)
1. [Person/Topic] - waiting on [who] since [date]
2. ...

## FYI / NO ACTION (X chats)
1. [Topic] - [reason no action needed]
2. ...
```

## Token Expiration

If the script errors with 401, the token is expired. Direct the user to refresh it:
1. Open Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer
2. Sign in, copy the access token
3. Paste into `DBALeadership\.graphtoken`

## Notes

- Meeting chats often accumulate "unread" system messages that aren't actionable
- The script pre-classifies "ball with" based on last message sender, but the AI should refine this by reading message content (a question from me doesn't mean they owe a response)
- For group chats, look at whether the message is addressed to the user specifically vs. the group generally

## Related Teams tooling (not triage, but Teams-adjacent)

This skill is for *reading* unread chats. If the user asks to **create a new Teams group chat** (e.g., "create a chat with my team and X, name it Y"), do NOT extend this skill -- use the existing artifacts in `DBALeadership\`:

- **`Copy-TeamsGroupChat.ps1`** -- clones members from an existing group chat into a new one with a new topic. Best when a similar chat already exists. Uses Graph API via `Start-GraphSession.ps1`; requires `Chat.ReadWrite` scope.
- **`DBAChat_CreateGroupChat.md`** -- Graph Explorer recipe showing the exact `POST /v1.0/chats` body for a group chat (chatType=group, topic, members by AAD object ID with `aadUserConversationMember` and `user@odata.bind`). Use as the template when writing a from-scratch creation script.

**Attachment caveat:** Graph API cannot attach a local file directly to a chat -- the file must first be uploaded to OneDrive/SharePoint, then referenced in a chat message. Often easier to create the empty chat via script and drag-drop attachments in the Teams client manually.

**Roster source of truth: the manager app DB**

Canonical roster lives in `DBALeadership\Management\app\data\dba_management.db`, table `people`. The .md files (`Team.md`, `TeamEmails.md`) are derived/secondary and will drift -- prefer the DB.

Key columns: `id, name, email, region, manager_id (self-ref FK), is_active`. Jeremy is `id=14`; his manager Justin Workman is `id=23`.

Queries for "my team":
- Direct reports only (13 DBAs): `SELECT name, email FROM people WHERE manager_id = 14 AND is_active = 1 ORDER BY name`
- **"My team" (what user means when saying it conversationally)** -- direct reports + manager: `SELECT name, email FROM people WHERE (manager_id = 14 OR id = 23) AND is_active = 1 ORDER BY name` -> includes Justin Workman

Run via:
```powershell
cd C:\code\ClientSetup\DBALeadership\Management
python -c "import sqlite3; c=sqlite3.connect('app/data/dba_management.db'); [print(r) for r in c.execute(\"SELECT name,email FROM people WHERE (manager_id=14 OR id=23) AND is_active=1 ORDER BY name\")]"
```

If `Team.md`/`TeamEmails.md` disagree with the DB, the DB wins -- flag the drift to the user instead of silently using the .md.
