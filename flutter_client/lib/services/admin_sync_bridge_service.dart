import 'dart:convert';
import 'dart:io';
import '../storage/moonveil_database.dart';

/// Explicit, opt-in outbound export. This is NOT a bidirectional sync engine.
/// The server must implement and authenticate this endpoint separately.
class AdminSyncBridgeService {
  const AdminSyncBridgeService(this.database);
  final MoonveilDatabase database;

  Future<List<Map<String, Object?>>> fetchAuditLogs({int limit = 100}) async {
    return database.db.query('vtt_campaign_events',
      columns: ['revision', 'occurred_at', 'event_type', 'actor_id'],
      where: 'campaign_id = ?', whereArgs: [database.campaignId],
      orderBy: 'revision DESC', limit: limit);
  }

  /// A successful HTTP response confirms receipt only, not remote durability.
  /// No request is made without a caller-supplied HTTPS endpoint and credential.
  Future<void> exportSnapshot({
    required Uri endpoint,
    required String bearerToken,
  }) async {
    if (endpoint.scheme != 'https' || endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty || endpoint.hasFragment) {
      throw ArgumentError('An explicit HTTPS endpoint is required');
    }
    if (bearerToken.trim().isEmpty) {
      throw ArgumentError('Authentication token required');
    }
    final snapshots = await database.db.query('character_snapshots',
      where: 'campaign_id = ?', whereArgs: [database.campaignId]);
    if (snapshots.isEmpty) throw StateError('No verified character checkpoint to export');
    final events = await database.events();
    final inventory = await database.db.query('inventory_entries',
      where: 'campaign_id = ?', whereArgs: [database.campaignId]);
    final payload = jsonEncode({
      'protocol': 'moonveil-snapshot-export-v1',
      'campaign_id': database.campaignId,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'snapshots': snapshots,
      'events': events,
      'inventory': inventory,
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(endpoint).timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      request.add(utf8.encode(payload));
      final response = await request.close().timeout(const Duration(seconds: 20));
      // Drain response without storing potentially sensitive server output.
      await response.drain<void>().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Server rejected export (HTTP ${response.statusCode})');
      }
    } finally {
      client.close(force: true);
    }
  }
}
