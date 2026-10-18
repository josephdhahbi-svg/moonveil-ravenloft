# Moonveil monster source integration review (2026-10-17)

Three user-provided source archives were inspected without executing their code.

| Repository | Role | Integration decision |
|---|---|---|
| nick-aschenbach/dnd-data | Large JSON reference catalog (items, monsters, spells, classes, species, backgrounds) | Metadata-only, source- and rights-reviewed importer |
| theoperatore/dnd-monster-api | Legacy 5e GraphQL monster lookup, monster images, and local database | Adapt lookup schema only; do not deploy old server or copy scraped art |
| abuzreq/dnd-monster-shopper | Image similarity explorer with gridded monster collection, deep zoom, image tiles | Adapt gallery browsing concept only; do not rely on its old Keras/TSNE pipeline or redistribute its image assets |

## Boundaries
- These are 5e-era or mixed-edition repositories; none establishes complete 2024/5.5e rules coverage.
- Monster art from scraped sources is not automatically licensed for Moonveil. MIT code licenses do not automatically license third-party illustrations or copyrighted game rules.
- Source identities must carry `source_repository`, `publisher`, `book`, `edition_status`, `review_status`, `license_status`.
- Content classified as unknown remains **unverified**; stat sheets must not invent values.
- Never merge monster catalogs into item acquisition inventories or change Vesper/Alice saves.
- Continue in `integration/copy-first-audit`; no writes to `main`.

## Next safe engineering steps
1. Build source adapter reading local JSON files, with validation and deduplication.
2. Preserve stable MOI and new MOM monster IDs, maintaining original external IDs as aliases.
3. Record AC, HP, CR, monster size, type, alignment, speed, senses, actions, and source metadata when independently licensed/verified.
4. Use approved original art files from Moonveil's numbered visual library, not scraped JPEGs.
5. Offer paginated search, challenge-rating filters, and encounter grouping inspired by Monster Shopper.
6. Test manifest hashes, duplicate handling, source classification and no-save-mutation.
