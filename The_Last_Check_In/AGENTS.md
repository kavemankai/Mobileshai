# Repository Instructions for Codex

This is a game implementation task. Prefer making/validating real source changes over responding with a high-level plan.

## Files
- `source/story.js` is canonical narrative content and level data. Keep all four chapters and 28 puzzle/clue records intact.
- `source/engine.js` owns state, saving, puzzle mechanics and screen transitions. It contains working debug skip logic.
- `source/art.js` owns original SVG scene illustrations; replace/extend with packaged original art.
- `source/style.css` contains the base styles; `source/polish.css` owns the production overrides.
- `source/soundscape.js` owns procedural audio and persistent settings. `source/interaction.js` owns gestures, settings UI and isolated developer inspection.
- Build order: story.js, art.js, soundscape.js, engine.js, interaction.js. Run `python tools/build_singlefile.py` with no runtime dependencies.
- `source/template.html` plus `tools/build_singlefile.py` produce the standalone HTML at `dist/The_Last_Check_In.html`.
- `source/level_manifest.json` is an **inspection aid**, generated from `story.js`; `story.js` wins if they diverge.
- `references/` contains screenshots of the *baseline prototype*, not final art; improve beyond them.

## Requirements
- Keep native touch controls on mobile portrait and keyboard focus/accessibility on desktop.
- Preserve save key `last-check-in-complete-v1` or perform a tested migration.
- Keep code asset-local/offline; no reliance on paid APIs or internet resources.
- Developer tools hidden by default; explicit `?debug=1`, `#debug` or 7 title taps can expose them. Developer Skip puzzle must call the same victory/evidence/reveal path as solving normally.
- A regular player still gets two progressive hints and an optional skip with no penalty.
- Check 360×780, 390×844, 412×915 and desktop. No clipped puzzle controls or unscrollable content.
- Source and built output must be in sync when finished. If you change the build process, update these instructions and keep an easy, reproducible offline build.
- Do not introduce copyrighted music or scraped art.
- Preserve correct chapter sequence and the complete solved ending.

## Definition of done
All 28 puzzles can be completed; all story beats render; clues and save remain correct; debug skip works at every level; polished UI, visual assets, and soundscape are present across the whole game; automated checks and screenshots exist; the shipped web build works offline.
