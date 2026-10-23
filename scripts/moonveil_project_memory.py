#!/usr/bin/env python3
"""Moonveil project memory and task robot.

This is *project memory*, not ChatGPT's private memory. Local SQLite index
stores documented facts, source references, dependencies and task outcomes.
Never stores secrets or modifies campaign save databases.

Examples:
 python scripts/moonveil_project_memory.py init
 python scripts/moonveil_project_memory.py remember --key checkpoint --value "Link 2 Sector D" --source "approved checkpoint"
 python scripts/moonveil_project_memory.py find "checkpoint"
 python scripts/moonveil_project_memory.py task-add --title "Verify art" --priority 1
 python scripts/moonveil_project_memory.py next
 python scripts/moonveil_project_memory.py export --output /tmp/moonveil_context.json
"""
import argparse
import json
import os
from pathlib import Path
import sqlite3
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = ROOT / ".moonveil_local" / "project_memory.sqlite3"
SCHEMA = """
PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS facts(
 key TEXT PRIMARY KEY,
 value TEXT NOT NULL,
 source TEXT NOT NULL,
 updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS tasks(
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 title TEXT NOT NULL,
 priority INTEGER NOT NULL DEFAULT 3 CHECK(priority BETWEEN 1 AND 5),
 status TEXT NOT NULL DEFAULT 'todo' CHECK(status IN ('todo','doing','blocked','done')),
 result TEXT NOT NULL DEFAULT '',
 created_at TEXT NOT NULL,
 updated_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS task_dependencies(
 task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
 depends_on INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
 PRIMARY KEY(task_id, depends_on),
 CHECK(task_id != depends_on)
);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(status,priority,id);
"""

def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")

def connect(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--db", type=Path, default=DEFAULT_DB)
    sub = p.add_subparsers(dest="action", required=True)
    sub.add_parser("init")
    r = sub.add_parser("remember")
    r.add_argument("--key", required=True)
    r.add_argument("--value", required=True)
    r.add_argument("--source", required=True)
    f = sub.add_parser("find")
    f.add_argument("query")
    a = sub.add_parser("task-add")
    a.add_argument("--title", required=True)
    a.add_argument("--priority", type=int, default=3)
    a.add_argument("--depends-on", type=int, action="append", default=[])
    u = sub.add_parser("task-update")
    u.add_argument("id", type=int)
    u.add_argument("--status", choices=["todo", "doing", "blocked", "done"], required=True)
    u.add_argument("--result", default="")
    sub.add_parser("next")
    e = sub.add_parser("export")
    e.add_argument("--output", required=True, type=Path)
    args = p.parse_args()

    with connect(args.db) as db:
        if args.action == "init":
            print("Project memory initialized:", args.db)
        elif args.action == "remember":
            db.execute("""INSERT INTO facts(key,value,source,updated_at) VALUES(?,?,?,?)
                ON CONFLICT(key) DO UPDATE SET value=excluded.value,
                source=excluded.source, updated_at=excluded.updated_at""",
                (args.key,args.value,args.source,now()))
            print("Stored sourced project fact:",args.key)
        elif args.action == "find":
            q = "%" + args.query.replace("%", "\\%").replace("_", "\\_") + "%"
            rows = db.execute("""SELECT * FROM facts WHERE key LIKE ? ESCAPE '\\'
                OR value LIKE ? ESCAPE '\\' ORDER BY key LIMIT 50""",(q,q)).fetchall()
            print(json.dumps([dict(x) for x in rows],indent=2))
        elif args.action == "task-add":
            if not 1 <= args.priority <= 5:
                p.error("Priority must be 1-5")
            cur=db.execute("INSERT INTO tasks(title,priority,created_at,updated_at) VALUES(?,?,?,?)",
                           (args.title,args.priority,now(),now()))
            task_id=cur.lastrowid
            for dep in args.depends_on:
                if db.execute("SELECT 1 FROM tasks WHERE id=?",(dep,)).fetchone() is None:
                    raise ValueError("Unknown dependency: "+str(dep))
                db.execute("INSERT INTO task_dependencies VALUES(?,?)",(task_id,dep))
            print("Created task:",task_id)
        elif args.action == "task-update":
            cur=db.execute("UPDATE tasks SET status=?,result=?,updated_at=? WHERE id=?",
                           (args.status,args.result,now(),args.id))
            if not cur.rowcount:
                raise ValueError("Unknown task")
            print("Updated task:",args.id)
        elif args.action == "next":
            rows=db.execute("""SELECT t.* FROM tasks t WHERE t.status='todo'
                AND NOT EXISTS(SELECT 1 FROM task_dependencies d
                    JOIN tasks predecessor ON predecessor.id=d.depends_on
                    WHERE d.task_id=t.id AND predecessor.status!='done')
                ORDER BY t.priority,t.id LIMIT 10""").fetchall()
            print(json.dumps([dict(x) for x in rows],indent=2))
        elif args.action == "export":
            data={
                "facts":[dict(x) for x in db.execute("SELECT * FROM facts ORDER BY key")],
                "tasks":[dict(x) for x in db.execute("SELECT * FROM tasks ORDER BY priority,id")],
                "dependencies":[dict(x) for x in db.execute("SELECT * FROM task_dependencies")],
            }
            args.output.parent.mkdir(parents=True,exist_ok=True)
            args.output.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")
            print("Exported project context:",args.output)

if __name__ == "__main__":
    main()
