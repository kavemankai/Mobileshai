# Verified production results — 7 November 2026

Final build SHA-256: `51853b537b5a53912b3af452a463c216e2280f7a4a73f2a71e77c51143eecba0`.

`tests/smoke_playwright.py`: passed normal/debug checks at 360×780 and 412×915.

`tests/full_case_debug.py`: passed all 28 developer skips, exact clue-title checks, four chapters and the complete ending.

`tests/production_qa.py`: **19 checks passed, 0 failed; zero JavaScript exceptions**.

- developer controls hidden by default
- network disabled for complete legal-input playthrough
- 28 puzzles solved using legal UI inputs; all 28 exact unique clues; four chapters and complete ending
- all runtime requests local; full case works without network
- completed save resumes after reload
- legacy save key and intro/puzzle/reveal resume; interrupted victory awards clue once
- persistent mute, bus volumes, reduce motion and text size
- seven title taps enable developer tools; stage sandbox preserves normal save
- all 28 puzzle layouts fit and controls scroll into view at 360x780
- all 28 puzzle layouts fit and controls scroll into view at 390x844
- all 28 puzzle layouts fit and controls scroll into view at 412x915
- all 28 puzzle layouts fit and controls scroll into view at 1280x900
- pointer drag reorders paper records and moves vehicles legally
- drag connects matching evidence; tap alternative also passed full case
- reset restores puzzle; two progressive hints and penalty-free player skip award exact clue
- query flag and hash flag enable developer mode
- all four named characters have original illustrated appearances
- keyboard puzzle focus survives render; settings trap focus and Escape closes
- zero JavaScript exceptions across all runs

## Evidence and reproducibility

See `artifacts/qa-results.json` for the machine-readable result, and `artifacts/index.html` for the screenshot gallery. The original handoff smoke/full-case tests passed before changes. `source/story.js` is byte-for-byte identical to the supplied archive (SHA-256 `1fba0f43000801c60f00f4b881771fd348077fa39a044e23e93d03da64996228`).

Normal-play solvers calculate legal moves externally and click the real UI; they never overwrite a puzzle with a solved state. Separate save-recovery, layout and developer fixtures intentionally select states to inspect those paths. The legal-input walkthrough disables browser-context network access after loading the local HTML. Desktop is checked at 1280×900; all three phone sizes inspect every stage and verify scroll access to controls, with header buttons remaining inside the viewport.

The standalone HTML is built only from local source. No runtime third-party dependencies or media requests are required. Screenshots settle finite animations for legible captures. The preview server's HTTP response was verified as 200.

## Acceptance limits

Automated Chromium touch emulation is not physical Android/iOS acceptance. Real-device audio balance, speaker/headphone listening, sustained performance, screen-reader usability and player judgement of art/game feel remain unverified. Runtime art and audio are original vector/procedural work; there is no painted raster pack, recorded soundtrack, voice acting, APK or installable PWA. The source retains background-tab audio suspension, but real-device audio interruption/recovery still needs hands-on testing.
