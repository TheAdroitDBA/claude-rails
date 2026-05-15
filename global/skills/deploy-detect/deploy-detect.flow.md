# Flow: Deploy Detect

## Entry Points

- `/deploy-detect` invoked directly
- `/project-setup` Q6 calls it during orientation audit
- `n:` / `f:` / `fs:` shorthand calls it to surface deploy impact when features change

Adaptive, not prescriptive: detects what exists, classifies automation, recommends only when evidence warrants. Never modifies existing deploy files; writes one artifact (`deploy.flow.md`).

## Pipeline

| Step | Action | Halt condition |
|---|---|---|
| 1 | Interview: ask the user "Which deploy mechanisms apply here? CI/CD, GitOps, Ansible, Docker-orchestrated, Kubernetes, PaaS, scheduled, manual, none." Record their claims and ask for file paths where they exist | -- |
| 2 | Scan repo for signals (see categories below); reconcile claims vs scan. Claim + matching signal -> confirmed. Claim without signal -> probe user for location or flag as `external` (lives outside the repo). Signal without claim -> surface to user | not a git repo |
| 3 | Classify: FULL / PARTIAL / NONE / DRIFT. DRIFT includes claim-vs-signal conflict as well as multi-mechanism conflict | -- |
| 4 | DRIFT -> present both sides (what the user said AND what was found), demand an authoritative pick | halts steps 5-6 until resolved |
| 5 | Recommendation: NONE -> at most 2 options from Recommendation Map; PARTIAL -> name the gap, recommend completion; FULL -> nothing | -- |
| 6 | Write `<repo>/deploy.flow.md` (FULL + PARTIAL only) with Entry Points, Pipeline, Failure Modes, Rollback, Files Involved. Flag rollback-missing FULL as [BUG]. Emit one-screen report | NONE skips write; DRIFT halted |

## Detection Signal Categories

Scan in this order; multiple may match.

| Category | Example signals |
|---|---|
| CI/CD services | `.github/workflows/*.yml`, `.gitlab-ci.yml`, `.circleci/`, `.drone.yml`, `.travis.yml`, `.buildkite/` |
| GitOps | `argocd/`, `flux-system/`, `Application` CRD in k8s manifests |
| Self-hosted orchestration | `ansible/` + playbook/`ansible.cfg`, Portainer stack files |
| Container runtimes | `Dockerfile`, `docker-compose*.yml`, Watchtower image in compose |
| Kubernetes | `k8s/`, `helm/`, `kustomize/`, `Chart.yaml` |
| PaaS | `fly.toml`, `vercel.json`, `netlify.toml`, `railway.toml`, `render.yaml`, `Procfile`, `heroku.yml`, Dokku/CapRover/Coolify git remotes |
| Scheduled | systemd unit/timer files, crontab entries referencing the repo |
| Manual | `deploy.sh`/`deploy.ps1`, `scripts/deploy.*`, Makefile `deploy:` target, webhook listener configs |

## Classification

- **FULL** -- `git push` -> deployed-and-running with no human step, rollback path exists (documented or automatic)
- **PARTIAL** -- some phases automated, at least one gap; skill names the gap specifically
- **NONE** -- no deploy signal
- **DRIFT** -- two+ mechanisms describe different targets/versions/behaviors

## Recommendation Map (NONE only)

Paired to the strongest environment cue; max 2 options per case.

| Cue | Recommendation |
|---|---|
| Home lab + existing Ansible dir | ansible-pull + cron |
| Home lab, no Ansible | webhook listener |
| Public cloud repo | GitHub Actions + SSH/kubectl/hosting-CLI |
| Kubernetes cluster | ArgoCD or Flux |
| Docker-heavy home lab | Portainer stack + Git integration |
| Static site | Vercel / Netlify / Cloudflare Pages |

PARTIAL recommendations complete the existing mechanism; do NOT replace unless current mechanism is fundamentally inadequate (manual-script-as-prod-deploy on multi-user system).

## Failure Modes

- Not in git repo -> exit 0 "not applicable", write nothing
- Ambiguous detection -> report WEAK with specific lines flagged
- DRIFT unresolved -> halt at step 3
- User declines NONE recommendation -> exit clean, no `deploy.flow.md`, Q6 stays WEAK/FAIL
- Re-run on unchanged repo -> byte-identical output (idempotent)

## Files Involved

- `global/skills/deploy-detect/SKILL.md` (implementation, pending)
- `global/skills/deploy-detect/deploy-detect.feature.md` (criteria)
- `<adopted-repo>/deploy.flow.md` (output artifact)
