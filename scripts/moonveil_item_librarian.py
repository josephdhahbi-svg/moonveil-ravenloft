#!/usr/bin/env python3
"""Build, audit and query the Moonveil item library. Standard library only.

Commands:
 python scripts/moonveil_item_librarian.py build
 python scripts/moonveil_item_librarian.py list
 python scripts/moonveil_item_librarian.py search vecna
 python scripts/moonveil_item_librarian.py audit
 python scripts/moonveil_item_librarian.py import path/to/licensed_records.json

Import is append-only and rejects duplicate IDs/names. Human-reviewed, lawful
source metadata only. No proprietary rule text generated or scraped.
"""
import json
from pathlib import Path
import re
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "data/item_library/official_item_seed.json"
DB = ROOT / "data/item_library/moonveil_items.sqlite3"
ID = re.compile(r"^MOI-[0-9]{6}$")

def validate(records):
    seen_id, seen_name = set(), set()
    for item in records:
        ident, name = item["id"], item["name"].strip()
        if not ID.fullmatch(ident) or not name:
            raise ValueError("Invalid ID or name")
        key = name.casefold()
        if ident in seen_id or key in seen_name:
            raise ValueError("Duplicate item ID or name")
        seen_id.add(ident)
        seen_name.add(key)
        if item.get("collection", {}).get("owned") is True:
            raise ValueError("Catalog imports cannot grant inventory")
        if item.get("mechanics", {}).get("rules_text"):
            raise ValueError("Import full rules text only through a separate licensed process")
    return records

def seed():
    return validate(json.loads(SEED.read_text(encoding="utf-8"))["items"])

def connect():
    DB.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(DB)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("""CREATE TABLE IF NOT EXISTS items (
      id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE COLLATE NOCASE,
      item_type TEXT NOT NULL, rarity TEXT, edition TEXT NOT NULL,
      source_title TEXT, source_page INTEGER, verified INTEGER NOT NULL DEFAULT 0,
      review_status TEXT NOT NULL, record_json TEXT NOT NULL)""")
    return db

def add(db, items):
    validate(items)
    with db:
        for item in items:
            src = item.get("source") or {}
            existing = db.execute("SELECT id,name,record_json FROM items WHERE id=? OR name=? COLLATE NOCASE", (item["id"], item["name"])).fetchall()
            if existing:
                if len(existing) != 1 or existing[0][0] != item["id"] or existing[0][1] != item["name"] or json.loads(existing[0][2]) != item:
                    raise ValueError("Conflicting existing catalog entry: " + item["id"])
                continue
            db.execute("""INSERT INTO items
              (id,name,item_type,rarity,edition,source_title,source_page,verified,
               review_status,record_json) VALUES (?,?,?,?,?,?,?,?,?,?)""",
              (item["id"],item["name"],item["item_type"],item.get("rarity"),
               item["edition"],src.get("title"),src.get("page"),
               int(src.get("verified") is True),item["review_status"],
               json.dumps(item,ensure_ascii=False,sort_keys=True)))

def main(argv):
    command = argv[0] if argv else "audit"
    if command == "audit":
        items = seed()
        print(json.dumps({"seed_count":len(items),
                          "verified_primary_sources":sum(bool(i["source"]["verified"]) for i in items),
                          "unowned":all(not i["collection"]["owned"] for i in items)}))
        return
    if command == "build":
        with connect() as db:
            add(db,seed())
            print(json.dumps({"database":str(DB),"total":db.execute("SELECT count(*) FROM items").fetchone()[0]}))
        return
    if command == "import":
        if len(argv) != 2:
            raise SystemExit("import requires a JSON file")
        imported = json.loads(Path(argv[1]).read_text(encoding="utf-8"))
        records = imported["items"]
        with connect() as db:
            add(db,records)
            print(json.dumps({"total":db.execute("SELECT count(*) FROM items").fetchone()[0]}))
        return
    if command in ("list","search"):
        with connect() as db:
            if command == "list":
                rows = db.execute("SELECT id,name,item_type,review_status FROM items ORDER BY id").fetchall()
            else:
                if len(argv) != 2:
                    raise SystemExit("search requires a term")
                rows = db.execute("SELECT id,name,item_type,review_status FROM items WHERE name LIKE ? ORDER BY id",
                                  ("%"+argv[1]+"%",)).fetchall()
            for row in rows:
                print(" | ".join(row))
        return
    raise SystemExit("Unknown command")

if __name__ == "__main__":
    main(sys.argv[1:])
