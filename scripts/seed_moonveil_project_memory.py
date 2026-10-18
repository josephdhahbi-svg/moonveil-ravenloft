#!/usr/bin/env python3
"""Import reviewed Moonveil project context into the separate task/memory database.

Idempotent: facts upsert by key; tasks are only added when their titles are absent.
Never opens campaign save files, and does not modify git branches.
"""
import json
from pathlib import Path
import sys

from moonveil_project_memory import connect, now, DEFAULT_DB

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "project_context" / "moonveil_verified_context.json"

def seed(path=DEFAULT_DB, source=SOURCE):
    payload = json.loads(Path(source).read_text(encoding="utf-8"))
    if payload.get("schema_version") != 1:
        raise ValueError("Unsupported project context schema")
    with connect(Path(path)) as db:
        for group in ("campaign", "artwork", "development"):
            for key, value in payload[group].items():
                name = group + "." + key
                text = json.dumps(value, ensure_ascii=False)
                db.execute("""INSERT INTO facts(key,value,source,updated_at) VALUES(?,?,?,?)
                  ON CONFLICT(key) DO UPDATE SET value=excluded.value,
                  source=excluded.source,updated_at=excluded.updated_at""",
                  (name,text, str(source),now()))
        for task in payload["tasks"]:
            if db.execute("SELECT 1 FROM tasks WHERE title=?",(task["title"],)).fetchone():
                continue
            db.execute("INSERT INTO tasks(title,priority,created_at,updated_at) VALUES(?,?,?,?)",
                       (task["title"],task["priority"],now(),now()))
    print("Imported reviewed context without opening game saves:", path)

if __name__ == "__main__":
    seed(Path(sys.argv[1]) if len(sys.argv)>1 else DEFAULT_DB)
