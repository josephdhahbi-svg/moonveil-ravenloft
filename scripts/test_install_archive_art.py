"""Offline safety tests for the seven-image Archive installer."""
import hashlib
import importlib.util
import json
import pathlib
import tempfile
import unittest
import zipfile

SCRIPT = pathlib.Path(__file__).with_name("install_archive_art.py")
spec = importlib.util.spec_from_file_location("archive_installer", SCRIPT)
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)
PNG = bytes([137, 80, 78, 71, 13, 10, 26, 10]) + b"test-fixture"


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        self.flutter = self.root / "flutter_client"
        self.manifest = self.flutter / "assets" / "moonveil_archive_asset_manifest.json"
        self.manifest.parent.mkdir(parents=True)
        self.archive = self.root / "archive.zip"
        self.names = list(installer.TARGETS)
        self.entries = [
            {"file": name, "sha256": hashlib.sha256(PNG + name.encode()).hexdigest()}
            for name in self.names
        ]
        self.manifest.write_text(json.dumps({"assets": self.entries}), encoding="utf-8")
        with zipfile.ZipFile(self.archive, "w") as zf:
            for name in self.names:
                zf.writestr(name, PNG + name.encode())
        self.old_flutter, self.old_manifest = installer.FLUTTER, installer.MANIFEST
        installer.FLUTTER, installer.MANIFEST = self.flutter, self.manifest
        self.addCleanup(self.restore)

    def restore(self):
        installer.FLUTTER, installer.MANIFEST = self.old_flutter, self.old_manifest

    def test_valid_archive_installs_all_seven(self):
        installer.install(self.archive)
        for name, relative in installer.TARGETS.items():
            self.assertEqual((self.flutter / relative).read_bytes(), PNG + name.encode())

    def test_checksum_mismatch_writes_nothing(self):
        self.entries[0]["sha256"] = "0" * 64
        self.manifest.write_text(json.dumps({"assets": self.entries}), encoding="utf-8")
        with self.assertRaises(ValueError):
            installer.install(self.archive)
        self.assertFalse((self.flutter / next(iter(installer.TARGETS.values()))).exists())

    def test_existing_different_art_is_never_overwritten(self):
        target = self.flutter / next(iter(installer.TARGETS.values()))
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b"protected original")
        with self.assertRaises(FileExistsError):
            installer.install(self.archive)
        self.assertEqual(target.read_bytes(), b"protected original")


if __name__ == "__main__":
    unittest.main()
