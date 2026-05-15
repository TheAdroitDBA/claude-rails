---
name: triage-email
description: 'Inbox-zero email triage via local Outlook COM. Handles the alert backlog first (export + ingest into manager-app dashboard + hard-delete source emails), then auto-cleans remaining noise, exports unread, classifies into dispositions (flag/followup/archive/keep/accept), and executes in batch. Use when: reading unread emails, dumping inbox, triaging email, classifying messages, checking what emails need attention, cleaning inbox, archiving noise emails, getting to inbox zero, dealing with alert noise.'
---

# Read and Manage Emails

Pull the alert backlog into the dashboard and delete the source emails, then auto-clean other noise, export remaining, classify every email into a disposition, execute dispositions in batch. Goal: inbox zero after every session.

> **ACTIVE BACKEND: Outlook COM (no auth, no tokens).** This skill uses the locally
> running Outlook desktop client via COM. There is no token to refresh.
>
> **Rollback to Graph backend** (one-time, when MSAL admin approval lands -- see
> `memory/nice_tenant_graph_consent.md`):
> 1. Run `DBALeadership\Get-GraphToken.ps1` once to seed the MSAL refresh-token cache.
> 2. In this file, replace every `Export-UnreadEmails-COM.ps1` -> `Export-UnreadEmails.ps1`
>    and every `Manage-Mailbox-COM.ps1` -> `Manage-Mailbox.ps1`.
> 3. Update the Graph scripts to call `& "$PSScriptRoot\Get-GraphToken.ps1"` instead
>    of reading `.graphtoken` (rewire pending; tracked separately).
>
> The COM scripts only implement the AutoClean + Execute modes the triage flow needs.
> Other modes (Flag/Sort/Unsubscribe/Analysis/TeamRoute) remain Graph-only.

## Prerequisites

