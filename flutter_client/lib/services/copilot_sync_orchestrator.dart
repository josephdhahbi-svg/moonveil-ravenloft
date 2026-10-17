import '../models/copilot_sync_telemetry.dart';
import '../storage/moonveil_database.dart';
import 'copilot_sync_event_bus.dart';

/// Runs a read-only local health check, NOT a remote Copilot sync.
class CopilotSyncOrchestrator {
  CopilotSyncOrchestrator._();
  static final instance = CopilotSyncOrchestrator._();

  Future<CopilotSyncTelemetry> performLocalHealthSweep(MoonveilDatabase database) async {
    String mode = 'UNKNOWN';
    String status = 'LOCAL_CHECK_ERROR';
    try {
      final rows = await database.db.rawQuery('PRAGMA journal_mode');
      mode = rows.isEmpty ? 'UNKNOWN' : rows.first.values.first.toString().toUpperCase();
      status = mode == 'WAL' ? 'LOCAL_CHECK_OK' : 'LOCAL_CHECK_WARNING';
    } catch (_) {
      status = 'LOCAL_CHECK_ERROR';
    }
    final telemetry = CopilotSyncTelemetry(
      status: status, copilotStatus: 'NOT_CONNECTED',
      activeProtocols: 0, databaseMode: mode, checkedAt: DateTime.now().toUtc(),
    );
    CopilotSyncEventBus.instance.dispatch(telemetry);
    return telemetry;
  }
}
