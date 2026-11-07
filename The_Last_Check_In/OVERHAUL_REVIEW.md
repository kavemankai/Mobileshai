# The Last Check-In: overhaul review

Reviewed 7 November 2026 against the illustrated playable build and source pack. Spoilers throughout.

## 1. Engine: stay on web, rebuild the code

Don't move to Godot. Do restructure the codebase before you add a single new puzzle.

The game is text, dialogue, portraits, 2D boards and an evidence log. Browsers handle that better than Godot does. HTML text rendering, font scaling, screen readers and responsive layout come free on the web and take real work in Godot's UI system. Godot 4's web export ships a large wasm runtime (tens of MB before your assets), has had a history of iOS Safari audio and memory trouble, and C# projects can't export to web at all. For a game you want on one person's phone, a link she can add to her home screen beats an engine build every time.

Godot would be the right call if any of these were true:

- You want a native App Store / Play Store release with heavy physics and particle effects.
- You want 3D sort games (Match Factory, Triple Match 3D style).
- Whoever builds this prefers working in an editor over writing code.

None of those apply to what this game is.

The engine isn't the problem. The code is. `engine.js` is 28 KB of single-line, minified-style JavaScript with every puzzle type in one `if (kind === ...)` chain. It works for seven trivial mechanics. It will collapse under eighteen. Before adding anything:

1. Move to Vite + TypeScript. Keep the single-file offline build as a build target (`vite-plugin-singlefile` does this).
2. Give each puzzle its own module with one shared interface: `init(level, seed)`, `render(el)`, `isSolved()`, `hint(n)`, `serialize()`. The story/level data picks the module by `kind`.
3. Keep story, dialogue, evidence and menus in plain DOM/CSS. Use PixiJS (v8) only inside the boards that need animation: match-3 cascades, water and goods sort, tilt maze, puzzle-box mechanisms.
4. Add a service worker and web manifest so it installs as a PWA and runs offline from the home screen. Wrap in Capacitor later if you ever want an APK. Don't do that first.
5. Port the existing Playwright tests to the new structure and keep the full 28-level legal-input walkthrough. That test is the best thing in the pack.

## 2. What the game has now

Seven mechanics across 28 levels. Most of them aren't the genre they look like.

| Kind | Uses | What it actually is | Real genre? |
|---|---|---|---|
| `circuit` | 5 | Rotate 5–7 tiles on a 3×3 grid to join battery to output | Yes: pipe rotation (Infinity Loop, Energy). Far too small. |
| `sort` | 6 | Drag 4 cards into order. The timestamps are printed on the cards. | No. It's a form. |
| `slide` | 5 | 8-tile sliding puzzle with labelled tiles | Yes, but dated and tedious. Nobody under 50 seeks these out. |
| `screws` | 3 | Tap screws in dependency order | No. It borrows the name of Screw Jam and none of the mechanic. |
| `match` | 5 | Pair 3 items across two columns | No. The answers are self-evident ("Martin Hale" ↔ "Room 17 guest receipt" when the intro just told you Hale was the Room 17 guest). |
| `keypad` | 3 | Type a 4-digit code | No. The code is spelled out in the intro every time ("The keypad accepts the four digits after the L"). |
| `parking` | 1 | Rush Hour sliding cars | Yes. Solid classic. Art is labelled rectangles. |

Blunt version: someone who plays lots of mobile puzzle games will clear most of these in under 30 seconds without thinking, and five of the seven types will feel like busywork between dialogue. The other problem is that the player never deduces anything. The story hands out every clue and the puzzles are locks in front of it. A mystery where you never work anything out is a visual novel with chores.

## 3. What she's playing: the PixelPicked top 31 (November 2026)

The lineup below is built from the PixelPicked monthly ranking she's been browsing, not from store-wide charts. That matters: PixelPicked is an indie discovery site, and one publisher (XSGames) holds 10 of the 31 spots, so this is a picture of her taste more than of the whole market. For a gift, that's the better signal.

Some titles are obscure enough that I couldn't confirm the mechanic. Those are marked with a question mark and classified from the name and icon.

