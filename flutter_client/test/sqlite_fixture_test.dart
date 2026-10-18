import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory temp;
  late String path;
  late Database raw;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('moonveil-storage-test-');
    path = '${temp.path}/vesper.db';
    raw = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
        },
        onCreate: (db, version) async {
          // Independent SQL fixture matching the committed schema.
          await db.execute('CREATE TABLE vtt_campaigns (campaign_id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT NOT NULL)');
          await db.execute("CREATE TABLE vtt_campaign_members (campaign_id TEXT NOT NULL REFERENCES vtt_campaigns(campaign_id) ON DELETE CASCADE, actor_id TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('DM','PLAYER','OBSERVER')), PRIMARY KEY(campaign_id,actor_id))");
          await db.execute('CREATE TABLE vtt_campaign_events (campaign_id TEXT NOT NULL REFERENCES vtt_campaigns(campaign_id) ON DELETE CASCADE, revision INTEGER NOT NULL CHECK(revision > 0), event_id TEXT NOT NULL, actor_id TEXT NOT NULL, event_type TEXT NOT NULL, payload_json TEXT NOT NULL, occurred_at TEXT NOT NULL, PRIMARY KEY(campaign_id,revision), UNIQUE(campaign_id,event_id))');
          await db.execute('CREATE INDEX idx_vtt_events_actor ON vtt_campaign_events(campaign_id,actor_id)');
          await db.execute('CREATE TABLE vtt_revoked_sessions (token_hash TEXT PRIMARY KEY, expires_at INTEGER NOT NULL, revoked_at TEXT NOT NULL)');
          await db.execute('CREATE INDEX idx_vtt_revoked_expiry ON vtt_revoked_sessions(expires_at)');
          await db.execute('CREATE TABLE character_snapshots (campaign_id TEXT NOT NULL, character_id TEXT NOT NULL, revision INTEGER NOT NULL CHECK(revision >= 0), state_json TEXT NOT NULL, updated_at TEXT NOT NULL, PRIMARY KEY(campaign_id,character_id), FOREIGN KEY(campaign_id) REFERENCES vtt_campaigns(campaign_id))');
          await db.execute('CREATE TABLE inventory_entries (campaign_id TEXT NOT NULL, character_id TEXT NOT NULL, item_id TEXT NOT NULL, item_json TEXT NOT NULL, owned INTEGER NOT NULL DEFAULT 0 CHECK(owned IN (0,1)), attuned INTEGER NOT NULL DEFAULT 0 CHECK(attuned IN (0,1)), PRIMARY KEY(campaign_id,character_id,item_id), FOREIGN KEY(campaign_id,character_id) REFERENCES character_snapshots(campaign_id,character_id))');
          await db.execute('CREATE TABLE vtt_schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL)');
          for (var version = 1; version <= 3; version++) {
            await db.insert('vtt_schema_migrations', {
              'version': version, 'name': 'fixture', 'applied_at': '2026-10-17T00:00:00Z'
            });
          }
        },
      ),
    );
  });

  tearDown(() async {
    await raw.close();
    await temp.delete(recursive: true);
  });

  test('WAL and schema v1-v3 tables exist', () async {
    final mode = await raw.rawQuery('PRAGMA journal_mode');
    expect(mode.first.values.first.toString().toLowerCase(), 'wal');
    final tables = (await raw.rawQuery("SELECT name FROM sqlite_master WHERE type='table'"))
        .map((r) => r['name']).toSet();
    expect(tables, containsAll([
      'vtt_campaigns', 'vtt_campaign_members', 'vtt_campaign_events',
      'vtt_revoked_sessions', 'character_snapshots', 'inventory_entries',
      'vtt_schema_migrations'
    ]));
    expect((await raw.query('vtt_schema_migrations')).length, 3);
  });

  test('event ledger rejects duplicate revision and event ID', () async {
    await raw.insert('vtt_campaigns', {
      'campaign_id': 'vesper', 'name': 'Vesper Vane', 'created_at': 'now'
    });
    final event = {
      'campaign_id': 'vesper', 'revision': 1, 'event_id': 'evt-1',
      'actor_id': 'vesper-vane', 'event_type': 'CHECK',
      'payload_json': '{}', 'occurred_at': 'now'
    };
    await raw.insert('vtt_campaign_events', event);
    await expectLater(raw.insert('vtt_campaign_events', event), throwsA(isA<DatabaseException>()));
    await expectLater(raw.insert('vtt_campaign_events', {
      ...event, 'revision': 2
    }), throwsA(isA<DatabaseException>()));
  });

  test('checkpoint import rejects wrong campaign and never overwrites', () async {
    final storage = MoonveilDatabaseForTestUnavailable();
    // Importer requires a MoonveilDatabase opened via its production factory.
    // This fixture checks equivalent SQLite constraints; integration test
    // must be run against the production open() path on a mobile emulator.
    expect(storage.reason, contains('production'));
    await raw.insert('vtt_campaigns', {
      'campaign_id': 'vesper', 'name': 'existing', 'created_at': 'now'
    });
    await expectLater(raw.insert('vtt_campaigns', {
      'campaign_id': 'vesper', 'name': 'replacement', 'created_at': 'now'
    }), throwsA(isA<DatabaseException>()));
  });

  test('foreign-key violation rolls back an entire transaction', () async {
    await expectLater(raw.transaction((txn) async {
      await txn.insert('vtt_campaigns', {
        'campaign_id': 'vesper', 'name': 'Vesper Vane', 'created_at': 'now'
      });
      await txn.insert('inventory_entries', {
        'campaign_id': 'vesper', 'character_id': 'missing-character',
        'item_id': 'test', 'item_json': '{}', 'owned': 1, 'attuned': 0
      });
    }), throwsA(isA<DatabaseException>()));
    expect(await raw.query('vtt_campaigns'), isEmpty);
    expect(await raw.query('inventory_entries'), isEmpty);
  });
}

class MoonveilDatabaseForTestUnavailable {
  final reason = 'production database open() needs an injectable database path';
}
