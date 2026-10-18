#!/usr/bin/env python3
"""Install verified V11 albums locally on the development branch.

Usage: python scripts/install_moonveil_v11.py /path/to/moonveil_item_albums_v11.zip
Never writes or opens campaign save databases.
"""
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "flutter_client"
BASE = CLIENT / "assets/images/moonveil_item_albums_v11"
INDEX = CLIENT / "assets/data/moonveil_item_albums_v11_index.json"
CATEGORIES = ("eyes", "hands", "longswords", "staffs", "cloaks", "gems",
              "spells", "focuses", "books", "scrolls", "cards", "miscellaneous")
PNG = b"\x89PNG\r\n\x1a\n"

def verify(archive_path):
    with zipfile.ZipFile(archive_path) as archive:
        manifest = json.loads(archive.read("manifest.json"))
        records = manifest.get("assets")
        if (manifest.get("atlas_id") != "moonveil-item-albums-v11"
            or manifest.get("schema_version") != 1
            or manifest.get("count") != 120
            or not isinstance(records, list) or len(records) != 120):
            raise ValueError("Invalid V11 manifest")
        blobs = {}
        ids = set()
        for item in records:
            category, sep, filename = item["path"].partition("/")
            if (not sep or category not in CATEGORIES or
                not re.fullmatch(r"[A-Z]{2}-[0-9]{3}\.png", filename) or
                item["id"] != filename[:-4] or item["category"] != category or
                item["id"] in ids):
                raise ValueError("Unsafe or duplicate image ID")
            blob = archive.read(item["path"])
            if len(blob) < 24 or not blob.startswith(PNG):
                raise ValueError("Invalid PNG")
            width, height = struct.unpack(">II", blob[16:24])
            if (width != item["width"] or height != item["height"] or
                hashlib.sha256(blob).hexdigest() != item["sha256"]):
                raise ValueError("Image integrity mismatch")
            ids.add(item["id"])
            blobs[item["path"]] = blob
        if set(archive.namelist()) != set(blobs) | {"manifest.json"}:
            raise ValueError("Unexpected ZIP contents")
    return manifest, blobs

def install(archive_path):
    branch = subprocess.run(["git", "branch", "--show-current"], cwd=ROOT,
                            capture_output=True, text=True, check=True).stdout.strip()
    if branch != "integration/copy-first-audit":
        raise RuntimeError("Refusing to install on main or other branches")
    manifest, blobs = verify(archive_path)
    pubspec = CLIENT / "pubspec.yaml"
    pubtext = pubspec.read_text(encoding="utf-8")
    if "  assets:" not in pubtext:
        raise ValueError("Flutter assets section missing")
    for name, blob in blobs.items():
        target = BASE / name
        if target.exists() and target.read_bytes() != blob:
            raise FileExistsError("Refusing overwrite: " + str(target))
    if INDEX.exists() and json.loads(INDEX.read_text()).get("atlas_id") != manifest["atlas_id"]:
        raise FileExistsError("Conflicting V11 index")
    for name, blob in blobs.items():
        target = BASE / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(blob)
    INDEX.parent.mkdir(parents=True, exist_ok=True)
    INDEX.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for category in CATEGORIES:
        line = f"    - assets/images/moonveil_item_albums_v11/{category}/"
        if line not in pubtext:
            pubtext = pubtext.rstrip() + "\n" + line + "\n"
    pubspec.write_text(pubtext, encoding="utf-8")
    print("Installed 120 verified images; no saves modified.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: install_moonveil_v11.py archive.zip")
    install(Path(sys.argv[1]))
