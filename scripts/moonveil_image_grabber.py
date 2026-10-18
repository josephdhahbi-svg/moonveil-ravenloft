#!/usr/bin/env python3
"""Moonveil Art Robot: extract independently named PNGs from an image.

A human-reviewed JSON crop plan is required. No guessed labels or items.
Usage: python scripts/moonveil_image_grabber.py source.png crops.json output_dir

Plan format:
{"album":"moonveil-v12","crops":[
 {"id":"EY-011","category":"eyes","label":"Moonstone Eye",
  "box":[10,20,150,170]}
]}
Requires Pillow. Does not alter game saves or existing assets.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

from PIL import Image

SAFE = re.compile(r"^[a-z][a-z0-9_]*$")
ID = re.compile(r"^[A-Z]{2}-[0-9]{3}$")

def extract(source, plan_file, destination):
    source = Path(source)
    destination = Path(destination)
    plan = json.loads(Path(plan_file).read_text(encoding="utf-8"))
    album = plan.get("album")
    crops = plan.get("crops")
    if not isinstance(album, str) or not SAFE.fullmatch(album):
        raise ValueError("Unsafe album name")
    if not isinstance(crops, list) or not crops:
        raise ValueError("Missing crop definitions")
    if destination.exists() and any(destination.iterdir()):
        raise FileExistsError("Output directory must be empty")
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    seen = set()
    validated = []
    for entry in crops:
        ident, category, label = entry["id"], entry["category"], entry["label"]
        box = entry["box"]
        if (not isinstance(ident, str) or not ID.fullmatch(ident) or
            not isinstance(category, str) or not SAFE.fullmatch(category) or
            not isinstance(label, str) or not label.strip() or
            ident in seen or not isinstance(box, list) or len(box) != 4 or
            not all(type(n) is int for n in box)):
            raise ValueError("Invalid crop metadata")
        left, top, right, bottom = box
        if not (0 <= left < right <= width and 0 <= top < bottom <= height):
            raise ValueError("Crop outside source image")
        seen.add(ident)
        validated.append((ident, category, label, tuple(box)))
    destination.mkdir(parents=True, exist_ok=True)
    entries = []
    for ident, category, label, box in validated:
        relative = f"{category}/{ident}.png"
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        image.crop(box).save(target, format="PNG")
        blob = target.read_bytes()
        entries.append({
            "id": ident, "category": category, "label": label,
            "path": relative, "width": box[2]-box[0],
            "height": box[3]-box[1],
            "sha256": hashlib.sha256(blob).hexdigest(),
            "status": "art_reference", "owned": False,
            "source_box": list(box),
        })
    manifest = {
        "schema_version": 1, "atlas_id": album,
        "count": len(entries), "source": source.name, "assets": entries,
    }
    (destination / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest

if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: moonveil_image_grabber.py source.png crops.json output_dir")
    print(json.dumps({"count": extract(*sys.argv[1:])["count"]}))
