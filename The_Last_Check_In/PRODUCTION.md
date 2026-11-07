# The Last Check-In — production build

A complete offline mystery: 28 puzzles, four chapters and the original solved ending. Integrated image-generated art pass: 7 November 2026. See ART_PASS_NOTES.md for a distinction between painted scene studies and original SVG fallback artwork.

## Play and build

Open `dist/The_Last_Check_In.html` in a browser. It is self-contained: no downloads, accounts, external fonts, libraries or runtime server calls. Some Android browsers restrict local HTML; serving the file is an alternative.

From this folder:

```powershell
python -m http.server 8000
```

Open http://localhost:8000/dist/The_Last_Check_In.html. A hosted page must be loaded before disconnecting; this build does not install a service worker or promise a new offline navigation to a remote host. The downloaded HTML itself works offline.

Rebuild with Python, with no build dependencies:

```powershell
python tools/build_singlefile.py
```

## This version

- Eight original illustrated locales with physical detail, window rain, reflections, lighting, camera movement and four recognisable character portraits. Characters have concerned/tense treatments.
- Copper circuit boards, shuffled paper records, illustrated restoration fragments, overlapping metal plates, pinned evidence pairings, physical keypads and vehicles on a wet service-yard grid. All seven mechanics apply throughout the 28 stages.
- Drag records into order, drag evidence between columns or move cars along their lanes. Tap-swap, tap-pair and vehicle arrow controls remain available. Sliding fragments move by tapping adjacent tiles.
- Clues appear as readable discovery documents and accumulate chronologically on the evidence board. Replay dialogue or move directly to the investigation without a timed lockout.
- Original procedural rain/room tone, an evolving ambient score and separate telephone, paper, metal, electrical, keypad, interference and discovery cues. Audio unlocks on interaction and suspends while the tab is hidden.
- Persistent master, music, ambience and effects volumes, mute, reduced motion and three text sizes. Dialogue advances at the reader's pace; there is no forced typewriter delay.

Progress keeps `last-check-in-complete-v1`. Settings use a separate `last-check-in-settings-v1` key. Resetting a puzzle does not reset the case. Starting a new case requires confirmation when a save exists. Browser storage must be permitted to retain progress.

## Developer tools

Add `?debug=1` or `#debug` to the URL, or tap the title seven times. During puzzles, **Skip puzzle** immediately uses the normal clue/reveal path. **Tools** opens stage inspection and sound auditions. Stage jumps enter an isolated sandbox and never write over the standard case. Return to title and Continue to restore the saved investigation. Ordinary debug skips without a jump save normal progress.

Normal players receive two progressive hints, then an optional skip with no penalty. Developer tools are hidden by default.

## Source

- `source/story.js`: unchanged canonical narrative, solutions, clues and chapters.
- `source/art.js`: original SVG environments, composited character portraits and material drawing helpers.
- `source/style.css`, `source/polish.css`: base layout and production visual system.
- `source/soundscape.js`: bounded WebAudio sound graph and settings persistence.
- `source/engine.js`: rules, transitions, evidence and compatible saves.
- `source/interaction.js`: pointer gestures, settings, keyboard behaviour and isolated developer inspection.
- `tools/build_singlefile.py`: inlines the above into the standalone HTML.
- `artifacts/`: captured phone/desktop screenshots and machine-readable test results.

## Validation

```powershell
python -m pip install playwright
python -m playwright install chromium
python tests/smoke_playwright.py
python tests/full_case_debug.py
python tests/production_qa.py
```

The production test solves every puzzle through legal UI actions and checks exact clue awards, saves, settings, offline play, gestures, keyboard focus and all 28 layouts at 360×780, 390×844, 412×915 and 1280×900. See `artifacts/qa-results.json` and `QA_RESULTS.md` for the result and build hash. Screenshot capture settles finite animations for consistent visual review.

## Remaining limits

This is a web build, not an APK or installable PWA. Phone checks use Chromium viewport/touch emulation; physical Android/iOS devices, real speaker/headphone balance, midrange-device frame rates and screen-reader acceptance still need hands-on review. Artwork is authored vector illustration rather than painted raster art. Sound is procedural rather than recorded foley, voice acting or a mastered soundtrack. Scene changes use restrained camera/light transitions, not full character animation. These production limits do not remove any levels.

All runtime media is original and bundled; see `ASSET_LICENSES.md`. The supplied `references/` screenshots document the earlier prototype. The handoff briefs remain available unchanged.
