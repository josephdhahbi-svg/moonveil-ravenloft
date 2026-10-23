# Moonveil Official Item Library

This is a **30-entry curated seed**, not a complete inventory of every D&D
5.5e/2024 item across every sourcebook. Names are metadata; each record is
flagged for primary-source review before being treated as verified.

## ID convention
`MOI-000001` through `MOI-999999`, stable, never renumbered.
Item names remain official names; homebrew uses a separate namespace.

## Fields
ID, name, type, edition compatibility, publisher/book/page/link,
rarity, attunement and prerequisite, AC, damage, damage type, charges,
recharge, saving throw DC, bonuses, properties, rules reference, visual
asset link, ownership, attunement, storage, verification and license.

Unverified details are null rather than invented. Library records do not
grant Vesper or Alice any items. Future artifacts remain unowned.

## Commands
```sh
python scripts/moonveil_item_librarian.py audit
python scripts/moonveil_item_librarian.py build
python scripts/moonveil_item_librarian.py list
python scripts/moonveil_item_librarian.py search Vecna
python scripts/moonveil_item_librarian.py import licensed_metadata.json
```

The build command creates an SQLite catalog only; it does not edit existing
game save databases. Do not commit generated .sqlite3 or WAL files.

## Robots / AI integration contract
1. Source discovery robot queues books and URLs for human verification.
2. Metadata robot proposes item names and source references.
3. Rules verifier approves edition, page, mechanics and licensing.
4. Art robot generates original illustrations, adds image IDs and checksums.
5. Librarian validates, archives and imports approved JSON records.
6. Game UI shows catalog entries separately from owned inventory.

No bot should fabricate rules, scrape restricted books, silently grant
inventory, or mark unreviewed entries as verified.
