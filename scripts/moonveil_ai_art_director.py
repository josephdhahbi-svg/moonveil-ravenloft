#!/usr/bin/env python3
"""Generate reviewable AI image briefs without claiming images were generated.

No API keys, credentials, or network calls. The output can be submitted to
an image generator by a human or a separately authorized integration.
"""
import argparse
import json
from pathlib import Path

ROLES = {
    "characters": "one named person, faithful costume and face continuity",
    "monsters": "one distinct creature, anatomically readable silhouette",
    "summons": "one summoned creature, clear faction and magic identity",
    "locations": "one recognizable environment, no characters obscuring layout",
    "battle_maps": "top-down playable terrain, unobstructed squares, no baked-in tokens",
    "objects": "one standalone interactable prop, isolated from scenery",
    "story_panels": "one cinematic narrative beat, dialogue stored as editable text overlay",
}


def make_brief(job):
    category = job["category"]
    return {
        "job_id": job["job_id"],
        "prompt": (
            "Photorealistic cinematic dark fantasy for Moonveil VTT. "
            + ROLES[category] + ". Consistent realistic lighting and material textures. "
            "No text, labels, speech balloons, logos, or baked-in grid. "
            "Generate a single source image. Do not imitate a living artist."
        ),
        "outputs": [
            "source illustration",
            "transparent-background token if the subject is placeable",
            "optional top-down footprint metadata for map use",
            "editable dialogue and speaker data if this is a story panel",
        ],
        "approval_required": True,
        "status": "brief_only",
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("queue", type=Path)
    p.add_argument("--output", required=True, type=Path)
    args = p.parse_args()
    queue = json.loads(args.queue.read_text(encoding="utf-8"))
    jobs = queue["jobs"]
    if len(jobs) != 300 or len({j["job_id"] for j in jobs}) != 300:
        raise ValueError("Expected 300 unique image jobs")
    briefs = [make_brief(job) for job in jobs]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({"briefs": briefs}, indent=2) + "\n")
    print("Prepared", len(briefs), "AI image briefs; generated images: 0")


if __name__ == "__main__":
    main()
