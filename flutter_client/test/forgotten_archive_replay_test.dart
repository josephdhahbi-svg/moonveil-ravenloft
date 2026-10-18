import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/forgotten_archive_replay.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('Replay restores guardian after reopen and never changes Vesper HP', () async {
    final dir = await Directory.systemTemp.createTemp('archive-replay-');
    final path = '${dir.path}/vesper.db';
    var db = await MoonveilDatabase.open('vesper', databasePath: path, factory: databaseFactoryFfi);
    await db.initializeCampaign(displayName: 'Vesper');
    await db.saveCharacter(characterId: 'vesper-vane', revision: 1,
      state: {'hp': 10, 'max_hp': 10});
    await db.appendEvent(eventId: 'archive-1', actorId: 'vesper-vane',
      type: 'ARCHIVE_TRAINING_ATTACK', payload: {
        'scene': 'forgotten-archive', 'training_only': true,
        'defender_id': ForgottenArchiveReplay.guardianId,
        'defender_remaining_hp': 5,
      });
    await db.close();
    db = await MoonveilDatabase.open('vesper', databasePath: path, factory: databaseFactoryFfi);
    expect(await ForgottenArchiveReplay.restoreGuardianHp(db), 5);
    expect((await db.loadCharacter('vesper-vane'))?['hp'], 10);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('Replay rejects impossible healing without an explicit reset', () async {
    final db = await MoonveilDatabase.open('vesper',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    await db.initializeCampaign(displayName: 'Vesper');
    for (final (id, hp) in [('one', 2), ('two', 8)]) {
      await db.appendEvent(eventId: id, actorId: 'vesper-vane',
        type: 'ARCHIVE_TRAINING_ATTACK', payload: {
          'scene': 'forgotten-archive', 'training_only': true,
          'defender_id': ForgottenArchiveReplay.guardianId,
          'defender_remaining_hp': hp,
        });
    }
    await expectLater(ForgottenArchiveReplay.restoreGuardianHp(db), throwsStateError);
    await db.close();
  });

  test('Alice campaign cannot replay Vesper guardian', () async {
    final alice = await MoonveilDatabase.open('alice',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    await alice.initializeCampaign(displayName: 'Alice');
    await expectLater(ForgottenArchiveReplay.restoreGuardianHp(alice), throwsStateError);
    await alice.close();
  });
}