| Cluster | Games on the list (rank) | Share |
|---|---|---|
| Escape room / mechanical puzzle box | Odd Machines (2), The Da Vinci Cryptex (6), Mystery Box: Hidden Secrets (7), Tiny Machinery (8), Mystery Box 3: Escape the Room (12), Blackmoon Mansion (17), Escape From Benjamin's Room (19) | 7, five of them in the top 8 |
| Illustrated, art-led puzzles | Gorogoa (3), Song of Bloom (9), The Inkline? (11) | 3 |
| Hidden object / picture puzzles | Hidden Birds (4), Infograf Puzzle? (13) | 2 |
| Daily logic | Zipstache? (10, looks like a Zip-style numbered path), 123doku (18), Lockstep: Daily Logic (23), Quadra? (25), CrissCross? (26) | 5 |
| Ordering / timeline | Listory? (24, looks like putting history in order) | 1 |
| Casual mass-market | Zukora match-3 (14), Block Puzzle Pro (15), CrossBlock? (22, number merge), InkDrop colour merge (29), Water Sort Deluxe (30), Pocha Moonlight goods sort (31), Tilt Maze Garden (21), Twistbloom? (27) | 8 |
| Word | Word Battle (16) | 1 |
| Not puzzle games | Pixel Rush (1)?, groky (5)?, Get a Grip (20), Prim3 Hunt (28)? | 4 |

### What this changes

The top of her list is escape-room and puzzle-box games. That is the genre this game should have been all along. The Last Check-In currently plays as a puzzle pack: read dialogue, solve an abstract board, read more dialogue. XSGames-style escape games put you *in* a room. You tap around, zoom into a drawer, pick up a screwdriver, find a number scratched on a clock, open a box that contains another box. The puzzles live inside the place.

So the structural change is bigger than swapping mechanics. Each of the eight locations becomes an explorable scene with hotspots, zoom-ins and a small inventory. The gadget puzzles sit inside those scenes. Codes and passwords stop being printed in the dialogue and start being found in the room, which fixes the "keypad isn't a puzzle" problem for free.

The list also says she likes handmade, atmospheric, harder puzzles (Gorogoa, Song of Bloom, Odd Machines), not only casual sorts. That backs the noir direction and the difficulty ramp. The casual cluster is still a third of the list, so a few match-3 / sort / block levels belong in the mix as breathers.

## 4. Drop, keep, replace (revised)

| Current | Verdict | Replaced by |
|---|---|---|
| `slide` ×5 | Drop | Puzzle box, match-3 reveal, Gorogoa-style panels |
| `keypad` ×3 | Rebuild | Codes found by exploring the room (escape-room style) and one cryptex |
| `match` ×5 | Drop | Logic grid ×2, goods sort, water sort, escape-room exploration |
| `sort` ×6 | Keep 3, make them hard | Timeline ordering with timestamps removed (Listory-style, but deductive). Others become hidden object and block puzzle. |
| `screws` ×3 | Drop as a type | Folded into puzzle boxes and room exploration (unscrewing a panel is one step of a box, not a level) |
| `circuit` ×5 | Replace | Zip-style numbered path ×4 (power routes, van route, upload relays), puzzle-box switchboard ×1 |
| `parking` ×1 | Drop | Zip path through the yard's camera checkpoints |

Dropped from my first draft because nothing on her list points at them: Screw Jam, colour block jam, pin pull, tap-away, Flow, jigsaw, Connections, Wordle-style code-break, spot the difference.

## 5. New 28-level map

Story beats and clue titles stay in place. Thirteen mechanics, each tied to a game on her list.

