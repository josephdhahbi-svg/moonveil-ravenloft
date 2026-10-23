import '../storage/moonveil_database.dart';

/// Read-only diagnostics against the already-open campaign database.
class MultiversalTelemetryService {
  const MultiversalTelemetryService(this.database);
  final MoonveilDatabase database;

  static const requiredTables = <String>{
    'vtt_campaigns', 'vtt_campaign_members', 'vtt_campaign_events',
    'vtt_revoked_sessions', 'character_snapshots', 'inventory_entries',
    'vtt_schema_migrations',
  };

  Future<Map<String, dynamic>> runDiagnosticAudit() async {
    final timer = Stopwatch()..start();
    final errors = <String>[];
    final report = <String, dynamic>{
      'status': 'CHECKING',
      'campaign_id': database.campaignId,
      'sqlite_wal_active': false,
      'journal_mode': 'unknown',
      'tables_verified': <String>[],
      'missing_tables': <String>[],
      'schema_version': null,
      'foreign_key_enabled': false,
      'foreign_key_violations': 0,
      'quick_check': 'unknown',
      'latency_ms': 0,
      'errors': errors,
    };
    try {
      final db = database.db;
      final journal = await db.rawQuery('PRAGMA journal_mode');
      final mode = journal.isEmpty ? 'unknown' : journal.first.values.first.toString().toLowerCase();
      report['journal_mode'] = mode;
      report['sqlite_wal_active'] = mode == 'wal';
      if (mode != 'wal') errors.add('Journal mode is $mode, not WAL');

      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
      final tables = tableRows.map((row) => row['name'].toString()).toList();
      report['tables_verified'] = tables;
      final missing = requiredTables.difference(tables.toSet()).toList()..sort();
      report['missing_tables'] = missing;
      if (missing.isNotEmpty) errors.add('Missing required tables: ${missing.join(', ')}');

      final versionRows = await db.rawQuery('PRAGMA user_version');
      final version = versionRows.isEmpty ? null : versionRows.first.values.first;
      report['schema_version'] = version;
      if (version != 3) errors.add('Expected schema version 3, found $version');

      final fkRows = await db.rawQuery('PRAGMA foreign_keys');
      final enabled = fkRows.isNotEmpty && fkRows.first.values.first == 1;
      report['foreign_key_enabled'] = enabled;
      if (!enabled) errors.add('Foreign-key enforcement is disabled');

      final violations = await db.rawQuery('PRAGMA foreign_key_check');
      report['foreign_key_violations'] = violations.length;
      if (violations.isNotEmpty) errors.add('${violations.length} foreign-key violations');

      final checkRows = await db.rawQuery('PRAGMA quick_check');
      final check = checkRows.isEmpty ? 'no result' : checkRows.first.values.first.toString();
      report['quick_check'] = check;
      if (check.toLowerCase() != 'ok') errors.add('SQLite quick_check: $check');

      report['status'] = errors.isEmpty ? 'HEALTHY' : 'WARNING';
    } catch (e) {
      errors.add('Diagnostic query failed: $e');
      report['status'] = 'CRITICAL_ERROR';
    } finally {
      timer.stop();
      report['latency_ms'] = timer.elapsedMilliseconds;
    }
    return report;
  }

  Future<String> generateMarkdownReport() async {
    final audit = await runDiagnosticAudit();
    final errors = audit['errors'] as List<String>;
    return '''
# Moonveil Local Database Diagnostic
- Time (UTC): ${DateTime.now().toUtc().toIso8601String()}
- Campaign: ${audit['campaign_id']}
- Status: ${audit['status']}
- SQLite journal mode: ${audit['journal_mode']}
- Schema version: ${audit['schema_version']}
- Foreign keys enabled: ${audit['foreign_key_enabled']}
- Foreign-key violations: ${audit['foreign_key_violations']}
- SQLite quick_check: ${audit['quick_check']}
- Query duration: ${audit['latency_ms']} ms
- Tables: ${(audit['tables_verified'] as List).join(', ')}
- Missing tables: ${(audit['missing_tables'] as List).join(', ')}
- Errors: ${errors.isEmpty ? 'None detected by these checks' : errors.join('; ')}
''';
  }
}
