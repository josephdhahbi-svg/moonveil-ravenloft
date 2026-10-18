#!/usr/bin/env python3
"""Moonveil visual library builder: verify, stage, index and plan 300 assets.

Standard-library only. Does not call an AI service, modify save databases,
deploy a site, or push Git branches. Run from repository checkout:
  python scripts/moonveil_art_robot.py verify /path/to/moonveil_comic_asset_library.zip
  python scripts/moonveil_art_robot.py install /path/to/moonveil_comic_asset_library.zip
  python scripts/moonveil_art_robot.py plan --output /tmp/moonveil_art_jobs.json
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FLUTTER = ROOT / "flutter_client"
DEST = FLUTTER / "assets" / "images" / "moonveil_comic"
INDEX = FLUTTER / "assets" / "data" / "moonveil_comic_index.json"
ALLOWED = ("story_panels/", "locations/", "tokens/")
PNG_MAGIC = bytes((137, 80, 78, 71, 13, 10, 26, 10))
BRANCH = "integration/copy-first-audit"


def require_branch():
    p = subprocess.run(["git", "branch", "--show-current"], cwd=ROOT,
                       capture_output=True, text=True, check=True)
    if p.stdout.strip() != BRANCH:
        raise RuntimeError("Refusing to install outside " + BRANCH)


def png_dimensions(data):
    if len(data) < 24 or data[:8] != PNG_MAGIC or data[12:16] != b"IHDR":
        raise ValueError("Invalid PNG header")
    w, h = struct.unpack(">II", data[16:24])
    if not (0 < w <= 16384 and 0 < h <= 16384):
        raise ValueError("Invalid PNG dimensions")
    return w, h


def validate(archive):
    staged = {}
    with zipfile.ZipFile(archive) as zf:
        names = zf.namelist()
        if "manifest.json" not in names:
            raise ValueError("Missing manifest.json")
        manifest = json.loads(zf.read("manifest.json"))
        entries = manifest.get("assets", [])
        if len(entries) != manifest.get("count") or len(entries) != 30:
            raise ValueError("Expected exactly 30 manifest assets")
        for item in entries:
            relative = item["path"]
            p = Path(relative)
            if (p.is_absolute() or ".." in p.parts or
                    not relative.startswith(ALLOWED) or p.suffix.lower() != ".png"):
                raise ValueError("Unsafe image path: " + relative)
            if relative in staged:
                raise ValueError("Duplicate image: " + relative)
            raw = zf.read(relative)
            if hashlib.sha256(raw).hexdigest() != item["sha256"]:
                raise ValueError("Checksum mismatch: " + relative)
            if list(png_dimensions(raw)) != [item["width"], item["height"]]:
                raise ValueError("Image dimensions mismatch: " + relative)
            staged[relative] = raw
        extras = set(names) - set(staged) - {"manifest.json"}
        if extras:
            raise ValueError("Unexpected archive entries: " + repr(sorted(extras)))
    return manifest, staged


def install(archive):
    require_branch()
    manifest, staged = validate(archive)
    for name, raw in staged.items():
        target = DEST / name
        if target.exists() and target.read_bytes() != raw:
            raise FileExistsError("Refusing to overwrite existing art: " + str(target))
    index = {
        "collection": manifest["collection"],
        "installed_count": len(staged),
        "assets": [
            {**entry, "flutter_asset": "assets/images/moonveil_comic/" + entry["path"]}
            for entry in manifest["assets"]
        ],
    }
    INDEX.parent.mkdir(parents=True, exist_ok=True)
    for name, raw in staged.items():
        target = DEST / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(raw)
    INDEX.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    pubspec = FLUTTER / "pubspec.yaml"
    pubtext = pubspec.read_text(encoding="utf-8")
    registrations = [
        "    - assets/images/moonveil_comic/story_panels/",
        "    - assets/images/moonveil_comic/locations/",
        "    - assets/images/moonveil_comic/tokens/",
    ]
    if "  assets:" not in pubtext:
        raise ValueError("Missing Flutter assets section in pubspec")
    missing = [line for line in registrations if line not in pubtext]
    if missing:
        pubspec.write_text(pubtext.rstrip() + "\\n" + "\\n".join(missing) + "\\n",
                           encoding="utf-8")
    print("Installed", len(staged), "verified PNGs and index:", INDEX)


def plan(output):
    """Queue missing image jobs. Human approval required before AI generation."""
    categories = {
        "characters": 65, "monsters": 65, "summons": 35,
        "locations": 45, "battle_maps": 35, "objects": 30, "story_panels": 25,
    }
    jobs = []
    for category, count in categories.items():
        for number in range(1, count + 1):
            jobs.append({
                "job_id": f"{category}-{number:03}",
                "category": category,
                "status": "not_generated",
                "style": "photorealistic cinematic dark fantasy",
                "requirements": [
                    "original individual image",
                    "separate map-ready token when subject is placeable",
                    "record transparent alpha and grid footprint for tokens",
                    "verify checksum, dimensions, identity, and scene continuity",
                    "human review before marking ready",
                ],
                "prompt": None,
                "source_file": None,
                "approved": False,
            })
    assert len(jobs) == 300
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({"target": 300, "jobs": jobs}, indent=2) + "\n")
    print("Wrote 300 ungenerated jobs:", output)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["verify", "install", "plan"])
    parser.add_argument("archive", nargs="?", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "art" / "production_queue.json")
    args = parser.parse_args()
    if args.action == "plan":
        plan(args.output)
    else:
        if args.archive is None:
            parser.error("verify/install requires an archive path")
        manifest, staged = validate(args.archive)
        print("Verified", len(staged), "PNG assets:", manifest["collection"])
        if args.action == "install":
            install(args.archive)


if __name__ == "__main__":
    main()
