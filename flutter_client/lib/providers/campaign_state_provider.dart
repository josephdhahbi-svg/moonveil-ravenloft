import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/moonveil_database.dart';

/// UI-facing Vesper state. Does not seed, reset, or fabricate a checkpoint.
/// The caller owns and closes the campaign-specific database connection.
class CampaignStateProvider extends ChangeNotifier {
  CampaignStateProvider(this.database, {this.characterId = 'vesper-vane'});

  final MoonveilDatabase database;
  final String characterId;
  Map<String, dynamic>? _character;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get character =>
      _character == null ? null : Map<String, dynamic>.unmodifiable(_character!);
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasVerifiedCheckpoint => _character != null;

  Future<void> reload() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _character = await database.loadCharacter(characterId);
    } catch (e) {
      _error = e.toString();
      _character = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Change HP only when an imported checkpoint explicitly contains integer
  /// hp/max_hp fields. Update the existing row without REPLACE, preserving
  /// inventory foreign keys. An absent checkpoint is never initialized here.
  Future<void> modifyHp(int delta) async {
    if (database.campaignId != 'vesper') {
      throw StateError('Vesper state controller requires the Vesper database');
    }
    await database.db.transaction((txn) async {
      final rows = await txn.query('character_snapshots',
          columns: ['revision', 'state_json'],
          where: 'campaign_id = ? AND character_id = ?',
          whereArgs: ['vesper', characterId],
          limit: 1);
      if (rows.isEmpty) throw StateError('Verified checkpoint not imported');
      final row = rows.single;
      final state = jsonDecode(row['state_json'] as String) as Map<String, dynamic>;
      final hp = state['hp'];
      final maxHp = state['max_hp'];
      if (hp is! int || maxHp is! int || maxHp < 0 || hp < 0 || hp > maxHp) {
        throw StateError('Checkpoint does not contain valid hp and max_hp');
      }
      state['hp'] = (hp + delta).clamp(0, maxHp);
      final previousRevision = row['revision'] as int;
      final changed = await txn.update('character_snapshots', {
        'state_json': jsonEncode(state),
        'revision': previousRevision + 1,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'campaign_id = ? AND character_id = ? AND revision = ?',
          whereArgs: ['vesper', characterId, previousRevision]);
      if (changed != 1) throw StateError('Concurrent checkpoint update');
      await txn.insert('vtt_campaign_events', {
        'campaign_id': 'vesper',
        'revision': (await txn.rawQuery(
          'SELECT COALESCE(MAX(revision),0) + 1 AS next FROM vtt_campaign_events WHERE campaign_id = ?',
          ['vesper'])).single['next'],
        'event_id': 'hp-$characterId-${previousRevision + 1}',
        'actor_id': characterId,
        'event_type': 'character.hp_changed',
        'payload_json': jsonEncode({'delta': delta, 'hp': state['hp'], 'max_hp': maxHp}),
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
    await reload();
  }
}
