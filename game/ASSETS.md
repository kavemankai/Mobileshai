# Art and sound: status and what's left

Last updated 7 November 2026, after integrating the seven-part WIP asset pack (`../asset-handoff/zips/`).

Every asset is wired through `src/assets/manifest.ts`. Anything not mapped falls back to a generated placeholder or a synthesised sound, so pieces can be replaced one at a time. `tests/assets.test.ts` fails if a scene, portrait mood, item icon or sound the code uses has no file.

Style direction: `../The_Last_Check_In/OVERHAUL_REVIEW.md`, section 7. One painted style, portrait 9:16, a tired late-70s/80s coastal motel, slate shadows, amber practical light, teal for surveillance, red only for danger.

## Status at a glance

Nothing here is final production art or audio. "Draft" means it's in the game and looks right in context, but should be replaced.

| Area | In the game now | Status |
|---|---|---|
| Scene backdrops | 9 of 9 painted | 5 good drafts (env pass 02), 4 soft WIP plates |
| Title art | WIP neon exterior | Soft WIP plate |
| Portraits | Nina ×3 and Claire ×3 expression cutouts; Owen and Daniel first-pass crops | Draft. Owen/Daniel expressions rejected (see below) |
| Hidden-object scenes | Scene backdrop dimmed behind emoji items | Placeholder. Needs dedicated paintings |
| Escape rooms | Scene backdrop with labelled prop cards | Placeholder. Needs aligned object layers |
| CCTV frames (level 4) | 4 grayscale footage pairs behind the path | Draft. Level 13 still has none |
| Inventory icons | Torch, screwdriver, coin, gloves | Draft (flat icons) |
| Match-3 tiles | 5 tile sprites | Draft, usable |
| Other puzzle boards | CSS | Placeholder |
| Sound effects | 22 of 22 from files | Synthesised drafts, not recorded foley |
| Room tone | 9 of 9 scene loops (18 s) | Synthesised drafts |
| Music | 5 of 5 cues (32 s loops) | Synthesised drafts |
| Stingers | 3 of 3 (clue found, chapter end, Nina's voice) | Synthesised drafts |

The single-file build is now about 8 MB, because images and audio are inlined as base64. The PWA build (`npm run build`) keeps them as separate cached files, which is the better way to put it on a phone.

## What was integrated from the WIP pack, and what wasn't

**Used**
- Scenes: `exterior`, `exterior_title`, `reception`, `security`, `room17` (as `*-wip.webp`). They replace the first-pass landscape crops, which read as a 1920s study and a log cabin. The WIP plates are enlarged from a reference board: soft detail, and a blurred lower third. CSS frames the painted middle (`object-position: center 35%`).
- Portraits: `nina_neutral|frightened|relieved`, `claire_guarded|grieving|angry`. Script lines choose them with `~mood` (`'NINA~relieved|You came.'`).
- Inventory icons (128 px), match-3 tiles 1–5, CCTV `panel_01/02/05/06` (wide and close, mapped to level 4 frames b/a/c/d).
- All 39 audio files.

**Not used, and why**
- `art/service|corridor17|yard|records|laundry.webp`: superseded by the env pass 02 paintings (`*-v2.webp`). The pack itself says not to overwrite them.
- `interactive/level_*.webp` and `hidden/level_*.webp`: placeholder rectangles are baked into the image and they aren't aligned with the hotspots in `levels.ts`. Using them would put two sets of boxes on screen.
- `puzzles/*.webp` skins (cabinet, switchboard, cryptex…): generic dark noise panels with the title text baked in. They add nothing the CSS boards don't already do, and the baked labels collide with board content.
- `portraits/daniel_*`: "Friendly" and "Threatening" are written into the image, the top of the head is sliced flat, and the threatening face is warped. `portraits/owen_*`: the back and side of the head are cut off. Both keep their first-pass portraits.
- `cctv/panel_03/04/07/08`: crops of "CAM 03" labels and timestamps, not footage.
- `build_*.py`, `finish_pack.py`, `improve_portraits.py`: pack build scripts. Not run, not needed at runtime.

The zips stay in `../asset-handoff/zips/` as the untouched originals.

## Environment pass 02 (provenance)

Five independently generated paintings for `service`, `corridor17`, `yard`, `records` and `laundry`. Runtime WebPs are `src/assets/art/*-v2.webp`; original PNGs, exact prompts, native dimensions and provenance are in `art-source/environment-pass-02/manifest.json`. Four are about 9:16 at 940–941×1672; records is 1054×1492 and uses the responsive cover crop. None are upscaled.

## What's left, in priority order

### 1. Escape rooms (levels 5, 9, 10, 23)

4:5 painted scene with every interactive object visible at the hotspot rectangles in `levels.ts` (x, y, w, h in %). When the painting shows the objects, set `PROPS_VISIBLE = false` in `src/puzzles/room.ts` and the labelled cards become invisible tap regions. Opened/taken states as separate layers.

| Level | Scene | Objects |
|---|---|---|
| 5 | Service corridor | Fuse cupboard, dark alcove under pipes, staff door with scuffs, mop bucket, hanging access reader |
| 9 | Corridor outside 17 | Door with missing number plate, door mat, housekeeping cart, chalk board (behind the cart), ice machine, staff keypad |
| 10 | Room 17, tossed | Dumped bedside drawer, windowsill with scratch, mattress half off, bin, bathroom door, painted-over air vent |
| 23 | Laundry entrance | Warped override tag, laundry basket, clipboard on a steam pipe, fire extinguisher, steel door, keypad |

### 2. Hidden-object scenes (levels 2, 14)

Painted 3:4, 1536×2048 or larger, dense clutter with the targets painted in. Then swap the emoji for invisible tap regions in `src/puzzles/hidden.ts`.

| Level | Scene | Targets (x%, y%) |
|---|---|---|
| 2 | Reception desk | 4 receipts (14,84) (85,12) (47,26) (76,71), Nina's spare key (62,33), yellow sticky note (40,58) |
| 14 | Records cupboard | Police report (72,22), insurance claim (27,47), maintenance request (55,64), archive tape (12,15), photo of Mara (86,82) |

### 3. Replace the four soft WIP plates

`exterior`, `reception`, `security`, `room17` (and the title) as independent paintings matching env pass 02.

### 4. Portraits

Owen (evasive, broken) and Daniel (friendly, threatening) as clean cutouts matching the Nina/Claire set. Then tag their lines with moods in `levels.ts`; the asset test will catch a mood with no file.

### 5. CCTV and the two hidden frames

- Level 13 frames (ids p, q, r, t: dashcam 11:35, yard map, laundry wall, dashcam 11:36), wide and close, mapped in `PANEL_ART`.
- Level 4 frames that actually show what their captions say (reception terminal, rear-yard van).
- Match-3 reveal images: the van at 11:34 (level 7) and Daniel at the wheel in 2019 (level 26). Today the reveal is text.

### 6. Puzzle boards

Material treatment for the zip boards, puzzle boxes (screws, sliders, dials, levers, rivets as sprites), cryptex, keycard rack, filter tanks, ledger strips and valve maze. CSS only; no rule changes needed.

### 7. Audio

All cues play from files, but they are synthesised drafts. For final polish: recorded foley for puzzle-box mechanics (latches, ratchets, sliding wood), real rain and room tone, and a composed or licensed score. Same file names in `src/assets/audio/` replace them with no code change. Keep m4a (AAC) for iPhone, and log provenance here.

### 8. Device check

Real phone: art crops, hotspot accuracy, audio balance on the speaker, iPhone tilt permission, offline install.
