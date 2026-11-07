# CODEX — IMPLEMENT THE FULL POLISH PASS

**Project:** THE LAST CHECK-IN — a complete, offline, portrait-first crime-thriller puzzle game.

## Your task (do the work, do not just write a plan)

Take this existing **working** web game through a substantial, high-quality UI, art, sound and game-feel production pass. Ship the functioning result in this repository. The 28 puzzles, all four chapters, the fixed mystery, clue acquisition, normal hints/skip, saved progress and ending must survive. The current working source is in `source/`; `dist/The_Last_Check_In.html` is the playable single-file baseline.

Our goal is a polished experience for an adult who loves mobile puzzle adverts and crime-thriller mysteries. The game is a personal, premium-feeling gift with **no ads, energy, accounts or microtransactions**. Story scenes should be cinematic but brisk (generally 20–40 seconds of dialogue at a typical reading pace, and always tappable/skip-friendly). Most stages should be 30 seconds to 2 minutes.

### PRIMARY DELIVERABLES

1. A production-quality, mobile-first **visual experience**: atmospheric motel, illustrated character appearances and expressions, cinematic transitions, accessible dialogue, distinctive room props, layered parallax/rain/lighting, more elaborate evidence board, cohesive typography and motion. Current scenes are functional SVG sketches; **replace/extend them into polished game presentation**, rather than wrapping the old UI in cosmetic gradients.
2. A **contextual visual overhaul of every puzzle type**: circuit routing, physical receipt sorting, CCTV/photo sliding restoration, screw/plate removal, evidence matching, keypad, and movable parking-grid cars. Keep or improve real gameplay and logical solutions. Make the puzzles look like tangible story objects, not abstract buttons.
3. An original, offline-compatible **soundscape**: rain, coastal storm/room tone, telephone and electrical hum, tactile UI and puzzle SFX, CCTV/static, suspense stingers, at least a subtle evolving music bed. Sound must start only following a user interaction and must have persistent mute/volume settings. See `VISUAL_AUDIO_BRIEF.md`.
4. **Game-feel polish**: good touch targets, touch dragging where appropriate with an accessible tap alternative, micro-animations, affordances/hints, elegant reveals, transitions that connect scene→puzzle→clue→next scene without hard cuts, responsive layout on real Android portrait sizes.
5. **DEV TESTING TOOLKIT**: Preserve the now-working hidden developer mode and one-tap `Skip puzzle` button. In the supplied version, enable via `?debug=1` or `#debug`, or seven taps on the title; it reveals a dev-only Skip puzzle button during puzzle play. It calls the normal `win()` path, awards evidence and shows the reveal. Improve it with a compact developer overlay (jump to stage, advance a scene, test sound events, reset current puzzle, clear save, stage/phase readout) if you can do so without compromising normal gameplay. Normal players never see it. Never allow developer state to corrupt the standard save.
6. A **tested playable deliverable**: updated source, an easy local run command, an exported offline HTML/web build, actual screenshots at phone sizes, and documented test results. Preserve full completion of all 28 levels. Any app packaging is secondary; focus on the great phone-browser version first.

### NON-NEGOTIABLES

- **Do not replace the game with mockups.** Every level must remain interactive and completable; do not silently shrink 28 levels to a demo.
- **Keep the established story and canonical clues.** The crime, culprit, timestamps and ending are intentional. You can refine wording, not rewrite who did what without discussing it.
- **Preserve offline-first behaviour**: bundle every required runtime asset; no external image hotlinks, server APIs, third-party analytics or DRM; no network requirement to play.
- **Keep save compatibility** with existing key `last-check-in-complete-v1`, or add a tested migration so existing playthroughs aren't lost.
- **Keep DEV skip as an instant action** in developer mode, separate from the player hint→skip flow. It must award the correct clue exactly once and continue into the matching reveal.
- **Produce original assets or bundle clearly licensed assets only.** No unlicensed music, copyrighted video or remote stock images. If raster assets can't be created, draw polished layered SVG/Canvas/CSS illustrations with the same standard of art direction and document limitations.
- **Avoid generic AI-generated dashboard aesthetics.** This is a moody, illustrated crime-thriller *game*, not a productivity application.

### START HERE / ORDER OF EXECUTION

1. Inspect `README.md`, `AGENTS.md`, `source/` and `references/`. Start the existing game and run its smoke and full-case debug tests before making major changes.
2. Establish a visual/audio design system and modular components, then polish the **opening 2 levels to final standard** (first 90 seconds are critical). Do not stop there: carry that standard through **all 28** levels by reusing scene templates and the seven puzzle components.
3. Design the character roster, backgrounds and puzzle artwork. Implement transitions and SFX. Improve evidence/menus and responsive layout. Keep performance suitable for midrange Android phones.
4. Keep gameplay logic data-driven and decouple rendering from puzzle logic as practical. A lightweight Vite/vanilla JS or equivalent stack is acceptable; **a large framework is not required**. Rebuild `dist/` for offline delivery.
5. Run an automated full-case test, debug skip test, normal-play test, save-resume test, sound-muted test and phone viewport tests. Capture final screenshots. Correct regressions.
6. Report the changes, test results, how to run locally, how to access debug mode, and the remaining known limitations. Finish with a playable build, not a proposal.

### Other design requirements

Read `VISUAL_AUDIO_BRIEF.md`, `STORY_AND_LEVELS.md` and `QA_ACCEPTANCE.md` for scene-by-scene requirements and acceptance criteria.

If you need to choose between visual extravagance and reliable gameplay, retain **reliable gameplay**, then polish progressively. Make the finished version feel coherent throughout; do not fully illustrate only the first scene and leave later chapters as unstyled placeholders.
