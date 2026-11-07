# The Last Check-In (v0.3, WIP art and audio integrated)

A 28-puzzle crime mystery for phones. This folder is the rebuilt game. The old single-file prototype is in `../The_Last_Check_In/` for reference only.

All nine locations have painted backdrops, Nina and Claire have expression portraits, and every sound plays from a file: 22 effects, 9 room tones, 5 music cues, 3 stingers. All of it is draft quality. Escape-room and hidden-object scenes, most puzzle boards and recorded audio are still to come. [ASSETS.md](ASSETS.md) has the status of every asset and what's left.

## Run it

```bash
npm install
npm run dev            # local dev server with hot reload
```

Open the address it prints. Add `?debug=1` to the URL (or tap the title seven times) for developer tools: a **DEV skip** button on every puzzle and a menu to jump straight to any puzzle. Jumping uses a sandbox and never touches the real save.

## Build it

```bash
npm run build          # installable web app (PWA) in dist/
npm run build:single   # one self-contained HTML file in dist-single/index.html
```

- **To put it on her phone:** it's published to GitHub Pages at **https://kavemankai.github.io/Mobileshai/**. Open that in the phone browser, then "Add to Home Screen" (Safari: Share → Add to Home Screen; Chrome: ⋮ → Add to Home screen / Install app). It installs like an app, runs full screen in portrait, and works offline once it has loaded once.
- **How publishing works:** `.github/workflows/pages.yml` runs on every push to `main` that touches `game/`. It installs, runs `npm test`, builds, and deploys `dist/`. If the tests fail, nothing is published. You can also run it by hand from the Actions tab (Deploy game to GitHub Pages → Run workflow).
- **One-time setup:** repo Settings → Pages → Build and deployment → Source: **GitHub Actions**. And set the default branch to `main` (Settings → General), because Pages only deploys from the default branch unless you change the `github-pages` environment rules.
- **To send it as a file:** `dist-single/index.html` is everything in one file. Some Android browsers block local HTML files, so hosting is more reliable.

## Test it

```bash
npm test               # solver, asset and difficulty-budget tests (about 70 checks)
npm run build:single && npm run e2e   # browser walkthrough in Chromium, screenshots in artifacts/
npm run check          # everything above

npm run build:single && npx vite-node tests/playthrough.ts   # solves all 28 puzzles by tapping the real UI
ONLY=7,26 npx vite-node tests/playthrough.ts                 # just some levels
GEN=1 npx vitest run tests/sim/generate.test.ts              # search for new puzzle designs (not part of the suite)
```

The solver tests replay each puzzle's solution through the same rule functions the UI uses (zip paths, panel arrangements, water pours, card sorts, maze tilts, logic-grid uniqueness, room item chains, lever minimum presses). Change a level's data and the tests tell you if you broke it.

**Difficulty budget** (`tests/balance.test.ts`). The puzzle data is measured, not eyeballed: match-3 is simulated with a casual player (random legal swaps) and a good one, the path boards are counted for how many solutions they have, logic clues are checked one by one for being needed, mazes and lever grids for their shortest solution, and within each kind of puzzle a later level must never be smaller than an earlier one. Change a level and a failing test says which number moved.

The browser test also checks that music, room tone, effects and stingers play from files (not the synth fallback), that every image loads, and that mood portraits show. It plays all 28 levels through the real UI (tapping every dialogue line), checks every puzzle at 360 px and 390 px widths, solves the mechanics with real taps (path boards, escape room, keypad, logic grids, accusation, cryptex, puzzle box, tilt maze, match-3), and checks hints, skips, save and resume. It also guards the bugs found in the audit: readable button text on paper boards, taps landing on the right square all the way down a path board, timeline cards scrolling the page, and the match-3 reveal being shown before the evidence card.

## Where things live

| Path | What it is |
|---|---|
| `src/story/levels.ts` | The whole script: chapters, dialogue, clues, hints and each level's puzzle data |
| `src/puzzles/*.ts` | One file per mechanic. Pure rule functions at the top (tested), the UI below |
| `src/puzzles/index.ts` | Registry mapping `kind` to a puzzle module |
| `src/ui/app.ts` | Screens and flow: title, name, chapter cards, story, puzzle, evidence, settings, debug |
| `src/core/` | Types, save/settings, audio engine, placeholder art, DOM and random helpers |
| `src/assets/manifest.ts` | **The only file the art and sound pass needs to edit** |
| `src/styles.css` | All styling |
| `public/` | PWA manifest, icon, service worker |
| `tests/` | Solver tests (Vitest) and browser test (Playwright) |

## The 13 mechanics

| Kind | Levels | Based on |
|---|---|---|
| `zip` path | 1, 6, 12, 27 | Zipstache / LinkedIn Zip |
| `box` puzzle box (screws, sliders, dials, levers, hidden button, patch cables, tilt stage) | 3, 20, 21, 25 | Odd Machines, Tiny Machinery |
| `room` escape room with items and keypads | 5, 9, 10, 23 | Mystery Box, Benjamin's Room, Blackmoon Mansion |
| `timeline` order without timestamps | 8, 18, 28 | Listory |
| `logic` grid, optional accusation | 11, 22 | Lockstep, 123doku |
| `hidden` object | 2, 14 | Hidden Birds |
| `panels` arrange and zoom frames | 4, 13 | Gorogoa |
| `match3` reveal | 7, 26 | Zukora |
| `cryptex` | 15 | The Da Vinci Cryptex |
| `goods` sort | 16 | Pocha Moonlight |
| `water` sort | 17 | Water Sort Deluxe |
| `blockfit` | 19 | Block Puzzle Pro |
| `tilt` maze | 24 | Tilt Maze Garden |

## Adding or changing a puzzle

1. Edit the level's `puzzle` object in `src/story/levels.ts`. The types in `src/core/types.ts` say what each kind needs.
2. Run `npm test`. If the data is unsolvable, ambiguous or too easy, a test fails and says which level.
3. Update that level's two hints if the solution changed. Hint 1 points, hint 2 solves.

A new mechanic is one file in `src/puzzles/` exporting a `PuzzleMount`, plus a line in `src/puzzles/index.ts` and a type in `src/core/types.ts`.

## Known limits of this build

- Art and audio are drafts (see ASSETS.md). The audio is synthesised, not recorded.
- The single-file build is about 8 MB because assets are inlined. Use the PWA build for her phone.
- Progress saves at every dialogue line and phase change. A puzzle in progress restarts from the beginning after a reload.
- Phone checks are Chromium emulation. It still needs a session on her actual phone: real touch feel, audio on the speaker, tilt permission on iPhone.
- Board animation is CSS only. If the match-3 or sort boards feel flat after the art pass, those two are the candidates for PixiJS.
