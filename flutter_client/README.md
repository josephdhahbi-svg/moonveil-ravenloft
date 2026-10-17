# Moonveil Flutter local-first storage (integration draft)

- Run `flutter pub get` from `flutter_client` after adding a standard Flutter application scaffold.
- `MoonveilDatabase.open('vesper')` and `open('alice')` create separate SQLite files in the application's database directory.
- Schema versions 1 and 2 mirror the original Node migration tables; version 3 adds character snapshots and inventory entries.
- Call `initializeCampaign(displayName: 'Vesper Vane')` before writing events or snapshots.
- No live checkpoint has been imported. Existing saves are never overwritten automatically.
- Mobile SQLite WAL is configured at open. For backups, use a transactionally consistent SQLite backup or a verified logical JSON export; never copy a live `.db` file alone and assume its WAL is included.
- **Not encrypted at rest** by sqflite. Device sandboxing is not database encryption. Encryption and verified import/export remain separate tasks.
- This is a Dart service layer, not yet a complete runnable Flutter UI.
- Source staging modules: `staging/shared-engine/backend`. Original Node migration source is not modified.
- Windows desktop requires a separately configured SQLite database factory (e.g. sqflite_common_ffi); this mobile implementation should not be assumed to work unchanged on Windows.
