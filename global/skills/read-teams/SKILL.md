---
name: read-teams
description: 'Export Teams chat history via Microsoft Graph API. Use when: exporting Teams chats, reading Teams conversations, pulling chat messages, refreshing Graph token, extracting Teams group chat history, monitoring 1:1 chats with stakeholders.'
---

# Read Teams Chat History

Export Teams chat to markdown using Microsoft Graph API.

## Tools Available

### Monitor-TeamsChats.ps1 (Recommended for Daily Monitoring)
Exports recent 1:1 messages from configured stakeholders (Justin + team leads).

**Use when:**
- Daily morning routine to capture overnight requests
- Monitoring multiple key people systematically
- Need organized exports by person

**Location:** `DBALeadership\Monitor-TeamsChats.ps1`

**Usage:**
```powershell
cd c:\code\ClientSetup\DBALeadership
.\Monitor-TeamsChats.ps1                 # Last 7 days (default)
.\Monitor-TeamsChats.ps1 -Days 3         # Last 3 days only
```

**First Time Setup:**
1. Copy `.graphtoken` from Graph Explorer (same as below)
2. Edit `monitor-chats.json` to configure people to monitor
3. Run the script - exports to `Management\Transcripts\`

**Output:** One markdown file per person: `[Name]_2026-04-21.md`

---

### Export-TeamsChatHistory.ps1 (For Specific Conversations)
Exports a single group chat or conversation by searching/selecting interactively.

**Use when:**
- Need to export a specific meeting chat or discussion
- One-off export of a group conversation
- Don't need systematic daily monitoring
- Searching message content across all chats

## Prerequisites

- Token file: `DBALeadership\.graphtoken`
- Export script: `DBALeadership\Export-TeamsChatHistory.ps1`

## Procedure

### Step 1: Refresh the Graph Token

1. Open Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer
2. Sign in with your Microsoft account
3. Click **Access token** tab (left sidebar, below the query box)
4. Copy the entire token
5. Paste it into `DBALeadership\.graphtoken` (replace the old token entirely)

### Step 2: Run the Export

```powershell
cd c:\code\ClientSetup\DBALeadership
.\Export-TeamsChatHistory.ps1 -SearchTopic "<search term>"
```

**Parameters:**
- `-SearchTopic` -- filters chats by topic name or member names (interactive picker)
- `-ChatId` -- skips search if you already know the chat ID (e.g. `19:abc...@thread.v2`)
- `-ChatUrl` -- accepts a Teams chat URL and extracts the chat ID automatically
- `-SearchContent` -- searches message content across ALL chats (uses Graph Search API)
- `-OutFile` -- overrides the default output path

**Common patterns:**
```powershell
# Search by member name
.\Export-TeamsChatHistory.ps1 -SearchTopic "Noman"

# Paste a Teams chat link directly
.\Export-TeamsChatHistory.ps1 -ChatUrl "https://teams.microsoft.com/l/chat/19:abc...@thread.v2/conversations?context=..."

# Search message content across all chats
.\Export-TeamsChatHistory.ps1 -SearchContent "rollback"

# Export a known chat by ID
.\Export-TeamsChatHistory.ps1 -ChatId "19:abc...@thread.v2"
```

### AI Usage: When the User Provides a Teams URL

Extract the chat ID from the URL (the `19:...@thread.v2` part, URL-decoded) and pass it via `-ChatUrl`:
```powershell
.\Export-TeamsChatHistory.ps1 -ChatUrl "<pasted URL>"
```

### AI Usage: When the User Says "Find the Chat Where X Said Y"

Use `-SearchContent` to search message content:
```powershell
.\Export-TeamsChatHistory.ps1 -SearchContent "<keywords>"
```

This uses the Microsoft Graph Search API (`/search/query` with `chatMessage` entity type). Requires `Chat.Read` permission.

## People Lookup

All team members are in the Management DB with emails:
```python
import sqlite3
conn = sqlite3.connect(r'c:\code\ClientSetup\DBALeadership\Management\app\data\dba_management.db')
cur = conn.cursor()
cur.execute("SELECT id, name, email FROM people WHERE is_active = 1 ORDER BY name")
```
Use this to resolve names from chat messages to Management DB person IDs when creating tasks or logging observations.

## Reading a Specific Team Member's Chat

All team members are configured in `DBALeadership\monitor-chats.json` with their emails. When the user says "read Noman's chat" or "what did Whitney say":

1. **Use Monitor-TeamsChats.ps1** -- it finds 1:1 chats by matching the member's email
   ```powershell
   cd c:\code\ClientSetup\DBALeadership
   .\Monitor-TeamsChats.ps1 -Days 7
   ```
   This exports all team members' recent messages to `Management\Transcripts\[Name]_YYYY-MM-DD.md`

2. **Read the exported file** for the specific person:
   ```
   DBALeadership\Management\Transcripts\Noman Rasheed_2026-04-23.md
   ```

3. **Or use Export-TeamsChatHistory.ps1** with `-SearchTopic` to find their chat:
   ```powershell
   .\Export-TeamsChatHistory.ps1 -SearchTopic "Noman"
   ```

### Team Member Quick Reference

| Name | Email | DB ID |
|------|-------|-------|
| Adrian Griffin | adrian.griffin@nice.com | 7 |
| Allen Atienza | allen.atienza@nice.com | 10 |
| Aristotle Pagulayan | aristotle.pagulayan@nice.com | 5 |
| Carter Cordingly | carter.cordingley@nice.com | 12 |
| Cretu Laurentiu | cretu.laurentiu@nice.com | 11 |
| Edgar Bayron | edgar.bayron@nice.com | 6 |
| Emmanuel De'Mzee | emmanuel.demzee@nice.com | 3 |
| Godwin Izekor | godwin.izekor@nice.com | 9 |
| Justin Workman | justin.workman@nice.com | 23 |
| Louie De La Paz | louie.delapaz@nice.com | 2 |
| Marvin Sy | marvin.sy@nice.com | 4 |
| Noman Rasheed | Noman.Rasheed@nice.com | 22 |
| Perry Whittle | perry.whittle@nice.com | 8 |
| Shawn Noker | shawn.noker@nice.com | 1 |
| Whitney Cahoon | whitney.cahoon@nice.com | 13 |

### Step 3: Output

Messages export to markdown, grouped by date with sender and timestamp.

## Output Organization

All Teams exports live under `DBALeadership\Management\Transcripts\` in subdirectories by type:

```
Transcripts/
  chats/                # Monitor-TeamsChats.ps1 structured 1:1 exports
    attachments/
      {FirstLast}/      # Downloaded files from that person's chat
  meetings/             # .docx meeting transcripts (weekly reviews, etc.)
  adhoc/                # One-off Export-TeamsChatHistory.ps1 exports
