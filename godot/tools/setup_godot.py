#!/usr/bin/env python3
"""Installs the pinned Godot editor and its web export templates, verified.

    python3 godot/tools/setup_godot.py                 # local: editor + web templates only
    python3 godot/tools/setup_godot.py --verify-full   # CI: also download the whole templates pack and check its SHA-512

Editor:    downloaded from the official godot-builds release and checked against that release's SHA512-SUMS.txt.
Templates: the full pack is 1.2 GB, but only four small web templates are needed. By default they are read out of
           the remote zip with HTTP range requests (each entry is CRC-checked). --verify-full downloads the whole
           pack instead and checks its SHA-512.
Nothing is executed during install, and only the exact file names listed below are extracted.

Layout (GODOT_HOME defaults to ~/.cache/godot-tools):
    $GODOT_HOME/godot-<version>/godot                      the editor (headless-capable)
    ~/.local/share/godot/export_templates/<version>.stable the templates Godot looks for
"""
import argparse
import hashlib
import io
import os
import re
import stat
import sys
import urllib.request
import zipfile

VERSION = "4.6.2"
BASE = "https://github.com/godotengine/godot-builds/releases/download/{v}-stable/{name}"
EDITOR_ZIP = "Godot_v{v}-stable_linux.x86_64.zip"
EDITOR_BIN = "Godot_v{v}-stable_linux.x86_64"
TEMPLATES = "Godot_v{v}-stable_export_templates.tpz"
WANTED_TEMPLATES = {
    "templates/web_nothreads_release.zip", "templates/web_nothreads_debug.zip",
    "templates/web_release.zip", "templates/web_debug.zip", "templates/version.txt",
}


def get(url: str, headers: dict | None = None) -> bytes:
    req = urllib.request.Request(url, headers=headers or {"User-Agent": "lci-setup"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def sha512_of(data: bytes) -> str:
    return hashlib.sha512(data).hexdigest()


def expected_sha(version: str, name: str) -> str:
    sums = get(BASE.format(v=version, name="SHA512-SUMS.txt")).decode()
    for line in sums.splitlines():
        digest, _, fname = line.strip().partition("  ")
        if fname.strip().lstrip("*") == name:
            return digest
    raise SystemExit(f"{name} is not listed in SHA512-SUMS.txt")


class RangeFile(io.RawIOBase):
    """A read-only seekable view of a remote file, using HTTP range requests."""

    def __init__(self, url: str):
        self.url = urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=60).geturl()
        head = urllib.request.urlopen(urllib.request.Request(self.url, method="HEAD"), timeout=60)
        self.size = int(head.headers["Content-Length"])
        if head.headers.get("Accept-Ranges") != "bytes":
            raise SystemExit("server does not support range requests; use --verify-full")
        self.pos = 0

    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.pos

    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.size + offset
        return self.pos

    def read(self, n=-1):
        if n < 0 or self.pos + n > self.size:
            n = self.size - self.pos
        if n <= 0:
            return b""
        data = get(self.url, {"Range": f"bytes={self.pos}-{self.pos + n - 1}", "User-Agent": "lci-setup"})
        self.pos += len(data)
        return data

    def readinto(self, b):
        data = self.read(len(b))
        b[:len(data)] = data
        return len(data)


def install_editor(version: str, home: str) -> str:
    dest = os.path.join(home, f"godot-{version}")
    binary = os.path.join(dest, "godot")
    if os.path.exists(binary):
        print(f"editor already installed: {binary}")
        return binary
    name = EDITOR_ZIP.format(v=version)
    print(f"downloading {name} ...")
    data = get(BASE.format(v=version, name=name))
    want = expected_sha(version, name)
    got = sha512_of(data)
    if got != want:
        raise SystemExit(f"SHA-512 mismatch for {name}\n  expected {want}\n  got      {got}")
    print("editor SHA-512 verified")
    os.makedirs(dest, exist_ok=False) if not os.path.isdir(dest) else None
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        member = EDITOR_BIN.format(v=version)
        with z.open(member) as src, open(binary, "wb") as out:
            out.write(src.read())
    os.chmod(binary, os.stat(binary).st_mode | stat.S_IXUSR | stat.S_IXGRP)
    print(f"editor installed: {binary}")
    return binary


def install_templates(version: str, verify_full: bool) -> str:
    dest = os.path.expanduser(f"~/.local/share/godot/export_templates/{version}.stable")
    have = all(os.path.exists(os.path.join(dest, os.path.basename(n))) for n in WANTED_TEMPLATES)
    if have:
        print(f"templates already installed: {dest}")
        return dest
    name = TEMPLATES.format(v=version)
    url = BASE.format(v=version, name=name)
    if verify_full:
        print(f"downloading {name} (about 1.2 GB) ...")
        data = get(url)
        want = expected_sha(version, name)
        if sha512_of(data) != want:
            raise SystemExit(f"SHA-512 mismatch for {name}")
        print("templates SHA-512 verified")
        z = zipfile.ZipFile(io.BytesIO(data))
    else:
        print(f"reading web templates from {name} with range requests ...")
        z = zipfile.ZipFile(RangeFile(url))
    os.makedirs(dest, exist_ok=True)
    names = set(z.namelist())
    for member in sorted(WANTED_TEMPLATES):
        if member not in names:
            raise SystemExit(f"{member} not found in {name}")
        out = os.path.join(dest, os.path.basename(member))
        with z.open(member) as src, open(out, "wb") as f:  # zipfile verifies the CRC while reading
            f.write(src.read())
        print(f"  {os.path.basename(member)}  {os.path.getsize(out) // 1024} KB")
    return dest


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--version", default=VERSION)
    ap.add_argument("--home", default=os.environ.get("GODOT_HOME", os.path.expanduser("~/.cache/godot-tools")))
    ap.add_argument("--verify-full", action="store_true", help="download the whole templates pack and check its SHA-512")
    args = ap.parse_args()
    if not re.fullmatch(r"\d+\.\d+(\.\d+)?", args.version):
        raise SystemExit("bad version")
    os.makedirs(args.home, exist_ok=True)
    binary = install_editor(args.version, args.home)
    install_templates(args.version, args.verify_full)
    print(f"\nGODOT={binary}")


if __name__ == "__main__":
    sys.exit(main())
