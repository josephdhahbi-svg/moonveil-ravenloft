#!/usr/bin/env python3
"""Install 32 checksum-verified Moonveil image buttons on development branch only.

Usage: python scripts/install_moonveil_ui_buttons.py path/to/moonveil_ui_image_buttons.zip
Does not access campaign saves or deploy a site.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FLUTTER = ROOT / "flutter_client"
DEST = FLUTTER / "assets/images/moonveil_ui_buttons"
BRANCH = "integration/copy-first-audit"
PNG = bytes([137,80,78,71,13,10,26,10])

def install(archive):
    current = subprocess.run(["git","branch","--show-current"],cwd=ROOT,
                             capture_output=True,text=True,check=True).stdout.strip()
    if current != BRANCH:
        raise RuntimeError("Refusing to install outside development branch")
    staged = {}
    with zipfile.ZipFile(archive) as zf:
        manifest = json.loads(zf.read("manifest.json"))
        entries = manifest["assets"]
        if manifest["count"] != 32 or len(entries) != 32:
            raise ValueError("Expected 32 image assets")
        for entry in entries:
            name = entry["path"]
            path = Path(name)
            if (path.is_absolute() or ".." in path.parts or
                path.parts[0] not in {"navigation","actions","party","scenes","portraits"} or
                path.suffix != ".png" or name in staged):
                raise ValueError("Invalid asset path: " + name)
            data = zf.read(name)
            if not data.startswith(PNG):
                raise ValueError("Invalid PNG: " + name)
            if hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise ValueError("Checksum mismatch: " + name)
            staged[name] = data
        if set(zf.namelist()) != set(staged) | {"manifest.json"}:
            raise ValueError("Unexpected archive entries")
    pubspec = FLUTTER / "pubspec.yaml"
    original = pubspec.read_text(encoding="utf-8")
    if "  assets:" not in original:
        raise ValueError("Flutter asset registration missing")
    for name, data in staged.items():
        target = DEST / name
        if target.exists() and target.read_bytes() != data:
            raise FileExistsError("Refusing to overwrite: " + str(target))
    for name, data in staged.items():
        target = DEST / name
        target.parent.mkdir(parents=True,exist_ok=True)
        if not target.exists():
            target.write_bytes(data)
    registration = "    - assets/images/moonveil_ui_buttons/"
    if registration not in original:
        pubspec.write_text(original.rstrip() + "\n" + registration + "\n",encoding="utf-8")
    print("Installed 32 image-button assets. Commit only to:", BRANCH)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: install_moonveil_ui_buttons.py archive.zip")
    install(Path(sys.argv[1]))
