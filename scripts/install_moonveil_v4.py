#!/usr/bin/env python3
"""Install Moonveil V4 visual atlas after verifying all 97 PNGs.

Never modifies campaign saves. Refuses to run outside integration branch.
Usage: python scripts/install_moonveil_v4.py /path/to/moonveil_ui_atlas_v4.zip
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
DEST=FLUTTER/"assets/images/moonveil_v4"
INDEX=FLUTTER/"assets/data/moonveil_v4_index.json"
BRANCH="integration/copy-first-audit"
CATEGORIES={"navigation","portraits","tokens","items","abilities","locations","story","actions","rituals","party","summons","factions"}
PNG=b"\x89PNG\r\n\x1a\n"

def install(archive):
    branch=subprocess.run(["git","branch","--show-current"],cwd=ROOT,
        text=True,capture_output=True,check=True).stdout.strip()
    if branch!=BRANCH:
        raise RuntimeError("Refusing to install outside "+BRANCH)
    staged={}
    with zipfile.ZipFile(archive) as z:
        manifest=json.loads(z.read("manifest.json"))
        entries=manifest["assets"]
        if manifest["schema_version"]!=1 or manifest["count"]!=97 or len(entries)!=97:
            raise ValueError("Expected 97 V4 images")
        for entry in entries:
            name=entry["path"]
            path=Path(name)
            if (path.is_absolute() or ".." in path.parts or len(path.parts)!=2
                or path.parts[0] not in CATEGORIES or path.suffix!=".png"
                or name in staged):
                raise ValueError("Unsafe or duplicate asset path")
            data=z.read(name)
            if len(data)<24 or not data.startswith(PNG):
                raise ValueError("Invalid PNG")
            width,height=struct.unpack(">II",data[16:24])
            if [width,height]!=[entry["width"],entry["height"]]:
                raise ValueError("Image dimensions mismatch")
            if hashlib.sha256(data).hexdigest()!=entry["sha256"]:
                raise ValueError("Checksum mismatch")
            staged[name]=data
        if set(z.namelist())!=set(staged)|{"manifest.json"}:
            raise ValueError("Unexpected archive entries")
    pubspec=FLUTTER/"pubspec.yaml"
    text=pubspec.read_text(encoding="utf-8")
    if "  assets:" not in text:
        raise ValueError("Flutter assets section missing")
    for name,data in staged.items():
        dest=DEST/name
        if dest.exists() and dest.read_bytes()!=data:
            raise FileExistsError("Refusing conflicting overwrite: "+str(dest))
    for name,data in staged.items():
        dest=DEST/name
        dest.parent.mkdir(parents=True,exist_ok=True)
        if not dest.exists(): dest.write_bytes(data)
    INDEX.parent.mkdir(parents=True,exist_ok=True)
    INDEX.write_text(json.dumps({"schema_version":1,"assets":[
        {**entry,"flutter_asset":"assets/images/moonveil_v4/"+entry["path"]}
        for entry in entries]},indent=2)+"\n",encoding="utf-8")
    for category in sorted(CATEGORIES):
        registration="    - assets/images/moonveil_v4/"+category+"/"
        if registration not in text:
            text=text.rstrip()+"\n"+registration+"\n"
    pubspec.write_text(text,encoding="utf-8")
    print("Installed 97 verified V4 images, with Flutter index. No saves touched.")

if __name__=="__main__":
    if len(sys.argv)!=2:
        raise SystemExit("Usage: install_moonveil_v4.py archive.zip")
    install(Path(sys.argv[1]))
