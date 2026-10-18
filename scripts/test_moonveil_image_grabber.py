"""Tests for the Moonveil image grabber: real crops, checksum, and safety."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from PIL import Image
from moonveil_image_grabber import extract


class ImageGrabberTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source.png"
        Image.new("RGB", (100, 80), (40, 80, 120)).save(self.source)
        self.plan = self.root / "plan.json"
        self.output = self.root / "album"

    def write_plan(self, crops):
        self.plan.write_text(json.dumps({
            "album": "moonveil_v12",
            "crops": crops,
        }), encoding="utf-8")

    def test_extracts_individual_images_and_manifest(self):
        self.write_plan([
            {"id": "EY-011", "category": "eyes",
             "label": "Silver Eye", "box": [0, 0, 30, 40]},
            {"id": "HD-011", "category": "hands",
             "label": "Moon Hand", "box": [30, 20, 100, 80]},
        ])
        result = extract(self.source, self.plan, self.output)
        self.assertEqual(result["count"], 2)
        for item in result["assets"]:
            file = self.output / item["path"]
            self.assertTrue(file.is_file())
            self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(),
                             item["sha256"])
            self.assertFalse(item["owned"])
        self.assertEqual(Image.open(self.output / "eyes/EY-011.png").size,
                         (30, 40))

    def test_rejects_duplicate_ids_without_writing(self):
        self.write_plan([
            {"id": "EY-011", "category": "eyes",
             "label": "First", "box": [0, 0, 20, 20]},
            {"id": "EY-011", "category": "eyes",
             "label": "Second", "box": [20, 0, 40, 20]},
        ])
        with self.assertRaises(ValueError):
            extract(self.source, self.plan, self.output)
        self.assertFalse(self.output.exists())

    def test_rejects_out_of_bounds_crop(self):
        self.write_plan([
            {"id": "EY-012", "category": "eyes",
             "label": "Invalid", "box": [0, 0, 101, 80]},
        ])
        with self.assertRaises(ValueError):
            extract(self.source, self.plan, self.output)

    def test_refuses_existing_output(self):
        self.write_plan([
            {"id": "EY-011", "category": "eyes",
             "label": "Eye", "box": [0, 0, 20, 20]},
        ])
        self.output.mkdir()
        sentinel = self.output / "existing.txt"
        sentinel.write_text("keep")
        with self.assertRaises(FileExistsError):
            extract(self.source, self.plan, self.output)
        self.assertEqual(sentinel.read_text(), "keep")


if __name__ == "__main__":
    unittest.main()
