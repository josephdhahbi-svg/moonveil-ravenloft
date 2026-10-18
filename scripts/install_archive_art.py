#!/usr/bin/env python3
"""Verify and stage the seven Moonveil Archive PNGs from the supplied ZIP.

Usage from repository root:
  python scripts/install_archive_art.py /path/to/moonveil_archive_assets.zip
Never changes a campaign database. Refuses to overwrite existing art.
"""
import hashlib
import json
import pathlib
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
FLUTTER = ROOT / "flutter_client"
MANIFEST = FLUTTER / "assets" / "moonveil_archive_asset_manifest.json"
TARGETS = {
    "forgotten_archive_scene.png": "assets/images/backgrounds/forgotten_archive_scene.png",
    "netherese_guardian_portrait.png": "assets/images/creatures/netherese_guardian_portrait.png",
    "vesper_vane_portrait.png": "assets/images/portraits/vesper_vane.png",
    "archive_story_panel_1.png": "assets/images/panels/panel_1_threshold.png",
    "archive_story_panel_2.png": "assets/images/panels/panel_2_vaelthara.png",
    "archive_story_panel_3.png": "assets/images/panels/panel_3_relics.png",
    "archive_story_panel_4.png": "assets/images/panels/panel_4_fate.png",
}


def install(archive: pathlib.Path) -> None:
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["assets"]
    expected = {entry["file"]: entry for entry in entries}
    if set(expected) != set(TARGETS):
        raise ValueError("Archive asset manifest does not match seven required assets")
    staged = {}
    with zipfile.ZipFile(archive) as zf:
        for name, relative in TARGETS.items():
            data = zf.read(name)
            info = expected[name]
            if hashlib.sha256(data).hexdigest() != info["sha256"]:
                raise ValueError("SHA-256 mismatch: " + name)
            if not data.startswith(b"\\x89PNG\\r\\n\\x1a\\n"):
                raise ValueError("Invalid PNG signature: " + name)
            target = FLUTTER / relative
            if target.exists() and target.read_bytes() != data:
                raise FileExistsError("Existing artwork differs; refusing overwrite: " + str(target))
            staged[target] = data
    for target, data in staged.items():
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            target.write_bytes(data)
        print("Verified:", target.relative_to(ROOT))
    print("Seven images verified and staged. Commit only to the development branch.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: install_archive_art.py moonveil_archive_assets.zip")
    install(pathlib.Path(sys.argv[1]))
