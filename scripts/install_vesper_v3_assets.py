#!/usr/bin/env python3
"""Install Moonveil Vesper V3 artwork without touching saves or main.

Usage: python scripts/install_vesper_v3_assets.py /path/to/moonveil_vesper_asset_library_v3.zip
Requires checkout of integration/copy-first-audit. Verifies manifest hashes,
image signatures and dimensions, refuses differing overwrites, registers Flutter
asset directory, and writes an asset index.
"""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[1]
FLUTTER=ROOT/"flutter_client"
DEST=FLUTTER/"assets/images/vesper_v3"
INDEX=FLUTTER/"assets/data/vesper_v3_index.json"
BRANCH="integration/copy-first-audit"
PNG=b"\x89PNG\r\n\x1a\n"
CATEGORIES={"portraits","tokens","expressions","items","abilities","navigation","actions"}

def install(archive):
    branch=subprocess.run(["git","branch","--show-current"],cwd=ROOT,
                          text=True,capture_output=True,check=True).stdout.strip()
    if branch!=BRANCH:
        raise RuntimeError("Only permitted on "+BRANCH)
    staged={}
    with zipfile.ZipFile(archive) as z:
        m=json.loads(z.read("manifest.json"))
        entries=m["assets"]
        if m["schema_version"]!=1 or m["count"]!=54 or len(entries)!=54:
            raise ValueError("Expected 54 V3 assets")
        for entry in entries:
            path=Path(entry["path"])
            if (path.is_absolute() or ".." in path.parts or len(path.parts)!=2
                    or path.parts[0] not in CATEGORIES or path.suffix!=".png"
                    or entry["path"] in staged):
                raise ValueError("Unsafe or duplicate asset path")
            data=z.read(entry["path"])
            if not data.startswith(PNG) or len(data)<24:
                raise ValueError("Invalid PNG")
            w,h=struct.unpack(">II",data[16:24])
            if [w,h]!=[entry["width"],entry["height"]]:
                raise ValueError("PNG dimensions mismatch")
            if hashlib.sha256(data).hexdigest()!=entry["sha256"]:
                raise ValueError("PNG checksum mismatch")
            staged[entry["path"]]=data
        if set(z.namelist())!=set(staged)|{"manifest.json"}:
            raise ValueError("Unexpected archive entries")
    pubspec=FLUTTER/"pubspec.yaml"
    old=pubspec.read_text(encoding="utf-8")
    if "  assets:" not in old:
        raise ValueError("Missing Flutter assets section")
    for name,data in staged.items():
        target=DEST/name
        if target.exists() and target.read_bytes()!=data:
            raise FileExistsError("Conflicting image: "+str(target))
    for name,data in staged.items():
        target=DEST/name
        target.parent.mkdir(parents=True,exist_ok=True)
        if not target.exists():
            target.write_bytes(data)
    INDEX.parent.mkdir(parents=True,exist_ok=True)
    index={"schema_version":1,"source":"verified 54-asset V3 archive",
           "assets":[{**e,"flutter_asset":"assets/images/vesper_v3/"+e["path"]}
                     for e in entries]}
    INDEX.write_text(json.dumps(index,indent=2)+"\n",encoding="utf-8")
    registration="    - assets/images/vesper_v3/"
    if registration not in old:
        pubspec.write_text(old.rstrip()+"\n"+registration+"\n",encoding="utf-8")
    print("Installed 54 Vesper assets; game saves untouched")

if __name__=="__main__":
    if len(sys.argv)!=2:
        raise SystemExit("Usage: install_vesper_v3_assets.py archive.zip")
    install(Path(sys.argv[1]))
