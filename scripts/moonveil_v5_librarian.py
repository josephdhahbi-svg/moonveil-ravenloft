#!/usr/bin/env python3
"""Moonveil V5 asset librarian: verify, install, index and search numbered art.

Usage:
 python scripts/moonveil_v5_librarian.py verify /path/to/moonveil_atlas_v5.zip
 python scripts/moonveil_v5_librarian.py install /path/to/moonveil_atlas_v5.zip
 python scripts/moonveil_v5_librarian.py search /path/to/moonveil_atlas_v5.zip dragon

Install requires integration/copy-first-audit, never writes campaign saves.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "flutter_client"
DEST = CLIENT / "assets/images/moonveil_v5"
INDEX = CLIENT / "assets/data/moonveil_v5_index.json"
BRANCH = "integration/copy-first-audit"
CATEGORIES = {"scenery", "dungeons", "monsters", "battles", "maps",
              "dialogue", "ui", "items", "spells", "rituals"}
PNG = b"\x89PNG\r\n\x1a\n"

def verified(archive):
    with zipfile.ZipFile(archive) as z:
        manifest = json.loads(z.read("manifest.json"))
        assets = manifest.get("assets")
        if (manifest.get("schema_version") != 1 or
            manifest.get("atlas_id") != "moonveil-v5" or
            not isinstance(assets, list) or
            manifest.get("count") != 81 or len(assets) != 81):
            raise ValueError("Invalid V5 manifest/count")
        data = {}
        ids = set()
        for asset in assets:
            name = asset["path"]
            parts = Path(name).parts
            if (len(parts) != 2 or parts[0] not in CATEGORIES or
                not re.fullmatch(r"[A-Z]{2}-\d{3}\.png", parts[1]) or
                name in data or asset["id"] in ids):
                raise ValueError("Unsafe or duplicate asset")
            payload = z.read(name)
            if len(payload) < 24 or payload[:8] != PNG:
                raise ValueError("Not a PNG: " + name)
            width, height = struct.unpack(">II", payload[16:24])
            if (width != asset["width"] or height != asset["height"] or
                hashlib.sha256(payload).hexdigest() != asset["sha256"]):
                raise ValueError("Image integrity mismatch: " + name)
            ids.add(asset["id"])
            data[name] = payload
        if set(z.namelist()) != set(data) | {"manifest.json"}:
            raise ValueError("Unexpected ZIP entries")
    return manifest, data

def install(archive):
    branch = subprocess.run(["git", "branch", "--show-current"], cwd=ROOT,
                            check=True, capture_output=True, text=True).stdout.strip()
    if branch != BRANCH:
        raise RuntimeError("Refusing to install outside development branch")
    manifest, payloads = verified(archive)
    pubspec = CLIENT / "pubspec.yaml"
    original = pubspec.read_text(encoding="utf-8")
    if "  assets:" not in original:
        raise ValueError("Missing Flutter assets section")
    if INDEX.exists():
        existing = json.loads(INDEX.read_text(encoding="utf-8"))
        if existing.get("atlas_id") != "moonveil-v5":
            raise ValueError("Conflicting registry; refusing overwrite")
    for name, data in payloads.items():
        path = DEST / name
        if path.exists() and path.read_bytes() != data:
            raise FileExistsError("Conflicting image: " + str(path))
    for name, data in payloads.items():
        path = DEST / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_bytes(data)
    INDEX.parent.mkdir(parents=True, exist_ok=True)
    manifest["assets"] = [
        {**item, "flutter_asset": "assets/images/moonveil_v5/" + item["path"]}
        for item in manifest["assets"]]
    INDEX.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    additions = "".join(
        "    - assets/images/moonveil_v5/" + category + "/\n"
        for category in sorted(CATEGORIES)
        if "    - assets/images/moonveil_v5/" + category + "/" not in original)
    if additions:
        pubspec.write_text(original.rstrip() + "\n" + additions, encoding="utf-8")
    print("Installed 81 V5 images and indexed them without touching saves.")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("command", choices=("verify", "install", "search"))
    p.add_argument("archive", type=Path)
    p.add_argument("query", nargs="?")
    args = p.parse_args()
    if args.command == "install":
        install(args.archive)
        return
    manifest, _ = verified(args.archive)
    if args.command == "verify":
        print(json.dumps({"valid": True, "count": manifest["count"]}))
    else:
        if not args.query: p.error("search requires a query")
        q = args.query.lower()
        for item in manifest["assets"]:
            if q in (item["id"] + " " + item["label"] + " " + item["category"]).lower():
                print(item["id"], item["label"], item["path"])

if __name__ == "__main__":
    main()
