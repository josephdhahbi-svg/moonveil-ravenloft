import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from scripts import moonveil_asset_robot_v6 as robot

PNG = robot.PNG + b"\0" * 8 + (24).to_bytes(4, "big") + (24).to_bytes(4, "big") + b"fixture"

class AssetRobotTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.flutter = self.root / "flutter_client"
        self.flutter.mkdir()
        (self.flutter / "pubspec.yaml").write_text("flutter:\n  assets:\n")
        self.previous = robot.FLUTTER
        robot.FLUTTER = self.flutter
        self.addCleanup(lambda: setattr(robot, "FLUTTER", self.previous))
        self.archive = self.root / "atlas.zip"
        self.assets = [
            {"id": f"SB-{i:03d}", "category": "scenery",
             "label": f"Scenery {i}", "path": f"scenery/SB-{i:03d}.png",
             "width": 24, "height": 24,
             "sha256": hashlib.sha256(PNG).hexdigest()}
            for i in range(1, 101)
        ]
        self.make_zip()

    def make_zip(self):
        with zipfile.ZipFile(self.archive, "w") as z:
            z.writestr("manifest.json", json.dumps({
                "schema_version": 1, "atlas_id": "moonveil-v6",
                "count": 100, "assets": self.assets}))
            for item in self.assets:
                z.writestr(item["path"], PNG)

    def test_verify_and_safe_install(self):
        manifest, files = robot.verify(self.archive)
        self.assertEqual(len(files), 100)
        with patch.object(robot.subprocess, "run") as run:
            run.return_value.stdout = robot.BRANCH
            robot.install(self.archive)
            robot.install(self.archive)
        self.assertEqual(len(list((self.flutter / "assets/images/moonveil_v6")
                                   .rglob("*.png"))), 100)

    def test_corruption_rejected_before_writes(self):
        self.assets[0]["sha256"] = "0" * 64
        self.make_zip()
        with patch.object(robot.subprocess, "run") as run:
            run.return_value.stdout = robot.BRANCH
            with self.assertRaises(ValueError):
                robot.install(self.archive)
        self.assertFalse((self.flutter / "assets/images/moonveil_v6").exists())

    def test_main_branch_refused(self):
        with patch.object(robot.subprocess, "run") as run:
            run.return_value.stdout = "main"
            with self.assertRaises(RuntimeError):
                robot.install(self.archive)

if __name__ == "__main__":
    unittest.main()
