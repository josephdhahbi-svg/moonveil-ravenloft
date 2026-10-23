import 'package:flutter/foundation.dart';
import '../storage/moonveil_database.dart';

/// Read-only local diagnostics. No remote AI or autonomous simulation is implied.
class LumaAutonomousAdminCore {
  static Future<Map<String, dynamic>> executeAutonomousAdminCycle(MoonveilDatabase database) async {
    final checkedAt = DateTime.now().toUtc().toIso8601String();
    try {
      final modeRows = await database.db.rawQuery('PRAGMA journal_mode');
      final mode = modeRows.isEmpty ? 'unknown' : modeRows.first.values.first.toString();
      final timeoutRows = await database.db.rawQuery('PRAGMA busy_timeout');
      final timeout = timeoutRows.isEmpty ? 'unknown' : timeoutRows.first.values.first.toString();
      final events = await database.db.rawQuery(
        'SELECT COUNT(*) AS count FROM vtt_campaign_events WHERE campaign_id = ?',
        [database.campaignId],
      );
      final eventCount = events.first['count'] as int? ?? 0;
      return {
        'status': mode.toLowerCase() == 'wal' ? 'LOCAL_CHECK_OK' : 'LOCAL_CHECK_WARNING',
        'campaign': database.campaignId,
        'journal_mode': mode,
        'busy_timeout_ms': timeout,
        'event_count': eventCount,
        'timestamp': checkedAt,
        'remote_sync': 'NOT_CONFIGURED',
        'npc_simulation': 'NOT_RUN',
        'backup': 'NOT_CREATED',
      };
    } catch (error, stackTrace) {
      debugPrint('[LUMA-01] Local diagnostics failed: $error\\n$stackTrace');
      return {'status': 'ERROR', 'message': error.toString(), 'timestamp': checkedAt};
    }
  }
}
