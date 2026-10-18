import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('Archive choices survive reopen without changing snapshot or Alice', () async {
    final factory = databaseFactoryFfi;
    final temp = await Directory.systemTemp.createTemp('moonveil-choice-test-');
    final path = '${temp.path}/vesper.db';
    final vesper = await MoonveilDatabase.open('vesper', databasePath: path, factory: factory);
    await vesper.initializeCampaign(displayName: 'Vesper');
    await vesper.saveCharacter(characterId: 'vesper-vane', revision: 1,
      state: {'hp': 10, 'max_hp': 10, 'checkpoint': 'link-2-sector-d-choice-f'});
    await vesper.appendEvent(eventId: 'choice-1', actorId: 'vesper-vane',
      type: 'FORGOTTEN_ARCHIVE_CHOICE', payload: {'choice': 'Lawful Good'});
    final snapshot = await vesper.loadCharacter('vesper-vane');
    expect(snapshot?['hp'], 10);
    final choices = (await vesper.events()).where(
      (event) => event['event_type'] == 'FORGOTTEN_ARCHIVE_CHOICE').toList();
    expect(jsonDecode(choices.single['payload_json'] as String)['choice'], 'Lawful Good');
    expect(snapshot?['checkpoint'], 'link-2-sector-d-choice-f');
    await vesper.close();
    final reopened = await MoonveilDatabase.open('vesper', databasePath: path, factory: factory);
    expect((await reopened.loadCharacter('vesper-vane'))?['hp'], 10);
    final savedEvents = await reopened.events();
    expect(jsonDecode(savedEvents.single['payload_json'] as String)['choice'], 'Lawful Good');
    await reopened.close();
    await temp.delete(recursive: true);
  });

  test('Training attacks are event-only and never alter saved HP', () async {
    final db = await MoonveilDatabase.open('vesper',
      databasePath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    await db.initializeCampaign(displayName: 'Vesper');
    await db.saveCharacter(characterId: 'vesper-vane', revision: 1,
      state: {'hp': 10, 'max_hp': 10});
    await db.appendEvent(eventId: 'attack-1', actorId: 'vesper-vane',
      type: 'ARCHIVE_TRAINING_ATTACK', payload: {
        'scene': 'forgotten-archive', 'training_only': true,
        'defender_id': 'archive-training-guardian', 'defender_remaining_hp': 3, 'damage_dealt': 5,
      });
    expect((await db.loadCharacter('vesper-vane'))?['hp'], 10);
    expect((await db.events()).length, 1);
    await db.close();
  });
}
