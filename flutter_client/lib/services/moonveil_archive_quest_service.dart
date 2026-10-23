import 'dart:convert';
import '../storage/moonveil_database.dart';

/// Event-only quest progression. Never modifies HP, equipment or inventory.
/// Replays the latest accepted archive choice and its explicitly logged outcome.
class MoonveilArchiveQuestService {
  const MoonveilArchiveQuestService(this.database);
  final MoonveilDatabase database;

  static const sceneId = 'forgotten-netherese-barovian-archive';
  static const choices = {
    'Lawful Good', 'Neutral Good', 'Chaotic Good', 'Utility', 'Action',
  };
  static const outcomes = {
    'guardian_repelled', 'survivor_located', 'seal_studied',
  };

  Future<String?> lastChoice() async {
    final events = await database.events();
    String? choice;
    for (final event in events) {
      if (event['event_type'] != 'FORGOTTEN_ARCHIVE_CHOICE') continue;
      final payload = jsonDecode(event['payload_json'] as String);
      if (payload is Map && payload['scene'] == sceneId &&
          choices.contains(payload['choice'])) {
        choice = payload['choice'] as String;
      }
    }
    return choice;
  }

  Future<Set<String>> completedObjectives() async {
    final events = await database.events();
    final result = <String>{};
    for (final event in events) {
      if (event['event_type'] != 'ARCHIVE_QUEST_OBJECTIVE') continue;
      final payload = jsonDecode(event['payload_json'] as String);
      if (payload is Map && payload['scene'] == sceneId &&
          outcomes.contains(payload['objective'])) {
        result.add(payload['objective'] as String);
      }
    }
    return result;
  }

  Future<void> completeObjective(String objective) async {
    if (!outcomes.contains(objective)) {
      throw ArgumentError.value(objective, 'objective', 'Unknown objective');
    }
    if (await lastChoice() == null) {
      throw StateError('Choose an archive approach before recording progress');
    }
    if ((await completedObjectives()).contains(objective)) return;
    await database.appendEvent(
      eventId: 'archive-objective-$objective',
      actorId: 'vesper-vane',
      type: 'ARCHIVE_QUEST_OBJECTIVE',
      payload: {'scene': sceneId, 'objective': objective,
        'mode': 'manual_verified_event', 'reward': null},
    );
  }
}