| # | Level | Was | Becomes | Her list | What the player does |
|---:|---|---|---|---|---|
| 1 | Restore the Terminal | circuit | Zip path | Zipstache | Draw one line through numbered junctions 1→6, filling the panel, to route backup power |
| 2 | The Night Register | sort | Hidden object (reception) | Hidden Birds | Find the four stuffed receipts, Nina's keys, her note |
| 3 | The Security Cabinet | slide | Puzzle box | Odd Machines, Tiny Machinery | Multi-step cabinet: slide the tray stops, turn the dial, find the false bottom |
| 4 | The Missing Footage | sort | Gorogoa-style panels | Gorogoa | Arrange and zoom four CCTV feeds until the figure's path joins up across frames |
| 5 | The Tampered Reader | screws | Escape room (service corridor) | Mystery Box, Benjamin's Room | Search the corridor, find a screwdriver and torch, open the reader |
| 6 | The Backup Recorder | circuit | Zip path | Zipstache | Bigger grid, with blocked cells |
| 7 | The Last Image | slide | Match-3 reveal | Zukora | Clear static tiles; the van frame shows underneath |
| 8 | The Contradiction | match | Timeline ordering | Listory | Order eight clues with no timestamps, using visual evidence |
| 9 | Through the Door | keypad | Escape room code hunt | Mystery Box | Digits are spread across Nina's note, the room-service tag and a stopped clock |
| 10 | The Hidden Vent | screws | Escape room (Room 17) | Blackmoon Mansion | Search the tossed room, follow the scratch arrow, open the vent |
| 11 | The Guest of Record | match | Logic grid | Lockstep, 123doku | Three names × three rooms × three payment methods |
| 12 | The Vehicle Trace | parking | Zip path | Zipstache | Trace the van through the yard's camera checkpoints in order; the path can't reach the gate |
| 13 | The Dashcam Fragment | slide | Gorogoa-style panels | Gorogoa | Line the dashcam frame up against the yard map to find the turn |
| 14 | The Ward File | sort | Hidden object (records) | Hidden Birds | Find the Ward documents in the clutter |
| 15 | The Sealed Recording | keypad | Cryptex | The Da Vinci Cryptex | Letter rings; the password comes from Mara's file |
| 16 | The Spare Credential | match | Goods sort | Pocha Moonlight | Sort keycards onto owner racks in threes; one NIGHT SHIFT card is left over |
| 17 | The Flooded Corridor | circuit | Water sort | Water Sort Deluxe | Separate floodwater, oil and sludge into tanks so the pump will run |
| 18 | The Archived Film | sort | Timeline ordering | Listory | Order the 2019 frames; the driver's face stays unclear |
| 19 | The Owner's Ledger | sort | Block puzzle | Block Puzzle Pro | Fit shredded ledger strips back into the page |
| 20 | The Emergency Intercom | circuit | Puzzle box (switchboard) | Odd Machines | Patch cords, levers and dials on the old switchboard |
| 21 | The Contractor's Case | screws | Puzzle box with tilt-maze stage | Tiny Machinery, Tilt Maze Garden | Nested case; one stage rolls a ball bearing through a maze to release the inner lid |
| 22 | The Only Explanation | match | Logic grid (accusation) | Lockstep | Weigh statements and accuse before Owen confirms |
| 23 | The Laundry Override | keypad | Escape room (laundry entrance) | Escape From Benjamin's Room | The tag is heat-damaged; the missing digits are in the room |
| 24 | The Boiler Bypass | circuit | Tilt maze | Tilt Maze Garden | Steer a pressure ball through the valve maze (tilt or drag) |
| 25 | The Last Barrier | slide | Puzzle box (finale) | Odd Machines | The gate interlock as one big mechanism |
| 26 | The Original Frame | slide | Match-3 reveal | Zukora | Clear the corruption over Nina's original frame |
| 27 | The Emergency Uplink | match | Zip path (finale) | Zipstache | Route the upload through relays while Daniel cuts power |
| 28 | The Final Account | sort | Timeline ordering (finale) | Listory | Place every key event on the case timeline |

Counts: Zip path 4, puzzle box 4, escape room 4, timeline 3, logic grid 2, hidden object 2, Gorogoa panels 2, match-3 2, and one each of cryptex, goods sort, water sort, block puzzle and tilt maze.

If scope bites, cut the Gorogoa panels first: they're the most art-heavy mechanic by far (every panel is a bespoke illustration that has to line up with others). Replace 4 and 13 with timeline ordering and match-3.

Tilt maze uses the phone's motion sensor, which needs a permission tap on iPhone. Always offer drag as well.

### Engine impact

None of this changes the engine call. Escape-room exploration in a browser is just layered images with tap regions, a zoom transition and an inventory bar. It does add two systems to the restructure in section 1: a scene/hotspot/inventory layer shared by every room, and a nested-gadget framework for puzzle boxes (a box is a sequence of small states, each unlocking the next).

### Difficulty and feel

- Ramp difficulty across chapters. Chapter 1 puzzles should take 1–2 minutes, Chapter 4 puzzles 4–6. Right now everything is 30 seconds.
- Keep the no-timer, no-lives, two-hints-then-skip rule. It's right for a story game.
- Hint 1 currently gives away too much (it often contains the answer). Hint 1 should point, hint 2 should solve.
- Add the juice mobile players expect: snap and squash on placement, a short particle burst on solve, screen shake on big reveals (off under reduced motion), haptics through `navigator.vibrate` on Android.

## 6. Narrative

### What works

The premise is good. A night receptionist, an empty desk, a handbag left behind, a checkout that couldn't have happened. "Nina never checked out" is a strong hook. The prose is clipped and readable, the setting is coherent, and the ending is grounded, which was the right call.

### What doesn't

