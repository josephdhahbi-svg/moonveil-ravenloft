#!/usr/bin/env python3
"""Local Moonveil script library, strictly separate from campaign save files.

Commands:
  python scripts/moonveil_script_library.py list
  python scripts/moonveil_script_library.py add scene.json
  python scripts/moonveil_script_library.py export output.json
Stored under .moonveil_local/scripts/; no SQLite save access.
"""
import argparse
import json
from pathlib import Path
import re
import tempfile
import os

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / ".moonveil_local" / "scripts" / "storyboards.json"
ID = re.compile(r"^[a-z][a-z0-9_-]{2,63}$")
CHOICES = ["Lawful Good", "Neutral Good", "Chaotic Good", "Utility", "Action"]

def validate(scene):
    if not isinstance(scene, dict):
        raise ValueError("Scene must be an object")
    if not isinstance(scene.get("id"), str) or not ID.fullmatch(scene["id"]):
        raise ValueError("Scene id must be a safe slug")
    if scene.get("campaign") not in ("vesper", "alice"):
        raise ValueError("Explicit campaign partition required")
    panels = scene.get("panels")
    if not isinstance(panels, list) or len(panels) != 4:
        raise ValueError("Exactly four panels required")
    if scene.get("choices") != CHOICES:
        raise ValueError("Exactly five ordered choices required")
    for panel in panels:
        if not isinstance(panel, dict) or not all(
            isinstance(panel.get(k), str) for k in ("background", "speaker", "dialogue")
        ):
            raise ValueError("Panel requires background, speaker and dialogue")
        if len(panel["dialogue"]) > 4000:
            raise ValueError("Dialogue exceeds 4000 characters")
    return scene

def read_library(path=LIBRARY):
    if not path.exists():
        return {"schema_version": 1, "scenes": []}
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1 or not isinstance(data.get("scenes"), list):
        raise ValueError("Invalid script library")
    for scene in data["scenes"]:
        validate(scene)
    return data

def write_library(data, path=LIBRARY):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=".storyboards-", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)

def add(scene, path=LIBRARY):
    validate(scene)
    data = read_library(path)
    if any(s["id"] == scene["id"] and s["campaign"] == scene["campaign"]
           for s in data["scenes"]):
        raise ValueError("Scene already exists; refusing overwrite")
    data["scenes"].append(scene)
    write_library(data, path)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("list", "add", "export"))
    parser.add_argument("file", nargs="?")
    args = parser.parse_args()
    if args.command == "add":
        if not args.file: parser.error("add requires a scene JSON file")
        add(json.loads(Path(args.file).read_text(encoding="utf-8")))
    elif args.command == "list":
        for scene in read_library()["scenes"]:
            print(scene["campaign"], scene["id"])
    else:
        if not args.file: parser.error("export requires a destination")
        target = Path(args.file).resolve()
        if ROOT / ".moonveil_local" / "scripts" in target.parents:
            raise ValueError("Export outside script library to avoid overwriting it")
        target.write_text(json.dumps(read_library(), indent=2)+"\n", encoding="utf-8")

if __name__ == "__main__":
    main()
