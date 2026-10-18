"""Regression tests for the Moonveil image-button installer.

Uses synthetic PNG fixtures. Never touches actual Flutter assets or save files.
"""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from unittest.mock import patch

from scripts import install_moonveil_ui_buttons as installer

PNG = installer.PNG + b"synthetic-image"

class ImageButtonInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.flutter = self.root / "flutter_client"
        self.flutter.mkdir()
        (self.flutter / "pubspec.yaml").write_text("flutter:\n  assets:\n    - assets/images/\n")
        self.archive = self.root / "buttons.zip"
        self.entries = [
            {"path": f"navigation/button_{i:02}.png",
             "sha256": hashlib.sha256(PNG).hexdigest()}
            for i in range(32)
        ]
        self.write_zip()
        self.original_flutter, self.original_dest = installer.FLUTTER, installer.DEST
        installer.FLUTTER = self.flutter
        installer.DEST = self.flutter / "assets/images/moonveil_ui_buttons"
        self.addCleanup(self.restore)

    def restore(self):
        installer.FLUTTER, installer.DEST = self.original_flutter, self.original_dest

    def write_zip(self):
        with zipfile.ZipFile(self.archive, "w") as zf:
            zf.writestr("manifest.json", json.dumps({"count":32,"assets":self.entries}))
            for entry in self.entries:
                zf.writestr(entry["path"], PNG)

    def test_all_32_verified_and_registered(self):
        with patch.object(installer.subprocess, "run") as run:
            run.return_value.stdout = installer.BRANCH + "\n"
            installer.install(self.archive)
        self.assertEqual(len(list(installer.DEST.rglob("*.png"))), 32)
        self.assertIn("assets/images/moonveil_ui_buttons/",
                      (self.flutter / "pubspec.yaml").read_text())
        # Reinstalling identical images is safe.
        with patch.object(installer.subprocess, "run") as run:
            run.return_value.stdout = installer.BRANCH + "\n"
            installer.install(self.archive)

    def test_rejects_checksum_without_partial_install(self):
        self.entries[0]["sha256"] = "0" * 64
        self.write_zip()
        with patch.object(installer.subprocess, "run") as run:
            run.return_value.stdout = installer.BRANCH + "\n"
            with self.assertRaises(ValueError):
                installer.install(self.archive)
        self.assertFalse(installer.DEST.exists())

    def test_main_branch_refused(self):
        with patch.object(installer.subprocess, "run") as run:
            run.return_value.stdout = "main\n"
            with self.assertRaises(RuntimeError):
                installer.install(self.archive)
        self.assertFalse(installer.DEST.exists())

if __name__ == "__main__":
    unittest.main()
