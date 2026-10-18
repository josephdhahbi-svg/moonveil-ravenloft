import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/moonveil_encounter_engine.dart';

void main() {
  test('conditions are tracked independently of original combatant', () {
    const original = MoonveilCombatant(
      id: 'skeleton', name: 'Skeleton', initiative: 14,
      maxHp: 13, hp: 13, ac: 13, isEnemy: true,
    );
    final encounter = MoonveilEncounter([original]);
    encounter.setCondition('skeleton', 'Poisoned', enabled: true);
    expect(encounter.active.conditions, contains('Poisoned'));
    expect(original.conditions, isEmpty);
    encounter.setCondition('skeleton', 'Poisoned', enabled: false);
    expect(encounter.active.conditions, isEmpty);
    expect(encounter.history.length, 2);
  });

  test('event history records repeated damage and healing accurately', () {
    final encounter = MoonveilEncounter([const MoonveilCombatant(
      id: 'vesper', name: 'Vesper Vane', initiative: 12,
      maxHp: 10, hp: 10, ac: 13,
    )]);
    encounter.applyDamage('vesper', 3);
    encounter.applyDamage('vesper', 2);
    encounter.heal('vesper', 1);
    encounter.nextTurn();
    expect(encounter.active.hp, 6);
    expect(encounter.round, 2);
    expect(encounter.history.map((e) => e['action']),
      ['damage', 'damage', 'heal', 'next_turn']);
    expect(encounter.exportPreview()['history'], isNotEmpty);
  });
}
