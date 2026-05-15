# Feature: Team Decisions Skill

## What It Does

`/team-decisions` tracks DBA team decisions, defines ownership domains, and reduces escalation bottlenecks. Applies a 4-Question Escalation Test to any decision, logs precedent-setting calls to `DecisionLog.md`, maintains `OwnershipMatrix.md`, and coaches toward the Multiplier goal of 80% of decisions never reaching the manager.

## Concern

**domain.** DBA leadership skill for managing decision authority on the NICE CXone DBA team. Lives in the global pool for machine portability; references `DBALeadership/Decisions/` files.

## Success Criteria

1. Applies the 4-Question Escalation Test for any decision presented: reversible? your domain? sets precedent? already decided? Outcome maps to Green / Yellow / Red authority level.
2. New precedent-setting decisions are logged to `DBALeadership/Decisions/DecisionLog.md` using the prescribed format (date header, Decision, Context, Reasoning, Owner, Related ticket).
3. Domain ownership assignments are recorded in `OwnershipMatrix.md` when ownership is established or transferred.
4. When escalation uncertainty exists, `EscalationCriteria.md` is the reference consulted, not ad-hoc judgment.
5. Default coaching response returns ownership to the team member: "You've thought this through. What do you want to do?" then backs them up.
6. Quarterly review workflow: surfaces decisions to revisit, ownership that may have drifted, and decisions still reaching the manager that shouldn't.

## Status

DONE

### Progress

- [x] Criteria 1-6 closed: escalation test, decision log format, ownership matrix, escalation criteria reference, ownership-transfer coaching, and quarterly review workflow all documented in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. Run quarterly review to keep DecisionLog.md and OwnershipMatrix.md current.

## Files

- global/skills/team-decisions/SKILL.md

## Scope

global/skills/team-decisions/**
