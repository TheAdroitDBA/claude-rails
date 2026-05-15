---
name: delegate-task
description: 'Delegate work using Multiplier principles and role-appropriate framing. Use when: assigning tasks, transferring ownership, scaling by empowering team, need help framing delegation message.'
argument-hint: 'Describe what needs to be delegated and to whom (or ask for recommendation)'
---

# Delegate Task Skill

Guide manager through proper delegation using Multiplier principles and role-based expectations.

## Workflow

### Step 1: Gather Context
Ask if not provided:
- **What needs to be done?** (the outcome, not the steps)
- **Who should own it?** (or help choose based on domain/role)
- **Timeline?** (when is it due)
- **Ticket system?** (ServiceNow/Jira/other, or just Teams message)

### Step 2: Load Person's Role
Read from `DBALeadership\Roles\` to understand expectations:
- **Principal**: Minimal direction, owns initiatives, defines standards
- **Lead**: Figures out "how", coordinates execution, leads workstreams
- **Senior**: Executes defined work, needs clear scope, asks questions
- **Mid-Level**: Follows documented process, needs steps + checkpoints

### Step 3: Frame Delegation by Role

#### For Principal
```
[Name] -- you own [initiative].

The objective: [High-level business outcome]

What I need from you by [DATE]:
1. Your approach (technical decisions, coordination plan, milestones)
2. Resource needs (people, budget, approvals)
3. Risk assessment (what could derail this)

You own the technical approach. I'm here if blocked at peer level or need executive buy-in. Bring recommendations, not problems.

Due: [DATE]. [Ticket/Teams reference]
```

#### For Lead
```
[Name] -- you own [workstream].

Background: [Context if needed]

Objective: [What "done" looks like]

You decide: [List the decisions they own - approach, testing, documentation, who to involve]

I'm [availability context]. [Backup person] can help if needed.

Due: [DATE]. [Ticket/Teams reference]
```

#### For Senior
```
[Name] -- you own [specific task].

Background: [Context]

Objective: [What "done" looks like]

