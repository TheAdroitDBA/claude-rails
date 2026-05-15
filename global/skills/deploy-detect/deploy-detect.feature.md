# Feature: Deploy Detect

## What It Does

Detects the current deploy mechanism in any repo, classifies its automation level, writes `deploy.flow.md` documenting what's there, and recommends completion or adoption only when evidence warrants. Adaptive, not prescriptive. Invoked as `/deploy-detect`, by `/project-setup` as Q6, or by `n:` / `f:` / `fs:` to surface deploy impact when features change.

See `deploy-detect.flow.md` for the pipeline, detection signals, and recommendation map. Criteria below reference its steps and must each be independently verifiable on a real repo.

## Concern

**framework.** Global-pool skill synced to every machine. Produces `deploy.flow.md` in adopted repos and integrates with `/project-setup` Q6 and `n:`/`f:`/`fs:` expansions -- all framework surfaces.

## Success Criteria

1. Running in a git repo produces a one-screen report: detected mechanism(s), classification, and either a written `deploy.flow.md` or a recommendation. Running in a non-git directory exits 0 with a "not applicable" message.
2. Detection combines user interview + repo scan. Step 1 asks the user which of the category-level mechanisms apply before any scan runs. Scan (step 2) reconciles against the interview: claim-without-signal prompts for a location or marks `external`; signal-without-claim is surfaced; user claim + matching signal is confirmed. Skill never scans silently and presents results as if the user had no knowledge.
3. Detection covers every category in the flow doc's Detection Signal Categories table. Adding a new category requires an update to both docs and an addition to the interview question.
4. Classification values are exactly `FULL`, `PARTIAL`, `NONE`, `DRIFT`. `FULL` requires a rollback path; absence of one makes the classification FULL with a `[BUG]` line in the written `deploy.flow.md` flagging "deploys are not reversible." `DRIFT` includes claim-vs-signal conflicts, not just multi-mechanism conflicts.
5. `PARTIAL` output names the specific missing step (e.g., "CI builds but has no deploy job"; "deploy script exists but no trigger wires it").
6. `DRIFT` halts the write step until the user picks an authoritative mechanism. Skill presents both sides (user claim AND scan finding, or mechanism A AND mechanism B) side by side; never silently chooses.
7. `NONE` emits at most 2 recommendations, selected from the flow doc's Recommendation Map by the strongest environment cue. Never a menu.
8. `PARTIAL` recommendations complete the existing mechanism rather than propose replacement, except when the current mechanism is fundamentally inadequate for the stated use (multi-user production on a manual script).
9. `FULL` emits no recommendation.
10. Writes exactly one artifact: `<adopted-repo>/deploy.flow.md`. Never modifies any existing workflow, playbook, manifest, script, or config file.
11. `deploy.flow.md` sections: Entry Points, Pipeline step table, Failure Modes, Rollback, Files Involved. All five present in every written output.
12. Idempotent. Re-running against an unchanged repo produces byte-identical `deploy.flow.md`.
13. `/project-setup` Q6 maps: `FULL` = PASS, `PARTIAL` = WEAK, `NONE` = WEAK (FAIL if repo has production callers), `DRIFT` = FAIL.
14. `n:` and `f:`/`fs:` call the skill and surface whether the feature changes the deploy pipeline (e.g., adds a service the current deploy doesn't cover).

## Status

IN PROGRESS

### Progress

- [x] Criteria approved; flow doc + feature doc committed (d563e47, 7b426fc)
- [x] SKILL.md scaffolded from the six flow-doc pipeline steps; rules section spells out never-modify / never-silent-full / never-more-than-two-recs / never-silent-drift / interview-first
- [ ] NEXT: `/project-setup` Q6 wiring (new criterion + audit step in project-setup SKILL.md)
- [ ] AFTER: `commands/n.md`, `commands/f.md`, `commands/fs.md` get a "consider deploy impact" line so feature work surfaces deploy impact (was: `n:`/`f:`/`fs:` shorthand manifest additions, retargeted to native plugin commands when shortcuts-manifest retired 2026-05-04)

## Files

- global/skills/deploy-detect/SKILL.md (pending)
- global/skills/deploy-detect/deploy-detect.flow.md
- global/skills/project-setup/SKILL.md (Q6 wiring, after SKILL.md lands)
- global/skills/project-setup/project-onboarding.feature.md (new criterion for Q6)
- commands/n.md, commands/f.md, commands/fs.md (deploy-impact line)
- `<adopted-repo>/deploy.flow.md` (output artifact)

## Scope

global/skills/deploy-detect/**, commands/{n,f,fs}.md

## Surface

CLI `/deploy-detect`; artifact `deploy.flow.md` at adopted-repo root; Q6 line in `/project-setup` output; "consider deploy impact" line in `/n`, `/f`, `/fs` slash commands.