**The villain is obvious from level 11 of 28.** Daniel's company pays for the fake guest at level 11. There is no suspect pool: Owen is obviously covering something but obviously not a kidnapper, and Claire is cleared one level after she appears. Seventeen levels of confirming what the player already knows.

**The player never deduces anything.** At level 22, "The Only Explanation", Owen walks in and says "Daniel." The puzzle afterwards is matching three pairs to confirm what he just said. The climax of the investigation is a confession.

**Daniel never appears.** He's an invoice, a recording and two shouted lines from offscreen ("You've made a terrible mistake"). A villain the player never meets can't surprise them.

**The climax happens offscreen.** The final act is two matching puzzles and a sort, then "officers confront Daniel". The player doesn't face anything.

**The player has no stake.** The unseen receptionist has no relationship to Nina. Why not just go home as Owen says?

**Continuity errors:**

- The note logic doesn't hold. CCTV puts Nina in security at 11:12 and the checkout at reception at 11:18. Her note under the keyboard says the 11:18 checkout "is impossible". When did she see it, and when did she get back to the desk to write it? Fix: she watched it happen live on the security monitor, ran back, wrote the note, and was taken at the desk around 11:26, which matches the staff-door access.
- The 12:09 AM Room 17 access (the Chapter 1 cliffhanger) has no payoff. At 12:13 the player finds a freshly cleaned room with the vent card untouched. If Daniel went in four minutes earlier, the room should be searched and the card should have survived because he missed it.
- Levels 18 and 26 both "identify Daniel as the driver". Level 18 should leave the face unclear so level 26 lands.
- Owen says "I'm coming down" at level 4 and turns up at level 22, roughly an hour later. Either the flood holds him up (say so) or, better, he arrives early and spends Chapter 2 as a live suspect.
- Police are called at level 6 and disappear until level 27. One dispatch check-in per chapter keeps them in the story.
- Fixed in this commit: "six-year-old incident" contradicted Claire's "seven years" (the game is set in 2026), and Claire's two surnames were never explained.

**The narrator does too much.** Lines like "On the security map, select a vehicle and use the arrows to slide it within its lane" and "Shift the trays into their numbered positions" are UI instructions in the story voice. Move them to the puzzle header. Several YOU lines are exposition for the player's benefit ("Daniel Price. The contractor who fitted the motel's access readers.").

### Revised direction

1. **Give the player a reason.** Nina trained the player this week, or covered a shift for them, so tonight was supposed to be the player's night off. One line in the opening does it.
2. **Make Nina the guide.** She left a trail: the note under the keyboard, the scratch arrow in Room 17, the vent card, the backup she made. Make that deliberate. Each chapter starts with something Nina left for whoever came next. Her voice runs through the whole game even while she's missing, and the rescue lands harder.
3. **Build a suspect pool and delay Daniel.** Chapter 1: Owen is the obvious suspect (lies on the phone, tells you not to touch the recordings). Chapter 2: Claire is suspicious (false name, asking about Room 17, she was outside at the right time). Daniel arrives in person at the end of Chapter 2, helpful and calm, "called out to fix the faulty readers". Price Security's name surfaces only in Chapter 3.
4. **Let the player solve it.** Level 22 becomes a real deduction: the player accuses before Owen confirms. If you want a stakes beat, wrong accusations cost nothing but get a character reaction.
5. **Put Daniel in the room for the ending.** During the uplink he cuts power at the switchboard and comes for the backup drive. Nina and Claire hold the door while the player finishes the upload. No timer, no fail state; just pressure in the writing and the sound. Police arrive. Keep it grounded.
6. **Merge the two "driver" reveals** as noted above.
7. **Since it's a gift:** let her name the receptionist on the first screen, and consider one or two in-jokes in the background (a guest name in the register, a photo on the reception wall). Small, not cute.

## 7. Art

### Assessment

**Two styles fighting.** Exterior, reception, security and Room 17 are painted generated studies. Service corridor, records, yard and laundry are flat SVG. The game visibly changes art style halfway through Chapter 1.

**The painted scenes don't look like a seaside motel.** Reception reads as a lamp-lit 1920s study: wooden pigeonholes, banker's lamp, framed photos. Room 17 reads as a log cabin. A roadside motel reception has a laminate counter, a key-hook board, a desk bell, a brochure rack, fluorescent tubes and a vending machine humming in the corner. The images are also 768×520 landscape crops shown on a portrait phone, so they're soft and lose half the frame.

**Portraits are generic and static.** One 380 px crop per character, no expressions. Owen looks like stock "trucker". They sit in a hard-edged box over the scene like a webcam inset.