What I need:
1. Your plan (steps, who you'll work with, where you might get stuck)
2. Questions (anything unclear about scope or success)
3. Completion update by [DATE]

I'm here if you hit blockers. [Lead name] can help during [timezone overlap]. Let me know early if something doesn't match documentation.

Due: [DATE]. [Ticket/Teams reference]
```

#### For Mid-Level
```
[Name] -- you own [task].

Background: [Context]

Objective: [What "done" looks like]

Approach:
1. [Reference doc or process]
2. [Key steps]
3. [Expected outcome]

Check in with me [when - after first step, before X, etc.]. Questions immediately if something doesn't match the doc.

I'm [availability]. [Lead name] can help if I'm unavailable.

Due: [DATE]. [Ticket/Teams reference]
```

### Step 4: Ticket/Tracking Setup

**If using ticketing system:**
Generate ticket description:
```
Title: [Clear action-oriented title]

Description:
[Current state and what needs to happen]

Deliverables:
1. [Concrete outcome 1]
2. [Concrete outcome 2]
3. [Documentation/testing as applicable]

Priority: [Level]
Due Date: [Date]
Assigned To: [Person]
```

**Ask for ticket link:** Request both ticket number (RITM/INC/CHG/etc.) AND direct link to include in final message.

**Create in Management app** (for manager tracking only):
- Title, Owner, Priority, Due Date, Ticket Number
- Notes: "Delegated [date]. [Context]"
- Status: Assigned

### Step 5: Delivery Method

**Preferred:** Teams message with ticket reference
- Conversational, allows questions
- Ticket has formal tracking
- Manager checks ticket, not person (avoids micromanaging)

**Message structure:**
```
[Name] -- you own this. Ticket RITM#. Update the ticket as you go. Questions, ping me.
```

**IMPORTANT:** 
- Provide message in code block with plain "RITM0104675" text
- User will paste into Word, add hyperlink to the RITM number, then copy from Word to Teams (preserves link formatting)
- OR use automated sending via PowerShell script with HTML contentType and `<a href="">` tags

**Token Management Options:**
1. **Manual (Graph Explorer)**: Copy token from https://developer.microsoft.com/en-us/graph/graph-explorer → Access token tab → Paste into `.graphtoken`. Expires after ~1 hour.
2. **Auto-refresh (OAuth)**: Use `Get-GraphToken.ps1` with Azure AD app registration. Tokens auto-refresh for ~90 days. One-time setup: register app, add Chat.ReadWrite + User.Read permissions, run `.\Get-GraphToken.ps1 -Initialize`.

**Graph API Limitation:** Personal "(You)" chats don't appear in /me/chats API. For testing, create a Teams meeting with yourself and use "Chat with participants" to create an accessible chat.

**Alternative if no ticket:** Full delegation in Teams message, create Management app task for tracking

## Key Principles

### Multiplier Investor Discipline
- **Transfer ownership, not tasks**: Give 51% of the vote
- **Define outcome, let them define approach**: Don't prescribe "how" unless Mid-Level
- **Invest resources**: Make yourself available for blockers, provide backup support
- **Let them struggle**: Don't rescue prematurely, growth happens through problem-solving

### Role-Based Differentiation
- **Principal/Lead**: More freedom, fewer checkpoints, outcome-focused
- **Senior**: Clear scope, invitation for questions, support when stuck
- **Mid-Level**: Steps provided, tighter checkpoints, scaffolding while learning

### Communication Balance
- **Assertive, not aggressive**: State facts, transfer ownership clearly
- **Friendly, not soft**: Expectations are clear, support is genuine
- **Context without apology**: "I haven't had capacity" not "I'm sorry I failed"

## Red Flags (What NOT to Do)

❌ **Don't give Lead-level framing to Mid-Level** → They'll get stuck, won't ask for help, task fails
❌ **Don't give Mid-Level steps to Lead** → Diminishes them, they stop thinking
❌ **Don't set 3+ checkpoints** → That's micromanaging disguised as delegation
❌ **Don't apologize for delegating** → "Sorry to burden you" undermines their ownership
❌ **Don't delegate and disappear** → "Figure it out" without availability/support is abandonment
❌ **Don't delegate urgent items while on vacation** → Unless emergency, push due date to after return

## Examples

### Good Delegation (Lead)
> "Manny -- you own the C45 failover investigation. Objective: Determine root cause and recommend prevention steps. You decide investigation approach, who to involve, timeline. I'm on vacation 4/27-5/1, Godwin can help if blocked. Due 5/5. Ticket RITM0103456."

**Why it works:** Clear ownership, outcome defined, decisions transferred, support identified, timeline reasonable.

### Bad Delegation (Too prescriptive for Lead)
> "Manny -- investigate C45 failover. Steps: 1) Pull DMV data from 2pm-4pm window, 2) Check blocking chains, 3) Review app logs with NOC, 4) Document findings in this format. Report back Tuesday with status."

**Why it fails:** No ownership transferred, all decisions made for him, treats Lead like Mid-Level, status check is micromanaging.

### Good Stretch Assignment (Mid-Level)
> "Whitney -- you own getting dal-indbw02 witness configured. Background: I said I'd handle permissions but haven't had capacity. Objective: DBA team has access, witnesses split, tested, documented. You decide which pairs to move, how to test. Check in after you get access, we'll confirm approach. I'm on vacation 4/27-5/1, Shawn can help. Due 5/5. Ticket RITM0103457."

**Why it works:** Gives context, transfers ownership, provides decision freedom, has one checkpoint (not three), identifies backup, realistic timeline.

## Success Metrics

**You delegated well if:**
- ✓ They come back with a plan, not questions about what to do
- ✓ They ask clarifying questions about outcome/scope, not "how should I do this?"
- ✓ They take action without needing permission for every step
- ✓ They update the ticket, not you (system working as designed)
- ✓ They ask for help when truly stuck, not when slightly uncertain

**You need to adjust if:**
- ⚠ They freeze, don't start, too overwhelmed → Gave too much freedom for their level
- ⚠ They ask "how do I do this?" every step → Gave Lead framing to Senior/Mid-Level
- ⚠ They execute without thinking → Gave too many steps, no ownership transferred
- ⚠ They go silent and resurface at deadline incomplete → No checkpoints, no backup support identified

## Output Format

Provide:
1. ServiceNow ticket description (for user to create ticket)
2. Wait for user to provide ticket number and link
3. Complete Teams message ready to send (with ticket number + link substituted)

**IMPORTANT:** Put the final Teams message in a code block (```text) so user can copy it cleanly without markdown formatting issues.

Ask for confirmation before delivery if user wants to review/adjust tone.
