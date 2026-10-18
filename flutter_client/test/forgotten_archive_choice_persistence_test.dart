import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('moonveil-choice-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<MoonveilDatabase> open(String campaign) =>
      MoonveilDatabase.open(campaign,
          databasePath: '${directory.path}/$campaign.db',
          factory: databaseFactoryFfi);

  test('five archive choices persist in order after database reopen', () async {
    final storage = await open('vesper');
    await storage.initializeCampaign(displayName: 'Vesper Vane');
    const choices = ['Lawful Good', 'Neutral Good', 'Chaotic Good', 'Utility', 'Action'];
    for (var i = 0; i < choices.length; i++) {
      await storage.appendEvent(
        eventId: 'archive-choice-test-$i',
        actorId: 'vesper-vane',
        type: 'FORGOTTEN_ARCHIVE_CHOICE',
        payload: {
          'scene': 'forgotten-netherese-barovian-archive',
          'sector': 'D',
          'link': 2,
          'choice': choices[i],
        },
      );
    }
    await storage.close();

    final reopened = await open('vesper');
    try {
      final events = (await reopened.events())
          .where((row) => row['event_type'] == 'FORGOTTEN_ARCHIVE_CHOICE')
          .toList();
      expect(events.length, 5);
      expect(events.map((row) =>
          (jsonDecode(row['payload_json'] as String) as Map<String, dynamic>)['choice']),
          choices);
      expect(events.map((row) => row['revision']), [1, 2, 3, 4, 5]);
    } finally {
      await reopened.close();
    }
  });

  test('archive events cannot overwrite character snapshot or Alice campaign', () async {
    final vesper = await open('vesper');
    final alice = await open('alice');
    try {
      await vesper.initializeCampaign(displayName: 'Vesper Vane');
      await alice.initializeCampaign(displayName: 'Alice');
      final state = <String, dynamic>{
        'name': 'Vesper Vane', 'level': 1, 'hp': 10, 'ac': 13,
        'location': 'Forgotten Netherese-Barovian Archive',
      };
      await vesper.saveCharacter(
        characterId: 'vesper-vane', revision: 1, state: state);
      await vesper.appendEvent(
        eventId: 'archive-choice-isolation',
        actorId: 'vesper-vane',
        type: 'FORGOTTEN_ARCHIVE_CHOICE',
        payload: {'choice': 'Utility', 'sector': 'D', 'link': 2},
      );
      expect(await vesper.loadCharacter('vesper-vane'), state);
      expect(await alice.loadCharacter('vesper-vane'), isNull);
      expect(await alice.events(), isEmpty);
      await expectLater(
        vesper.appendEvent(
          eventId: 'archive-choice-isolation',
          actorId: 'vesper-vane',
          type: 'FORGOTTEN_ARCHIVE_CHOICE',
          payload: {'choice': 'Action'},
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect((await vesper.events()).length, 1);
    } finally {
      await vesper.close();
      await alice.close();
    }
  });
}
