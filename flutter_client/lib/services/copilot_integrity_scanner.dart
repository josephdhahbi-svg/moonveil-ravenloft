import '../storage/moonveil_database.dart';

/// Read-only SQLite checks; does not pretend to verify compilation or image quality.
class CopilotIntegrityScanner {
  CopilotIntegrityScanner(this.database);
  final MoonveilDatabase database;

  Future<Map<String, dynamic>> runIntegrityScan() async {
    final checkedAt = DateTime.now().toUtc().toIso8601String();
    try {
      final integrity = await database.db.rawQuery('PRAGMA quick_check');
      final mode = await database.db.rawQuery('PRAGMA journal_mode');
      final check = integrity.isEmpty ? 'UNKNOWN' : integrity.first.values.first.toString();
      final journal = mode.isEmpty ? 'UNKNOWN' : mode.first.values.first.toString().toUpperCase();
      return {
        'status': check == 'ok' && journal == 'WAL' ? 'LOCAL_CHECK_OK' : 'LOCAL_CHECK_WARNING',
        'sqlite_quick_check': check,
        'database_mode': journal,
        'modules_ok': 'NOT_TESTED',
        'assets_ok': 'NOT_TESTED',
        'photorealism_ok': 'NOT_TESTED',
        'timestamp': checkedAt,
      };
    } catch (error) {
      return {'status': 'ERROR', 'message': error.toString(), 'timestamp': checkedAt};
    }
  }
}
