# Copy-first migration and compatibility audit

Source: josephdhahbi-svg/alice-zress-campaign (read-only reference).
Target: moonveil-ravenloft integration/copy-first-audit. Do not modify either repository's main branch.

## Verified source inventory
- Source contains backend JS/Python services and tests, assets catalog/manifest, game, data, docs, campaigns.
- Source data/items.json, data/quests.json, data/spells.json are only 3 bytes each: **not** a complete item/quest/spell catalog.
- Target currently has index.html only. No committed Flutter project or verified SQLite save database in target.
- Source has backend/migrations.js, backup-service.js, campaign_store.py, session-auth.js, and multiple tests; review schema and API contracts before reuse.

## Copy rules
1. Copy reusable code to staging/shared-engine/ initially; preserve original paths in provenance manifest.
2. Never copy Alice campaign data into Vesper's active save namespace.
3. Import Vesper's latest checkpoint only after validating against existing save and retaining a backup.
4. Preserve existing target index.html. No live database or user-specific saves in Git.
5. Record source commit SHA and checksums for every copied file; never delete source.
6. Run existing tests before and after migration; flag incompatible assumptions.
7. Flutter mobile persistence: sqflite on supported mobile platforms; use a compatible desktop SQLite implementation on Windows. Enable WAL as supported and checkpoint before export; never export just the .db file while uncheckpointed WAL writes exist.
8. Use per-campaign identifiers and separate save files, immutable event IDs, schema migrations, transactional restores, and backup verification.
9. Cross-device automatic sync is a separate authenticated cloud layer, not provided by SQLite WAL or GitHub Pages.

## Audit gates before migration
- [ ] Record source and target commit SHAs
- [ ] Inventory dependencies, entrypoints and tests
- [ ] Validate schema, migration versioning and append-only ledger behavior
- [ ] Identify campaign-specific imports, assets and assumptions
- [ ] Confirm Vesper's authoritative checkpoint from original source files
- [ ] Check asset licenses and provenance
- [ ] Copy selected shared modules into staging, not active runtime
- [ ] Run unit/integration tests and document results
- [ ] Review before merging

## Canonical namespaces (planned)
assets/common, assets/vesper, assets/alice-reference
campaigns/vesper, campaigns/alice-reference
backend/db/migrations, flutter_client, tools, docs

Status: AUDIT STARTED; NO SOURCE FILES MIGRATED; NO LIVE SAVE MODIFIED.
