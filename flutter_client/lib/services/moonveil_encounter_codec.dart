import 'dart:convert';
import 'moonveil_encounter_engine.dart';

/// Versioned, portable encounter snapshots. Never reads or writes campaign DBs.
class MoonveilEncounterCodec {
  static const int version = 1;

  static String encode(MoonveilEncounter encounter) => jsonEncode({
    'format': 'moonveil-encounter',
    'version': version,
    'round': encounter.round,
    'turnIndex': encounter.turnIndex,
    'combatants': [
      for (final c in encounter.state)
        {
          'id': c.id, 'name': c.name, 'initiative': c.initiative,
          'initiativeModifier': c.initiativeModifier,
          'hp': c.hp, 'maxHp': c.maxHp, 'ac': c.ac,
          'temporaryHp': c.temporaryHp, 'conditions': c.conditions,
          'characterId': c.characterId, 'isEnemy': c.isEnemy,
        }
    ],
    'history': encounter.history,
  });

  static MoonveilEncounter decode(String source) {
    final dynamic parsed = jsonDecode(source);
    if (parsed is! Map<String, dynamic> ||
        parsed['format'] != 'moonveil-encounter' ||
        parsed['version'] != version) {
      throw const FormatException('Unsupported Moonveil encounter format');
    }
    int integer(Map<String, dynamic> value, String key) {
      final result = value[key];
      if (result is! int) throw FormatException('Invalid integer: $key');
      return result;
    }
    final raw = parsed['combatants'];
    if (raw is! List || raw.isEmpty || raw.length > 100) {
      throw const FormatException('Invalid combatant list');
    }
    final combatants = <MoonveilCombatant>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid combatant');
      }
      final id = entry['id'];
      final name = entry['name'];
      final conditions = entry['conditions'];
      if (id is! String || name is! String || name.isEmpty ||
          conditions is! List || conditions.any((c) => c is! String) ||
          (entry['characterId'] != null && entry['characterId'] is! String) ||
          entry['isEnemy'] is! bool) {
        throw const FormatException('Invalid combatant fields');
      }
      combatants.add(MoonveilCombatant(
        id: id, name: name, initiative: integer(entry, 'initiative'),
        initiativeModifier: integer(entry, 'initiativeModifier'),
        hp: integer(entry, 'hp'), maxHp: integer(entry, 'maxHp'),
        ac: integer(entry, 'ac'),
        temporaryHp: integer(entry, 'temporaryHp'),
        conditions: List<String>.from(conditions),
        characterId: entry['characterId'] as String?,
        isEnemy: entry['isEnemy'] as bool,
      ));
    }
    final encounter = MoonveilEncounter(combatants);
    final round = integer(parsed, 'round');
    final turnIndex = integer(parsed, 'turnIndex');
    if (round < 1 || turnIndex < 0 || turnIndex >= combatants.length) {
      throw const FormatException('Invalid round or turn');
    }
    // Engine sorts by initiative, so the saved turn is recovered by actor ID.
    final actorId = combatants[turnIndex].id;
    encounter.round = round;
    encounter.turnIndex = encounter.state.indexWhere((c) => c.id == actorId);
    final events = parsed['history'];
    if (events is! List || events.length > 10000) {
      throw const FormatException('Invalid encounter history');
    }
    for (final event in events) {
      if (event is! Map<String, dynamic> ||
          event['round'] is! int || event['actor'] is! String ||
          event['action'] is! String ||
          (event['amount'] != null && event['amount'] is! int)) {
        throw const FormatException('Invalid history event');
      }
    }
    encounter.restoreHistory(events.cast<Map<String, dynamic>>());
    return encounter;
  }
}
