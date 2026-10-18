#!/usr/bin/env python3
"""Moonveil art robot: safely verify, index and install numbered asset packs.

Commands:
 python scripts/moonveil_asset_robot_v6.py verify archive.zip
 python scripts/moonveil_asset_robot_v6.py search archive.zip dragon
 python scripts/moonveil_asset_robot_v6.py install archive.zip

No external AI calls, no save mutations, no main-branch installation.
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
FLUTTER = ROOT / "flutter_client"
BRANCH = "integration/copy-first-audit"
CATEGORIES = {"scenery", "dungeons", "battles", "monsters", "characters",
              "items", "spells", "maps", "dialogue", "rituals", "factions"}
PNG = b"\x89PNG\r\n\x1a\n"

def verify(archive):
    with zipfile.ZipFile(archive) as z:
        manifest = json.loads(z.read("manifest.json"))
        assets = manifest.get("assets")
        if (manifest.get("schema_version") != 1 or
            manifest.get("atlas_id") != "moonveil-v6" or
            manifest.get("count") != 100 or not isinstance(assets, list) or
            len(assets) != 100):
            raise ValueError("V6 manifest must contain 100 assets")
        seen_ids = set()
        files = {}
        for entry in assets:
            name = entry["path"]
            parts = Path(name).parts
            if (len(parts) != 2 or parts[0] not in CATEGORIES or
                not re.fullmatch(r"[A-Z]{2}-\d{3}\.png", parts[1]) or
                entry["id"] in seen_ids or name in files):
                raise ValueError("Unsafe or duplicate path/ID")
            blob = z.read(name)
            if len(blob) < 24 or not blob.startswith(PNG):
                raise ValueError("Invalid PNG: " + name)
            width, height = struct.unpack(">II", blob[16:24])
            if (width != entry["width"] or height != entry["height"] or
                hashlib.sha256(blob).hexdigest() != entry["sha256"]):
                raise ValueError("Checksum/dimension mismatch: " + name)
            seen_ids.add(entry["id"])
            files[name] = blob
        if set(z.namelist()) != set(files) | {"manifest.json"}:
            raise ValueError("Unexpected files in archive")
        return manifest, files

def install(archive):
    branch = subprocess.run(["git", "branch", "--show-current"],
        cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()
    if branch != BRANCH:
        raise RuntimeError("Installation allowed only on " + BRANCH)
    manifest, files = verify(archive)
    base = FLUTTER / "assets/images/moonveil_v6"
    index = FLUTTER / "assets/data/moonveil_v6_index.json"
    pubspec = FLUTTER / "pubspec.yaml"
    pubtext = pubspec.read_text(encoding="utf-8")
    if "  assets:" not in pubtext:
        raise ValueError("Flutter assets declaration missing")
    for name, blob in files.items():
        target = base / name
        if target.exists() and target.read_bytes() != blob:
            raise FileExistsError("Refusing to overwrite: " + str(target))
    if index.exists():
        old = json.loads(index.read_text(encoding="utf-8"))
        if old.get("atlas_id") != "moonveil-v6":
            raise FileExistsError("Conflicting asset index")
    for name, blob in files.items():
        target = base / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(blob)
    index.parent.mkdir(parents=True, exist_ok=True)
    manifest["assets"] = [
        {**asset, "flutter_asset": "assets/images/moonveil_v6/" + asset["path"]}
        for asset in manifest["assets"]]
    index.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    for category in sorted(CATEGORIES):
        line = "    - assets/images/moonveil_v6/" + category + "/"
        if line not in pubtext:
            pubtext = pubtext.rstrip() + "\n" + line + "\n"
    pubspec.write_text(pubtext, encoding="utf-8")
    print("Installed 100 verified assets. No campaign saves touched.")

def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("verify", "search", "install"):
        raise SystemExit("Usage: robot.py verify|search|install archive.zip [query]")
    command, archive = sys.argv[1:3]
    if command == "install":
        install(archive)
    else:
        manifest, _ = verify(archive)
        if command == "verify":
            print("Verified", manifest["count"], "assets")
        else:
            if len(sys.argv) < 4:
                raise SystemExit("Search requires a query")
            query = " ".join(sys.argv[3:]).lower()
            for asset in manifest["assets"]:
                if query in (asset["id"] + " " + asset["category"] + " " + asset["label"]).lower():
                    print(asset["id"], asset["path"], asset["label"])

if __name__ == "__main__":
    main()
