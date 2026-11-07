# Story Bible and Complete Level List

**Contains full spoilers. This is an implementation reference for Codex, not player-facing copy.**

## Canonical facts

- An ordinary overnight receptionist arrives at the Mariner Motel at **11:43 PM** and discovers Nina missing; her personal belongings remain at the desk.
- Motel owner **Owen Mercer** claims Nina went home. He is evasive because he helped cover up an older crime.
- A false checkout of **Room 17 at 11:18 PM** uses Nina’s account, but CCTV places her away from the terminal.
- The player’s NIGHT SHIFT credential was cloned and used **before** the player arrived, and then used again later.
- **Daniel Price**, a security contractor, copied credentials, took Nina and concealed the connection between the motel and the older case.
- **Claire Bennett** (Room 12) is connected to the older death of **Mara Ward**, recorded as having occurred **18 October 2019**.
- The van in the rear yard never actually completed its apparent departure; the disused laundry is central to Nina’s location.
- The third chapter establishes the perpetrator and the old cover-up; the fourth rescues Nina and preserves evidence.
- Ending: Nina survives. Daniel is taken into custody; Owen’s involvement in hiding evidence is investigated. Keep the ending grounded; no unrelated supernatural twist.

## Chapters

**1. THE EMPTY RECEPTION** — 8 levels. Someone has vanished, and the night register is lying.

**2. ROOM SEVENTEEN** — 7 levels. A false guest. An older crime. A reason to disappear.

**3. THE MISSING MINUTES** — 7 levels. The evidence survived. So did the person who buried it.

**4. BEFORE DAWN** — 6 levels. Find Nina. Preserve the truth. Get out.

## Stage manifest

| # | Chapter | Level | Puzzle | Scene | Clue earned |
|---:|---:|---|---|---|---|
| 01 | 1 | Restore the Terminal | `circuit` | `reception` | The impossible checkout |
| 02 | 1 | The Night Register | `sort` | `reception` | The unsigned receipt |
| 03 | 1 | The Security Cabinet | `slide` | `security` | Forgotten backup |
| 04 | 1 | The Missing Footage | `sort` | `security` | A second person at the desk |
| 05 | 1 | The Tampered Reader | `screws` | `service` | The impossible access |
| 06 | 1 | The Backup Recorder | `circuit` | `security` | Nina’s last recording |
| 07 | 1 | The Last Image | `slide` | `security` | Two figures in the van |
| 08 | 1 | The Contradiction | `match` | `security` | A cloned identity |
| 09 | 2 | Through the Door | `keypad` | `room` | Room 17 was staged |
| 10 | 2 | The Hidden Vent | `screws` | `room` | The WARD memory card |
| 11 | 2 | The Guest of Record | `match` | `room` | A false guest identity |
| 12 | 2 | The Vehicle Trace | `parking` | `yard` | The van never left |
| 13 | 2 | The Dashcam Fragment | `slide` | `yard` | The rear-laundry turn |
| 14 | 2 | The Ward File | `sort` | `records` | Mara Ward’s death |
| 15 | 2 | The Sealed Recording | `keypad` | `records` | The cover-up recording |
| 16 | 3 | The Spare Credential | `match` | `security` | Who copied the card |
| 17 | 3 | The Flooded Corridor | `circuit` | `service` | A trail to the laundry |
| 18 | 3 | The Archived Film | `sort` | `records` | The driver in 2019 |
| 19 | 3 | The Owner’s Ledger | `sort` | `records` | Years of payments |
| 20 | 3 | The Emergency Intercom | `circuit` | `service` | Nina is in the laundry |
| 21 | 3 | The Contractor’s Case | `screws` | `service` | Daniel’s cloning equipment |
| 22 | 3 | The Only Explanation | `match` | `security` | Daniel identified |
| 23 | 4 | The Laundry Override | `keypad` | `laundry` | Laundry entrance unlocked |
| 24 | 4 | The Boiler Bypass | `circuit` | `laundry` | Safe access to the inner corridor |
| 25 | 4 | The Last Barrier | `slide` | `laundry` | Nina rescued |
| 26 | 4 | The Original Frame | `slide` | `records` | The original frame |
| 27 | 4 | The Emergency Uplink | `match` | `security` | Evidence preserved off-site |
| 28 | 4 | The Final Account | `sort` | `security` | Case closed |

## Script and puzzle data are canonical

The complete dialogue (intro and reveal per level), puzzle definitions, solutions and hint text are in `source/story.js`. A structured reference of all the same stages is in `source/level_manifest.json`. Do not retype them from this table: render them from the data and preserve the actual clue consequences.

## Story pacing and cliffhangers

- Most transitions follow `intro → puzzle → reveal`, then proceed to next level. Keep scenes tappable; 20–40 seconds represents typical material, not a lockout.
- Chapter 1 (after Level 8) ends with a cloned staff credential unlocking Room 17 while the player is elsewhere.
- Chapters 2–3 connect false motel records to the 2019 death and the security contractor’s evidence concealment.
- Chapter 4 includes rescue, secure evidence transmission and a final chronological reckoning.

## Player experience rules

- The narrative should respond to solving a puzzle; clue awarding is not optional.
- Hints and player skips do not punish the player.
- The evidence board may show acquired evidence only; no spoilers.
- Plot and puzzle objective must correspond in each level, with accessible visual cues.
- The same scene backdrop may return but should evolve through cropping/lighting/props.
