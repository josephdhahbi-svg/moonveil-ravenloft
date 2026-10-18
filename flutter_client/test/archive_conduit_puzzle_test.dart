import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moonveil_client/models/archive_conduit_puzzle.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('conduit requires the correct order and wrong tries are harmless', () {
    expect(ArchiveConduitPuzzle.isSolved(['Moon', 'Weave', 'Star']), isTrue);
    expect(ArchiveConduitPuzzle.isSolved(['Star', 'Weave', 'Moon']), isFalse);
    expect(ArchiveConduitPuzzle.isSolved(['Moon', 'Star']), isFalse);
    expect(ArchiveConduitPuzzle.isValid(['Moon', 'Unknown']), isFalse);
  });

  test('solved conduit survives reopening without altering character or Alice', () async {
    final directory = await Directory.systemTemp.createTemp('moonveil-puzzle-');
    final path = '${directory.path}/vesper.db';
    try {
      var db = await MoonveilDatabase.open('vesper',
          databasePath: path, factory: databaseFactoryFfi);
      await db.initializeCampaign(displayName: 'Vesper Vane');
      final state = <String, dynamic>{
        'name': 'Vesper Vane', 'level': 1, 'hp': 10, 'ac': 13,
      };
      await db.saveCharacter(characterId: 'vesper-vane',
          revision: 1, state: state);
      await db.appendEvent(
        eventId: 'archive-conduit-solved-v1',
        actorId: 'vesper-vane',
        type: 'ARCHIVE_CONDUIT_SOLVED',
        payload: {'sector': 'D', 'link': 2,
          'sequence': ArchiveConduitPuzzle.solution},
      );
      await db.close();

      db = await MoonveilDatabase.open('vesper',
          databasePath: path, factory: databaseFactoryFfi);
      expect((await db.events()).where((event) =>
          event['event_type'] == 'ARCHIVE_CONDUIT_SOLVED').length, 1);
      expect(await db.loadCharacter('vesper-vane'), state);
      await expectLater(db.appendEvent(
        eventId: 'archive-conduit-solved-v1',
        actorId: 'vesper-vane',
        type: 'ARCHIVE_CONDUIT_SOLVED',
        payload: {'sequence': ArchiveConduitPuzzle.solution},
      ), throwsA(isA<DatabaseException>()));
      expect((await db.events()).length, 1);
      await db.close();

      final alice = await MoonveilDatabase.open('alice',
          databasePath: '${directory.path}/alice.db',
          factory: databaseFactoryFfi);
      expect(await alice.events(), isEmpty);
      await alice.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
