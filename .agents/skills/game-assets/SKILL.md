---
name: game-assets
description: Inventory and validate game art, audio and model assets and record visual QA.
---

# game-assets

Run from the game repository root. In the standalone toolkit, use the same paths without the `.game-toolkit/` prefix.

Read `.game-toolkit/docs/ASSET_PIPELINE.md`. Map existing manifests without modifying runtime references. Run `node .game-toolkit/scripts/validate-manifest.mjs --repo . --manifest <file>`. Inspect previews on the target device or emulator. Report missing files, budget failures and provenance gaps. Use original sources for changes and retain rejected items outside release inputs.
