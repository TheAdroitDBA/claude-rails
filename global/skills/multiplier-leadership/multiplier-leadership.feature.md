# Feature: Multiplier Leadership Skill

## What It Does

`/multiplier-leadership` (trigger: `m:`) applies Liz Wiseman's Multiplier framework to leadership situations. Coaches using the 5 disciplines (Talent Magnet, Liberator, Challenger, Debate Maker, Investor), identifies Accidental Diminisher behaviors, and distinguishes Corrective from Teaching communication patterns. Always defaults to empowering questions over direct answers.

## Concern

**domain.** DBA leadership coaching skill for Jeremy Allen's role managing the NICE CXone DBA team. Lives in the global pool for machine portability; carries team-specific initiative context (Role Expectations Alignment, started 2026-04-08) directly in SKILL.md.

## Success Criteria

1. Applies all 5 Multiplier disciplines in responses: Talent Magnet, Liberator, Challenger, Debate Maker, Investor. Each discipline has a named Diminisher counterpart and coaching questions.
2. Default response posture is empowering questions, not direct answers. User preference is hardcoded in SKILL.md and takes precedence.
3. Distinguishes Corrective Communication Pattern (known convention missed by someone who knows it) from Teaching Communication Pattern (convention was never shared). Applies the correct pattern based on context signals.
4. Identifies and names Accidental Diminisher behaviors (Idea Fountain, Always On, Rescuer, Pacesetter, Rapid Responder, Optimist) when observed in the user's descriptions.
5. Carries current initiative context: Role Expectations Alignment for the DBA team, started 2026-04-08. Frames new gaps as teaching first (Challenger), not correction, until the 6-week mark.
6. Self-assessment section surfaces the 6 Accidental Diminisher patterns via targeted questions the user can ask themselves.

## Status

DONE

### Progress

- [x] Criteria 1-6 closed: 5-discipline framework, empowering-question default, corrective/teaching distinction, accidental-diminisher taxonomy, and current initiative context all in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. Update the Current Initiative section in SKILL.md as the Role Expectations Alignment initiative progresses or closes.

## Files

- global/skills/multiplier-leadership/SKILL.md

## Scope

global/skills/multiplier-leadership/**
