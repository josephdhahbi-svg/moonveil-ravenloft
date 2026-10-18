import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moonveil_client/services/moonveil_encounter_store.dart';
import 'package:moonveil_client/services/moonveil_encounter_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  MoonveilEncounter encounter(int hp) => MoonveilEncounter([
    MoonveilCombatant(id: 'hero', name: 'Hero', initiative: 12,
      maxHp: 10, hp: hp, ac: 13),
  ]);

  test('persistent encounters are isolated by campaign', () async {
    const vesper = MoonveilEncounterStore('vesper');
    const alice = MoonveilEncounterStore('alice');
    await vesper.save(encounter(7));
    expect((await vesper.load())!.active.hp, 7);
    expect(await alice.load(), isNull);
    await alice.save(encounter(4));
    expect((await alice.load())!.active.hp, 4);
    expect((await vesper.load())!.active.hp, 7);
  });

  test('explicit delete only removes the selected encounter', () async {
    const vesper = MoonveilEncounterStore('vesper');
    const alice = MoonveilEncounterStore('alice');
    await vesper.save(encounter(9));
    await alice.save(encounter(3));
    await vesper.deleteCheckpoint();
    expect(await vesper.load(), isNull);
    expect((await alice.load())!.active.hp, 3);
  });

  test('rejects malformed campaign ID without writing data', () async {
    const store = MoonveilEncounterStore('../vesper');
    expect(() => store.key, throwsArgumentError);
  });

  test('load rejects corrupted checkpoint rather than fabricating state', () async {
    SharedPreferences.setMockInitialValues({
      'moonveil.encounters.v1.vesper': 'not valid JSON',
    });
    await expectLater(const MoonveilEncounterStore('vesper').load(),
      throwsFormatException);
  });
}
