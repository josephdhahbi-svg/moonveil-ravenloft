import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';
import 'package:moonveil_client/services/moonveil_archive_quest_service.dart';

void main() {
  sqfliteFfiInit();
  test('quest objectives require a saved choice, remain idempotent and do not change snapshots', () async {
    final db = await MoonveilDatabase.open('vesper',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(db.close);
    await db.initializeCampaign(displayName: 'Vesper');
    await db.saveCharacter(characterId: 'vesper-vane', revision: 1,
      state: {'hp': 10, 'maxHp': 10, 'ac': 13});
    final service = MoonveilArchiveQuestService(db);
    await expectLater(service.completeObjective('seal_studied'), throwsStateError);
    await db.appendEvent(eventId: 'choice-one', actorId: 'vesper-vane',
      type: 'FORGOTTEN_ARCHIVE_CHOICE',
      payload: {'scene': MoonveilArchiveQuestService.sceneId, 'choice': 'Utility'});
    expect(await service.lastChoice(), 'Utility');
    await service.completeObjective('seal_studied');
    await service.completeObjective('seal_studied');
    expect(await service.completedObjectives(), {'seal_studied'});
    expect((await db.events()).length, 2);
    expect((await db.loadCharacter('vesper-vane'))!['hp'], 10);
    expect(await db.db.query('inventory_entries'), isEmpty);
  });

  test('quest objectives never cross campaign boundaries', () async {
    final vesper = await MoonveilDatabase.open('vesper',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    final alice = await MoonveilDatabase.open('alice',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(vesper.close);
    addTearDown(alice.close);
    await vesper.initializeCampaign(displayName: 'Vesper');
    await alice.initializeCampaign(displayName: 'Alice');
    await vesper.appendEvent(eventId: 'choice', actorId: 'vesper-vane',
      type: 'FORGOTTEN_ARCHIVE_CHOICE',
      payload: {'scene': MoonveilArchiveQuestService.sceneId, 'choice': 'Action'});
    await MoonveilArchiveQuestService(vesper).completeObjective('guardian_repelled');
    expect(await MoonveilArchiveQuestService(alice).completedObjectives(), isEmpty);
  });
}
