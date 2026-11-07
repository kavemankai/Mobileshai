---
name: repo-game-audit
description: Audit an existing game repository before implementation or release work.
---

# repo-game-audit

Run from the game repository root. In the standalone toolkit, use the same paths without the `.game-toolkit/` prefix.

Run `node .game-toolkit/scripts/detect-engine.mjs --repo .` and use `--project` if multiple candidates are reported. Record HEAD, default branch, project-local instructions, locked versions, documented commands and CI triggers. Locate the authoritative game rules, save entry points and asset manifest. Review scripts before executing the existing checks. Return a prioritized list of blockers, regressions and optional polish with command exit codes and open gates.
