import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';
import 'package:moonveil_client/storage/moonveil_backup.dart';
import 'package:moonveil_client/storage/vesper_checkpoint_import.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory directory;
  Future<MoonveilDatabase> open(String name, String campaign) =>
      MoonveilDatabase.open(campaign,
          databasePath: '${directory.path}/$name.db',
          factory: databaseFactoryFfi);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('moonveil-integration-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  final checkpoint = utf8.encode(jsonEncode({
    'campaign_id': 'vesper',
    'character_id': 'vesper-vane',
    'revision': 2,
    'state': {
      'name': 'Vesper Vane',
      'level': 1,
      'source': 'synthetic test fixture only',
    },
    'inventory': [
      {
        'item_id': 'test-codex',
        'item': {'name': 'Synthetic Test Codex'},
        'owned': true,
        'attuned': false,
      }
    ]
  }));

  test('production initializer creates v1-v3 schema and enables WAL', () async {
    final storage = await open('schema', 'vesper');
    try {
      final mode = await storage.db.rawQuery('PRAGMA journal_mode');
      expect(mode.first.values.first.toString().toLowerCase(), 'wal');
      final versions = await storage.db.query('vtt_schema_migrations',
          orderBy: 'version ASC');
      expect(versions.map((row) => row['version']).toList(), [1, 2, 3]);
      final names = (await storage.db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table'"))
          .map((row) => row['name']).toSet();
      expect(names, containsAll([
        'vtt_campaigns', 'vtt_campaign_members', 'vtt_campaign_events',
        'vtt_revoked_sessions', 'character_snapshots', 'inventory_entries',
      ]));
    } finally {
      await storage.close();
    }
  });

  test('checkpoint import is atomic and refuses replacement', () async {
    final storage = await open('import', 'vesper');
    try {
      await VesperCheckpointImport.importJson(
          storage, Uint8List.fromList(checkpoint));
      final state = await storage.loadCharacter('vesper-vane');
      expect(state?['source'], 'synthetic test fixture only');
      expect((await storage.db.query('inventory_entries')).length, 1);
      await expectLater(
          VesperCheckpointImport.importJson(
              storage, Uint8List.fromList(checkpoint)),
          throwsA(isA<StateError>()));
      expect((await storage.db.query('inventory_entries')).length, 1);
    } finally {
      await storage.close();
    }
  });

  test('invalid checkpoint rolls back without partial campaign', () async {
    final storage = await open('bad-import', 'vesper');
    try {
      final bad = jsonDecode(utf8.decode(checkpoint)) as Map<String, dynamic>;
      (bad['inventory'] as List).add({
        'item_id': 'test-codex',
        'item': {'name': 'Duplicate'},
        'owned': true,
        'attuned': false,
      });
      await expectLater(
          VesperCheckpointImport.importJson(
              storage, Uint8List.fromList(utf8.encode(jsonEncode(bad)))),
          throwsA(isA<DatabaseException>()));
      expect(await storage.db.query('vtt_campaigns'), isEmpty);
      expect(await storage.db.query('character_snapshots'), isEmpty);
    } finally {
      await storage.close();
    }
  });

  test('encrypted backup round-trip restores to empty database', () async {
    final source = await open('source', 'vesper');
    final target = await open('target', 'vesper');
    try {
      await VesperCheckpointImport.importJson(
          source, Uint8List.fromList(checkpoint));
      final encrypted = await MoonveilBackup.exportEncrypted(
          source, 'long-test-password-1234');
      expect(utf8.decode(encrypted), isNot(contains('Synthetic Test Codex')));
      final inspected = await MoonveilBackup.inspectEncrypted(
          encrypted, 'long-test-password-1234', expectedCampaign: 'vesper');
      expect(inspected['campaign_id'], 'vesper');
      await MoonveilBackup.restoreIntoEmpty(
          target, encrypted, 'long-test-password-1234');
      expect((await target.loadCharacter('vesper-vane'))?['name'],
          'Vesper Vane');
      expect((await target.db.query('inventory_entries')).length, 1);
      await expectLater(
          MoonveilBackup.restoreIntoEmpty(
              target, encrypted, 'long-test-password-1234'),
          throwsA(isA<StateError>()));
    } finally {
      await source.close();
      await target.close();
    }
  });

  test('wrong password, tampering and wrong campaign preserve target', () async {
    final source = await open('protected-source', 'vesper');
    final target = await open('protected-target', 'vesper');
    try {
      await VesperCheckpointImport.importJson(
          source, Uint8List.fromList(checkpoint));
      final encrypted = await MoonveilBackup.exportEncrypted(
          source, 'long-test-password-1234');
      await expectLater(
          MoonveilBackup.restoreIntoEmpty(
              target, encrypted, 'incorrect-password-123'),
          throwsA(anything));
      await expectLater(
          MoonveilBackup.inspectEncrypted(encrypted, 'long-test-password-1234',
              expectedCampaign: 'alice'),
          throwsA(isA<FormatException>()));
      final envelope = jsonDecode(utf8.decode(encrypted))
          as Map<String, dynamic>;
      final cipher = base64Decode(envelope['ciphertext'] as String);
      cipher[0] ^= 1;
      envelope['ciphertext'] = base64Encode(cipher);
      await expectLater(
          MoonveilBackup.restoreIntoEmpty(target,
              Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
              'long-test-password-1234'),
          throwsA(anything));
      expect(await target.db.query('vtt_campaigns'), isEmpty);
      expect(await target.db.query('inventory_entries'), isEmpty);
    } finally {
      await source.close();
      await target.close();
    }
  });
}
