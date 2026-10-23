#!/usr/bin/env python3
"""Install verified Moonveil PNG assets into an existing checkout.
Does not read, write, or migrate any SQLite database or save file.
Usage: python3 tools/install_artwork.py /path/to/moonveil_library_150.zip
"""
import hashlib
import pathlib
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSET_ROOT = (ROOT / "flutter_client/assets/images").resolve()
PREFIX = "flutter_client/assets/images/"
SIGNATURE = b"\x89PNG\r\n\x1a\n"

def install(archive):
    installed = 0
    skipped = 0
    with zipfile.ZipFile(archive) as bundle:
        members = [n for n in bundle.namelist() if n.lower().endswith(".png")]
        if not members:
            raise ValueError("No PNG artwork found")
        planned = []
        digests = set()
        for name in members:
            if not name.startswith(PREFIX):
                raise ValueError("Unexpected artwork path: " + name)
            relative = pathlib.PurePosixPath(name[len(PREFIX):])
            if not relative.parts or ".." in relative.parts or relative.is_absolute():
                raise ValueError("Unsafe path: " + name)
            dest = (ASSET_ROOT / pathlib.Path(*relative.parts)).resolve()
            if not dest.is_relative_to(ASSET_ROOT):
                raise ValueError("Path escapes artwork directory")
            payload = bundle.read(name)
            if not payload.startswith(SIGNATURE):
                raise ValueError("Invalid PNG signature: " + name)
            digest = hashlib.sha256(payload).hexdigest()
            if digest in digests:
                raise ValueError("Duplicate PNG content: " + name)
            digests.add(digest)
            planned.append((dest, payload, digest))
        for dest, payload, digest in planned:
            if dest.exists():
                if hashlib.sha256(dest.read_bytes()).hexdigest() == digest:
                    skipped += 1
                    continue
                raise FileExistsError("Refusing to overwrite existing artwork: " + str(dest))
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(payload)
            installed += 1
    print(f"Verified {len(planned)} PNG files; installed {installed}; already present {skipped}")
    print("No campaign databases or saves accessed")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 tools/install_artwork.py ARTWORK.zip")
    install(sys.argv[1])
