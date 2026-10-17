class CopilotSyncTelemetry {
  const CopilotSyncTelemetry({
    required this.status,
    required this.copilotStatus,
    required this.activeProtocols,
    required this.databaseMode,
    required this.checkedAt,
  });
  final String status;
  final String copilotStatus;
  final int activeProtocols;
  final String databaseMode;
  final DateTime checkedAt;

  factory CopilotSyncTelemetry.fromMap(Map<String, dynamic> map) => CopilotSyncTelemetry(
    status: map['status']?.toString() ?? 'UNKNOWN',
    copilotStatus: map['copilot_status']?.toString() ?? 'NOT_CONNECTED',
    activeProtocols: (map['active_protocols'] as num?)?.toInt() ?? 0,
    databaseMode: map['database_mode']?.toString() ?? 'UNKNOWN',
    checkedAt: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now().toUtc(),
  );
}