- **Working Directory**: `c:\code\ClientSetup\DBALeadership\`
- Outlook desktop installed and signed in with the target profile (Outlook does not need to be the foreground window)
- Alert pipeline scripts: `DBALeadership\Export-AlertHistory.ps1`, `DBALeadership\Delete-AlertsByEntryId.ps1`, `DBALeadership\Management\app\scripts\ingest_alert_csv.py`
- Email triage scripts: `DBALeadership\Export-UnreadEmails-COM.ps1`, `DBALeadership\Manage-Mailbox-COM.ps1`
- Pipeline reference: `DBALeadership\Export-AlertHistory.flow.md`

## Procedure

### Step 1: (Removed -- no token refresh needed)

The COM backend uses your already-signed-in Outlook profile. Skip straight to Step 2.

---

### Step 2: Handle the alert backlog (bulk)

**Run first. Alerts (Inbox\Alerts subtree) are the bulk of every triage session -- thousands of items per day. Pull them into the manager-app dashboard and hard-delete the source emails before touching anything else.**

This step is unconditional: run it every session.

**Step 2a: Export alerts to CSV + summary**

```powershell
cd c:\code\ClientSetup\DBALeadership
.\Export-AlertHistory.ps1
```

Outputs two timestamped files into `Management\Logs\`:

- `AlertHistory_<yyyyMMdd_HHmm>.csv` -- one row per alert email (durable record; includes `EntryID`)
- `AlertHistory_<yyyyMMdd_HHmm>.md` -- aggregate summary (by family, by sender, last 14 days, data quality)

Echo the totals from the script's "Captured N items, M errors" line so the user sees the volume before deletion.

**Step 2b: Ingest the CSV into the manager-app `alerts` table**

```powershell
Management\app\.venv\Scripts\python.exe Management\app\scripts\ingest_alert_csv.py
```

Use the manager-app venv's python explicitly -- the global `python` on this box is 3.13 without SQLAlchemy and will ModuleNotFoundError. Any script under `Management\app\` has the same requirement.

Idempotent on `entry_id` -- re-running against previously ingested CSVs is a no-op. The script prints `inserted N, skipped M` per file. The dashboard at `/api/alerts/*` reflects the new rows immediately (SQLite, no app restart needed).

**Step 2c: Hard-delete the alert emails from the mailbox**

```powershell
.\Delete-AlertsByEntryId.ps1 -AlertOnly -Live
```

- Operates on the most recent `AlertHistory_*.csv` automatically.
- `-AlertOnly` filters to alert families (tbad, ignite, dba-system, unknown-no-sender, incident-platform) so non-alert rows in the CSV are never touched.
- `-Live` is required to execute; without it the script dry-runs.
- Per-item try/catch; reports `deleted / missing / failed` at the end.

**The CSV is the durable record.** Once Step 2c completes, the source emails are gone (not recoverable from Deleted Items). Any later re-ingest or re-analysis runs from the CSV in `Management\Logs\`.

**If something looks wrong** -- volume way higher than usual, unfamiliar families showing up, or scan errors above zero -- stop and review the `.md` summary before running 2c. Replace `-Live` with `-WhatIf` to dry-run the delete.

---

### Step 3: Auto-Clean Noise Emails

**Run automatically before triage -- clears internal noise first**

**Direct execution:**
```powershell
cd c:\code\ClientSetup\DBALeadership
.\Manage-Mailbox-COM.ps1 -Mode AutoClean
```

> Add `-WhatIf` to preview matches without moving anything.

**What Gets Cleaned**

Auto-clean rules match internal noise emails:

| Category | Rule Examples |
|----------|--------------|
| Calendar responses | Accepted:, Declined:, Tentative:, Canceled: |
| System notifications | noreply, jira@, servicenow, pagerduty, github.com, azure-noreply, MicrosoftTeams, MSServiceAlerts, ignite_ |
| Auto-replies / OOO | Subject contains "Automatic reply:" |
| Sprint lifecycle | Sprint Closure Reminder, "has been closed and ... started" |
| Training | From Dojo@ (silent archive); subject "Mandatory Training is Due" -> flag-keep so deadline misses stay visible |
| Internal announcements | LifeatSandy, NiCE to Know, FacilitiesSLC, Campus Services, Americas.Benefits, Happy Spring, Global Community Month, All-Hands, Life@NICE, Leadership@NICE, cloudopsannouncements |
| CSOC advisories | From CSOC (security advisories are FYI) |
| Recurring alerts | UKLOT-Bad |
| Deployment confirmations | Subject matches Deploy/Deployment patterns |
| ServiceNow approvals | nicensc@service-now.com, satmetrix surveys |
| Vendor notifications | Microsoft (Stephanie Petrakos), Visual Studio, GitHub PAT, SolarWinds security bulletins |
| Group joins | "You've joined the X group", PE AI Team, PEAK Members, Teams join notifications |
| Scorecard reminders | "fill out your scorecard" |
| FYI project chains | OKTA SSO Implementation, shared Retrospective docs |
| Marketing webinars | Sunset Learning, Coralogix, `[MARKETING]` subject prefix |
| HR events | Communication training, mission announcements |
| Patent invites | Annual submission invites from Moty Cory |
| ECAB follow-ups | Change manager follow-ups after ECAB approval completion |

**Keep patterns** (exempt from auto-clean): ESSP, RSU

**Behavior:**
1. Scans recent inbox items (up to 500 by default; tune with `-MaxScan`)
2. Matches against 45+ auto-clean rules (kept in sync with the Graph version manually)
3. Marks matched emails as read + moves to the built-in Archive folder
4. No confirmation prompt -- runs straight through (use `-WhatIf` to dry-run first)

---

### Step 4: Export Remaining Unread Emails

**After auto-clean, dump what's left for triage**

```powershell
.\Export-UnreadEmails-COM.ps1
```

**Optional Parameters:**

| Param | Purpose | Example |
|-------|---------|---------|
| `-Top` | Max emails to fetch (default 100) | `-Top 20` |
| `-From` | Filter by sender address | `-From "manager@nice.com"` |
| `-Subject` | Filter by subject keyword | `-Subject "outage"` |
| `-OutFile` | Custom output path | `-OutFile "C:\my\path.md"` |

**Output:**
- Markdown: `DBALeadership\Management\Transcripts\UnreadEmails.md`
- Sidecar JSON: `UnreadEmails.md.entryids.json` -- maps each `[N]` index in the
  markdown to the underlying Outlook EntryID. Step 5.5 reads this sidecar to
  apply dispositions reliably (no fragile subject lookup).

**Export includes:**
- **Summary table** -- quick scan of all emails (sender, subject, priority, time)
- **Full details** -- each email with headers and body (truncated at 2000 chars), grouped by date

---

### Step 5: Classify Every Email (Dispositions)

**Every email must get exactly one disposition. Triage is not complete until all are classified.**

Read the exported dump and assign each email one of these dispositions:

| Disposition | Meaning | Inbox result |
|-------------|---------|-------------|
| `flag` | Needs the user's direct response | Flagged + archived (visible in Outlook Flagged Mail) |
| `flag-keep` | Critical action item the user must keep visible in inbox until it's done | Flagged + STAYS in inbox (visible at the top of triage queue) |
| `followup` | Delegated, waiting on someone else | Moved to top-level `2-Waiting` folder (the user's "blocked on" list) |
| `archive` | FYI, monitor, noise, closed loops, company broadcasts, thank-you replies | Marked read + archived |
| `keep` | User is actively working on it right now | Stays in inbox (max 2 per session) |
| `accept` | Meeting invite, no action beyond attending | Accept silently (no response sent) + archive |
| `phish` | Suspected phishing per the 4-point external-email screen below | Moved to `Phishing-Reported` folder + flag-keep so the user clicks the Outlook "Report Phishing" button to forward to NiCE security |

**Phishing screen (run on every external email):**

Run this 4-point check before assigning `archive` to any externally-sourced email. If two or more points trip, classify as `phish` (not `archive`).

1. **Sender domain integrity** -- Does the SMTP domain match the claimed organization, with no lookalike substitutions (rediis.com, n1ce.com, hyphens-where-none-exist.com)? Does the display name match the SMTP address (no "Justin Workman" coming from `justin.workman@gmail.com`)? Check the underlying `From:` SMTP, not just the rendered display name.
2. **Urgency + auth ask** -- Does it combine pressure ("urgent", "action required", "account suspended", "verify within 24h") with a request for credentials, MFA approval, payment, gift cards, wire transfers, or a password change? Either alone is mild; together is a phishing fingerprint.
3. **Link / attachment shape** -- Are links going to URL shorteners (bit.ly, t.co, tinyurl), lookalike domains, or "click to view secure document" pages? Are there unexpected attachments -- especially `.docm`, `.xlsm`, `.html`, or password-protected `.zip`? Real vendor mail uses the vendor's own tracking subdomain (e.g. `engage.redis.com/api/mailings/click/`); shorteners hiding the destination are a red flag.
4. **Role / context mismatch** -- Does the email impersonate IT, HR, payroll, finance, or an exec while asking you to bypass policy ("don't loop in IT", "keep this confidential")? Does the greeting or context fail to match your actual role at the company? Generic "Dear customer" from what looks like internal-branded mail is a tell.

External marketing/sales outreach that passes all four points is just noise -- `archive` it. Internal emails (`@nice.com`, `@niceincontact.com`, or X500 internal addresses) skip the screen unless the display name is impersonating an internal person but the SMTP route is external.

**Phish disposition handling:** the executor (`Manage-Mailbox-COM.ps1`) does not yet support the `phish` action natively. Until it does, treat `phish` items as a manual step:
- Write them as `flag-keep` in `dispositions.json` so they stay visible
- After Step 5.5b completes, call out each phish item by index in chat and tell the user to click the Outlook "Report Phishing" button on each one
- (Backlog: extend the executor to move to `Phishing-Reported` and forward via the security mailbox automatically.)

**Classification rules:**
- "Monitor" is not a valid inbox state -- if you'd call it "monitor," it's `archive`
- `followup` means delegated and waiting on someone else (lands in `2-Waiting`). If you're not actually blocked on someone, it's not followup.
- "Deal with later" / "I owe a response" = `flag` (visible in Flagged Mail; lives in Archive)
- Company-wide announcements (CEO notes, earnings, HR promos, training) = `archive`
- Thank-you / acknowledgment replies with no open question = `archive`
- Meeting invites with no action beyond attending = `accept`
- Approval requests addressed to the user = `flag`
- Threads where user is CC'd and others own the response = `archive` (unless user spots something wrong)
- **New-hire on-boarding tasks (`On-Boarding task HRT##### has been assigned to you` from NSC):** these are critical to leadership success and must stay visible until the follow-on ServiceNow tickets are filed. Use `flag-keep` so the email is flagged AND stays in the inbox. The AutoClean rule already handles these automatically (Category=Onboarding, Action=flag-keep) -- they should not appear in the manual triage export unless AutoClean missed them.
- **On-call pay / PTO requests from SOV (UK/EU/AUS) or PH direct reports:** Jeremy is the working manager and must approve UNLESS a matrix manager has already replied with approval ("Applied", "Approved", etc.) in the same thread.
  - Matrix manager already replied -> `archive` (loop closed)
  - No matrix manager reply yet -> `flag` (Jeremy still needs to approve)
  - Known matrix managers: Alex Noori (SOV/PH on-call pay), Levi Galo (NOC night-shift PTO)
  - Subjects to watch: "On-Call Week Ending M/D/YYYY", "PTO ... Night Shift", "Approval Request- HRC######" (USA-only, auto-cleaned)
  - Source memory: `oncall_pay_approval_routing.md`

**Present the classification to the user as a table:**

```
| # | Subject (short) | Disposition | Reason |
|---|-----------------|-------------|--------|
| 1 | Energy Australia | archive     | CC'd, Alfredo owns response |
| 2 | Offer approval   | flag        | Needs direct approval |
...
```

Ask the user to confirm or adjust before executing.

---

### Step 5.5: Execute Dispositions (Batch)

After the user confirms the classification, write a JSON dispositions file and run the executor. The executor reads the EntryID sidecar produced by the export, so lookup is exact -- no fragile subject matching, no NOT FOUND errors.

**Step 5.5a: Write the dispositions JSON**

Create `DBALeadership\Management\Transcripts\dispositions.json` with one entry per email:

```json
[
  { "Index": 1, "Action": "archive" },
  { "Index": 2, "Action": "flag" },
  { "Index": 3, "Action": "accept" },
  { "Index": 4, "Action": "keep" }
]
```

The `Index` is the `[N]` number from the markdown export. Valid `Action` values:

| Action     | Effect |
|------------|--------|
| `flag`     | Mark for follow-up + move to Archive |
| `flag-keep`| Mark for follow-up + STAY in inbox (use for critical action items the user wants to see every time they open Outlook -- e.g. new-hire onboarding tickets) |
| `followup` | Move to top-level `2-Waiting` folder (the user's "blocked on" list). Falls back to flag+archive if `2-Waiting` doesn't exist. |
| `archive`  | Mark read + move to Archive |
| `accept`   | Silently accept the meeting (calendar updated, no response sent), request moved to Deleted Items |
| `keep`     | No-op (stays in inbox; max 2 per session) |

**Step 5.5b: Run the executor**

```powershell
.\Manage-Mailbox-COM.ps1 -Mode Execute -DispositionsFile .\Management\Transcripts\dispositions.json
```

Add `-WhatIf` first if you want a dry run.

**Per-action notes:**
- `followup`: lands in `2-Waiting`. Use this only when you have actually delegated and are waiting on someone -- not as a "deal with later" bucket. (For "deal with later" use `flag`.)
- `keep`: skip entirely (the executor honors this and leaves the email untouched).

**Completion check:** After executing, the inbox should contain only `keep` emails (0-2). If the user had no `keep` items, inbox is at zero. The executor reports counts per action plus any `missing` (EntryID lookup failed -- usually means the email was already moved) or `failed` items.

---

### Step 6: Clean Up

After you are done using the export, wipe the dump file clean:

```powershell
Set-Content -Path "Management\Transcripts\UnreadEmails.md" -Value "" -Encoding UTF8
```

The empty file stays in the repo. The content is ephemeral -- wipe it after every triage session.

The alert CSV in `Management\Logs\` is durable -- do NOT wipe it. The dashboard reads from the SQLite table, but the CSV is the source of truth if the table is ever rebuilt.

---

## Customizing Auto-Clean Rules

Edit the `$AutoCleanRules` array in `Manage-Mailbox-COM.ps1`. Each rule has:
- `Field`: `"from"` or `"subject"`
- `Contains`: exact substring match (escaped for regex)
- `Pattern`: regex match (use instead of Contains for complex patterns)

**Example:**
```powershell
@{ Field = "from"; Contains = "noreply@example.com" },
@{ Field = "subject"; Pattern = "^\[JIRA\]" }
```

> The Graph version (`Manage-Mailbox.ps1`) keeps its own copy of the rules.
> When you edit one, mirror the change to the other so the rollback path stays
> equivalent.

## Notes

- No `.graphtoken` -- COM uses your signed-in Outlook profile directly
- The `UnreadEmails.md` and `UnreadEmails.md.entryids.json` files are ephemeral; wipe after each session
- `AlertHistory_*.csv` files in `Management\Logs\` are durable; leave them in place
- Email bodies longer than 2000 characters are truncated to keep the dump scannable
- Emails are sorted oldest-first for chronological reading
- AutoClean runs straight through without prompting -- use `-WhatIf` to preview
- Outlook desktop must be installed; if it is closed when the script runs, COM starts it (the started instance stays open)
- Feature doc: `DBALeadership/email-triage.feature.md`
- Alert pipeline: `DBALeadership/Export-AlertHistory.flow.md`
- Goal: inbox zero after every triage session -- every email gets a disposition
