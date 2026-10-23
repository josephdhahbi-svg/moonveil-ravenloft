"""Regression tests for the V11 ZIP installer and shipped archive structure."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

from install_moonveil_v11 import CATEGORIES, verify


class V11InstallerTests(unittest.TestCase):
    def test_readme_and_all_albums_are_accepted(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "album.zip"
            records = []
            with zipfile.ZipFile(path, "w") as archive:
                for category in CATEGORIES:
                    for n in range(10):
                        ident = f"{category[:2].upper()}-{n+1:03d}"
                        name = f"{category}/{ident}.png"
                        blob = b"\x89PNG\r\n\x1a\n" + b"\x00\x00\x00\x0dIHDR" + struct.pack(">II", 2, 3) + b"\x08\x06\x00\x00\x00"
                        archive.writestr(name, blob)
                        records.append({"id": ident, "category": category,
                                        "path": name, "width": 2, "height": 3,
                                        "sha256": hashlib.sha256(blob).hexdigest()})
                archive.writestr("README.md", "Album documentation")
                archive.writestr("manifest.json", json.dumps({
                    "atlas_id": "moonveil-item-albums-v11",
                    "schema_version": 1, "count": 120, "assets": records,
                }))
            manifest, images = verify(path)
            self.assertEqual(manifest["count"], 120)
            self.assertEqual(len(images), 120)

    def test_rejects_missing_category(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "album.zip"
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("manifest.json", json.dumps({
                    "atlas_id": "moonveil-item-albums-v11",
                    "schema_version": 1, "count": 120, "assets": [],
                }))
            with self.assertRaises(ValueError):
                verify(path)


if __name__ == "__main__":
    unittest.main()
