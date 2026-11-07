# Art and sound pass: everything that's a placeholder

## Environment pass 02 — 7 November 2026

Five independently generated paintings now replace the fallback backdrops for `service`,
`corridor17`, `yard`, `records` and `laundry`. Runtime WebPs are in `src/assets/art/*-v2.webp`;
original PNGs, exact generation prompts, native dimensions and provenance are in
`art-source/environment-pass-02/manifest.json`. Generation used the built-in image tool
with the supplied Mariner Motel master board as a style reference, not as a crop source.
The five runtime images total 2,014,996 bytes. Four are approximately 9:16 at 940–941×1672;
records is 1054×1492, and uses the existing responsive cover crop. No source is upscaled.

All nine scene keys now have paintings, although exterior/reception/security/Room 17
and the portraits remain the earlier studies. The tables below retain the original backlog;
the five formerly missing scene backdrops are addressed by this pass.

These are atmosphere plates. Room prop cards and hidden-object targets remain enabled:
the painted objects are not aligned interaction layers. Bespoke pickup/open states,
hidden-object compositions, CCTV frames, clean expression cutouts, puzzle surfaces and
recorded audio remain unfinished. The supplied WIP pack has been inspected, but its
reference crops and synthesised audio have not been presented as final assets or imported.

Every asset is wired through `src/assets/manifest.ts`. Drop a file into `src/assets/…`, import it in the manifest, map it to its key, and the game uses it. Anything not mapped falls back to a generated placeholder, so you can replace things one at a time.

Style direction is in `../The_Last_Check_In/OVERHAUL_REVIEW.md`, section 7: one painted style, portrait 9:16, a tired late-70s/80s coastal motel, slate shadows, amber practical light, teal for surveillance, red only for danger.

## 1. Scene backdrops

Portrait 9:16, 1080×1920 source, WebP. Shown cropped behind dialogue (top ~45% of the screen) and full-bleed behind escape rooms.

| Key | Used in | Current |
|---|---|---|
| `exterior` | Title fallback, ending | Generated study from first art pass (landscape crop) |
| `reception` | Levels 1–2, name screen | Generated study (landscape crop; reads as a 1920s study, not a motel) |
| `security` | Levels 3–4, 6–8, 16, 22, 27–28 | Generated study (landscape crop) |
| `service` | Levels 5, 17, 20–21 | Generated SVG placeholder |
| `corridor17` | Level 9 | Generated SVG placeholder |
| `room17` | Levels 10–11 | Generated study (landscape crop; reads as a log cabin) |
| `yard` | Levels 12–13 | Generated SVG placeholder |
| `records` | Levels 14–15, 18–19, 26 | Generated SVG placeholder |
| `laundry` | Levels 23–25 | Generated SVG placeholder |

`TITLE_ART`: vertical title image. Currently the first art pass's exterior study.

Nice to have: a second state for repeat locations (security with the corkboard filling up, the corridor flooded, Room 17 tossed).

## 2. Portraits

Half-body, transparent background, same light rig for all four, about 800 px tall, WebP with alpha. Keyed by the first word of the speaker tag, so `OWEN · PHONE` uses `OWEN`.

| Key | Needs | Current |
|---|---|---|
| `NINA` | neutral, frightened, relieved | One cropped study, no expressions |
| `CLAIRE` | guarded, grieving, angry | One cropped study |
| `OWEN` | evasive, broken | One cropped study (reads as stock "trucker") |
| `DANIEL` | friendly, threatening | One cropped study. He now appears in person, so the friendly version matters |

To support expressions, extend `PORTRAITS` to `NINA_FRIGHTENED` etc. and add the variant to speaker tags in `levels.ts` (`NINA · FRIGHTENED|…`). The lookup uses the first word today; that's a five-line change in `src/core/art.ts`.

## 3. Hidden-object scenes (biggest art job)

Painted 3:4, 1536×2048 or larger, dense clutter with the target objects painted in. Target positions are percentages in `levels.ts`; paint the objects there, or move the percentages to match your painting. Once painted, swap the emoji glyphs for transparent tap regions (`src/puzzles/hidden.ts`, `ho-target` style).

| Level | Scene | Targets (x%, y%) |
|---|---|---|
| 2 | Reception desk, ransacked then tidied | 4 receipts (14,84) (85,12) (47,26) (76,71), Nina's spare key (62,33), yellow sticky note (40,58) |
| 14 | Records office cupboard | Police report (72,22), insurance claim (27,47), maintenance request (55,64), archive tape (12,15), photo of Mara (86,82) |

