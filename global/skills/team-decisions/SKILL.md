---
name: team-decisions
description: 'DBA team decision tracking and delegation framework. Use when: logging decisions, checking ownership, determining escalation, updating the decision matrix, onboarding someone to a domain, reducing decision fatigue.'
argument-hint: 'Describe the decision situation or what you need to track'
---

# Team Decision Framework

System for tracking decisions, defining ownership, and reducing escalation bottlenecks on a 17-person DBA team.

## Key Files

All files live in `DBALeadership/Decisions/`:

| File | Purpose | When to Use |
|------|---------|-------------|
| [DecisionLog.md](file:///c:/code/ClientSetup/DBALeadership/Decisions/DecisionLog.md) | Running log of precedent-setting decisions | After making a call others will reference |
| [OwnershipMatrix.md](file:///c:/code/ClientSetup/DBALeadership/Decisions/OwnershipMatrix.md) | Who owns what domains and decisions | When assigning ownership or checking authority |
| [EscalationCriteria.md](file:///c:/code/ClientSetup/DBALeadership/Decisions/EscalationCriteria.md) | When to escalate vs decide yourself | When unsure whether to escalate |

## Quick Reference

### The 4-Question Escalation Test

1. **Reversible?** Can undo within 24 hours → lean toward deciding
2. **Your domain?** You own this area → you decide
3. **Sets precedent?** Others will reference this → escalate first
4. **Already decided?** Check DecisionLog.md → follow the existing call

**If reversible + your domain + no precedent → make the call.**

### Adding a Decision to the Log

```markdown
### YYYY-MM-DD: [Short Title]

**Decision:** [What we decided]

**Context:** [Why this came up]

**Reasoning:** [Why we decided this way]

**Owner:** [Who made the call]

**Related:** [RITM/INC/ticket number if applicable]
```

### Decision Authority Levels

| Level | Criteria | Action |
|-------|----------|--------|
| **Green** | Reversible, your domain, follows patterns | Decide yourself |
| **Yellow** | Reversible but effort, minor cross-domain | Decide, inform Jeremy after |
| **Red** | Irreversible, sets precedent, commits team | Escalate before deciding |

## Common Workflows

### Someone asks "Can we do X for this customer?"

1. Check DecisionLog.md — have we decided this before?
2. If yes → point them to the decision
3. If no → run the 4-question test
4. If you decide → add to log if it sets precedent

### Assigning ownership of a new domain

1. Update OwnershipMatrix.md with:
   - Domain name
   - Owner name
   - What they can decide autonomously
   - When they should escalate
2. Announce in team channel
3. They now own those decisions

### After making a precedent-setting decision

1. Add entry to DecisionLog.md (newest at top)
2. Post in team channel: "FYI — decided X because Y"
3. Done — don't wait for validation

### Quarterly review

1. Review DecisionLog.md — any decisions to revisit?
2. Review OwnershipMatrix.md — ownership still accurate?
3. Ask: "What decisions are still coming to me that shouldn't?"

## Multiplier Principle

The goal is **80% of decisions never reach the manager**. This happens when:

- Ownership is clear (people know what they own)
- Precedents are documented (people can reference past decisions)
- Escalation criteria are explicit (people know when to ask)

When someone brings you a decision, default response:
> "You've thought this through. What do you want to do?"

Then back them up.

## Coaching Prompts

When helping someone decide:
- "What's the risk if we do this?"
- "What's the maintenance burden?"
- "What's your gut telling you?"
- "Have we done this before? What happened?"

When they make a call:
- "Sounds like you know what you want to do. Go with it — I'll back you up."

## Files to Update Together

When a decision affects team process:
1. DecisionLog.md — document the decision
2. OwnershipMatrix.md — if ownership changed
3. Team channel — inform everyone

Don't create bureaucracy. Update files only when decisions set precedent or ownership changes.
