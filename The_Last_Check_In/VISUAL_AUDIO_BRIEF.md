# Visual, UI, Sound and Game-Feel Production Brief

## Creative north star
The Last Check-In is a 60–90-minute *cinematic crime-thriller puzzle game*, not a typical puzzle-pack app. The player works overnight at an isolated seaside motel where Nina, the previous receptionist, has vanished. Every puzzle is a physical/digital action that uncovers evidence. Quiet, ominous, grounded; no jump-scare dependency. Core feeling: "one more puzzle because I need to know what happened."

## Art direction: intimate illustrated noir
- **Look:** high-quality 2D illustrated environments with expressive shadow shapes, subtle wet reflections, warm practical light against cold blue-green rain, textured paper, chipped paint and lived-in motel details. Think prestige indie narrative game rather than corporate UI.
- **Colour language:** deep blue/slate shadows (#0b1520, #182e36); amber incandescent (#e8b877) for affordances; desaturated teal for surveillance/tech; muted red for danger, never overuse bloom.
- **Characters:** Nina (smart, determined motel staffer); Owen (owner, nervous and withholding); Claire (guest, grief sharpened into determination); Daniel (security contractor, threatening without caricature); player as an unseen night receptionist. Create portrait/half-body original illustrations with at least neutral, concerned and tense variants when possible.
- **Staging:** 8 current scene locales: exterior, reception, security, Room 17, service corridor, records office, rear yard, disused laundry. Provide framing changes, close-ups and clue inserts so repeated locations feel purposeful. Backgrounds can be a multilayered scene with composited overlays and animated lighting/rain, not 28 independent full illustrations.
- **UI metaphor:** motel records, worn plastic access panels, CCTV overlays, physical receipts, desk drawers, dossiers and evidence photos. Avoid generic cards everywhere or stereotypical "AI dashboard" glow.
- **Asset rule:** all runtime assets bundled. Generate original SVG/Canvas/CSS or self-made illustrations; use licensed offline assets only when rights are clear. Do not fetch remote images at runtime.

## Screen architecture
1. **Title:** moody animated motel exterior; simple logo, Begin/Continue, subtitle, Sound, and Credits. The first tap activates audio. No account/monetisation.
2. **Narrative scene:** art takes 55–65% of the phone height when appropriate; character portrait or silhouette, elegant caption/dialogue area below, speaker ID, tap to advance, optional fast-forward and text replay, safe-area support. At typical reading speed, scenes around **20–40 seconds** (player-controlled, not timed).
3. **Puzzle mode:** visual close-up of in-world object; visually unambiguous objective; inputs at least ~44 CSS pixels; contextual first-time affordances; Hint, Reset; subtle sound and responsive feedback. No forced timers/lives.
4. **Discovery:** object reacts, scene refocuses, clue becomes legible, narrative reveals new fact, evidence auto-stores. Use short transitions; don't insert a generic coin/reward screen.
5. **Evidence board:** chapter tabs or chronology, readable clues, named people/locations and crime timeline. Never spoil future clue content. Accessible from story and puzzle, with a clean close/back gesture.
6. **Settings/pause:** independent Music, Ambience and Effects sliders or toggles; text speed, reduce motion, sound state persistence; continue/reset warning.

## Puzzle visual overhaul (seven systems)
| Existing kind | Visual fiction | Interaction and animation |
| --- | --- | --- |
| `circuit` | Spare battery, CCTV board, emergency intercom, boiler/valve wiring | Tap to rotate real elbow/straight copper traces; powered path pulses, switches clack; wrong orientation visible |
| `sort` | Hotel receipts, timelines, old ledger, CCTV events | Paper/card stack with ink, dates, varied thickness and clear order; drag to reorder plus accessible tap-swap fallback; gentle bounce/snap |
| `slide` | Drawer trays, CCTV pixel-fragment reconstruction, inner barrier | Context-sensitive image fragments and embossed metal drawers, not numbered beige tiles; preserve 8-puzzle logical accessibility; highlight movable tiles |
| `screws` | Access reader, vent grille, equipment case | Layered plates, actual screw heads, shadow/depth and stacking order, screw animation and plates dropping away; preserve dependency graph |
| `match` | Evidence board: suspects, receipts, statements, timestamps | Connect visual evidence cards via string/lines, preferably drag/select two items; preserve correct pair associations; no accidental spoilers |
| `keypad` | Room 17 electronic door, archived recording safe, laundry override | Physically convincing backlit keypad, metallic casing, mechanical feedback, masked code, clear clue available without leaving screen |
| `parking` | Top-down motel service yard and delivery van | Draw distinct cars, wet asphalt markings, tyre highlights, lane movement with drag plus arrow controls; collision constraints unchanged; clear exit |

Important: maintain each puzzle's input validation and guaranteed solution. Aesthetic redraws must not make puzzle states impossible to interpret.

## Cinematic grammar / animation
- Scene starts: quick establishing push or lateral drift (1–2 s maximum), no unskippable cinematic between every puzzle.
- Rain outside, flickering VACANCY sign, water streaks on windows, signage glow. Respect `prefers-reduced-motion`.
- Dialogue: brief expression shifts and depth-of-field/tint cues; optional restrained typewriter effect but never delays fast readers.
- Inspection: camera crops tightly onto an object; physically transition from narrative wide shot to puzzle close-up and back to clue reveal.
- Success: preserve visible solved state for ~0.5–0.9 seconds; play contextual sound, then show the evidence in world; no coins/stars/confetti.
- Mystery reveals: occasional 0.3-second visual cut, VHS noise, distant door slam or sudden silence. Use contrast sparingly.
- Keep 60 fps on mobile during simple interactions when feasible; avoid 4K textures, high-overdraw particle storms, heavy shader stacks or large third-party engines.

## Audio production spec
**Priority 1:** genuinely layered ambience, not just beeps. Create an original bundled soundtrack/sound set; procedural WebAudio synthesis is a valid fallback. Avoid copyrighted recordings.

- Global buses: `master`, `music`, `ambience`, `effects`, (optional `voice`). Persist settings, default modestly quiet, mute easily.
- Room tones: exterior heavy rain/wind/distant surf, reception softened rain/electric buzz, security low monitor fan/static, Room 17 fluorescent hum/rain on glass, service corridor metal creaks/drips, records room muted hum, yard wind and vehicle ambience, laundry boiler/drips.
- Context cues: desk phone ring/click, note unfold, document shuffle, metal drawer slide, screw ratchet, keypad clicks/errors, CCTV interference, circuit powerup, access granted, evidence lock-in, thud/door creak, walkie/radio filter, epilogue relief.
- Music: sparse low suspense pads, light investigative pulse, stronger but restrained final-act cue, quiet resolution; loop/transition seamlessly. Do not overwhelm dialogue or puzzle sounds.
- Use volume envelopes/crossfades/ducking rather than abrupt jumps. Start AudioContext only after user input, pause on background/tab hidden, handle iOS/Android audio unlocking reliably.
- If `prefers-reduced-motion` enabled, reduce camera effects; audio accessibility remains independent.
- If shipping recorded SFX/music, list each asset and its original/licensed origin in `ASSET_LICENSES.md`.

## Specific scene beat treatment
- Opening 11:43 PM: exterior rain; reception interior; abandoned handbag/keys/cup; Owen phone call; folded warning; monitor dead; zoom to under-desk backup panel. Reach first interactive puzzle promptly.
- Level 1 solved: current flows through copper traces, monitor boots, `ROOM 17 — 11:18 PM — AUTHORISED: NINA S.` is revealed. Slight music drop.
- Level 4: CCTV reconstruction with static/wet security-camera feel, shadowy maintenance jacket.
- Level 8: impossible keycard use and Room 17 re-entry. Silence, hard cut, restrained cliffhanger.
- Middle chapters: room cleaning clues, old 2019 file, van and hidden laundry access, increasingly oppressive atmosphere.
- Final chapter: build pressure through intercom and machinery, rescue Nina (not exploitative), back up evidence, reveal consequences and finish with an earned quiet epilogue.

## Usability and technical quality
- Portrait priority on Android: check 360×780, 390×844, 412×915; respect camera notch, status and gesture nav bars; no footer covering game controls; allow content scrolling if short screens.
- Body text ideally 16–19 px with sensible contrast. Labels never too tiny to read at phone viewing distance. Minimum touch target 44×44 CSS px.
- All actions doable without drag as alternative, all narrative skippable/advancable, loading never hides critical clues, transitions don't block input indefinitely.
- Provide motion/audio/text-speed options and test sound disabled; correct screen reader labels where practical.