## 4. Escape rooms

4:5 painted scene with each interactive object visible. Hotspot rectangles (x, y, w, h in %) are in `levels.ts`. When the painting shows the objects, set `PROPS_VISIBLE = false` in `src/puzzles/room.ts` and the labelled placeholder cards become invisible tap regions.

| Level | Scene | Objects to paint |
|---|---|---|
| 5 | Service corridor | Fuse cupboard, dark alcove under pipes, staff door with scuffs, mop bucket, hanging access reader |
| 9 | Corridor outside 17 | Room door with missing number plate, door mat, housekeeping cart, chalk housekeeping board (behind the cart), ice machine, staff keypad |
| 10 | Room 17, tossed | Dumped bedside drawer, windowsill with scratch, mattress half off, bin, bathroom door, painted-over air vent |
| 23 | Laundry entrance | Warped override tag, laundry basket, clipboard on a steam pipe, fire extinguisher, steel door, keypad |

Inventory icons (currently emoji): torch, screwdriver, 50c coin, work gloves. 128×128 PNG with alpha.

## 5. Puzzle skins

All boards are CSS today. Each needs a material treatment; none of them need new code beyond swapping backgrounds and colours in `src/styles.css`.

| Mechanic | Levels | What it should look like |
|---|---|---|
| Zip path | 1, 6, 12, 27 | Junction box / recorder board / yard map / server panel. Numbers as labelled terminals |
| Puzzle box | 3, 20, 21, 25 | Brushed steel cabinet, bakelite switchboard, hard tool case, industrial gate. Screws, sliders, dials, levers, rivets as sprites |
| Panels | 4, 13 | Eight illustrated CCTV/dashcam frames, each in a wide and a close version, with the path line painted to exit at the edges listed in `levels.ts` |
| Match-3 | 7, 26 | Five tile sprites (evidence icons, tape reels?), static texture, and the two hidden frames: the van at 11:34, Daniel at the wheel in 2019 |
| Timeline | 8, 18, 28 | Pinned index cards / film frames |
| Logic grid | 11, 22 | Carbon-copy booking sheet / police notepad |
| Cryptex | 15 | Brass cylinder with letter rings |
| Goods sort | 16 | Keycard rack, five card designs (NIGHT, OWNER, HOUSE, CONTRACTOR, GUEST) |
| Water sort | 17 | Filter tanks; water, oil, sludge, rust |
| Block fit | 19 | Shredded ledger strips with handwriting |
| Tilt maze | 24 (and the stage in 21) | Valve diagram / ball-bearing tray |

## 6. Sound

Synthesised placeholders for everything. Recorded files go in `src/assets/audio/` and map by name in `AUDIO_FILES`. Use m4a (AAC) so iPhone plays them. Keep the whole set under 8–10 MB.

Effects (each name is called from code already):

| Name | Used for |
|---|---|
| `tap` | Dialogue advance, minor taps |
| `pick` / `place` / `swap` | Picking up, placing and swapping pieces |
| `invalid` | Illegal move |
| `solve` | Puzzle solved |
| `clue` | Evidence card appears |
| `power` | Circuits and pumps come alive (zip, water) |
| `door` | Doors unlocking, level change |
| `paper` | Cards, hints, ledger strips |
| `metal` | Plate drops |
| `click` | Dials, levers, cryptex rings, path junctions |
| `static` | Recordings, intercom, wrong patch socket |
| `phone` | Phone lines in dialogue |
| `pour` | Water sort |
| `clear` / `combo` | Match-3 clear and cascade, goods rack clear |
| `roll` | Tilt maze ball |
| `ratchet` | Screws |
| `latch` | Puzzle-box stage opens, cryptex opens, cable seated |
| `chapter` | Chapter card |
| `found` | Hidden object found, room item picked up |

Ambience, one loop per scene (currently filtered noise): exterior rain and surf; reception rain on glass and fluorescent buzz; security monitor fans; service corridor drips and pipe creaks; corridor 17 ice machine hum; Room 17 rain on the window; yard wind and rain on metal; records muffled rain; laundry boiler roar and hiss. Hooking these up needs a small addition to `audioScene()` in `src/core/audio.ts`, since ambience is synthesised there today.

Music, five cues plus three stingers (currently four sine pads): title, investigation loop, tension loop, chapter 4 pressure, resolution; stingers for clue found, chapter end, Nina's voice. Music already ducks under dialogue.
