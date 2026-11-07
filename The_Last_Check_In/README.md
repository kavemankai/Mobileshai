# The Last Check-In — Codex Handoff Package

**Overhaul review, 7 November 2026:** see [OVERHAUL_REVIEW.md](OVERHAUL_REVIEW.md) for the engine decision, puzzle genre lineup and narrative/art/sound direction.

**Integrated generated-art pass delivered, 7 November 2026.** See [ART_PASS_NOTES.md](ART_PASS_NOTES.md) for actual image integration, tests, production limitations and next steps. The original notes below describe the prior game baseline. Open `dist/The_Last_Check_In.html`. See [PRODUCTION.md](PRODUCTION.md) for current features, source map, controls, testing and known limits. The rest of this README describes the supplied baseline handoff.

**Status:** Working complete HTML5 game plus a carefully scoped production-polish task. Not yet a commercial-quality art/audio build. Version of this package: 2026-11-07.

## Fastest way to hand this to Codex
1. Unzip this archive into an empty project folder (ideally a Git repository).
2. Open that folder with Codex and tell it: **"Read `CODEX_START_HERE.md` and `AGENTS.md`; implement the complete game-polish brief. Do not stop at a plan. Update the source, run tests, and deliver the offline playable build."**
3. Alternatively, copy the text of `PASTE_INTO_CODEX.txt` as your first Codex instruction.
4. Keep these exact files in the repository. Codex has the baseline game, story/level data, reference screenshots, debug tools and acceptance tests.

## Play now
Open `dist/The_Last_Check_In.html` in a browser that supports local HTML, or serve this folder as a static website (e.g. `python -m http.server 8000`, then open `http://localhost:8000/dist/The_Last_Check_In.html`). No installation or account is needed. Android Chrome sometimes refuses direct local-file navigation; a static host or local HTML viewer is an alternative.

## Editable source / rebuild
- `source/story.js` — dialogue, 28 puzzles, clues, 4 chapters.
- `source/art.js` — current in-file SVG environments.
- `source/engine.js` — save/menus/input/puzzle logic/audio and **new developer skip**.
- `source/style.css` — current design.
- `source/template.html` — single-page shell with source insertion markers.
- `source/level_manifest.json` — readable level summary.

To regenerate the zero-dependency single-file version, run:

```bash
python tools/build_singlefile.py
```

## Developer skip puzzle — WORKING in this baseline
- Add `?debug=1` to a hosted URL (or `#debug`) before starting.
- Or tap the title **THE LAST CHECK-IN** seven times on the title screen. This only lasts for the current page session unless you use the URL flag.
- In puzzle play, a copper dashed **DEV · 1 / 28 — Skip puzzle** row appears. Tap **Skip puzzle** once to receive the clue and trigger the correct story reveal.
- Regular players instead get Hint 1 → Hint 2 → optional Skip puzzle, and cannot see developer controls.
- Debug mode does not form part of the persisted save data.

## Package layout
- `CODEX_START_HERE.md` — detailed one-shot implementation mandate.
- `AGENTS.md` — persistent coding-agent project instructions.
- `VISUAL_AUDIO_BRIEF.md` — complete UX, illustration, animation and audio brief.
- `STORY_AND_LEVELS.md` — canonical case facts, sequence and all 28 stages.
- `QA_ACCEPTANCE.md` — acceptance tests and non-regression checks.
- `PASTE_INTO_CODEX.txt` — copyable one-shot instruction.
- `source/` — editable game source and manifest.
- `dist/` — runnable offline game.
- `references/` — screenshots from prototype and new debug tool.
- `tools/` — reproducible build.
- `tests/` — Playwright smoke and complete 28-level debug walkthrough tests.

## Known limitations of baseline
Prototype artwork is stylised SVG with limited character presence. Audio is generated short WebAudio tones rather than authored ambience/music. Most puzzles are visually abstract and tap-based; sophisticated scene transitions and touch dragging need polish. A phone browser can save progress if local storage is permitted. This is a web game, not an APK.
