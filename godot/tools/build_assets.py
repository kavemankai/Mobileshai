#!/usr/bin/env python3
"""One-off conversion of the web game's assets into the Godot project.

    python3 godot/tools/build_assets.py

Reads game/src/assets (the web build's art and AAC audio) and writes godot/assets:
  - images copied under clean names (Godot imports WebP and PNG directly)
  - audio converted from AAC (.m4a) to Ogg Vorbis, because Godot cannot play AAC
  - fonts: Liberation Serif (story text) and DejaVu Sans/Mono (symbols, labels), plus a subset of
    Noto Color Emoji holding only the glyphs the placeholder icons use (10 MB down to about 100 KB)

After the web build is retired, godot/assets is the canonical copy and this script is no longer needed.
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "game", "src", "assets")
DST = os.path.join(ROOT, "godot", "assets")

SCENES = {  # clean name -> source file
    "exterior": "art/exterior-wip.webp", "title": "art/exterior_title-wip.webp", "reception": "art/reception-wip.webp",
    "security": "art/security-wip.webp", "room17": "art/room17-wip.webp", "service": "art/service-v2.webp",
    "corridor17": "art/corridor17-v2.webp", "yard": "art/yard-v2.webp", "records": "art/records-v2.webp",
    "laundry": "art/laundry-v2.webp",
}
PORTRAITS = {n: f"portraits/{n}.webp" for n in (
    "nina_neutral", "nina_frightened", "nina_relieved", "claire_guarded", "claire_grieving", "claire_angry", "owen", "daniel")}
ITEMS = {n: f"inventory/{n}.png" for n in ("torch", "screwdriver", "coin_50c", "gloves")}
TILES = {f"match_tile_{i}": f"puzzles/match_tile_{i}.png" for i in range(1, 6)}
CCTV = {n: f"cctv/panel_{n}.webp" for n in ("01_wide", "01_close", "02_wide", "02_close", "05_wide", "05_close")}

FONTS = {  # destination name -> system file
    "serif.ttf": "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf",
    "serif_italic.ttf": "/usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf",
    "serif_bold.ttf": "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf",
    "symbols.ttf": "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "mono.ttf": "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    "mono_bold.ttf": "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
}
EMOJI_SRC = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"


def copy_group(group: str, mapping: dict, ext: str) -> None:
    out = os.path.join(DST, group)
    os.makedirs(out, exist_ok=True)
    for name, rel in mapping.items():
        shutil.copyfile(os.path.join(SRC, rel), os.path.join(out, name + ext))


def convert_audio() -> None:
    for group in ("sfx", "ambience", "music", "stingers"):
        src_dir = os.path.join(SRC, "audio", group)
        out = os.path.join(DST, "audio", group)
        os.makedirs(out, exist_ok=True)
        for f in sorted(os.listdir(src_dir)):
            if not f.endswith(".m4a"):
                continue
            dst = os.path.join(out, f[:-4] + ".ogg")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", os.path.join(src_dir, f),
                            "-c:a", "libvorbis", "-q:a", "4", "-ac", "1", dst], check=True)


def emoji_codepoints() -> str:
    """Every emoji the story data and the code ask for, so the subset never misses one."""
    text = ""
    # the level data, plus every script (some icons are written in code)
    paths = [os.path.join(ROOT, "godot", "data", "levels.json")]
    for base, _dirs, files in os.walk(os.path.join(ROOT, "godot", "scripts")):
        paths += [os.path.join(base, f) for f in files if f.endswith(".gd")]
    for path in paths:
        text += open(path, encoding="utf-8").read()
    extra = "🔦🪛🕸🔳🧰🔲🪙🧤👆"
    cps = set()
    for ch in text + extra:
        cp = ord(ch)
        if cp >= 0x1F000 or (0x2600 <= cp <= 0x27BF and ch not in "✓✗") or cp in (0x2B50, 0x2B06, 0x2B07):
            cps.add(cp)
    cps.discard(0xFE0F)
    return ",".join(f"U+{c:X}" for c in sorted(cps))


def build_fonts() -> None:
    out = os.path.join(DST, "fonts")
    os.makedirs(out, exist_ok=True)
    for name, src in FONTS.items():
        shutil.copyfile(src, os.path.join(out, name))
    subprocess.run([sys.executable, "-m", "fontTools.subset", EMOJI_SRC, f"--unicodes={emoji_codepoints()},U+FE0F",
                    f"--output-file={os.path.join(out, 'emoji_subset.ttf')}"], check=True)


def main() -> None:
    copy_group("art", SCENES, ".webp")
    copy_group("portraits", PORTRAITS, ".webp")
    copy_group("items", ITEMS, ".png")
    copy_group("tiles", TILES, ".png")
    copy_group("cctv", CCTV, ".webp")
    convert_audio()
    build_fonts()
    total = 0
    for dp, _, files in os.walk(DST):
        for f in files:
            size = os.path.getsize(os.path.join(dp, f))
            total += size
            if size > 6 * 1024 * 1024:
                print("WARNING: large file", os.path.join(dp, f), size)
    print(f"godot/assets: {total / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()



def build_emoji_only() -> None:
    """Rebuilds just the emoji subset, when new icons appear in the data or code."""
    out = os.path.join(DST, "fonts")
    subprocess.run([sys.executable, "-m", "fontTools.subset", EMOJI_SRC, f"--unicodes={emoji_codepoints()},U+FE0F",
                    f"--output-file={os.path.join(out, 'emoji_subset.ttf')}"], check=True)
