import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/moonveil_encounter_codec.dart';
import 'package:moonveil_client/services/moonveil_encounter_engine.dart';

void main() {
  test('encounter JSON round-trip preserves actors, HP, conditions and history', () {
    final encounter = MoonveilEncounter([
      const MoonveilCombatant(id: 'vesper', name: 'Vesper Vane',
        initiative: 14, maxHp: 10, hp: 10, ac: 13, characterId: 'vesper-vane'),
      const MoonveilCombatant(id: 'enemy-1', name: 'Skeleton',
        initiative: 12, maxHp: 13, hp: 13, ac: 13, isEnemy: true),
    ]);
    encounter.applyDamage('enemy-1', 5);
    encounter.setCondition('enemy-1', 'Prone', enabled: true);
    encounter.nextTurn();
    final restored = MoonveilEncounterCodec.decode(MoonveilEncounterCodec.encode(encounter));
    expect(restored.round, 1);
    expect(restored.active.id, 'enemy-1');
    expect(restored.state.last.hp, 8);
    expect(restored.state.last.conditions, contains('Prone'));
    expect(restored.state.last.isEnemy, isTrue);
    expect(restored.history.length, 3);
  });

  test('rejects unsupported or corrupt encounter snapshots', () {
    expect(() => MoonveilEncounterCodec.decode('{}'), throwsFormatException);
    expect(() => MoonveilEncounterCodec.decode(
      '{"format":"moonveil-encounter","version":99}'), throwsFormatException);
    expect(() => MoonveilEncounterCodec.decode('not json'), throwsFormatException);
  });

  test('restored combat can continue without changing source snapshot', () {
    final original = MoonveilEncounter([const MoonveilCombatant(
      id: 'vesper', name: 'Vesper', initiative: 10,
      maxHp: 10, hp: 10, ac: 13,
    )]);
    final json = MoonveilEncounterCodec.encode(original);
    final restored = MoonveilEncounterCodec.decode(json);
    restored.applyDamage('vesper', 4);
    expect(restored.active.hp, 6);
    expect(original.active.hp, 10);
  });
}
