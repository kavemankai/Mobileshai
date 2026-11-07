# The Last Check-In: asset handoff

**Status: uploaded and integrated (7 November 2026).** All seven ZIPs are in `zips/` under their canonical names, and every one matches `CHUNK_SHA256SUMS.txt`:

```bash
cd asset-handoff/zips && sha256sum -c ../CHUNK_SHA256SUMS.txt
```

Parts 3–7 were first uploaded to the repo root as `LCI_Assets_03.zip`…`07.zip`. They were moved here and renamed. The bytes are unchanged.

| File | Bytes | Files inside |
|---|---:|---:|
| `Last_Check_In_Part_01_Docs_and_Master_Reference.zip` | 2,726,676 | 16 |
| `Last_Check_In_Part_02_Scenes_Portraits_and_Concept_Boards.zip` | 1,392,235 | 26 |
| `Last_Check_In_Part_03_Interactive_CCTV_and_Inventory.zip` | 1,204,604 | 31 |
| `Last_Check_In_Part_04_Puzzle_Skins_A.zip` | 2,671,478 | 11 |
| `Last_Check_In_Part_05_Puzzle_Skins_B.zip` | 1,585,892 | 12 |
| `Last_Check_In_Part_06_Music_and_Ambience.zip` | 2,728,916 | 15 |
| `Last_Check_In_Part_07_SFX_and_Stingers.zip` | 208,807 | 26 |

137 files in total. The earlier note said 127; the difference is pack metadata (chunk info files, manifests, scripts).

## What happened to the contents

Integrated selectively into `game/`. The full list of what went in, what didn't and why is in [`game/ASSETS.md`](../game/ASSETS.md). In short:

- **In:** five scene plates (exterior, title, reception, security, Room 17), Nina and Claire expression cutouts, inventory icons, match-3 tiles, four CCTV footage pairs, and all 39 audio files.
- **Out:** the five older scene plates that the env pass 02 paintings supersede, the interactive and hidden-object plates (placeholder boxes baked in), the puzzle skin textures (labels baked in), Owen and Daniel expressions (cutout defects), four CCTV label crops, and the build scripts.

The newer `*-v2.webp` environment paintings were not overwritten.

These ZIPs are a work-in-progress pack, not finished art. Once nothing more is needed from them, consider moving them to a GitHub Release attachment. They add about 12.5 MB to every clone of the repository.
