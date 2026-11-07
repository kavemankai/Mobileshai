# Environment pass 02 validation

7 November 2026. Five scene backdrops generated with the built-in image tool using
the user-supplied Mariner Motel board as a style reference. Exact prompts, native
dimensions and source/runtime paths are in `manifest.json`; `index.html` previews
the original paintings. Runtime files are WebP quality 88, with no upscaling.

## Checks completed

- Visually inspected all five generated paintings: separate full-scene compositions,
  coherent teal/amber coastal-motel materials, no UI or board labels baked in.
- All nine `SceneKey` values now map to a local painted image.
- `npm run build`: passed, including TypeScript checking.
- `npm run build:single`: passed; self-contained HTML is approximately 3.33 MB.
- `npm test`: 32/32 passed, covering all 28 puzzles.
- Room cards remain visible (`PROPS_VISIBLE = true`), so existing interaction
  coordinates are not mistaken for aligned painted objects.

## Browser verification blocked

`npm run e2e` could not start because the Playwright browser bundle is absent.
A retry using installed `/usr/bin/chromium` also failed before opening the game:
`process_singleton_posix.cc:297: socket() failed: Operation not permitted (1)`.
No phone viewport, offline-PWA or full browser walkthrough pass is claimed.
Run the existing `npm run check` suite in an environment that permits Chromium,
then inspect the five new locations on a real phone.

## Remaining art work

These are background plates, not completed escape-room paintings. Service corridor,
Room 17 corridor and laundry need hotspot-aligned layers and pickup/open states.
Records needs a dedicated hidden-object composition. Four earlier scene paintings,
character expressions/cutouts, CCTV path frames, puzzle skins and recorded audio
remain separate work. The records painting is 1054×1492 rather than 9:16; the
runtime uses its existing cover crop. All assets need phone crop/readability review.

## Rebuild

From `game/`, run `npm ci`, `npm run build`, `npm run build:single`, and `npm test`.
Both generated builds were refreshed locally; build directories remain ignored as
configured by this repository. Original prototype under `The_Last_Check_In/` is
untouched; the active game is `game/`.
