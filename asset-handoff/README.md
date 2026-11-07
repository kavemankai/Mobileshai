# The Last Check-In — upload handoff

**Status: ZIPs have NOT been uploaded.** This branch was created from `assets/environment-pass-02` to stage a 127-file *WIP* art/audio pack. The ZIP files are available from the ChatGPT conversation download links but cannot be transferred to GitHub through the current binary-limited connector. This directory provides exact expected filenames and checksums for a manual upload.

## Expected ZIP files (upload to `asset-handoff/zips/`)

| File | Bytes | SHA-256 |
|---|---:|---|
| `Last_Check_In_Part_01_Docs_and_Master_Reference.zip` | 2726676 | `e5a2daf42d5ed41bf20a278cf0df93d3846655e10a7a19cbf96fbc76bcdc528b` |
| `Last_Check_In_Part_02_Scenes_Portraits_and_Concept_Boards.zip` | 1392235 | `e25afb99c725229b3054663a988906727b7141570187d03ad3d8faa796343fea` |
| `Last_Check_In_Part_03_Interactive_CCTV_and_Inventory.zip` | 1204604 | `470757eedc6549bb2a844c811b759c782950894a880db27731d2292b67b22a56` |
| `Last_Check_In_Part_04_Puzzle_Skins_A.zip` | 2671478 | `ded7967a30cecd76ef43da2b7d7fe225e3d4c0261da661b9650bfac1e0230256` |
| `Last_Check_In_Part_05_Puzzle_Skins_B.zip` | 1585892 | `e8581c00400ef564f552d870098ebc1fa282f4ed64207851500ee3d968a60024` |
| `Last_Check_In_Part_06_Music_and_Ambience.zip` | 2728916 | `af2122dea8c25a14f56f50ceeab2970bbb7226bc0164adaea6fc23d296f7c244` |
| `Last_Check_In_Part_07_SFX_and_Stingers.zip` | 208807 | `5d5b1cf69bbaa4352dd1308fcb3af4dcca310621fd3a4f6c12e9a32c11b53919` |

## How to complete upload

1. Download all seven ZIPs from the ChatGPT conversation.
2. In GitHub, select branch `assets/zip-handoff-2026-11-07`, navigate to this `asset-handoff/` directory, use **Add file → Upload files**, and place each ZIP under `asset-handoff/zips/` (or use a local clone and `git add`).
3. Check that all seven ZIP files exist in the repository with the same names and SHA-256 hashes.
4. Extract all parts into a **single staging directory**, not directly into the game. Preserve the relative paths and read the included `CODEX_TASK.md`.
5. Use Codex to integrate selectively; **never overwrite the five newer `*-v2.webp` environment images** already referenced in `game/src/assets/manifest.ts`.
6. Run `npm test`, `npm run build`, and browser/gameplay QA.

Do not describe these as finished art: interactive alignments, CCTV joins, expressions, scene layers, audio integration, and device QA still need work.
