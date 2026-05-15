# Feature: Confluence Documentation Skill

## What It Does

`/confluence-documentation` guides uploading markdown files to Confluence as properly formatted ADF pages. Checks for title conflicts before any upload, strips local filesystem paths from content, and manages the page registry for the DBA space.

## Concern

**domain.** DBA documentation skill for the NICE CXone DBA team. Lives in the global pool for machine portability; references project-specific paths in `c:\code\ClientSetup\Documentation\Tools\confluence_loader\` and the DBA space page IDs.

## Success Criteria

1. Before any upload, checks whether the target title already exists in Confluence; halts and asks for user confirmation if a match is found.
2. Never passes `--page-id` without explicit user confirmation -- update mode requires deliberate intent.
3. Strips the local working-directory prefix (`c:\code\ClientSetup\`) from all paths shown in uploaded content; only relative workspace paths appear.
4. Supports both create mode (`--file --parent-id`) and update mode (`--file --page-id`).
5. Reads pages by page ID or URL using `confluence_reader.py`.
6. Searches Confluence by keyword with optional `--space` and `--limit` filters.
7. Page registry sync commands (`--list-parents`, `--parent-id`, `--parent-id --recursive`, `--page-id`) work via `sync_registry.py`.
8. Activates the venv at `c:\code\ClientSetup` before running any Python tool.

## Status

DONE

### Progress

- [x] Criteria 1-8 closed: upload workflow, conflict check, path-stripping rule, registry sync, and venv activation all documented in SKILL.md.
- [x] NEXT: handoff line -- maintenance-only. If new DBA parent pages are created, update the Common Parent Pages table and `page_registry.json`.

## Files

- global/skills/confluence-documentation/SKILL.md

## Scope

global/skills/confluence-documentation/**
