#!/usr/bin/env python3
"""Verify and install Moonveil ritual V9 atlas on development branch only.

python scripts/install_moonveil_ritual_v9.py /path/to/moonveil_ritual_v9.zip
"""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "flutter_client"
DEST = CLIENT / "assets/images/moonveil_ritual_v9"
INDEX = CLIENT / "assets/data/moonveil_ritual_v9_index.json"
CATEGORIES = {"sites","circles","components","books","items","spells",
              "scrolls","process","tokens","spell_tokens","maps","bubbles"}
PREFIXES = {"sites":"RS","circles":"RC","components":"RI","books":"BK",
            "items":"IT","spells":"SP","scrolls":"SC","process":"ST",
            "tokens":"TK","spell_tokens":"TS","maps":"MP","bubbles":"DB"}

def verify(path):
    with zipfile.ZipFile(path) as archive:
        manifest = json.loads(archive.read("manifest.json"))
        assets = manifest.get("assets")
        if (manifest.get("atlas_id") != "moonveil-ritual-v9" or
            manifest.get("schema_version") != 1 or
            manifest.get("count") != 137 or not isinstance(assets,list)
            or len(assets) != 137):
            raise ValueError("Invalid V9 manifest")
        files = {}
        ids = set()
        for entry in assets:
            name = entry["path"]
            parts = Path(name).parts
            if (len(parts) != 2 or parts[0] not in CATEGORIES or
                not parts[1].startswith(PREFIXES[parts[0]]+"-") or
                not parts[1].endswith(".png") or
                entry["id"] != parts[1][:-4] or entry["id"] in ids or
                name in files):
                raise ValueError("Unsafe/duplicate asset name")
            data = archive.read(name)
            if len(data)<24 or not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Invalid PNG")
            width,height = struct.unpack(">II",data[16:24])
            if (width != entry["width"] or height != entry["height"] or
                hashlib.sha256(data).hexdigest() != entry["sha256"]):
                raise ValueError("Asset integrity mismatch")
            ids.add(entry["id"])
            files[name] = data
        if set(archive.namelist()) != set(files) | {"manifest.json"}:
            raise ValueError("Unexpected ZIP contents")
    return manifest,files

def install(path):
    branch = subprocess.run(["git","branch","--show-current"],cwd=ROOT,
        check=True,capture_output=True,text=True).stdout.strip()
    if branch != "integration/copy-first-audit":
        raise RuntimeError("Refusing to install outside development branch")
    manifest,files = verify(path)
    pubspec = CLIENT / "pubspec.yaml"
    text = pubspec.read_text(encoding="utf-8")
    if "  assets:" not in text:
        raise ValueError("Flutter assets section missing")
    for name,data in files.items():
        target = DEST / name
        if target.exists() and target.read_bytes() != data:
            raise FileExistsError("Refusing image overwrite")
    if INDEX.exists():
        old = json.loads(INDEX.read_text(encoding="utf-8"))
        if old.get("atlas_id") != "moonveil-ritual-v9":
            raise FileExistsError("Conflicting index")
    for name,data in files.items():
        target = DEST / name
        target.parent.mkdir(parents=True,exist_ok=True)
        if not target.exists(): target.write_bytes(data)
    INDEX.parent.mkdir(parents=True,exist_ok=True)
    manifest["assets"] = [{**a,"flutter_asset":
        "assets/images/moonveil_ritual_v9/"+a["path"]}
        for a in manifest["assets"]]
    INDEX.write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    for category in sorted(CATEGORIES):
        line = "    - assets/images/moonveil_ritual_v9/"+category+"/"
        if line not in text: text = text.rstrip()+"\n"+line+"\n"
    pubspec.write_text(text,encoding="utf-8")
    print("137 verified images installed. Campaign saves untouched.")

if __name__ == "__main__":
    if len(sys.argv)!=2: raise SystemExit("Usage: installer archive.zip")
    install(Path(sys.argv[1]))
