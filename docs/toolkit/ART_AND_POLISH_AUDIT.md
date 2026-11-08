# The Last Check-In art and polish audit

Baseline `b4eee49c1cf028d4ab864aa084186362142e274a` on `ccr-9346ee96-cvq9fq`. The source for shipped and rejected art is [game/ASSETS.md](../../game/ASSETS.md). The runtime asset map remains `game/src/assets/manifest.ts`.

| Priority | Evidence | Acceptance |
| --- | --- | --- |
| 1. Escape rooms 5, 9, 10 and 23 | Level 5 renders a strong corridor backdrop behind labelled translucent prop cards. The WIP pack's baked rectangles are incompatible with the live hotspots. | Paint 4:5 scenes to the existing hotspot coordinates. Supply open/taken overlays. Confirm touch alignment at 360×640 and 390×844 before hiding cards. |
| 2. Hidden objects 2 and 14 | Existing playthrough loads both boards. Items remain emoji over a dimmed background. | Provide dedicated 3:4 illustrations at 1536×2048 or larger and visually verify existing target positions. |
| 3. Title and environment continuity | The title neon sign clips at the right edge in the 390×844 crop. The reception plate in narrative is visibly softer than the env-pass-02 corridor. | Match env pass 02 with independent 9:16 paintings. Review native 1080×1920 targets and keep the sign readable behind the title layout. |
| 4. Supporting art | Owen and Daniel use first-pass crops. Level 13 CCTV and both match-3 reveal illustrations are outstanding. | Deliver transparent expression cutouts, clean wide/close footage and reveal images with the approved composition. |
| 5. Layout and audio | At 844×390, the escape-room scene extends below the fold and settings need scrolling for the lower controls. No horizontal overflow or image decode failure occurred in the captured scenes. The native suite decoded 22 effects and 3 stingers. | Test scroll and reachability on actual phones before changing layout. Use the existing AAC paths for approved recorded assets and check focus, interruptions and tilt on hardware. |

The existing docs record draft provenance and original prompts. Before commercial distribution, record rights and original sources per asset, especially for the supplied WIP pack and synthesized audio. The PWA was built locally for QA.

## Reproduce

Use Node 22 or newer. From `game/`, run `npm ci --ignore-scripts`, `npm exec -- playwright install chromium` if matching Chromium is missing, and `npm run check`. From the repository root, start the loopback preview in one terminal.

```text
node .game-toolkit/adapters/web/serve.mjs --dir game/dist --port 4173
```

Run the capture in a second terminal. Use a fresh local output path outside the checkout and stop the preview when done.

```text
node .game-toolkit/adapters/web/playtest.mjs --project game --url http://127.0.0.1:4173/ --scenario tests/toolkit-preview.mjs --out ../lci-preview
```

The captures cover title, settings, narrative, puzzle and ending at 360×640, 390×844, 844×390 and 1280×720. The scenario checks normal save/resume, a debug sandbox skip, asset decode and offline reload after service-worker activation. The existing suite supplies full 28-puzzle walkthrough and audio checks. The ending screenshots contain spoilers and are retained in local evidence.

GitHub reports the default branch as `ccr-9346ee96-cvq9fq`. Pages workflow push triggers target `main`. The public site returned HTTP 200 and the latest visible successful deployment was `main` at `7c16adbd2771836a05566241ceff524ecc1ada65`. The unauthenticated Pages settings endpoint returned 404. [Pages run](https://github.com/kavemankai/Mobileshai/actions/runs/42354996706)
