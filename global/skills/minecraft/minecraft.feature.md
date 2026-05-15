# Feature: Minecraft Skill

## What It Does

Domain expert for Minecraft 1.20.1 Fabric modding. Covers the Fabric ecosystem (Loader, Fabric API, Mod Menu, Kotlin), mod compatibility and dependency chains, popular mod categories (performance, rendering, worldgen, content, storage, QoL, building, combat, library), configuration, and troubleshooting. Includes a verified-details section for specific mods whose compatibility has been researched.

## Concern

**framework.** Domain-expert skill in the global pool. Synced to every machine; portable knowledge only (criterion 8 pins "no project hardcodes"). Any project that needs Minecraft 1.20.1 Fabric guidance can invoke it.

## Success Criteria

1. Scope is strictly Minecraft 1.20.1 Fabric. The skill declares this explicitly and avoids giving version-agnostic advice that might mislead across minor versions.
2. Mod recommendations always mention key dependencies and flag alpha/beta status where applicable.
3. Compatibility checks answer "does X work with Y on 1.20.1 Fabric?" with known-conflict callouts, or admit uncertainty and point the user at Modrinth/CurseForge.
4. Modpack-building advice covers performance baseline, dependency resolution via shared libraries (Cloth Config, Architectury), and known incompatibilities.
5. Troubleshooting asks for crash logs when relevant, reads Fabric crash reports, and guides through common fixes (mixin conflicts, JVM memory, config issues).
6. The "Verified Mod Details" section is treated as authoritative. Mods not listed trigger an uncertainty admission and a recommendation to verify on Modrinth/CurseForge.
7. Prefers Modrinth links when available (primary Fabric mod repository); uses CurseForge when Modrinth is absent.
8. No project hardcodes. Answers the same regardless of which repo the user is in.

## Status

DONE

### Progress

- [x] All 8 criteria closed. Skill stays scoped to 1.20.1 Fabric, mentions dependencies, prefers Modrinth, admits uncertainty on non-verified mods, contains no project hardcodes.
- [x] NEXT: handoff line -- maintenance-only. When a new major Minecraft version ships (e.g., 1.21.x), consider whether to update the scope or ship a sibling skill; do not silently broaden criterion 1.

## Files

- global/skills/minecraft/SKILL.md

## Scope

global/skills/minecraft/**
