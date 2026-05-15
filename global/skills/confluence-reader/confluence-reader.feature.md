# Feature: Confluence Reader Skill

## What It Does

`/confluence-reader` fetches the content of a Confluence page by URL or page ID and returns it in text, HTML, or JSON format. Used when needing to read existing documentation before drafting updates or answering questions about page content.

## Concern

**domain.** DBA documentation skill for the NICE CXone DBA team. Lives in the global pool for machine portability; references project-specific paths in `c:\code\ClientSetup\Documentation\Tools\confluence_loader\` and the DBA space page IDs.

## Success Criteria

1. Reads Confluence pages by URL (`--url`) or page ID (`--page-id`).
2. Supports three output formats: `--format text` (default, HTML stripped), `--format html` (raw storage format), `--format json` (full metadata).
3. Supports `--output <file>` to save result to a file instead of printing.
4. Activates the venv at `c:\code\ClientSetup\Documentation\Tools\confluence_loader` before running the script.
5. SKILL.md has a frontmatter header (`name`, `description`, `argument-hint` fields) so the plugin system registers it correctly.
6. [BUG] criterion 5: SKILL.md was missing frontmatter at time of feature doc creation. Fixed as part of this feature doc -- frontmatter added to SKILL.md.

## Status

DONE

### Progress

- [x] Criteria 1-4 closed: read-by-URL, read-by-ID, output formats, and venv activation all documented in SKILL.md.
- [x] Criterion 5/6 [BUG] resolved: frontmatter added to SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. Update the Common Page IDs table when DBA space structure changes.

## Files

- global/skills/confluence-reader/SKILL.md

## Scope

global/skills/confluence-reader/**
