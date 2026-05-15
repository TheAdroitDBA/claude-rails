---
name: confluence-reader
description: 'Read Confluence pages using confluence_reader.py. Use when: reading a specific page by ID or URL, fetching page content for analysis, checking existing documentation before updating, exporting page content to a file.'
argument-hint: 'Page URL or page ID'
---

# Confluence Reader Skill

Read Confluence pages using the existing confluence_reader.py tool.

## Tool Location

`Documentation/Tools/confluence_loader/confluence_reader.py`

## Prerequisites

1. Python environment with dependencies installed:
   ```bash
   cd Documentation/Tools/confluence_loader
   pip install -r requirements.txt
   ```

2. Configuration file exists at `Config/site_config.json` with Confluence credentials:
   - `confluence.url`: Atlassian URL (e.g., `https://nice-ce-cxone-prod.atlassian.net`)
   - `confluence.email`: User email
   - `confluence.token`: API token from [Atlassian Account Settings](https://id.atlassian.com/manage-profile/security/api-tokens)

## Usage

### Read by URL

```powershell
cd c:\code\ClientSetup\Documentation\Tools\confluence_loader
python confluence_reader.py --url "https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/15138714/DBA"
```

### Read by Page ID

```powershell
python confluence_reader.py --page-id 15138714
```

### Output Formats

- `--format text` (default): Plain text, HTML stripped
- `--format html`: Raw Confluence storage format
- `--format json`: Full page metadata including title, space, version

### Save to File

```powershell
python confluence_reader.py --url "..." --output page_content.txt
```

## Output Structure

```
Title: Page Title
URL: https://...
Page ID: 12345
Space: IN
==================================================
[Page content here]
```

## Common Page IDs (DBA Space)

| Page | ID | URL |
|------|----|----|
| DBA Home | 15138714 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/15138714/DBA |
| DBA Operations | 3500343367 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/3500343367 |
| DBA Operations Team | 3500539957 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/3500539957 |
| DBA Operations Processes | 3500507189 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/3500507189 |
| DBA Operations Weekly Reports | 3500441658 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/3500441658 |
| Cloud Database Engineer Role | 3500539975 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/3500539975 |
| Manager Role Expectations | 3500965944 | https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/3500965944 |
| DataOps (not our team) | 258639598 | - |
| DevOpsDBA (Marcelo's team) | 15359902 | - |

## Workflow for AI Agent

When asked to read a Confluence page:

1. Navigate to the confluence_loader directory
2. Activate the venv if needed: `.\venv\Scripts\Activate`
3. Run the reader with the URL or page ID
4. Parse the output for the user

## Example Commands

```powershell
# Read DBA home page
cd c:\code\ClientSetup\Documentation\Tools\confluence_loader
.\venv\Scripts\Activate
python confluence_reader.py --url "https://nice-ce-cxone-prod.atlassian.net/wiki/spaces/IN/pages/15138714/DBA" --format text

# Get page structure as JSON
python confluence_reader.py --page-id 15138714 --format json
```

## Troubleshooting

- **Authentication error**: Check Config/site_config.json has valid token
- **Page not found**: Verify page ID extracted from URL correctly
- **Module not found**: Activate venv or install requirements
