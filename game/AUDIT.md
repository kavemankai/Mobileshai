# Play and asset audit, 7 November 2026

Build audited: `main` at the Pages deploy (same build as https://kavemankai.github.io/Mobileshai/).

## Resolution

Everything below the "Verdict" heading is the audit as first written. This section records what was done about it. All fixes are on the same branch as the audit, with tests that fail if they regress.

**Result:** all 28 puzzles solve through the real UI (`tests/playthrough.ts`, 28/28, zero JS errors, zero synth fallbacks, no layout overflow). Unit and difficulty tests: 69 pass. Browser test: 38 checks pass, including one for each bug below.

### Must-fix bugs

| Bug | Fix | Guarded by |
|---|---|---|
| Button text invisible on paper boards (level 22 accusation, level 19 rotate) | `.btn` has an explicit ink colour. Accusation buttons now measure 11.8:1 contrast | e2e: contrast of every paper-board button, and of the accusation buttons |
| Path boards: taps landed on the wrong square (levels 6, 12, 27) | Rows are equal height, the tapped square is found with the element under the finger, and the line is drawn from real square positions | e2e: taps every square of levels 6, 12 and 27 |
| Match-3 never showed its picture | The tiles fade away and the finished frame is held for 2.6 s before the evidence card. Placeholder frames: the yard painting (the van) and Daniel's portrait (the driver) | e2e: reveal image loads and is held at least 1.5 s |
| Match-3 grind | A match also wipes one square of static past each end of the run. Static is no longer able to hide in a corner for hundreds of swaps | `tests/balance.test.ts`, below |

### Match-3, measured

The audit's bot took the first legal swap, which never aims at the static. The balance test simulates two realistic players with the game's own rules.

| | Static squares | Casual player (random legal swaps), median / 90th percentile | Good player, median | Audit's first-move bot |
|---|---:|---|---:|---|
| Level 7 | 25 | 20 / 35 swaps | 6 | 135 swaps |
| Level 26 | 45 | 36 / 58 swaps | 13 | gave up at 400 |

A good player's slow tail on level 26 used to reach 111 swaps. It is now 46. Without the new rule, a casual player took a median of 29 and 49.

### Should-fix issues

| Issue | Fix |
|---|---|
| Timeline cards blocked scrolling | Dragging moves to a handle. The page scrolls over the cards. Arrows are now 44×40 |
| Music looped every 32 s | Each cue plays once, fades, then rests 20 to 45 s with only room tone. This eases the repetition, but longer recorded cues are the real fix and are still on the sound pass |
| Title art read "YACKCY" | The small sign was repainted as a clean "VACANCY". The reception sign's unreadable small print now reads "MOTEL". The patch is visible up close |
| Text too small | Path-board labels moved to a legend. Frame captions wrap under the picture. Keycard labels are 11px, and racks are wider so cards are 40px. Logic row names wrap |
| Controls under 36px | Cryptex arrows 36×42, timeline arrows 44×40, tanks at least 37px wide. The browser test now enforces 36px |
| Oil unreadable | Legend and card text pick light or dark ink to suit the swatch. Oil is lighter |
| Level 5 alcove icon invisible | Replaced with a cobweb |
| Level 4 footage didn't match captions; level 13 had none | Stills that fit are kept. The van frame uses the yard painting. Level 13's six frames are crops of the yard and laundry paintings. All placeholders for real frames |
| "1 cells" | Singular and plural fixed |

### Difficulty

The ramp now climbs. Every number below is measured from the puzzle data by the game's own rules.

| Level | Before | After |
|---|---|---|
| 10 Room 17 | 6 spots, 1 item | 7 spots, 2 items, 2 locks (coin for the screws, screwdriver for the painted-shut grille) |
| 11 Guest of record | 4 clues, one flavour line | 5 clues, every one needed |
| 13 Dashcam | 4 frames, one answer | 6 frames, timestamps, exactly one arrangement is both connected and in time order, plus a connecting trap the game explains |
| 17 Flooded corridor | 4 liquids, 6 tanks, 14 pours at best | 5 liquids, 7 tanks, 17 pours at best |
| 20 Intercom | Levers 3 presses; patch chart printed outright; dial code printed | Levers 5 presses; 4-way patch chart solved by elimination; the dial code is read from the chart's result |
| 21 Contractor's case | Maze 4 tilts; code printed on the lid | Maze 7 tilts; the code comes from the case file (cloned at 10:57 PM, so 2257) |
| 22 Accusation | 4 rules, all direct matches | 6 clues, every one needed, all eliminations, none names the culprit directly |
| 23 Laundry override | 6 spots, 1 item | 8 spots, 2 items, a keypad behind a cover that needs a screwdriver |
| 24 Boiler maze | 8×8 grid, 7 tilts | 9×9 grid, 13 tilts |
| 25 Last barrier | 3×3 levers (5 presses), a trivial press panel | 4×4 levers (6 presses, the most a 4×4 allows), sliders, and a dial code read from the case file |
| 27 Uplink | 6×6, no blocked squares, 6 numbers | 7×6, six racks, 7 numbers, exactly one solution so it can't be guessed by snaking |

`tests/balance.test.ts` locks these in. Within each kind of puzzle (path, timeline, logic, frames, match-3, box, room, hidden object), a later level may not be smaller than an earlier one. I confirmed the tests have teeth: swapping in a redundant logic clue and a trivial maze each failed them.

New tool: `tests/sim/generate.test.ts` (run with `GEN=1`) searches for puzzle designs and checks them with the game's rules. It found the six-frame design, the water boards, the mazes, the lever grids, the 7×6 path board and the minimal logic clue sets.

### Not done, and why

- **Escape rooms still draw every object as a labelled card**, so "explore" is partly "tap every card". That ends with the room paintings in the art pass, when `PROPS_VISIBLE` can be turned off. The two extra locks do make the rooms take more steps.
- **Hidden-object lists still name every item.** The same art-pass dependency.
- **Level 22 is a 3×3 logic grid, not 4×4.** A fourth suspect would need new story. Six clues that must all be used makes it genuinely harder, but it is still the same size grid as level 11.
- **The music fix is a mitigation.** Silence between plays hides the repetition without removing it.
- **No real-phone test yet.** Everything above ran in emulated Chromium.

## Verdict

The game runs end to end, nothing crashes, and every sound plays from a file. But four bugs would spoil it for her, and two of them hit the biggest moments in the story. Fix those before she plays. After that, the main weakness is design: too many puzzles hand you the answer, and the difficulty doesn't climb.

## How this was tested

- A bot (`tests/playthrough.ts`) played all 28 puzzles at phone size (390×844) by tapping the real UI with legal moves only. It plans each solution with the game's own rule functions, then performs it. It recorded taps, sounds and whether each came from a file or the synth, status messages, layout problems, and screenshots at start and solve.
- Every start and solve screen was reviewed by eye.
- Earlier passes: the 41 solver/asset unit tests, the 27 browser checks, and a live-site check on an emulated Pixel 7, including offline.

**Result:** 26 of 28 solved by legal tapping. Zero JS errors. Zero synth fallbacks. The two failures are real bugs (level 27) or a real design problem (level 26), described below.

## Must fix before she plays

### 1. Button text is invisible on paper-coloured boards

On the cream "paper" boards, ordinary buttons inherit the dark paper ink as their text colour, on a dark button background. You can't read them.

- **Level 22, "Who took Nina?"**: the accusation, the climax of chapter 3, shows three blank dark boxes. The names Owen, Claire and Daniel are there but invisible.
- **Level 19**: the "Rotate strip" button is a blank grey pill.

The automated tests missed this because they find buttons by accessible name, not by what's visible. Fix: give `.btn` an explicit light text colour. One line of CSS.

### 2. Path puzzles register taps on the wrong cell (levels 6, 12, 27)

Rows with a numbered circle grow taller than rows without one. The tap and drag logic assumes equal rows, so in the lower part of the grid a finger lands on a different cell than the one under it. The drawn line is skewed the same way.

On level 27 this made the bot's correct path fail at cell 17: "Numbers have to be reached in order", then every later tap rejected. Levels 6 and 12 solved only because the errors happened to line up. On her phone it will feel like the game ignoring her finger.

Fix: fix the grid rows to equal heights, and map taps with the element under the finger rather than arithmetic.

### 3. Match-3 never shows the picture it promises (levels 7, 26)

"Uncover the whole frame." When the last static clears, the tiles stay on top and the evidence card pops straight up. The van at 11:34 and Daniel at the wheel, the payoff of both levels, are never seen.

Fix: on solve, fade the tiles out and hold the revealed frame for a second or two before the evidence card.

### 4. Match-3 is a grind

| Level | Static cells | Bot result |
|---|---:|---|
| 7 | 25 | Solved in 135 swaps |
| 26 | 45 | 400 swaps and still 3 cells left; gave up |

The bot takes the first legal move, so a person aiming at the static will do better. Still, static in the corners and edges only clears if a match happens to land exactly there. That's the classic match-3 failure mode, and a 10–15 minute slog at the climax of chapter 4 is the last thing the story needs.

Fix: a match also clears static on the cells next to it, line clearers wipe static along their whole line, and level 26 gets fewer static cells. Then target 25–40 swaps for level 7 and 40–60 for level 26, and check with the bot.

## Should fix

**Timeline cards block scrolling (levels 8, 18, 28).** The card list has `touch-action: pan-x`, so a vertical swipe that starts on a card doesn't scroll the page. Level 28's eight cards are taller than the screen, so she has to find a strip of margin to scroll with. Fix: drag only from a handle, and leave the list scrollable.

**Music and room tone loop too often.** The music cues are 32-second loops and room tone is 18 seconds. The investigation cue covers chapters 1 and 2, roughly 30–40 minutes, which is about 60–75 repeats of the same 32 seconds. That will grate. Fix: longer cues (2–3 minutes), or alternate two variants per cue. This is part of the sound pass, not code.

**The title art has garbled text.** The neon VACANCY sign reads as "YACKCY". The image generator mangled the lettering, and it's the first thing she sees. The reception sign's small text is garbled too. Fix in the art pass, or paint out the lettering.

**Text too small to read on a phone:**
- Path-puzzle labels (BATTERY, CAM A, GATE, CHAIN) are 8px.
- Frame-puzzle captions are about 7px and cut off ("A jacket at the termin…").
- Keycard labels are 9px vertical text.
- Logic-grid row names are truncated ("Claire Ben…").

**Tap targets under the usual 44px minimum:** timeline arrows (36×30) and cryptex arrows (34×32 on narrow phones).

**Water sort:** "Oil" is dark text on a near-black swatch, so the legend and the tank layers can't be read.

**Level 5:** the 🌑 "Dark alcove" icon is a dark circle on a dark card and is nearly invisible.

**Level 4:** the CCTV footage doesn't match the captions. "11:34 rear yard" shows a corridor, and "11:18 reception" shows a figure in a hallway, not a terminal. Level 13 has no footage at all. It's inconsistent next to level 4.

## Design: where the puzzles are weak

Minimum actions to solve, from the bot (taps, or moves where noted):

| Chapter | Levels and minimum actions |
|---|---|
| 1 | Path 16 · Search 6 · Box 8 · Frames 8 · Room 7 · Path 25 · Match-3 135 swaps · Timeline 6 cards |
| 2 | Room 12 · Room 7 · Logic 12 · Path 28 · Frames 8 · Search 5 · Cryptex 17 |
| 3 | Sort ~15 moves for a person (bot: 41) · Water 14 pours · Timeline 6 cards · Block fit 8 strips · Box 19 · Box 29 · Logic 13 |
| 4 | Room 12 · Maze 7 tilts · Box 10 · Match-3 400+ swaps · Path 36 · Timeline 8 cards |

- **The curve doesn't climb.** Chapter 4 is mostly easier than chapter 3. Room 23 and box 25 are among the shortest puzzles in the game, then match-3 26 is the longest by far. The finale should feel like the hardest thinking, not the longest grind.
- **Too many puzzles give you the answer.** The puzzle boxes are instruction-following: the switchboard chart literally lists the patch connections, and the dial codes are printed in the note from the previous stage. Hidden objects are labelled in the list. Escape rooms draw every interactive object as a labelled card, so "explore" means tap every card. Fine as placeholders, but someone who plays Mystery Box and Odd Machines will find these trivial.
- **The genuine thinking puzzles are good:** the path puzzles, the frame arrangements, water sort, keycard sort, the levers (lights-out), the tilt maze and the logic grids. They're where the game feels like the games on her list. The logic grids are small, though: four clues on a 3×3 is a warm-up.
- **Fixes, cheapest first:**
  - Make box stages need a deduction (dial codes derived from an earlier clue, not printed in the note; a patch chart with a missing line).
  - Remove the labels from room props once the art shows the objects, which the art pass needs anyway.
  - A 4×4 logic grid with 6–7 clues for level 22.
  - More numbers spread through the later path puzzles, so the route can't be guessed by snaking.
  - Tune match-3 as above.

## Asset audit

| Asset | Where | Verdict |
|---|---|---|
| Scenes: service, corridor 17, yard, records, laundry (env pass 02) | Story and rooms | Good. Consistent painted style, sharp, on brief |
| Scenes: exterior, title, reception, security, Room 17 (WIP plates) | Story, title | Usable but soft, with a blurred lower third, and the title's sign lettering is garbled. Replace first |
| Portraits: Nina ×3, Claire ×3 | Story | Good expressions, rough cutout edges, head-only framing |
| Portraits: Owen, Daniel | Story | First-pass rectangular crops. Style clash with the Nina/Claire cutouts; no expressions |
| Hidden-object scenes (2, 14) | Search | Emoji over a dimmed painting. Plays fine, looks like a placeholder |
| Escape rooms (5, 9, 10, 23) | Explore | Labelled cards over the painting. Plays fine, gives the game away |
| CCTV footage | Level 4 | Atmosphere only; content doesn't match captions. Level 13 none |
| Match-3 tiles | 7, 26 | Good: clear shapes and colours |
| Inventory icons | Rooms | Fine, but flat vector style next to painted scenes |
| All other puzzle boards | — | CSS. Functional, readable apart from the small text above |
| Sound effects (22) | Everywhere | All play from files. The bot heard 19 of 22 during puzzles. `phone` and `chapter` belong to story screens. `clue` is now unused, replaced by the clue-found stinger |
| Room tone (9), music (5), stingers (3) | Everywhere | All play from files and switch correctly by scene and chapter (checked in the browser test). Loops too short, see above. Synthesised drafts: nobody has listened on a phone speaker |

No asset failed to load on any screen. No JS errors.

## Recommended order

1. **Fix now, about an hour of work:**
   - invisible button text (1)
   - path-puzzle tap mapping (2)
   - match-3 reveal (3)
   - timeline scrolling
   - "1 cells" grammar
   - Oil legend contrast
   - minimum text and target sizes
2. **Tune match-3 (4)** and re-run the playthrough bot to confirm swap counts.
3. **Harder logic grid and deduction in box stages:** script and data changes, no new code.
4. **Art pass:** title lettering, the room and hidden-object paintings (which then lets the room labels go), CCTV frames, Owen and Daniel cutouts.
5. **Sound pass:** longer music and room-tone loops, then a listen on her phone's speaker.

## Re-running this audit

```bash
cd game
npm run build:single
npx vite-node tests/playthrough.ts          # all levels; screenshots and report.json in artifacts/playthrough/
ONLY=7,26 npx vite-node tests/playthrough.ts # just some levels
```
