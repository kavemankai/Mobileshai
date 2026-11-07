# Migration to Godot

The web build in `game/` (TypeScript, Vite) stays deployed and is the reference until the Godot build reaches parity and is approved. The Godot project lives here, in `godot/`. Nothing in `game/` or the Pages workflow changes until then.

**Engine:** Godot 4.6.2, GL Compatibility renderer (the only one that exports to web), single-threaded web export (no COOP/COEP headers needed, so it works on GitHub Pages).

## Set up and run

```bash
python3 godot/tools/setup_godot.py                 # editor + web templates, SHA-512 verified (--verify-full in CI)
G=~/.cache/godot-tools/godot-4.6.2/godot
$G --headless --path godot --import                # first import of assets
$G --headless --path godot --export-release "Web" build/web/index.html
node .game-toolkit/adapters/web/serve.mjs --dir godot/build/web --port 4180
```

`cd godot && $G --headless --quit-after 60` runs the project for 60 frames and prints any script errors.

## Findings that shaped the build

These were found by trying, not assumed. Each one cost an hour somewhere if forgotten.

- **Fonts must be loaded as imported resources**: `load("res://assets/fonts/x.ttf")`. `FontFile.load_dynamic_font("res://…")` reads the raw file, which an exported build does not contain, so every glyph silently became a missing-character box.
- **A JavaScriptBridge callback returns nothing to the page.** To read a result, the page passes a holder object and Godot writes into it: `args[0].v = json`. The `window.__lci` shim wraps this.
- **Control rectangles for tests** come from `get_global_transform_with_canvas()` run through `get_viewport().get_final_transform()` and divided by `devicePixelRatio`. Verified: a real mouse click at the reported centre presses the button at 390×844@3, 844×390@2 and 1280×720@1.
- **Godot cannot play AAC.** The 39 `.m4a` files were converted to Ogg Vorbis (`tools/build_assets.py`).
- **Emoji**: `NotoColorEmoji` is 10 MB; a 109 KB subset holding only the glyphs the placeholder icons use renders in colour as a font fallback.
- **JSON numbers load as floats.** `Game` normalises whole numbers back to `int` on load.
- **The wasm engine is 37 MB uncompressed** (about 9 MB gzipped). The first load is heavy; the service worker caches it afterwards.

## Layout

```
godot/
  project.godot, export_presets.cfg, main.tscn
  data/levels.json            generated from game/src/story/levels.ts (tools/export_levels.ts)
  assets/                     art, portraits, items, tiles, cctv, audio (ogg), fonts
  scripts/autoload/           Game (state, saves, settings), Sound, QA (browser test bridge)
  scripts/core/               UI helpers, Fx (juice), FxButton
  scripts/ui/                 App router and screens
  scripts/puzzles/            one view per puzzle kind, plus models/ for the rules
  shaders/                    rain, vignette, static, liquid, glow
  tests/                      headless rule tests, Playwright scenario and playthrough
  tools/                      setup_godot.py, build_assets.py, export_levels.ts
```

## Status

See the task list in the pull request. Milestones: M0 toolchain (done), M1 app shell, M2 to M4 the 13 puzzles, M5 QA, CI and deploy.

## Known limits of a Godot web build

- **No screen-reader support.** The game draws to a canvas, so there is no DOM text for TalkBack or VoiceOver. Keyboard focus order and target sizes are covered; screen readers are not, and this is a loss against the web build.
- **Larger first download** than the 8 MB web build, and iOS Safari is the platform most likely to show audio or memory quirks. Neither can be tested without a device.
- **Saves**: Godot web stores `user://` in IndexedDB, not localStorage. The first run imports an existing web save from localStorage once.
