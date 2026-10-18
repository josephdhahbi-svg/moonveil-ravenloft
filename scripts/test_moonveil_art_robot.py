#!/usr/bin/env python3
"""Safe tests for Moonveil's 30-image robot; never modifies real Flutter assets."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile
from unittest.mock import patch
from scripts import moonveil_art_robot as robot

PNG = robot.PNG_MAGIC + b"\x00\x00\x00\x0dIHDR" + struct.pack(">II", 2, 2) + b"\x08\x06\x00\x00\x00"

class RobotTests(unittest.TestCase):
    def test_archive_verification_and_rejected_checksum(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / "art.zip"
            data = PNG
            entry = {"path":"tokens/vesper.png","sha256":hashlib.sha256(data).hexdigest(),
                     "width":2,"height":2}
            # A 30-image test fixture uses distinct paths and verifies all entries.
            entries=[dict(entry,path=f"tokens/token_{i:02}.png") for i in range(30)]
            manifest={"collection":"test-fixture","count":30,"assets":entries}
            with zipfile.ZipFile(archive,"w") as z:
                z.writestr("manifest.json",json.dumps(manifest))
                for e in entries:
                    z.writestr(e["path"],data)
            parsed, staged=robot.validate(archive)
            self.assertEqual(len(staged),30)
            entries[0]["sha256"]="0"*64
            with zipfile.ZipFile(archive,"w") as z:
                z.writestr("manifest.json",json.dumps(manifest))
                for e in entries:
                    z.writestr(e["path"],data)
            with self.assertRaises(ValueError):
                robot.validate(archive)

    def test_branch_guard_blocks_main(self):
        class Result:
            stdout="main\n"
        with patch.object(robot.subprocess,"run",return_value=Result()):
            with self.assertRaises(RuntimeError):
                robot.require_branch()

    def test_300_jobs_are_only_planned(self):
        with tempfile.TemporaryDirectory() as tmp:
            output=Path(tmp)/"queue.json"
            robot.plan(output)
            jobs=json.loads(output.read_text())["jobs"]
            self.assertEqual(len(jobs),300)
            self.assertTrue(all(j["status"]=="not_generated" for j in jobs))

if __name__=="__main__":
    unittest.main()
