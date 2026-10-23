#!/usr/bin/env python3
"""Tests that reviewed context seeds idempotently without changing game saves."""
import json
from pathlib import Path
import tempfile
import unittest
from scripts.moonveil_project_memory import connect
from scripts.seed_moonveil_project_memory import seed, SOURCE

class SeedTests(unittest.TestCase):
    def test_seed_twice_keeps_single_tasks_and_checkpoint(self):
        with tempfile.TemporaryDirectory() as tmp:
            db_path=Path(tmp)/"memory.sqlite3"
            seed(db_path,SOURCE)
            seed(db_path,SOURCE)
            with connect(db_path) as db:
                facts=dict(db.execute("SELECT key,value FROM facts").fetchall())
                tasks=db.execute("SELECT title FROM tasks").fetchall()
            approved=json.loads(SOURCE.read_text(encoding="utf-8"))
            self.assertEqual(json.loads(facts["campaign.hp"]),10)
            self.assertEqual(json.loads(facts["campaign.checkpoint"]),
                             approved["campaign"]["checkpoint"])
            self.assertEqual(len(tasks),len(approved["tasks"]))
            self.assertFalse((Path(tmp)/"vesper_save.db").exists())
            self.assertFalse((Path(tmp)/"alice_save.db").exists())

if __name__ == "__main__":
    unittest.main()
