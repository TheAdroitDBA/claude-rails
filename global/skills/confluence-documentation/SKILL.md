---
name: confluence-documentation
description: 'Upload and manage Confluence documentation. Use when: uploading to Confluence, creating Confluence pages, updating documentation, checking for existing pages, organizing page hierarchy, converting markdown to Confluence format.'
argument-hint: 'Provide file path and parent page ID (optional)'
---

# Confluence Documentation Upload

Upload markdown files to Confluence using proper ADF formatting.

## When to Use

- Uploading local markdown documentation to Confluence
- Creating new Confluence pages from local files
- Updating existing Confluence pages
- Checking if a page already exists before upload
- Organizing documentation under parent pages

## Critical Rules

**NEVER overwrite existing pages owned by others.**

Before ANY upload:
1. Check if the title already exists in Confluence
2. If "Found existing page" appears, **STOP** and confirm with user
3. Only create NEW pages or update pages you own
4. Use unique titles that won't collide with existing content

## Upload Process

### 1. Activate Virtual Environment

```powershell
cd c:\code\ClientSetup
.venv\Scripts\activate
cd Documentation\Tools\confluence_loader
```

### 2. Check for Existing Page (Optional)

```powershell
python confluence_search.py "Page Title" --space IN --limit 5
```

### 3. Upload Document

**New page:**
```powershell
python DocumentUploaderADF.py --file "path\to\file.md" --parent-id <parent-page-id>
```

**Update existing page (use with caution):**
```powershell
python DocumentUploaderADF.py --file "path\to\file.md" --page-id <existing-page-id>
```

## Path Rules for Uploaded Content

**Strip local paths** — Do not include full local paths like `c:\code\ClientSetup\` in uploaded pages.

Show only relative workspace paths:
- Bad: `c:\code\ClientSetup\DBALeadership\Roles\file.md`
- Good: `DBALeadership\Roles\file.md`

## Common Parent Pages

| Purpose | Page ID | Key |
|---------|---------|-----|
| Default / Stored Procedure Reports | 2172518690 | default |
| DBA Documentation | 15153176 | dba_documentation |
| Alert Management | 3515483109 | alert_management |
| DBA Monitoring/Alerting | 617973018 | dba_monitoring |

**Full hierarchy stored in:** `page_registry.json`

## Page Registry

Local registry tracks pages and parent hierarchy:

```powershell
# List known parent pages
python sync_registry.py --list-parents

# Sync children of a parent page
python sync_registry.py --parent-id 15153176

# Recursively sync entire subtree
python sync_registry.py --parent-id 15138714 --recursive

# Add single page to registry
python sync_registry.py --page-id 617973018
```

## Reading Confluence Pages

```powershell
# By page ID
python confluence_reader.py --page-id 617973018

# By URL
python confluence_reader.py --url "https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/123456/Page"

# Output formats: text (default), html, json
python confluence_reader.py --page-id 123456 --format json
```

## Searching Confluence

```powershell
# General search
python confluence_search.py "search terms" --limit 20

# Search specific space
python confluence_search.py "DBA alert" --space IN --limit 15
```

## Markdown Formatting Guidelines

The ADF converter handles:
- Headings (# through ######)
- Bold (**text**) and italic (*text*)
- Inline code (`code`)
- Code blocks (```language)
- Bullet and numbered lists
- Links [text](url)
- Tables (basic markdown tables)

**Not supported:**
- Nested tables
- Complex HTML
- Mermaid diagrams (render as images first)

## Links: friendly names, no raw URLs

Every URL in an uploaded page must use markdown link syntax with a descriptive name:

- Bad: `https://niceincontact.service-now.com/sp?id=sc_cat_item&sys_id=b234...`
- Good: `[DBA-Operations General Request](https://niceincontact.service-now.com/sp?id=sc_cat_item&sys_id=b234...)`

The markdown `[Friendly Name](URL)` converts to a Confluence `<a href="...">Friendly Name</a>` element. Raw URLs render as wall-of-character text in the page body and break scannability.

### Rules
- The link text must describe what the link points to. Avoid "click here," "this link," "see here." If the target is a ServiceNow catalog item, the link text is the catalog item name. If it's another Confluence page, the link text is the page title.
- Never paste a bare URL inline. If the URL is the only thing you have, wrap it: `[Open in browser](URL)`.
- For internal Confluence-to-Confluence references, use the page title as the link text so future renames are findable in search.

### Open in new page

External URLs (ServiceNow, GitHub, other tools) open in a new browser tab by default in Confluence Cloud when the destination is outside the Confluence domain. Markdown link syntax produces the correct storage format for this behavior -- no extra attributes are needed in the markdown.

For internal Confluence-to-Confluence links the default is same-tab. If a workflow requires a Confluence page to open in a new tab, document the requirement in the feature/runbook itself and edit the link in the Confluence UI after upload (the uploader does not emit `target="_blank"` from markdown).

## File Title Extraction

The uploader extracts page title from the **first line** of the markdown file:
- First `# Heading` becomes the page title
- If no heading, filename (without extension) is used

## Error Handling

| Error | Solution |
|-------|----------|
| "Page already exists" | Use `--page-id` to update, or rename your file |
| "Parent not found" | Verify parent-id exists and you have access |
| "Authentication failed" | Check token in Config/site_config.json |
| "Connection timeout" | Network issue; retry |

## Workflow Example

1. **Create local markdown file** in appropriate folder
2. **Verify content** — check formatting, strip local paths
3. **Search for conflicts** — ensure title doesn't exist
4. **Upload** — use DocumentUploaderADF.py with correct parent-id
5. **Verify** — check the page in Confluence
