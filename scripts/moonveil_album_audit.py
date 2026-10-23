#!/usr/bin/env python3
"""Verify an image album before adding it to the game.

Usage: python scripts/moonveil_album_audit.py path/to/album
Reads a manifest and image files; never changes the album or game saves.
"""
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

PNG = b"\x89PNG\r\n\x1a\n"
ID = re.compile(r"^[A-Z]{2}-[0-9]{3}$")
CATEGORY = re.compile(r"^[a-z][a-z0-9_]*$")


def audit(directory):
    directory = Path(directory)
    manifest = json.loads((directory / "manifest.json").read_text(encoding="utf-8"))
    records = manifest["assets"]
    if len(records) != manifest["count"]:
        raise ValueError("Manifest count mismatch")
    ids = set()
    paths = set()
    for item in records:
        ident, category, relative = item["id"], item["category"], item["path"]
        if (not ID.fullmatch(ident) or not CATEGORY.fullmatch(category)
                or relative != f"{category}/{ident}.png"
                or ident in ids or relative in paths):
            raise ValueError("Invalid, unsafe or duplicate asset record")
        ids.add(ident)
        paths.add(relative)
        file = directory / relative
        blob = file.read_bytes()
        if len(blob) < 24 or not blob.startswith(PNG):
            raise ValueError(f"Not PNG: {relative}")
        width, height = struct.unpack(">II", blob[16:24])
        if ((width, height) != (item["width"], item["height"])
                or hashlib.sha256(blob).hexdigest() != item["sha256"]):
            raise ValueError(f"Corrupted asset: {relative}")
        if item.get("owned") is True or item.get("ownership") == "acquired":
            raise ValueError("Artwork album must not grant inventory")
    disk = {p.relative_to(directory).as_posix()
            for p in directory.rglob("*.png")}
    if disk != paths:
        raise ValueError("Missing or unindexed PNGs")
    return {"album": manifest["atlas_id"], "verified": len(records),
            "categories": sorted({item["category"] for item in records}),
            "safe_for_reference_catalog": True}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: moonveil_album_audit.py album_directory")
    print(json.dumps(audit(sys.argv[1]), indent=2))
