# Known Issues

## 1. project-setup SKILL.md is 438 lines

Templates extracted to `templates/` directory, but the main SKILL.md remains long. Steps 2-3 (orientation audit detail + legacy-detection bash blocks) are the bulk. Low priority -- the skill works correctly, it is just verbose.

**Status**: open, low priority

## 2. hook-health skill needs update for new hook model

The `/hook-health` skill was written for the shell-script + settings.local.json wiring model. It needs to be updated to verify the new plugin-native hooks/hooks.json model instead. Currently it checks for bash/powershell scripts and settings.local.json entries that no longer exist.

**Status**: open, medium priority
