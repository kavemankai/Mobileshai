#!/usr/bin/env python3
"""Writes godot/asset-manifest.json in the game-toolkit format from what is in godot/assets.

Rights are recorded honestly: the art and audio are the project's own work-in-progress pack and still need an
explicit license decision; the fonts are open fonts that are not on the toolkit's permissive list.
Check it with:  node .game-toolkit/scripts/validate-manifest.mjs --repo . --manifest godot/asset-manifest.json
"""
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "godot" / "assets"

PURPOSE = {
    "art": "Scene backdrop and title art",
    "portraits": "Speaker portrait",
    "items": "Inventory icon",
    "tiles": "Match-3 tile sprite",
    "cctv": "CCTV footage frame for the Frames puzzle",
    "fonts": "UI font",
    "audio/sfx": "Sound effect",
    "audio/ambience": "Room tone loop",
    "audio/music": "Score cue loop",
    "audio/stingers": "One-shot stinger",
}
FONT_SOURCES = {
    "serif": "Liberation Serif", "serif_bold": "Liberation Serif Bold", "serif_italic": "Liberation Serif Italic",
    "mono": "DejaVu Sans Mono", "mono_bold": "DejaVu Sans Mono Bold", "symbols": "DejaVu Sans",
    "emoji_subset": "Noto Color Emoji (subset)",
}


def entry_id(group: str, stem: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", f"{group}-{stem}".lower()).strip("-")


assets = []
for path in sorted(ASSETS.rglob("*")):
    if not path.is_file() or path.suffix in {".import"}:
        continue
    rel = path.relative_to(ASSETS)
    group = "/".join(rel.parts[:-1])
    ext = path.suffix.lstrip(".")
    e = {
        "id": entry_id(group, path.stem),
        "purpose": PURPOSE.get(group, "Game asset"),
        "engine": "godot",
        "exportTarget": ext.upper(),
        "visualQa": "pending",
        "generated": [],
        "sourceFile": f"godot/assets/{rel.as_posix()}",
    }
    if group == "fonts":
        e.update(kind="other", origin="third-party", producer=FONT_SOURCES.get(path.stem, path.stem),
                 license="OFL-1.1" if path.stem != "emoji_subset" else "OFL-1.1", redistribution="allowed",
                 note="Open font. OFL-1.1 is not on the toolkit permissive list, so a person has to approve it.")
    elif ext in {"ogg"}:
        e.update(kind="audio", origin="first-party", producer="Project WIP audio pack (synthesised drafts)",
                 license="pending-review", redistribution="pending")
    else:
        with Image.open(path) as im:
            e.update(kind="image", width=im.width, height=im.height)
        e.update(origin="first-party", producer="Project WIP art pack (placeholders for the art pass)",
                 license="pending-review", redistribution="pending")
    assets.append(e)

out = ROOT / "godot" / "asset-manifest.json"
out.write_text(json.dumps({"schemaVersion": 1, "assets": assets}, indent=2) + "\n")
print(f"{len(assets)} assets -> {out.relative_to(ROOT)}")
