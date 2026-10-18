import json
from pathlib import Path
import tempfile
import unittest

from scripts.moonveil_script_library import add, read_library, validate, CHOICES

def scene(name="archive", campaign="vesper"):
    return {
        "id": name,
        "campaign": campaign,
        "panels": [
            {"background": "assets/images/moonveil_v4/locations/ruins.png",
             "speaker": "Vesper Vane", "dialogue": "The archive awaits."}
            for _ in range(4)
        ],
        "choices": CHOICES.copy(),
    }

class ScriptLibraryTests(unittest.TestCase):
    def test_roundtrip_and_partition(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "scripts.json"
            add(scene(), path)
            add(scene(campaign="alice"), path)
            data = read_library(path)
            self.assertEqual(len(data["scenes"]), 2)
            self.assertEqual({s["campaign"] for s in data["scenes"]},
                             {"vesper", "alice"})

    def test_duplicate_is_rejected_without_overwrite(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "scripts.json"
            add(scene(), path)
            before = path.read_bytes()
            with self.assertRaises(ValueError):
                add(scene(), path)
            self.assertEqual(path.read_bytes(), before)

    def test_invalid_choices_and_panel_count(self):
        bad = scene()
        bad["panels"] = bad["panels"][:3]
        with self.assertRaises(ValueError):
            validate(bad)
        bad = scene()
        bad["choices"] = list(reversed(CHOICES))
        with self.assertRaises(ValueError):
            validate(bad)

if __name__ == "__main__":
    unittest.main()
