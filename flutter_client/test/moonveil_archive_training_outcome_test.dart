import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';
import 'package:moonveil_client/services/moonveil_archive_training_outcome.dart';

void main() {
  sqfliteFfiInit();

  test('victory cannot be recorded before verified guardian defeat', () async {
    final db = await MoonveilDatabase.open('vesper',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(db.close);
    await db.initializeCampaign(displayName: 'Vesper');
    final outcome = MoonveilArchiveTrainingOutcome(db);
    expect(await outcome.recordVictoryIfEarned(), isFalse);
    expect(await db.events(), isEmpty);
  });

  test('valid lethal attack records exactly one training victory and no rewards', () async {
    final db = await MoonveilDatabase.open('vesper',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(db.close);
    await db.initializeCampaign(displayName: 'Vesper');
    await db.saveCharacter(characterId: 'vesper-vane', revision: 1,
      state: {'hp': 10, 'maxHp': 10, 'ac': 13});
    await db.appendEvent(eventId: 'lethal-attack', actorId: 'vesper-vane',
      type: 'ARCHIVE_TRAINING_ATTACK',
      payload: {
        'scene': 'forgotten-archive', 'training_only': true,
        'defender_id': 'archive-training-guardian',
        'defender_remaining_hp': 0, 'damage_dealt': 8,
      });
    final outcome = MoonveilArchiveTrainingOutcome(db);
    expect(await outcome.recordVictoryIfEarned(), isTrue);
    expect(await outcome.recordVictoryIfEarned(), isTrue);
    final events = await db.events();
    expect(events.where((e) => e['event_type'] == 'ARCHIVE_TRAINING_VICTORY').length, 1);
    expect((await db.loadCharacter('vesper-vane'))!['hp'], 10);
    expect(await db.db.query('inventory_entries'), isEmpty);
  });
}