**The UI over-labels.** A single story screen shows "CHAPTER 1 / 4 · LEVEL 01 / 28", the level title, the chapter name, "CHAPTER 1: THE EMPTY RECEPTION", "INCOMING CASE NOTE · RECEPTION" and "MARINER / RECEPTION". That's six labels saying where you are. There's a large dead gap between the dialogue and the buttons, and three controls (Replay text, Inspect now, Continue) for what is mostly one action.

**Puzzle boards are flat.** The receipts are the best of them. The parking cars are labelled rectangles. Nothing moves when you solve.

### Direction

- **One style for everything.** Painted 2D, composed for portrait 9:16 (1080×1920 source, cropped responsively), not landscape crops.
- **Period and place.** A late-70s/80s coastal motel gone tired: wood-grain laminate, teal and burnt-orange paint, salt-stained windows, a buzzing neon VACANCY sign. Keep the existing palette brief (slate shadows, amber practicals, teal surveillance, sparing red). It's good.
- **Generate all eight locations in one batch with a shared style reference** so lighting, brushwork and palette match. Each location needs two or three states (lights on/off, flooded, searched) so repeat visits move the story on.
- **Explorable rooms and hidden-object scenes need dedicated art:** dense, high-res (2048 px+), with interactive objects painted as separate layers so they can be picked up, opened or zoomed into. Puzzle boxes need close-up mechanism art with moving parts. This is the biggest art cost in the plan, and it's where XSGames-style games earn their reputation, so it's the last place to save money.
- **Character sheets.** Four characters × three expressions (neutral, worried, tense), half-body, same light rig, transparent background, so portraits sit in the scene rather than in a box. Daniel needs a "friendly" expression now that he's met in person.
- **Strip the UI.** One location line, one progress marker. Dialogue panel sits directly under the art. Tap anywhere to advance; drop "Inspect now".
- **Puzzle boards as objects.** Real receipts, top-down car sprites with wet highlights, colour-coded screw heads, CCTV scanlines over match-3 tiles. The board should look like the thing in the story.

## 8. Sound

### Assessment

Everything is procedural WebAudio: looped brown noise filtered per room, four sine-wave pads, and oscillator blips for effects. As placeholder work it's tidy (proper buses, unlock on first tap, suspends when hidden). As something a heavy mobile gamer hears, it won't pass. Puzzle games live on feedback sound, and a sine blip on a match-3 cascade or a screw twist will feel dead next to what she plays daily.

### Direction

- **Feedback sounds first.** They matter more than music. Every mechanic needs pick-up, place, invalid, combo/cascade and solve sounds. Puzzle boxes live or die on mechanical foley: latches, ratchets, sliding wood, a satisfying clunk when a stage opens. Royalty-free and CC0 sources: Kenney audio packs (CC0), the Sonniss GDC bundles (royalty-free for commercial use), and Freesound filtered to CC0. Log each file in `ASSET_LICENSES.md`.
- **Real ambience per location** from the same sources: rain on glass, rain on a tin awning, fluorescent hum, monitor fan, boiler, drips, distant surf. Keep the existing bus setup and crossfade between rooms.
- **Music: five cues.** Title, investigation loop, tension loop, Chapter 4 pressure, resolution. Plus three stingers: clue found, chapter end, Nina's voice. Commission, license, or generate and edit. Sparse is right; the brief's "low suspense pads" direction is fine, it just needs real instruments.
- **Duck music under dialogue** and drop it to silence for the big reveals (the 12:09 cliffhanger, the knock on the wall, Daniel's first appearance). Silence is the cheapest scare you have.
- **Format.** Ship AAC/M4A for iOS with Opus/OGG fallback, or use Howler.js and let it pick. Keep the whole audio set under 8–10 MB.
- **Haptics** on solves and big reveals (Android only; iOS Safari doesn't expose vibration).

## 9. Build order

1. Restructure the code (section 1). Port tests. No new content until this is done.
2. Rewrite the script to the revised direction (section 6), keeping clue titles stable where possible so saves and tests survive.
3. Build the room/hotspot/inventory layer and the puzzle-box framework, then the other mechanics in the order she'll meet them, with placeholder art, and playtest each chapter on a real phone.
4. Art pass: style reference, eight locations, character sheets, hidden-object scenes, board skins.
5. Sound pass: feedback sounds, ambience, music, mix on real headphones and a phone speaker.
6. PWA install and offline check on her actual phone.
