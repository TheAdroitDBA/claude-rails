---
name: deploy-detect
description: Detect the repo's current deploy mechanism via interview + scan, classify automation level (FULL / PARTIAL / NONE / DRIFT), write deploy.flow.md documenting what exists, recommend completion or adoption only when evidence warrants. Adaptive, not prescriptive.
---

# Deploy Detect

See `deploy-detect.flow.md` for the full pipeline definition. This skill is the procedural form of those steps. See `deploy-detect.feature.md` for the success criteria each step must satisfy.

## Step 1: Interview the user

Before any file scan, ask:

> Which deploy mechanisms apply to this repo? Answer yes/no for each category, and if yes, point at the files or hosts:
> - CI/CD service (GitHub Actions, GitLab CI, CircleCI, Drone, Travis, Buildkite)
> - GitOps (ArgoCD, Flux)
> - Self-hosted orchestration (Ansible, Portainer stacks, self-hosted runners)
> - Container runtime (Dockerfile, docker-compose, Watchtower)
> - Kubernetes (k8s manifests, Helm, Kustomize)
> - PaaS (Fly, Vercel, Netlify, Railway, Render, Heroku, Dokku, CapRover, Coolify)
> - Scheduled (systemd timers, cron)
> - Manual (shell script, Makefile target, webhook listener)
> - None / don't know

Record the user's claims. "I don't know" counts as zero claimed mechanisms; proceed to scan.

If the user says an external system deploys this repo (e.g., "Jenkins on another server" or "a GitHub workflow in a different repo builds and pushes this image"), mark as `external` -- outside the scope of what this skill can scan. Note it in the report and proceed.

## Step 2: Scan and reconcile

Scan the repo for signals from the flow doc's Detection Signal Categories table. Build a list of detected mechanisms.

Reconcile claims vs scan:

- **Claim + matching signal** -> confirmed, add to working set
- **Claim, no matching signal** -> ask the user for the file path. If the user points at something unexpected, add it to the working set with a note. If the user says "it's external" or "I was wrong," mark accordingly.
- **Signal, no claim** -> surface to the user: "I found X at `<path>`. Is this active? (yes / no / don't know)". Yes adds to working set; no marks the signal as dead code; don't-know flags for later human review.

Output of this step: a working set of { mechanism, authoritative_path_or_external, user_confirmed }.

## Step 3: Classify

For each entry in the working set, classify:

- **FULL** -- `git push` -> deployed-and-running with no human intervention, AND a rollback path exists (automated or documented). Look for: complete CI workflow with deploy job + trigger, or GitOps reconciling, or PaaS with auto-deploy, etc.
- **PARTIAL** -- mechanism exists but covers only some phases. Name the specific gap: "builds but doesn't deploy," "deploy script exists but no trigger wires it," "cron pulls but doesn't restart service."
- **NONE** -- no mechanism in the working set covers deploy for this repo.
- **DRIFT** -- two or more entries in the working set describe different deploy targets / versions / behaviors. Claim-vs-signal conflict counts here (user said X, scan found Y incompatible).

The whole repo gets one classification: the highest-severity state of any single mechanism. DRIFT > PARTIAL > NONE, and FULL only if at least one mechanism is FULL and no others conflict.

## Step 4: DRIFT handling

If classification is DRIFT:

1. Present both sides: what the user claimed AND what the scan found, or mechanism A's details AND mechanism B's details.
2. Ask the user to pick the authoritative mechanism. Options:
   - "Mechanism A is correct, mechanism B is legacy/dead -- remove from scope"
   - "Both are correct but apply to different subsystems -- describe the boundary"
   - "Not sure -- halt, user will investigate and re-run"
3. Do NOT proceed to Steps 5-6 until user resolves. The report for this run is "DRIFT unresolved; halted until user picks."

Never silently choose.

## Step 5: Recommend

Behavior depends on classification:

- **FULL** -- emit no recommendation. Skill's job for this repo is documenting, not prescribing.
- **PARTIAL** -- name the specific missing step and propose completion of the EXISTING mechanism. Replacement proposals allowed only when the existing mechanism is fundamentally inadequate for the stated use (e.g., manual script as the sole deploy for multi-user production).
- **NONE** -- emit at most two recommendations from the flow doc's Recommendation Map, paired to the strongest environment cue:
  - Home lab + existing Ansible dir -> `ansible-pull + cron`
  - Home lab, no Ansible -> `webhook listener`
  - Public cloud repo -> `GitHub Actions + SSH/kubectl/hosting-CLI`
  - Kubernetes cluster -> `ArgoCD or Flux`
  - Docker-heavy home lab -> `Portainer stack + Git integration`
  - Static site -> `Vercel / Netlify / Cloudflare Pages`

Never present a menu of 5+. Force a pick or force the user to reject both.

## Step 6: Write and report

**Write `<repo>/deploy.flow.md`** (FULL and PARTIAL only; NONE skips the write, DRIFT halted in Step 4) with these sections:

1. Entry Points -- exactly what triggers a deploy (push to main, manual dispatch, cron tick, webhook POST, image tag update, external system notification)
2. Pipeline -- step table with action, files touched, failure branches
3. Failure Modes -- what breaks the deploy and how the user notices (logs, notifications, silent)
4. Rollback -- how to reverse. If no rollback mechanism exists, include a `[BUG]` line: "deploys are not reversible -- add rollback before this becomes production-load-bearing."
5. Files Involved -- workflow files, playbooks, scripts, manifests, config

Use the existing flow-doc shape from `global/skills/project-setup/project-setup.flow.md` as the template.

**Emit report** (one screen) covering:

- Working set (mechanism + path, user-confirmed or external)
- Classification + any named gaps for PARTIAL
- Recommendation (NONE/PARTIAL) or "no recommendation -- using existing mechanism" (FULL)
- Path to written `deploy.flow.md`, or "no flow doc written" (NONE / DRIFT)

## Failure Modes

- **Not a git repo** -> exit 0 with "not applicable." No interview, no scan, no write.
- **User declines to answer interview** -> proceed to scan alone; report the limitation ("classification is scan-only; user knowledge absent").
- **Ambiguous detection** (workflow exists but deploy job unclear) -> report WEAK with the specific lines flagged; classify PARTIAL with the gap as "detection uncertain, review `<path>:<line>`".
- **User declines NONE recommendation** -> exit clean, no `deploy.flow.md`, Q6 stays WEAK/FAIL on subsequent orientation audits.
- **DRIFT unresolved** -> halt at Step 4; report summarizes the conflict and exits.
- **Re-run on unchanged repo with same interview answers** -> byte-identical `deploy.flow.md` output (idempotent).

## Rules

- Never modify existing deploy files. Read to classify, write one artifact (`deploy.flow.md`).
- Never ship a FULL classification silently. If rollback is missing, the written `deploy.flow.md` flags it as `[BUG]`.
- Never recommend more than two options in a NONE case.
- Never silently resolve DRIFT. The user picks.
- Interview always comes first. No silent scan-only behavior.
