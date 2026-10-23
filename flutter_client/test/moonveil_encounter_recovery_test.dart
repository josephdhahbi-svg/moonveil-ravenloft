import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moonveil_client/services/moonveil_encounter_store.dart';
import 'package:moonveil_client/services/moonveil_encounter_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  MoonveilEncounter make(int hp) => MoonveilEncounter([
    MoonveilCombatant(id: 'vesper', name: 'Vesper', initiative: 14,
      maxHp: 10, hp: hp, ac: 13),
  ]);

  test('second save retains first as previous recoverable checkpoint', () async {
    const store = MoonveilEncounterStore('vesper');
    await store.save(make(10));
    expect(await store.loadPrevious(), isNull);
    await store.save(make(6));
    expect((await store.load())!.active.hp, 6);
    expect((await store.loadPrevious())!.active.hp, 10);
  });

  test('corrupt primary does not erase known-good previous backup', () async {
    const store = MoonveilEncounterStore('vesper');
    await store.save(make(10));
    await store.save(make(8));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(store.key, 'corrupted');
    await expectLater(store.load(), throwsFormatException);
    expect((await store.loadPrevious())!.active.hp, 10);
  });

  test('recovery remains isolated between campaigns', () async {
    const vesper = MoonveilEncounterStore('vesper');
    const alice = MoonveilEncounterStore('alice');
    await vesper.save(make(10));
    await vesper.save(make(7));
    await alice.save(make(5));
    expect(await alice.loadPrevious(), isNull);
    expect((await vesper.loadPrevious())!.active.hp, 10);
  });
}
