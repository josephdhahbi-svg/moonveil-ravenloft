import 'package:flutter/material.dart';
import '../models/copilot_sync_telemetry.dart';

/// Ordinary widget; can be placed inside a Stack or a normal layout.
class CopilotSyncHUD extends StatelessWidget {
  const CopilotSyncHUD({super.key, required this.telemetry});
  final CopilotSyncTelemetry telemetry;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF211830),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Copilot connection: NOT CONNECTED', style: TextStyle(color: Colors.amberAccent)),
        Text('Local diagnostics: ${telemetry.status}'),
        Text('Database journal: ${telemetry.databaseMode}'),
        Text('Remote protocols: ${telemetry.activeProtocols}'),
      ]),
    ),
  );
}
