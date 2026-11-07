# The Last Check-In — integrated art pass

Produced 7 November 2026.

## What's new

This is **an actual playable HTML integration**, not just art direction images.

- Painted (generated) artwork integrated for **Mariner Motel exterior**, **reception**, **security office** and **Room 17**, with layered lighting/rain and a safe illustrated fallback while images load.
- Cinematic portrait imagery for the four existing speaking characters: **Nina, Claire, Owen, Daniel**. Portraits are displayed over the story scene, not baked into story images.
- Separate vertically composed motel exterior for the title screen. The motel name, story content and 28-level progression are unchanged.
- All generated artwork is embedded as `data:image/webp;base64` into the standalone output; no external assets are loaded at runtime.
- Accessible HTML dialogue, captions, evidence, buttons and puzzle numbers remain code-rendered. Puzzle rules and save formats are unchanged.

## Still pending

- Generate **full-resolution**, independently commissioned background illustrations for each of the eight locations; the current reception/security/Room 17 art originated as cropped image-generation *concept boards*, so they are softer than production final art. Exterior artwork is higher resolution but its motel sign was corrected during the reference pass.
- Design **front/back/neutral/tense expression sheets** for the four characters instead of reusing a single cropped portrait per character; the current style study is not a narrative casting bible.
- Paint the records room, service corridor, disused laundry and rear yard (these still use the original procedural vector scenes).
- Give the seven puzzles bespoke material/texture art and small animations without changing hitboxes, solutions or the 28-stage case timeline.
- Finish authored environmental audio and character transition work before treating this as a final commercial art pass.

## Source map and build

Artwork files: `assets/art/*.webp`. Source scene logic: `source/art.js`. Layout: `source/polish.css`. Offline generator: `tools/build_singlefile.py`, which embeds the WebP images. Runnable offline build: `dist/The_Last_Check_In.html`.

To build, run `python tools/build_singlefile.py`. No external Python packages required for rebuilding. The original game is preserved in the input package; this folder is the edited version.

## Verified in this environment

- `tests/smoke_playwright.py`: PASS at 360×780 and 412×915; normal player controls and debug skip behave as before.
- `tests/full_case_debug.py`: PASS across 28 levels, 28 correct clues, four chapters and ending.
- Phone-sized render captures: `previews/` (screenshots for title, rooms, characters and circuit).
- The larger `tests/production_qa.py` suite wasn't completed in this environment because its localhost web server URL was blocked by the browser sandbox, not because of a reported game bug.

## Story canon, not the concept art text

The correct setting is **Mariner Motel**. **Room 17** is the room under investigation. The player arrives at 11:43 PM, and the discrepancy concerns a checkout at 11:18 PM. This pass never changes script/story.js or imports invented signage, roles or room numbers from AI concept boards. The generated portraits are image studies assigned to the existing characters by HTML logic, not new story canon.
