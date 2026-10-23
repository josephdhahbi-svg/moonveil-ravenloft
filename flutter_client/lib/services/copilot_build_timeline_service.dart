import '../storage/moonveil_database.dart';

/// Local, append-only developer event history. Not a CI/CD server.
class CopilotBuildTimelineService {
  CopilotBuildTimelineService(this.database);
  final MoonveilDatabase database;

  Future<void> _ensureTable() async {
    await database.db.execute('''
      CREATE TABLE IF NOT EXISTS local_build_timeline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campaign_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        build_version TEXT,
        verified_modules INTEGER,
        media_categories INTEGER,
        database_mode TEXT
      )
    ''');
  }

  Future<void> logBuildEvent(Map<String, dynamic> metrics) async {
    await _ensureTable();
    await database.db.insert('local_build_timeline', {
      'campaign_id': database.campaignId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'status': metrics['status']?.toString() ?? 'UNKNOWN',
      'build_version': metrics['build_version']?.toString(),
      'verified_modules': metrics['verified_modules'] is int ? metrics['verified_modules'] : null,
      'media_categories': metrics['media_categories'] is int ? metrics['media_categories'] : null,
      'database_mode': metrics['database_mode']?.toString(),
    });
  }

  Future<List<Map<String, Object?>>> loadTimeline() async {
    await _ensureTable();
    return database.db.query('local_build_timeline',
      where: 'campaign_id = ?', whereArgs: [database.campaignId],
      orderBy: 'id DESC', limit: 200);
  }
}