```

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Monitor exports | `{FirstLast}_{YYYY-MM-DD}.md` | `NomanRasheed_2026-04-23.md` |
| Meeting transcripts | Original .docx filename | `DBA Ops weekly review 4-14-26.docx` |
| Ad-hoc exports | `{Topic}_{YYYY-MM-DD}.md` | `IngressEgressChannel_2026-04-22.md` |

### Rules
- Monitor exports go to `chats/` -- one file per person per run, overwritten on re-export same day
- Meeting transcripts go to `meetings/` -- never rename, keep original filename
- Ad-hoc exports go to `adhoc/` -- include a descriptive topic in the filename
- Do NOT put emails, unrelated documents, or scratch files in Transcripts

### After Running Monitor
The latest 1:1 chat for each person is always at:
```
Transcripts/chats/{FirstLast}_{YYYY-MM-DD}.md
```

### Note on Attachments
Teams file attachments (images, .docx, .xlsx) are NOT captured by the Graph API message export. If a message references "see attached" or "find it in below document," the file must be downloaded manually from Teams or requested via email/ticket.

Once downloaded, store in the person's attachment folder:
```
Transcripts/chats/attachments/{FirstLast}/{filename}
```
Example: `Transcripts/chats/attachments/NomanRasheed/C45_Failover_Investigation.docx`

## Chats vs Channel Threads

Teams has two distinct message types with different URLs, APIs, and tooling.

### How to tell them apart

| Signal | Chat | Channel Thread |
|--------|------|----------------|
| URL contains | `@thread.v2` | `@thread.skype` |
| URL has `groupId` | No | Yes (the team ID) |
| URL has `channelName` | No | Yes |
| URL has `parentMessageId` | No | Yes |
| Example | `19:abc...@thread.v2` | `19:d6b...@thread.skype/1776818425933` |

### Chat (`@thread.v2`) -- use the script

`Export-TeamsChatHistory.ps1` handles these. Pass `-ChatUrl`, `-ChatId`, or `-SearchContent`.

```powershell
.\Export-TeamsChatHistory.ps1 -ChatUrl "https://teams.microsoft.com/l/chat/19:abc...@thread.v2/..."
```

### Channel Thread (`@thread.skype`) -- use Graph API directly

The export script does NOT support channel threads. Use the Graph API manually.

**Extract IDs from the URL:**
- `groupId` = team ID (GUID in the query string)
- `19:...@thread.skype` = channel ID
- `parentMessageId` (or the number after the channel ID in the path) = root message ID

**Read the root message:**
```powershell
$token = (Get-Content "c:\code\ClientSetup\DBALeadership\.graphtoken" -Raw).Trim()
$h = @{ Authorization = "Bearer $token" }
$teamId = "<groupId from URL>"
$channelId = "19:...@thread.skype"
$messageId = "<parentMessageId from URL>"

$uri = "https://graph.microsoft.com/v1.0/teams/$teamId/channels/$channelId/messages/$messageId"
$root = Invoke-RestMethod -Uri $uri -Headers $h
"$($root.from.user.displayName): $(($root.body.content -replace '<[^>]+>','') -replace '&nbsp;',' ')"
```

**Read all replies:**
```powershell
$repliesUri = "https://graph.microsoft.com/v1.0/teams/$teamId/channels/$channelId/messages/$messageId/replies?`$top=50"
$replies = Invoke-RestMethod -Uri $repliesUri -Headers $h
$replies.value | Sort-Object createdDateTime | ForEach-Object {
    "$($_.createdDateTime) | $($_.from.user.displayName):"
    ($_.body.content -replace '<[^>]+>','') -replace '&nbsp;',' '
    "---"
}
```

**Required permissions:** `ChannelMessage.Read.All` (in addition to `Chat.Read` for chats)

### Common mistake

Passing a channel thread URL to `Export-TeamsChatHistory.ps1 -ChatUrl`. The script regex expects `@thread.v2` and will error with "Could not extract a chat ID." When you see `@thread.skype` in the URL, skip the script and go straight to the Graph API.

## Token Expiration

Graph Explorer tokens expire after ~1 hour. If the script errors with 401, repeat Step 1.

## Notes

- The `.graphtoken` file is gitignored -- safe to keep locally
- Ensure `Chat.Read` permission is consented in Graph Explorer (Modify Permissions tab)
- For channel threads, also consent `ChannelMessage.Read.All`
