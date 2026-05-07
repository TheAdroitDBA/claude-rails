# 0005: No emojis or graphical characters in .md files

## Status

ACCEPTED — 2026-04-21

## Context

Emojis and decorative Unicode (box-drawing characters, stars, checkmarks beyond basic ASCII) have three measurable costs. First, they render inconsistently: terminals, diff tools, web renderers, and AI model tokenizers all treat them differently, and grep patterns that include emoji are brittle. Second, they raise token cost for identical semantic content — one emoji is often a full token where the word it replaces would be a fraction. Third, they are a reliable marker of AI-generated slop, lowering reader trust in docs that should read as authoritative framework contracts.

## Decision

All `.md` files in claude-config and in adopted repos use plain text only. No emojis. No decorative Unicode. Section markers, lists, and emphasis use standard Markdown (`#`, `##`, `-`, `**bold**`, `` `code` `` ) — nothing beyond. Box-drawing diagrams are acceptable when they carry information (hierarchy, flow), but only via the narrow set of standard ASCII art forms; decorative borders are not.

## Consequences

- Framework docs stay diffable, greppable, and tokenizer-neutral.
- Writers must resist the temptation to add visual flourish. The rule is bright-line: any emoji is a violation, regardless of how "tasteful" it looks. A post-commit lint or the `auto-lint` hook can catch violations mechanically.
- Generated output (Claude's own replies inside a session) is governed separately by CLAUDE.md guidance and by Claude Code's own style. The rule here applies to files that land in the repo.
- The rule is explicit in `MEMORY.md` as Hard Rule #1, inlined into `/project-setup`'s scaffolded `CLAUDE.md` conventions section, and reinforced in every rules-template file so adopted repos inherit it.

## Alternatives Considered

- **Allow emojis in non-framework docs** — rejected. A mixed rule is harder to enforce than a strict one; writers will push the line until violations appear in framework docs.
- **Allow emojis only as list markers or status indicators** — rejected. Slippery slope: list markers become section markers become full paragraphs of decoration.
- **Silent convention without explicit rule** — rejected. Without a written rule, new contributors (human or AI) default to the broader internet convention, which is "emojis everywhere."

## Affected Features

- MEMORY.md (Hard Rule #1)
- CLAUDE.md (every repo's, scaffolded by `/project-setup`)
- All `*.feature.md`, `*.flow.md`, `rules/**`, `docs/**`, `decisions/**`, `memory/**` files
