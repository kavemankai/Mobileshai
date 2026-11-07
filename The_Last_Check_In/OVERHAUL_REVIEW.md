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
3. Keep story, dialogue, evidence and menus in plain DOM/CSS. Use PixiJS (v8) only inside the boards that need animation: match-3 cascades, screw jam, colour block jam, pin pull.
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

## 3. Current hot puzzle genres, and whether they fit

What's dominating mobile puzzle charts through 2025–26, with a fit rating for a 60–90 minute linear crime story. "Fit" means it can carry a story beat without feeling bolted on.

| Genre | Reference games | Fit | Notes |
|---|---|---|---|
| Match-3 | Royal Match, Candy Crush | Good, as a reveal | Clear "static" tiles to uncover a CCTV frame or decrypt an archive. Objective mode, no move limit. |
| Screw puzzle | Screw Jam, Screw Sort 3D | Excellent | Coloured screws go into matching toolboxes with limited slots. Plates fall. Perfect for vents, readers, tool cases. |
| Hidden object | June's Journey, Hidden City | Excellent | The genre most associated with narrative mysteries. Needs high-res dense art. |
| Connections-style grouping | NYT Connections | Excellent | Sort 12–16 evidence cards into groups. Red herrings make it a real deduction. |
| Logic grid / deduction | Murdle, Clues by Sam | Excellent | The player actually solves the case. This is the biggest fix the game needs. |
| Colour block jam | Color Block Jam, Bus Jam | Good | Slide coloured bars out through matching gates. Lock mechanisms. |
| Ball / water sort | Ball Sort, Water Sort, Goods Sort | Good | Keycards into owner racks, with one card too many. |
| Pin pull | Pull the Pin, Hero Rescue | Good | Floodwater, steam. Needs a small particle sim. |
| Code-break (Wordle-style) | Wordle, Mastermind | Good | Replaces dead keypads. Partial clue plus coloured feedback per guess. |
| Spot the difference | Find Differences apps | Good | Before/after photos of a staged room, doctored vs original footage. |
| Flow / connect pairs | Flow Free | Good | Wiring. Distinct enough from pipe rotation to use both. |
| Pipe rotation | Infinity Loop, Energy | Good | Keep, but 4×4 to 5×5 with multiple outputs. |
| Block fit | Block Blast (fixed-solution variant) | Fair | Reassemble shredded pages from polyomino strips. Block Blast itself is endless scoring, which doesn't fit. |
| Jigsaw | Jigsaw Puzzles, Magic Jigsaw | Fair | Torn photos, corrupted frames. Big with the same audience as hidden object. |
| Tap-away | Tap Away 3D, Arrows | Fair | Jammed trays slide out in their arrow direction. |
| Sliding tile (Rush Hour) | Unblock Me, Parking Jam | Fair | Keep the one use. |
| Triple-tile tray | Tile Busters, Zen Match | Fair | 2D version is doable. Optional swap. |
| Queens / grid placement | LinkedIn Queens, Star Battle | Fair | Could work as "place cameras so every corridor is covered". Optional swap. |
| Merge | Travel Town, Merge Mansion | Poor | Needs an economy and a long meta loop. Fights a linear 90-minute story. |
| Yarn / wool sort | Wool Sort, Knit Out | Poor | Hot, but forcing it into a laundry is a stretch. |
| Word games | Wordscapes, word search | Poor | Possible, but adds little a deduction puzzle doesn't do better. |

If you know which games she plays most, weight the lineup toward them. That matters more than this table.

## 4. Drop, keep, replace

| Current | Verdict | Replaced by |
|---|---|---|
| `slide` ×5 | Drop entirely | Match-3 reveal, jigsaw, colour block jam, spot the difference, tap-away |
| `keypad` ×3 | Drop as a puzzle | Code-break (Wordle feedback) ×2; one keypad becomes a plain interaction, not a level |
| `match` ×5 | Drop | Connections ×2, logic grid, "who's lying" deduction, card sort |
| `sort` ×6 | Cut to 3, rebuild | Two become sequence deductions with timestamps removed (order by visual evidence). The finale stays as a timeline board. The rest become hidden object and block fit. |
| `screws` ×3 | Rebuild as real Screw Jam | Screw Jam ×2, spot the difference ×1 |
| `circuit` ×5 | Keep 2, rebuild bigger | Pipe rotation ×2, flow ×2, pin pull ×1 |
| `parking` ×1 | Keep, re-art | Rush Hour with top-down car sprites and a harder layout |

## 5. New 28-level map

The story beats and clue titles stay in place. Each chapter introduces new mechanics, and each chapter ends on a deduction puzzle so the player feels clever at the cliffhanger.

