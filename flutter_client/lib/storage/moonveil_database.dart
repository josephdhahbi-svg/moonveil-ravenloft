import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Offline-first campaign database. No remote service is required.
/// Uses a separate file per campaign, never a shared live save.
class MoonveilDatabase {
  MoonveilDatabase._(this.db, this.campaignId);
  final Database db;
  final String campaignId;

  static const allowedCampaigns = {'vesper', 'alice'};
  static Future<MoonveilDatabase> open(String campaign, {String? databasePath, DatabaseFactory? factory}) async {
    if (!allowedCampaigns.contains(campaign)) {
      throw ArgumentError.value(campaign, 'campaign', 'Unknown campaign');
    }
    final root = databasePath == null ? await getDatabasesPath() : null;
    final path = databasePath ?? p.join(root!, '${campaign}_save.db');
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
        // sqflite Android execute() rejects PRAGMA statements that return rows.
        await db.rawQuery('PRAGMA busy_timeout = 5000');
      },
      onCreate: (db, version) async {
        await _migrate(db, 0, version);
      },
      onUpgrade: _migrate,
      ),
    );
    return MoonveilDatabase._(db, campaign);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 1 && to >= 1) {
      await db.execute('CREATE TABLE vtt_campaigns (campaign_id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT NOT NULL)');
      await db.execute("CREATE TABLE vtt_campaign_members (campaign_id TEXT NOT NULL REFERENCES vtt_campaigns(campaign_id) ON DELETE CASCADE, actor_id TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('DM','PLAYER','OBSERVER')), PRIMARY KEY(campaign_id,actor_id))");
      await db.execute('CREATE TABLE vtt_campaign_events (campaign_id TEXT NOT NULL REFERENCES vtt_campaigns(campaign_id) ON DELETE CASCADE, revision INTEGER NOT NULL CHECK(revision > 0), event_id TEXT NOT NULL, actor_id TEXT NOT NULL, event_type TEXT NOT NULL, payload_json TEXT NOT NULL, occurred_at TEXT NOT NULL, PRIMARY KEY(campaign_id,revision), UNIQUE(campaign_id,event_id))');
      await db.execute('CREATE INDEX idx_vtt_events_actor ON vtt_campaign_events(campaign_id,actor_id)');
    }
    if (from < 2 && to >= 2) {
      await db.execute('CREATE TABLE vtt_revoked_sessions (token_hash TEXT PRIMARY KEY, expires_at INTEGER NOT NULL, revoked_at TEXT NOT NULL)');
      await db.execute('CREATE INDEX idx_vtt_revoked_expiry ON vtt_revoked_sessions(expires_at)');
    }
    // New mobile-only migration. Original Node migrations remain unchanged.
    if (from < 3 && to >= 3) {
      await db.execute('CREATE TABLE character_snapshots (campaign_id TEXT NOT NULL, character_id TEXT NOT NULL, revision INTEGER NOT NULL CHECK(revision >= 0), state_json TEXT NOT NULL, updated_at TEXT NOT NULL, PRIMARY KEY(campaign_id,character_id), FOREIGN KEY(campaign_id) REFERENCES vtt_campaigns(campaign_id))');
      await db.execute('CREATE TABLE inventory_entries (campaign_id TEXT NOT NULL, character_id TEXT NOT NULL, item_id TEXT NOT NULL, item_json TEXT NOT NULL, owned INTEGER NOT NULL DEFAULT 0 CHECK(owned IN (0,1)), attuned INTEGER NOT NULL DEFAULT 0 CHECK(attuned IN (0,1)), PRIMARY KEY(campaign_id,character_id,item_id), FOREIGN KEY(campaign_id,character_id) REFERENCES character_snapshots(campaign_id,character_id))');
    }
    await db.execute('CREATE TABLE IF NOT EXISTS vtt_schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL)');
    for (var v = from + 1; v <= to; v++) {
      await db.insert('vtt_schema_migrations', {
        'version': v,
        'name': {1: 'campaign access and event ledger', 2: 'revoked actor sessions', 3: 'mobile character snapshots and inventory'}[v]!,
        'applied_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> initializeCampaign({required String displayName}) async {
    await db.insert('vtt_campaigns', {
      'campaign_id': campaignId, 'name': displayName,
      'created_at': DateTime.now().toUtc().toIso8601String()
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Atomic, idempotent append-only event. Duplicate IDs are rejected.
  Future<int> appendEvent({
    required String eventId, required String actorId,
    required String type, required Map<String, dynamic> payload,
  }) => db.transaction((txn) async {
    final rows = await txn.rawQuery(
      'SELECT COALESCE(MAX(revision),0) AS rev FROM vtt_campaign_events WHERE campaign_id = ?',
      [campaignId],
    );
    final revision = (rows.first['rev'] as int) + 1;
    await txn.insert('vtt_campaign_events', {
      'campaign_id': campaignId, 'revision': revision, 'event_id': eventId,
      'actor_id': actorId, 'event_type': type, 'payload_json': jsonEncode(payload),
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    });
    return revision;
  });

  Future<List<Map<String, Object?>>> events() => db.query(
    'vtt_campaign_events', where: 'campaign_id = ?', whereArgs: [campaignId],
    orderBy: 'revision ASC',
  );

  /// Never overwrites a newer snapshot with a stale checkpoint.
  Future<void> saveCharacter({
    required String characterId, required int revision,
    required Map<String, dynamic> state,
  }) => db.transaction((txn) async {
    final old = await txn.query('character_snapshots',
      columns: ['revision'], where: 'campaign_id = ? AND character_id = ?',
      whereArgs: [campaignId, characterId]);
    if (old.isNotEmpty && (old.first['revision'] as int) >= revision) {
      throw StateError('Stale or duplicate character snapshot');
    }
    await txn.insert('character_snapshots', {
      'campaign_id': campaignId, 'character_id': characterId,
      'revision': revision, 'state_json': jsonEncode(state),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  });

  Future<Map<String, dynamic>?> loadCharacter(String characterId) async {
    final rows = await db.query('character_snapshots',
      where: 'campaign_id = ? AND character_id = ?',
      whereArgs: [campaignId, characterId], limit: 1);
    return rows.isEmpty ? null : jsonDecode(rows.first['state_json'] as String) as Map<String, dynamic>;
  }

  Future<void> putInventory({
    required String characterId, required String itemId,
    required Map<String, dynamic> item, bool owned = false, bool attuned = false,
  }) async {
    if (attuned && !owned) throw ArgumentError('Cannot attune an unowned item');
    await db.insert('inventory_entries', {
      'campaign_id': campaignId, 'character_id': characterId,
      'item_id': itemId, 'item_json': jsonEncode(item),
      'owned': owned ? 1 : 0, 'attuned': attuned ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() => db.close();
}
