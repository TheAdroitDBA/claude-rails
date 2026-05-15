---
name: review-skills
description: Review all Claude Code skills for optimization opportunities, redundancy, and improvements.
disable-model-invocation: true
---

# Review Skills

Audit all skills in `.claude/skills/` for quality, efficiency, and optimization opportunities.

## Review Criteria

For each skill, evaluate:

### 1. Token efficiency
- Are instructions concise or bloated?
- Could shell commands use `!`backtick`` injection to reduce runtime queries?
- Are there redundant steps that could be eliminated?
- Could steps be parallelized?

### 2. Correctness
- Do the commands match the actual project structure?
- Are file paths accurate?
- Do the patterns match what the codebase actually uses?
- Are there stale references to files/patterns that have changed?

### 3. Completeness
- Does each skill cover the full workflow?
- Are edge cases handled (e.g., "nothing to deploy")?
- Are error paths addressed?

### 4. Redundancy with agents
- Does any skill duplicate what an agent already knows?
- Could a skill delegate to an agent for the heavy lifting while keeping the skill as the entry point?
- Are there agents that should be converted to skills or vice versa?

### 5. Missing skills
- Are there recurring workflows that don't have a skill yet?
- Could existing skills be split or combined for better UX?

## Output

Present findings as a structured report:

**Skill: /skill-name**
- Status: (good / needs improvement / needs rewrite)
- Issues: (list specific problems)
- Suggestions: (list specific improvements)

**Missing skills:**
- (workflows that should have skills but don't)

**Agent/skill overlap:**
- (where agents and skills duplicate effort)

End with a prioritized list of recommended changes for discussion.

## What to read

Discover the target pool at invocation time -- do not hardcode paths:

**For a project-pool audit** (skills/agents colocated with a specific repo):
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
ls "$REPO_ROOT/.claude/skills/"*/SKILL.md 2>/dev/null
ls "$REPO_ROOT/.claude/agents/"*.md 2>/dev/null
```

**For a global-pool audit** (skills/agents that ship to every machine via `~/.claude/`):
```bash
ls "$HOME/.claude/skills/"*/SKILL.md 2>/dev/null
ls "$HOME/.claude/agents/"*.md 2>/dev/null
```

If the user does not specify, ask which pool to audit. Read every skill and agent file in the chosen pool before making recommendations. Cross-reference with the project's CLAUDE.md and MEMORY.md (for project-pool) or `~/.claude/CLAUDE.md` (for global-pool) for accuracy.
