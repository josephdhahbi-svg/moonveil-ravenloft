import 'dart:convert';
import '../storage/moonveil_database.dart';
import 'forgotten_archive_replay.dart';

/// Derives a training victory from the saved attack ledger, never from a UI
/// checkbox. This is not a real guardian quest reward or campaign victory.
class MoonveilArchiveTrainingOutcome {
  const MoonveilArchiveTrainingOutcome(this.database);
  final MoonveilDatabase database;

  Future<bool> get defeated async =>
      await ForgottenArchiveReplay.restoreGuardianHp(database) == 0;

  Future<bool> recordVictoryIfEarned() async {
    if (!await defeated) return false;
    final rows = await database.events();
    for (final row in rows) {
      if (row['event_type'] != 'ARCHIVE_TRAINING_VICTORY') continue;
      final payload = jsonDecode(row['payload_json'] as String);
      if (payload is Map && payload['scene'] == 'forgotten-archive' &&
          payload['guardian_id'] == ForgottenArchiveReplay.guardianId) {
        return true;
      }
    }
    await database.appendEvent(
      eventId: 'archive-training-victory-v1',
      actorId: 'vesper-vane',
      type: 'ARCHIVE_TRAINING_VICTORY',
      payload: {
        'scene': 'forgotten-archive',
        'guardian_id': ForgottenArchiveReplay.guardianId,
        'training_only': true,
        'reward': null,
      },
    );
    return true;
  }
}
