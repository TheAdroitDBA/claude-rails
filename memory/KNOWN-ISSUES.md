# Known Issues

## Active

### project-setup

- BUG-0001 | project-setup command is 438 lines -- templates extracted to `templates/` but command remains verbose (steps 2-3 orientation audit detail + legacy-detection bash blocks are the bulk) | 2025-01-01
  Repro: read commands/project-setup.md and count lines.
  Evidence: 438 lines; templates already extracted to templates/; bulk is steps 2-3 (orientation audit) and inline bash blocks for legacy detection.
  First place to look: commands/project-setup.md steps 2-3 and legacy-detection blocks.

## Resolved

- (none yet)