| # | Level | Was | Becomes | What the player does |
|---:|---|---|---|---|
| 1 | Restore the Terminal | circuit | Pipe rotation 4×4 | Route backup power to the terminal |
| 2 | The Night Register | sort | Hidden object (reception) | Find the four stuffed receipts, Nina's keys, her note |
| 3 | The Security Cabinet | slide | Tap-away | Clear jammed trays in the right order to reach the key |
| 4 | The Missing Footage | sort | Sequence deduction | Order four CCTV stills with no timestamps, using the wall clock reflection, rain on the lens, lights going off |
| 5 | The Tampered Reader | screws | Screw Jam | Coloured screws into matching trays; plates drop to expose the memory unit |
| 6 | The Backup Recorder | circuit | Flow | Connect colour-matched wire leads, filling the board |
| 7 | The Last Image | slide | Match-3 reveal | Clear static tiles; the van frame emerges underneath |
| 8 | The Contradiction | match | Connections | Sort 12 cards into Nina's movements / the stranger's movements / the van, with one decoy |
| 9 | Through the Door | keypad | Code-break | Rain-smudged note shows `1?1?`; Wordle-style feedback on guesses |
| 10 | The Hidden Vent | screws | Spot the difference | Booking photo of Room 17 vs now; the last difference is the scratched vent |
| 11 | The Guest of Record | match | Logic grid | Three names × three rooms × three payment methods |
| 12 | The Vehicle Trace | parking | Rush Hour (rebuilt) | Prove whether the van could reach the gate |
| 13 | The Dashcam Fragment | slide | Jigsaw (16 pieces) | Rebuild the corrupted dashcam still |
| 14 | The Ward File | sort | Hidden object (records office) | Find the Ward documents in the clutter |
| 15 | The Sealed Recording | keypad | Match-3 decryption | Clear the lock blocks over the archive |
| 16 | The Spare Credential | match | Card sort (ball-sort mechanic) | Sort keycards into owner racks; one NIGHT SHIFT card is left over |
| 17 | The Flooded Corridor | circuit | Pin pull | Pull pins in order so floodwater reaches the drain, not the fuse box |
| 18 | The Archived Film | sort | Sequence deduction | Order the 2019 frames; the driver's face stays unclear |
| 19 | The Owner's Ledger | sort | Block fit | Reassemble shredded ledger strips into the page |
| 20 | The Emergency Intercom | circuit | Pipe rotation 5×5, two outputs | Power both the speaker and the microphone |
| 21 | The Contractor's Case | screws | Screw Jam (harder) | Open Daniel's tool case |
| 22 | The Only Explanation | match | Who's-lying deduction | Weigh statements from Owen, Claire, the invoice and the intercom; accuse before Owen confirms |
| 23 | The Laundry Override | keypad | Code-break | Heat-damaged tag shows two of four digits |
| 24 | The Boiler Bypass | circuit | Flow | Connect valve control leads |
| 25 | The Last Barrier | slide | Colour block jam | Slide coloured lock bars out through matching gates |
| 26 | The Original Frame | slide | Spot the difference | The doctored 2019 frame vs Nina's original; the differences put Daniel behind the wheel |
| 27 | The Emergency Uplink | match | Connections | Route 16 files to 4 upload channels, with decoys |
| 28 | The Final Account | sort | Timeline board | Place six evidence cards on the case timeline |

That is 18 mechanics, which is a lot of build. If scope bites, cut tap-away (3 → pipe rotation), jigsaw (13 → match-3) and block fit (19 → Connections). Fifteen mechanics still covers every genre she's likely to recognise.

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
- **Hidden-object scenes need dedicated art:** dense, high-res (2048 px+), with the target objects painted in, not composited. This is the biggest art cost in the plan. Budget for it or cut to one hidden-object scene.
- **Character sheets.** Four characters × three expressions (neutral, worried, tense), half-body, same light rig, transparent background, so portraits sit in the scene rather than in a box. Daniel needs a "friendly" expression now that he's met in person.
- **Strip the UI.** One location line, one progress marker. Dialogue panel sits directly under the art. Tap anywhere to advance; drop "Inspect now".
- **Puzzle boards as objects.** Real receipts, top-down car sprites with wet highlights, colour-coded screw heads, CCTV scanlines over match-3 tiles. The board should look like the thing in the story.

## 8. Sound

### Assessment

Everything is procedural WebAudio: looped brown noise filtered per room, four sine-wave pads, and oscillator blips for effects. As placeholder work it's tidy (proper buses, unlock on first tap, suspends when hidden). As something a heavy mobile gamer hears, it won't pass. Puzzle games live on feedback sound, and a sine blip on a match-3 cascade or a screw twist will feel dead next to what she plays daily.

### Direction

- **Feedback sounds first.** They matter more than music. Every mechanic needs pick-up, place, invalid, combo/cascade and solve sounds. Royalty-free and CC0 sources: Kenney audio packs (CC0), the Sonniss GDC bundles (royalty-free for commercial use), and Freesound filtered to CC0. Log each file in `ASSET_LICENSES.md`.
- **Real ambience per location** from the same sources: rain on glass, rain on a tin awning, fluorescent hum, monitor fan, boiler, drips, distant surf. Keep the existing bus setup and crossfade between rooms.
- **Music: five cues.** Title, investigation loop, tension loop, Chapter 4 pressure, resolution. Plus three stingers: clue found, chapter end, Nina's voice. Commission, license, or generate and edit. Sparse is right; the brief's "low suspense pads" direction is fine, it just needs real instruments.
- **Duck music under dialogue** and drop it to silence for the big reveals (the 12:09 cliffhanger, the knock on the wall, Daniel's first appearance). Silence is the cheapest scare you have.
- **Format.** Ship AAC/M4A for iOS with Opus/OGG fallback, or use Howler.js and let it pick. Keep the whole audio set under 8–10 MB.
- **Haptics** on solves and big reveals (Android only; iOS Safari doesn't expose vibration).

## 9. Build order

1. Restructure the code (section 1). Port tests. No new content until this is done.
2. Rewrite the script to the revised direction (section 6), keeping clue titles stable where possible so saves and tests survive.
3. Build the new mechanics in the order she'll meet them, with placeholder art, and playtest each chapter on a real phone.
4. Art pass: style reference, eight locations, character sheets, hidden-object scenes, board skins.
5. Sound pass: feedback sounds, ambience, music, mix on real headphones and a phone speaker.
6. PWA install and offline check on her actual phone.
