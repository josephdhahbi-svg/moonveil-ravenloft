import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/moonveil_encounter_engine.dart';

void main() {
  const vesper = MoonveilCombatant(
    id: 'vesper', name: 'Vesper Vane', initiative: 12,
    maxHp: 10, hp: 10, ac: 13,
  );
  const skeleton = MoonveilCombatant(
    id: 'skeleton', name: 'Skeleton', initiative: 12,
    initiativeModifier: 2, maxHp: 13, hp: 13, ac: 13,
    temporaryHp: 4,
  );

  test('initiative tie uses modifier and turns increment round', () {
    final encounter = MoonveilEncounter([vesper, skeleton]);
    expect(encounter.active.id, 'skeleton');
    encounter.nextTurn();
    expect(encounter.active.id, 'vesper');
    encounter.nextTurn();
    expect(encounter.active.id, 'skeleton');
    expect(encounter.round, 2);
  });

  test('temporary hit points absorb damage first; heal caps', () {
    final encounter = MoonveilEncounter([vesper, skeleton]);
    encounter.applyDamage('skeleton', 6);
    expect(encounter.active.temporaryHp, 0);
    expect(encounter.active.hp, 11);
    encounter.applyDamage('skeleton', 200);
    expect(encounter.active.hp, 0);
    encounter.heal('skeleton', 99);
    expect(encounter.active.hp, 13);
    expect(skeleton.hp, 13); // Input snapshot unchanged.
  });

  test('Vesper checkpoint can be previewed without changing save', () {
    final snapshot = <String, dynamic>{'hp': 10, 'maxHp': 10, 'ac': 13};
    final character = MoonveilCombatant.fromCharacterSnapshot(
      id: 'vesper', name: 'Vesper Vane',
      snapshot: snapshot, initiative: 15,
    );
    final encounter = MoonveilEncounter([character]);
    encounter.applyDamage('vesper', 3);
    expect(encounter.active.hp, 7);
    expect(snapshot['hp'], 10);
    expect(encounter.exportPreview()['round'], 1);
  });

  test('rejects duplicate IDs and invalid combat actions', () {
    expect(() => MoonveilEncounter([vesper, vesper]), throwsArgumentError);
    final encounter = MoonveilEncounter([vesper]);
    expect(() => encounter.applyDamage('vesper', -1), throwsArgumentError);
    expect(() => encounter.heal('missing', 1), throwsArgumentError);
    expect(() => MoonveilCombatant.fromCharacterSnapshot(
      id: 'alice', name: 'Alice', snapshot: {'hp': 10},
      initiative: 2), throwsFormatException);
  });
}
