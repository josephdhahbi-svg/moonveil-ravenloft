#!/usr/bin/env python3
"""Validate visual briefs against the approved Moonveil Vesper style bible.

This is an editorial linter, not an image classifier or a guarantee that
rendered images match the requested appearance.
"""
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
BIBLE = ROOT / "project_context" / "vesper_photorealistic_art_bible.json"

def validate_brief(text, subject="vesper"):
    bible = json.loads(BIBLE.read_text(encoding="utf-8"))
    lowered = text.lower()
    violations = []
    forbidden = ["anime", "cartoon", "emoji", "plastic cgi", "comic illustration"]
    for word in forbidden:
        if word in lowered and not any(
            phrase in lowered for phrase in ["no " + word, "avoid " + word, "not " + word]
        ):
            violations.append("Disallowed style: " + word)
    if not any(word in lowered for word in ("photorealistic", "photographic", "realistic")):
        violations.append("Missing photorealism requirement")
    if subject.lower() in ("vesper", "vesper vane"):
        required = ["nordic", "london", "paris", "transylvan"]
        for word in required:
            if word not in lowered:
                violations.append("Missing Vesper identity anchor: " + word)
    return violations

def main():
    if len(sys.argv) < 2:
        raise SystemExit("Usage: python scripts/validate_moonveil_art_brief.py brief.txt [subject]")
    brief = Path(sys.argv[1]).read_text(encoding="utf-8")
    issues = validate_brief(brief, sys.argv[2] if len(sys.argv)>2 else "vesper")
    if issues:
        print("\n".join(issues))
        raise SystemExit(1)
    print("Art brief matches required textual style anchors; visual review still required")

if __name__ == "__main__":
    main()
