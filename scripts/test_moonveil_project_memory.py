#!/usr/bin/env python3
"""Unit tests for Moonveil project memory. Run: python -m unittest scripts/test_moonveil_project_memory.py"""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from scripts import moonveil_project_memory as memory

class ProjectMemoryTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.db=Path(self.tmp.name)/"memory.db"

    def run_cli(self,*args):
        buf=io.StringIO()
        with patch("sys.argv",["memory","--db",str(self.db),*args]):
            with contextlib.redirect_stdout(buf):
                memory.main()
        return buf.getvalue()

    def test_sourced_fact_and_export(self):
        self.run_cli("remember","--key","checkpoint","--value","Link 2 Sector D",
                     "--source","approved checkpoint")
        found=json.loads(self.run_cli("find","checkpoint"))
        self.assertEqual(found[0]["value"],"Link 2 Sector D")
        self.assertEqual(found[0]["source"],"approved checkpoint")
        output=Path(self.tmp.name)/"export.json"
        self.run_cli("export","--output",str(output))
        self.assertEqual(json.loads(output.read_text())["facts"][0]["key"],"checkpoint")

    def test_dependency_blocks_until_completed(self):
        self.run_cli("task-add","--title","Verify image","--priority","1")
        self.run_cli("task-add","--title","Install image","--priority","1",
                     "--depends-on","1")
        ready=json.loads(self.run_cli("next"))
        self.assertEqual([x["title"] for x in ready],["Verify image"])
        self.run_cli("task-update","1","--status","done","--result","SHA verified")
        ready=json.loads(self.run_cli("next"))
        self.assertEqual([x["title"] for x in ready],["Install image"])

    def test_no_campaign_save_db_created(self):
        self.run_cli("init")
        self.assertEqual([p.name for p in Path(self.tmp.name).iterdir()],["memory.db"])

if __name__ == "__main__":
    unittest.main()
