import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';
import 'moonveil_database.dart';

/// Password-encrypted logical backup. Export is read-only and WAL-safe.
/// Restore is atomic and refuses to overwrite an existing campaign.
class MoonveilBackup {
  static const format = 'moonveil-logical-backup-v1';
  static const iterations = 210000;
  static final _cipher = AesGcm.with256bits();

  static Uint8List _random(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  static Future<SecretKey> _derive(String password, List<int> salt) async {
    if (password.length < 12) throw ArgumentError('Use a password of at least 12 characters');
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    return kdf.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  static Future<Uint8List> exportEncrypted(MoonveilDatabase storage, String password) async {
    final db = storage.db;
    final payload = await db.transaction((txn) async {
      Future<List<Map<String, Object?>>> rows(String table) => txn.query(table);
      return <String, Object?>{
        'format': format,
        'campaign_id': storage.campaignId,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'tables': {
          'vtt_campaigns': await rows('vtt_campaigns'),
          'vtt_campaign_members': await rows('vtt_campaign_members'),
          'vtt_campaign_events': await rows('vtt_campaign_events'),
          'character_snapshots': await rows('character_snapshots'),
          'inventory_entries': await rows('inventory_entries'),
        }
      };
    }, exclusive: false);
    final salt = _random(16);
    final nonce = _random(12);
    final key = await _derive(password, salt);
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)), secretKey: key, nonce: nonce,
      aad: utf8.encode(format),
    );
    return Uint8List.fromList(utf8.encode(jsonEncode({
      'format': format, 'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': iterations, 'salt': base64Encode(salt),
      'nonce': base64Encode(nonce), 'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    })));
  }

  /// Decrypts and validates metadata without modifying any database.
  static Future<Map<String, dynamic>> inspectEncrypted(
    Uint8List bytes, String password, {required String expectedCampaign}
  ) async {
    if (bytes.length > 50 * 1024 * 1024) throw FormatException('Backup too large');
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (envelope['format'] != format ||
        envelope['kdf'] != 'PBKDF2-HMAC-SHA256' ||
        envelope['iterations'] != iterations) {
      throw FormatException('Unsupported backup format');
    }
    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['nonce'] as String);
    if (salt.length != 16 || nonce.length != 12) throw FormatException('Invalid encryption parameters');
    final key = await _derive(password, salt);
    final plaintext = await _cipher.decrypt(
      SecretBox(base64Decode(envelope['ciphertext'] as String),
        nonce: nonce, mac: Mac(base64Decode(envelope['mac'] as String))),
      secretKey: key, aad: utf8.encode(format),
    );
    final data = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    if (data['format'] != format || data['campaign_id'] != expectedCampaign) {
      throw FormatException('Campaign mismatch or invalid payload');
    }
    final tables = data['tables'];
    if (tables is! Map<String, dynamic> ||
        !['vtt_campaigns','vtt_campaign_members','vtt_campaign_events',
          'character_snapshots','inventory_entries'].every((k) => tables[k] is List)) {
      throw FormatException('Missing backup tables');
    }
    return data;
  }
  /// Restore only into an EMPTY campaign database. A failed insert rolls back
  /// all rows. The caller must verify a separate encrypted backup of any
  /// existing save before replacing it; this method never deletes live data.
  static Future<void> restoreIntoEmpty(
    MoonveilDatabase storage, Uint8List bytes, String password,
  ) async {
    final data = await inspectEncrypted(
      bytes, password, expectedCampaign: storage.campaignId,
    );
    final rawTables = data['tables'] as Map<String, dynamic>;
    const names = [
      'vtt_campaigns', 'vtt_campaign_members', 'vtt_campaign_events',
      'character_snapshots', 'inventory_entries'
    ];
    final parsed = <String, List<Map<String, Object?>>>{};
    for (final name in names) {
      final rows = rawTables[name] as List;
      if (rows.length > 100000) throw FormatException('Too many rows');
      parsed[name] = rows.map((row) {
        if (row is! Map<String, dynamic>) throw FormatException('Invalid row');
        if (row['campaign_id'] != storage.campaignId) {
          throw FormatException('Cross-campaign row in backup');
        }
        return Map<String, Object?>.from(row);
      }).toList();
    }
    if (parsed['vtt_campaigns']!.length != 1) {
      throw FormatException('Expected exactly one campaign');
    }
    const columns = <String, Set<String>>{
      'vtt_campaigns': {'campaign_id','name','created_at'},
      'vtt_campaign_members': {'campaign_id','actor_id','role'},
      'vtt_campaign_events': {'campaign_id','revision','event_id','actor_id','event_type','payload_json','occurred_at'},
      'character_snapshots': {'campaign_id','character_id','revision','state_json','updated_at'},
      'inventory_entries': {'campaign_id','character_id','item_id','item_json','owned','attuned'},
    };
    for (final name in names) {
      for (final row in parsed[name]!) {
        if (row.keys.toSet().difference(columns[name]!).isNotEmpty ||
            !columns[name]!.containsAll(row.keys)) {
          throw FormatException('Unexpected or missing columns in $name');
        }
      }
    }
    await storage.db.transaction((txn) async {
      final existing = await txn.rawQuery(
        'SELECT (SELECT COUNT(*) FROM vtt_campaigns) + '
        '(SELECT COUNT(*) FROM vtt_campaign_events) + '
        '(SELECT COUNT(*) FROM character_snapshots) + '
        '(SELECT COUNT(*) FROM inventory_entries) AS total'
      );
      if ((existing.first['total'] as int) != 0) {
        throw StateError('Restore refused: destination is not empty');
      }
      for (final name in names) {
        for (final row in parsed[name]!) {
          await txn.insert(name, row, conflictAlgorithm: ConflictAlgorithm.abort);
        }
      }
      final check = await txn.rawQuery('PRAGMA foreign_key_check');
      if (check.isNotEmpty) throw StateError('Backup foreign key validation failed');
    });
  }

}
