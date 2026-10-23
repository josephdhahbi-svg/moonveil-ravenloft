import 'dart:convert';
import 'dart:typed_data';
import 'moonveil_database.dart';

/// Imports a user-provided, explicitly verified checkpoint into an EMPTY
/// Vesper database. No fabricated default checkpoint is embedded.
class VesperCheckpointImport {
  static Future<void> importJson(
    MoonveilDatabase storage, Uint8List bytes,
  ) async {
    if (storage.campaignId != 'vesper') throw StateError('Vesper only');
    final document = jsonDecode(utf8.decode(bytes));
    if (document is! Map<String, dynamic> ||
        document['campaign_id'] != 'vesper' ||
        document['character_id'] != 'vesper-vane' ||
        document['state'] is! Map<String, dynamic> ||
        document['inventory'] is! List ||
        document['revision'] is! int) {
      throw FormatException('Invalid Vesper checkpoint envelope');
    }
    final state = document['state'] as Map<String, dynamic>;
    if (state['name'] != 'Vesper Vane') {
      throw FormatException('Character mismatch');
    }
    final items = document['inventory'] as List;
    final parsed = <Map<String, dynamic>>[];
    for (final entry in items) {
      if (entry is! Map<String, dynamic> ||
          entry['item_id'] is! String ||
          entry['item'] is! Map<String, dynamic> ||
          entry['owned'] is! bool ||
          entry['attuned'] is! bool ||
          (entry['attuned'] == true && entry['owned'] != true)) {
        throw FormatException('Invalid inventory entry');
      }
      parsed.add(entry);
    }
    await storage.db.transaction((txn) async {
      final existing = await txn.rawQuery(
        'SELECT (SELECT COUNT(*) FROM vtt_campaigns) + '
        '(SELECT COUNT(*) FROM character_snapshots) + '
        '(SELECT COUNT(*) FROM vtt_campaign_events) AS n');
      if ((existing.first['n'] as int) != 0) {
        throw StateError('Import refused: database already initialized');
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await txn.insert('vtt_campaigns', {
        'campaign_id': 'vesper', 'name': 'Vesper Vane', 'created_at': now
      });
      await txn.insert('character_snapshots', {
        'campaign_id': 'vesper', 'character_id': 'vesper-vane',
        'revision': document['revision'],
        'state_json': jsonEncode(state), 'updated_at': now,
      });
      for (final entry in parsed) {
        await txn.insert('inventory_entries', {
          'campaign_id': 'vesper', 'character_id': 'vesper-vane',
          'item_id': entry['item_id'], 'item_json': jsonEncode(entry['item']),
          'owned': entry['owned'] == true ? 1 : 0,
          'attuned': entry['attuned'] == true ? 1 : 0,
        });
      }
    });
  }
}
