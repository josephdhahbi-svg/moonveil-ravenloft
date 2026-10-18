# Moonveil recovery checkpoint — 2026-10-18

1. Read continuity/session_state.json, conflicts.json, canon.json and artwork_manifest.json BEFORE narration or editing.
2. Library source: /Moonveil/Moonveil_Continuity_v3_PLAYABLE.zip. Contains 110 entries including game/public/index.html, assets, records, tests, handoffs. Preserve original unchanged.
3. GitHub main index.html is a different build (Ravenloft v43), not the v3 Library index. Do not overwrite it.
4. Vesper: Forgotten Archive Link 2 Sector D, Guardian waiting, PariahT present, HP 10/10 AC 13 pact 1/1. No automatic combat, item, location or level changes.
5. Original art: use only verified artwork manifest entries and the actual files; no substitute stock art.
6. Deity lists remain unresolved; no invented five-per-alignment assignments.
7. The new save-store module provides local atomic saves and backups; it is not yet wired to the game UI, backend or GitHub automation.
8. Next engineering task: compare v3 game/public/index.html against repo index.html, integrate through reviewed PR without replacing existing features, then test save/load and artwork references in browser.
