import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('observatory discovery persists without modifying Vesper or Alice', () async {
    final dir = await Directory.systemTemp.createTemp('moonveil-observatory-');
    try {
      final path = '${dir.path}/vesper.db';
      var db = await MoonveilDatabase.open('vesper',
        databasePath: path, factory: databaseFactoryFfi);
      await db.initializeCampaign(displayName: 'Vesper Vane');
      final state = <String, dynamic>{
        'name': 'Vesper Vane', 'level': 1, 'hp': 10, 'ac': 13,
      };
      await db.saveCharacter(characterId: 'vesper-vane',
        revision: 1, state: state);
      await db.appendEvent(eventId: 'archive-conduit-solved-v1',
        actorId: 'vesper-vane', type: 'ARCHIVE_CONDUIT_SOLVED',
        payload: {'sector': 'D', 'link': 2});
      await db.appendEvent(eventId: 'archive-observatory-discovered-v1',
        actorId: 'vesper-vane', type: 'ARCHIVE_OBSERVATORY_DISCOVERED',
        payload: {'sector': 'D', 'link': 2, 'location': 'archive-observatory'});
      await db.close();

      db = await MoonveilDatabase.open('vesper',
        databasePath: path, factory: databaseFactoryFfi);
      final events = await db.events();
      expect(events.map((e) => e['event_type']), contains('ARCHIVE_OBSERVATORY_DISCOVERED'));
      expect(await db.loadCharacter('vesper-vane'), state);
      await expectLater(db.appendEvent(
        eventId: 'archive-observatory-discovered-v1',
        actorId: 'vesper-vane', type: 'ARCHIVE_OBSERVATORY_DISCOVERED',
        payload: {}), throwsA(isA<DatabaseException>()));
      expect((await db.events()).length, 2);
      await db.close();

      final alice = await MoonveilDatabase.open('alice',
        databasePath: '${dir.path}/alice.db', factory: databaseFactoryFfi);
      expect(await alice.events(), isEmpty);
      await alice.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
