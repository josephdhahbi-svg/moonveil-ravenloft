import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from scripts import install_moonveil_v4 as mod

PNG = mod.PNG + b"\0" * 8 + (16).to_bytes(4, "big") + (16).to_bytes(4, "big") + b"fixture"

class V4InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.flutter = self.root / "flutter_client"
        self.flutter.mkdir()
        (self.flutter / "pubspec.yaml").write_text("flutter:\n  assets:\n")
        self.archive = self.root / "v4.zip"
        self.entries = [
            {"path": f"items/asset_{i:03}.png",
             "width": 16, "height": 16,
             "sha256": hashlib.sha256(PNG).hexdigest()}
            for i in range(97)
        ]
        self.saved = (mod.FLUTTER, mod.DEST, mod.INDEX)
        mod.FLUTTER = self.flutter
        mod.DEST = self.flutter / "assets/images/moonveil_v4"
        mod.INDEX = self.flutter / "assets/data/moonveil_v4_index.json"
        self.addCleanup(self.restore)
        self.write_archive()

    def restore(self):
        mod.FLUTTER, mod.DEST, mod.INDEX = self.saved

    def write_archive(self):
        with zipfile.ZipFile(self.archive, "w") as z:
            z.writestr("manifest.json", json.dumps({
                "schema_version": 1, "count": 97, "assets": self.entries}))
            for e in self.entries:
                z.writestr(e["path"], PNG)

    def test_installs_and_reinstalls_identically(self):
        with patch.object(mod.subprocess, "run") as run:
            run.return_value.stdout = mod.BRANCH + "\n"
            mod.install(self.archive)
            mod.install(self.archive)
        self.assertEqual(len(list(mod.DEST.rglob("*.png"))), 97)
        self.assertEqual(len(json.loads(mod.INDEX.read_text())["assets"]), 97)

    def test_rejects_corrupted_checksum_without_installing(self):
        self.entries[0]["sha256"] = "f" * 64
        self.write_archive()
        with patch.object(mod.subprocess, "run") as run:
            run.return_value.stdout = mod.BRANCH + "\n"
            with self.assertRaises(ValueError):
                mod.install(self.archive)
        self.assertFalse(mod.DEST.exists())

    def test_refuses_main_branch(self):
        with patch.object(mod.subprocess, "run") as run:
            run.return_value.stdout = "main\n"
            with self.assertRaises(RuntimeError):
                mod.install(self.archive)
        self.assertFalse(mod.DEST.exists())

if __name__ == "__main__":
    unittest.main()
