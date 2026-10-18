import 'dart:convert';
import '../storage/moonveil_database.dart';

/// Strict, read-only replay of the isolated Forgotten Archive training ledger.
/// Invalid records fail closed instead of resetting the guardian to full HP.
class ForgottenArchiveReplay {
  static const guardianId = 'archive-training-guardian';
  static const initialHp = 8;

  static Future<int> restoreGuardianHp(MoonveilDatabase database) async {
    if (database.campaignId != 'vesper') {
      throw StateError('Archive training belongs only to the Vesper campaign');
    }
    final rows = await database.events();
    var hp = initialHp;
    for (final row in rows) {
      if (row['event_type'] != 'ARCHIVE_TRAINING_ATTACK') continue;
      if (row['actor_id'] != 'vesper-vane') {
        throw StateError('Unexpected actor in archive training ledger');
      }
      final dynamic payload;
      try {
        payload = jsonDecode(row['payload_json'] as String);
      } catch (_) {
        throw StateError('Malformed archive combat event');
      }
      if (payload is! Map ||
          payload['scene'] != 'forgotten-archive' ||
          payload['training_only'] != true ||
          payload['defender_id'] != guardianId) {
        throw StateError('Unrecognized archive combat event');
      }
      final remaining = payload['defender_remaining_hp'];
      if (remaining is! int || remaining < 0 || remaining > hp) {
        throw StateError('Impossible guardian HP transition');
      }
      hp = remaining;
    }
    return hp;
  }
}
