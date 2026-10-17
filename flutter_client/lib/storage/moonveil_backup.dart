import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';
import 'moonveil_database.dart';

/// Password-encrypted logical backup. Export is read-only and WAL-safe.
/// Restore is intentionally *not* implemented until a staging/rollback test exists.
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
}
