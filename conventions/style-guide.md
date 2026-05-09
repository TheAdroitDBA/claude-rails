# Style Guide

How to write the words in claude-rails docs and in any docs an
adopting repo publishes through claude-rails. The cheapest doc-quality
tool: one consistent voice across the corpus.

Apply this guide to any `*.md` published through the framework. Use
your judgment for sections this guide does not cover.

## Voice

Active voice. Second person. Direct.

| Don't | Do |
|-------|-----|
| The migration should be run | Run the migration |
| Files will be backed up automatically | The system backs up files automatically |
| It is recommended that users review | Review the criteria before approving |
| One can use either method | Use either method |

The reader is the protagonist. Tell them what to do; do not narrate
what an unspecified actor will do at an unspecified time.

## Tone matches mode

Diátaxis modes have different tones:

- **Tutorial** — encouraging, second person, single path. "You will
  see X. Now do Y."
- **How-to guide** — direct, task-oriented. "To deploy: 1) build, 2)
  push, 3) verify."
- **Reference** — austere, complete, lookup-friendly. Predictable
  structure. No prose that does not earn its place.
- **Explanation** — reflective, contextual, may diverge into
  background. Discursive but not rambling.

Mixing tones inside one doc is a smell that the doc itself is mixing
modes. Split.

## Front-load the answer

The first sentence states the conclusion. The rest justifies it.
Inverted pyramid, not detective novel.

| Don't | Do |
|-------|-----|
| There are several factors to consider before choosing a backup strategy. The most important is recovery time, but other considerations include cost and complexity. After weighing these, you should pick rsync. | Use rsync. It optimizes for recovery time at modest cost; the alternatives (zfs send, restic) trade off either complexity or speed. |

A reader who bounces after three lines should still have the answer.

## Cut filler

Delete on sight:

- "in order to" → "to"
- "it is important to note that" → delete the whole phrase
- "please be aware" → delete
- "as previously mentioned" → delete
- "currently", "as of now", "at this time" — temporal qualifiers rot
- "simply", "just", "easily" — patronizes the reader; usually wrong
- "obvious", "trivial", "of course" — same problem
- "we should", "one might consider" — say it or do not

## Be specific

Numbers, dates, paths, names. Not "performance is improved" but "p95
latency drops from 800 ms to 120 ms at 1 k RPS." Not "recently" but
"2026-05-09." Not "the script" but "`tools/storage_audit.py`."

If you cannot be specific, the claim is not yet ready to write.

## Inclusive and current terminology

Industry-standard. Not a debate.

| Use | Not |
|-----|-----|
| allowlist / denylist | whitelist / blacklist |
| primary / replica or leader / follower | master / slave |
| main (branch) | master (branch) |
| placeholder | dummy |
| sanity check | (use "consistency check", "smoke test", or "validation") |

## Acronyms and jargon

First use of an acronym spells it out: "Service Level Objective
(SLO)." Subsequent uses can use the acronym alone within the same doc.

Domain jargon (e.g. "vzdump", "PERC H700", "ZFS ARC") is fine in docs
whose audience is operators -- but link to a glossary entry on first
use if a non-operator reader could land on the page.

## No "we", "I", or "the user"

| Don't | Do |
|-------|-----|
| We back up nightly | The system backs up nightly |
| I recommend rsync | Use rsync |
| The user should run | Run |

Exception: feature docs' `## What It Does` may use "we" when
describing team intent. Otherwise keep the doc impersonal.

## Code blocks and commands

Every code block declares its language: ` ```bash`, ` ```python`,
` ```toml`. Plain ` ``` ` blocks fail accessibility tooling and skip
syntax highlighting.

Commands MUST be copy-pasteable from a fresh checkout. No implicit
variables; no "fill in your value here." If the command needs a
variable, declare it as a shell variable on the line above and tell
the reader what to set it to.

```bash
# Don't
psql -h <your host> -U <your user> -d <your db>

# Do
HOST=10.0.0.179
USER=jellyfin
psql -h "$HOST" -U "$USER" -d jellyfin
```

## Diagrams

Mermaid for graphs and flows. Source is text in the markdown file --
never PNG-as-source.

```markdown
\```mermaid
flowchart LR
  client --> nginx --> app --> db
\```
```

Diagrams clarify *relationships*. They do not clarify procedures
(use a numbered list). They do not narrate timelines (use a table).

C4 model levels for architecture diagrams (context / container /
component / code) -- pick one level per diagram and stick to it.
Mixing levels confuses every reader.

## Headings and structure

- One `<h1>` per file, the title. Subsequent headings descend from
  `<h2>`.
- Heading text is sentence case ("Doc lifecycle"), not title case
  ("Doc Lifecycle") -- one fewer arbitrary rule to enforce.
- A heading without content under it is a stub. Either fill it or
  delete it. "TBD" and "Coming soon" headings rot the page.
- A doc that needs more than two `<h2>` to organize is two docs.

## Lists

- Use bulleted lists for unordered things, numbered for sequences.
- Parallel structure: every item starts the same way (all noun
  phrases, all imperative verbs, all complete sentences). Mix and
  the list reads like noise.
- Lists of more than 7 items are hard to scan. Group into
  sub-headings or split into a table.

## Tables

- Use tables for structured comparison or reference lookup.
- Header row labels every column.
- Cell contents are scannable values, not prose. If a cell needs a
  paragraph, the data wants to be a sub-section, not a row.
- Align columns for readability when authoring. Renderers do not
  care; humans editing source do.

## Links

- Link text describes the destination: `[storage inventory](...)`,
  not `[click here](...)`.
- In-repo links are relative paths. Cross-repo links use the
  published path namespace (`/repos/<reponame>/...`); see the
  cross-repo link convention in `conventions/auto-doc.md`.
- External links to standards, tools, vendor docs are fine. Vendor
  docs that move regularly (Microsoft, AWS) are spot-checked on a
  schedule -- expect breakage and fix when reported.

## Avoid temporal qualifiers

"Currently", "at this time", "as of now", "recently" all rot. Use
absolute dates if a time is meaningful, or remove the qualifier:

| Don't | Do |
|-------|-----|
| The site is currently running mkdocs | The site runs mkdocs |
| As of now, three repos are enrolled | Three repos are enrolled (2026-05-09) |
| Recently we migrated to Larry | Migrated to Larry on 2026-05-04 |

## Avoid hedging

| Don't | Do |
|-------|-----|
| This might be a good idea | (delete, OR) Recommended: ... |
| It seems that the audit fails | The audit fails when ... |
| Probably the right path is | Use this path: ... |

If the writer does not know, the writer says so explicitly: "Unknown
whether X happens; needs investigation." If the writer does know,
the writer makes the claim.

## When to delete

Always preferable to:

- Add filler so a section "feels complete"
- Mark a section "draft" and leave it
- Keep a doc "for reference" that nobody uses

Less, better. A small accurate corpus beats a large stale one.

## Adoption litmus test

Before merging a doc PR, scan the changes for:

1. Passive voice — flip to active.
2. Temporal qualifiers — delete or replace with dates.
3. Hedging — delete or commit to a claim.
4. Stub headings — fill or delete.
5. Generic link text — replace with descriptive text.
6. Mixed Diátaxis modes — split.

Each of these is mechanical to fix. None requires expertise. The
reviewer who notices them is doing the doc's reader a favor.
