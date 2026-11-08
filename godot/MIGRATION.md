# Migration to Godot

The web build in `game/` (TypeScript, Vite) stays at the site root and is the reference until the Godot build is approved. The Godot project lives here, in `godot/`. The Pages workflow builds both: the Godot build is published at `/godot/`. Nothing in `game/` changed.

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

All 28 levels play in Godot: the story, saves, settings, the evidence board and all 13 puzzle kinds are built and animated.

| Kind | View | What moves |
|---|---|---|
| Path (zip) | `zip_puzzle.gd` | glowing trail that glides after the finger, retracts when you back up, numbers light up, line sweeps and bursts on a solve |
| Timeline | `timeline_puzzle.gd` | grip drag with live reorder (cards slide aside), arrows, tap-to-swap, ticks on a wrong check, thread lights up on a solve |
| Deduction (logic) | `logic_puzzle.gd` | ink-draw crosses and ticks, spreading auto-crosses, row and column highlight, accusation step |
| Cryptex | `cryptex_puzzle.gd` + `core/drum_wheel.gd` | cylinder drums with inertia, snap and click, golden lock-in |
| Sort (goods) | `goods_puzzle.gd` | cards fly in an arc and land with a squash, locked sets flash and burst |
| Pump tanks (water) | `water_puzzle.gd` | tank lifts, tips over the target, liquid runs across, stream drawn between |
| Signal recovery (match 3) | `match3_puzzle.gd` | swaps slide, pops burst, bounce-drop refill, cascades, line-clearer beams, TV static dissolves off the picture (`static.gdshader`) |
| Reassemble (blockfit) | `blockfit_puzzle.gd` | drag a strip with a ghost that turns green or red, snap, tap to lift back |
| Maze (tilt) | `tilt_board.gd` | rolling ball with trail, squash on walls, hole swirl, spinning valve; swipe, keys, buttons, phone tilt |
| Frames (panels) | `panels_puzzle.gd` | frames glide on swap, crossfade and punch zoom, lit path with a travelling bead |
| Search (hidden) | `hidden_puzzle.gd` | items pop and fly to the list, miss ripples, idle glimmer |
| Mechanism (box) | `box_puzzle.gd`, `box_stages.gd` | screws spin and drop, notched sliders, drum dials, spring levers, patch cables with sparks, maze stage |
| Explore (room) | `room_puzzle.gd` | items fly to the pockets, drag an item onto the scene, lit keypad |

Rules live in `scripts/puzzles/models/` as plain GDScript with no nodes, so `tests/test_models.gd` can check every level headless: Path and Cryptex are solvable, every Deduction level has exactly one solution, Water, Sort and Maze levels are solvable, every Frames level has a solution, every room can be finished, every lever stage can be lit, and random match-3 play clears the static.

## Tests

```bash
G=~/.cache/godot-tools/godot-4.6.2/godot
$G --headless --path godot --import
$G --headless --path godot --script res://tests/test_models.gd        # rules, every level
$G --headless --path godot --export-debug Web build/web/index.html
NODE_PATH=$(npm root -g) node godot/tests/qa/run.mjs --all --viewport 390x844    # every level, real mouse and keyboard
NODE_PATH=$(npm root -g) node godot/tests/qa/run.mjs --level 24 --viewport 360x640
NODE_PATH=$(npm root -g) node godot/tests/qa/run.mjs --offline                   # reload with the network off
node .game-toolkit/scripts/validate-manifest.mjs --repo . --manifest godot/asset-manifest.json
```

`tests/qa/run.mjs` jumps to a level through the debug bridge (`?debug=1`, never present in a normal session, and the jump runs in a sandbox that does not touch the real save), then a per-kind driver in `tests/qa/drivers/` finishes the puzzle with real pointer and key input at the positions the bridge reports, and checks the game reaches the evidence card. The bridge also reports every `qa`-tagged control's rectangle, so a test clicks exactly where a player would.

`asset-manifest.json` is generated by `tools/build_manifest.py`. The art and audio are the project's placeholder pack and are recorded as `license: pending-review`; the fonts are OFL-1.1, which the toolkit's policy does not pre-approve. A person has to decide both before release.

### Results (debug export, headless Chromium with SwiftShader)

| Check | Result |
|---|---|
| Every level, 390×844 | 28 of 28 pass |
| Every level, 360×640 | 28 of 28 pass |
| Every level, 844×390 (landscape) | 28 of 28 pass |
| Every level, 1280×720 | 28 of 28 pass |
| Title to ending in one run (real saves, 28 puzzles) | pass |
| Offline reload after a second visit | pass |
| Rule tests (`test_models.gd`) | pass |
| Asset manifest (79 assets) | validates |

The offline check needs two visits: Godot's service worker caches the engine and data on the first load it controls. A first-time visitor with no network cannot start the game.

Not run: any real device, TalkBack or VoiceOver, text-scale 2 and 3 sweeps, safe-area insets, release-export timing.

## Layout notes learned the hard way

- A wrapped `Label` reports its real height two or three frames after its width is set. Anything positioned from `get_combined_minimum_size()` has to wait (see `title_screen.gd`, `timeline_puzzle.gd`, the keypad).
- Tweening `position` on a child of a `Container` fights the container. Boards are plain `Control`s with manual layout; containers only hold UI.
- A node that defines `_input` receives every event in window coordinates. Board input uses `gui_input` instead; only the Maze defines `_input` on purpose, so arrow keys work wherever focus is.
- A puzzle that needs more room than the window gives calls `ask_height()`; in portrait `PuzzleScreen` makes the page scroll instead of squeezing the board. In landscape the request is dropped, the header moves to the right column, and the board fits the window (Deduction and Mechanism scroll inside themselves; Explore and Search go side by side).

## Known limits of a Godot web build

- **No screen-reader support.** The game draws to a canvas, so there is no DOM text for TalkBack or VoiceOver. Keyboard focus order and target sizes are covered; screen readers are not, and this is a loss against the web build.
- **Larger first download** than the 8 MB web build, and iOS Safari is the platform most likely to show audio or memory quirks. Neither can be tested without a device.
- **Saves**: Godot web stores `user://` in IndexedDB, not localStorage. The first run imports an existing web save from localStorage once.
