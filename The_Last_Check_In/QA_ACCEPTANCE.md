# Quality Assurance and Acceptance Criteria

## Functional regression — must pass
- [ ] A new player can begin with no saved progress, play Level 1, see its solved circuit and receive the correct 11:18 PM checkout clue.
- [ ] All **28** levels can be completed using normal input; no solution or mechanic is inaccessible due to art/UI layout changes.
- [ ] Four chapters play in order (levels 1–8, 9–15, 16–22, 23–28); intro/reveal for every level, then the complete end screen.
- [ ] All 28 clues appear once in the archive; duplicate taps and repeated winning signals do not duplicate them.
- [ ] Standard hints work as before: Hint 1, Hint 2, and optional Skip. Player can still skip after hint use without losing the clue.
- [ ] Developer mode is **off by default**. It is enabled by `?debug=1`, `#debug` or seven taps on the title; `DEV Skip puzzle` exists ONLY during developer play.
- [ ] Tapping developer `Skip puzzle` immediately causes the same correct evidence/reveal transition as a real win and never overwrites another stage's clue. Repeat through the complete game as a test.
- [ ] Save/continue works across reloads during intro, active puzzle, after reveal and at ending. Changing code doesn't wipe existing `last-check-in-complete-v1` saves.
- [ ] Reset the current puzzle, pause/resume, go to title/continue, view archive, toggle sound, restart with confirmation all work.
- [ ] The game plays with network offline after assets are locally available; no remote runtime calls.

## Visual / feel — must pass
- [ ] Illustrated original motel exterior and eight scene locales appear consistently; puzzle presentation is contextual rather than a bare labelled tile grid.
- [ ] Character designs/expressions and evidence close-ups enrich the scenes. At least the main four NPCs have recognisable visual identities.
- [ ] Interactive puzzle elements have obvious pressed/selected/valid/invalid states, with tactile animation and sound.
- [ ] Scene→puzzle→evidence transitions read cinematically without slow repeated intros.
- [ ] Evidence board visually organises clues and does not reveal future information.
- [ ] No generic grey placeholder blocks, missing asset symbols or unfinished chapter screens in the shipped build.

## Audio — must pass
- [ ] Room ambience exists; sound events for phone, power, clues, keypad, paper, metal and CCTV are distinct.
- [ ] At least one original ambient music loop or equivalent procedural mood bed and a subtle ending shift are present.
- [ ] Audio only begins after user gesture (browser policy), can be muted, settings persist and audio pauses appropriately in background.
- [ ] No copyrighted third-party music/audio used without explicit licence; attribution included when needed.

## Usability and performance — must pass
- [ ] Test Android-style portrait **360×780, 390×844, 412×915** and desktop window. No content clipped, horizontally scrolling or hidden under the phone safe-area.
- [ ] Long item text, font scaling, small screens and on-screen controls still work. Critical buttons at least 44px where feasible.
- [ ] `prefers-reduced-motion` reduces unnecessary effects. No flashing/hard strobe.
- [ ] Keyboard focus remains visible on desktop; pointer/touch input works reliably; accessibility fallback exists for drag interactions.
- [ ] No console errors in a complete start-to-ending test. No runaway audio sources, unbounded timeouts, input double-activation or memory leaks.

## Test artifacts Codex must deliver
- Screenshot: title, opening narrative, Level 1 puzzle, a matching/screw/parking puzzle, evidence board, chapter finale, ending.
- Automated result: story completion, 28-level victory path, 28-level developer skip path, save migration check, normal user hidden debug check, offline availability check.
- README: how to run/build, debug flag, audio settings, known limitations, where assets live and licensing.
- Final offline playable build in `dist/`; no placeholder work plan in place of a game.

## Baseline (before Codex polish)
- 28 authored levels across 4 chapters; 7 puzzle mechanics; current visuals are minimalist SVG scenes; short synthesized WebAudio clicks.
- New developer skip was checked in Chromium through in-memory page injection at widths **360×780** and **412×915**, verified to grant the Level 1 clue and enter reveal state; default mode remained hidden and seven-title-tap activation worked. In addition, the packaged baseline passed an automated 28-stage developer-skip walkthrough, confirming 28 unique evidence awards and the complete ending with no JS exceptions (390×844 in Chromium). These are tests of the handoff baseline, NOT proof of full Android device compatibility or complete post-polish acceptance.
