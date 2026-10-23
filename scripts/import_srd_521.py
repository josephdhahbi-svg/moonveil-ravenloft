#!/usr/bin/env python3
"""Safely index the CC BY 4.0 SRD 5.2.1 Markdown ZIP, without running code.

Usage:
 python scripts/import_srd_521.py dnd-5e-srd-markdown-master.zip output.json

Creates *metadata-only* catalog entries. External IDs use MSRD, never MOI.
Does not overwrite campaign saves, modify live inventories or copy art.
"""
import json
import re
import sys
from pathlib import Path
from zipfile import ZipFile

SECTIONS = {
    "magic-items.md": ("item", "## Magic Items A–Z", "#### "),
    "monsters-A-Z.md": ("monster", "# Monsters A–Z", "### "),
}
def index(archive_path):
    result = {"schema_version": 1, "source": "downfallx/dnd-5e-srd-markdown",
              "srd": "5.2.1", "license": "CC BY 4.0",
              "attribution": "Includes material from SRD 5.2.1 © 2024 Wizards of the Coast LLC, available under CC BY 4.0. Converted to Markdown by downfallx.",
              "status": "metadata_extraction_only", "records": []}
    with ZipFile(archive_path) as archive:
        for basename, (kind, start, heading) in SECTIONS.items():
            matches = [n for n in archive.namelist()
                       if n.endswith("/" + basename) and not n.startswith("__MACOSX/")]
            if len(matches) != 1:
                raise ValueError("Expected one source file: " + basename)
            content = archive.read(matches[0]).decode("utf-8")
            if start not in content:
                raise ValueError("Missing source section: " + start)
            block = content.split(start, 1)[1]
            if basename == "magic-items.md":
                headings = re.findall(r"^#### ([^\n]+)$", block, re.M)
            else:
                headings = re.findall(r"^### ([^\n]+)$", block, re.M)
            unique = set()
            for name in headings:
                name = name.strip()
                if not name or name.casefold() in unique or name.lower() in ("traits", "actions", "reactions", "legendary actions", "bonus actions"):
                    continue
                unique.add(name.casefold())
                result["records"].append({
                    "id": f"MSRD-{kind.upper()}-{len([r for r in result['records'] if r['kind'] == kind])+1:05d}",
                    "kind": kind, "name": name,
                    "source_file": basename, "source_repository": result["source"],
                    "edition": "SRD 5.2.1 (2024)", "source_license": "CC BY 4.0",
                    "rules_text": None, "artwork": None, "review_status": "unverified",
                    "owned": False})
    result["record_count"] = len(result["records"])
    result["counts"] = {kind: sum(r["kind"] == kind for r in result["records"])
                         for kind in ("item", "monster")}
    return result

def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: import_srd_521.py archive.zip output.json")
    source, target = Path(sys.argv[1]), Path(sys.argv[2])
    if target.exists():
        raise FileExistsError("Refusing to overwrite: " + str(target))
    payload = index(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"file": str(target), "counts": payload["counts"]}))

if __name__ == "__main__":
    main()
