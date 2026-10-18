# Moonveil Continuity Recovery v1

Source of truth: original Library archive `Moonveil_Continuity_v3_PLAYABLE.zip` (110 ZIP entries, 2026-10-18). This repository branch is a non-destructive integration staging area; do NOT replace the existing game with this snapshot.

## Boot order (every session)
1. Read `continuity/session_state.json` and `continuity/conflicts.json`.
2. Read `continuity/canon.json`; never promote proposals or incomplete deity rosters to approved canon.
3. Read `continuity/artwork_manifest.json`; verify SHA-256 of assets before displaying them. These assets are referenced by their paths in the original v3 archive; they are NOT claimed to be present in this GitHub repository.
4. Read `continuity/NEXT_SESSION.md` and existing game source; restore state only after validating identity and schema.
5. Write saves to a user-authorized persistent backend, never assume ChatGPT conversation or browser storage syncs to GitHub.

## Save engine
`node continuity/save-store.cjs save path/to/current.json path/to/new.json` writes a validated, atomic, backed-up JSON save to a chosen path. `node continuity/save-store.cjs load path/to/save.json` validates and prints it. Never auto-advance narrative or overwrite the source v3 archive.

## Tests
`node --test continuity/save-store.test.cjs`

## Current limitations
The repository's existing `index.html` is a different version from the v3 Library game. No game UI changes or automatic GitHub/browser sync are asserted. Artwork and full deity rankings require further source reconciliation. No original assets were modified.
