import 'package:flutter/material.dart';
import '../models/copilot_sync_telemetry.dart';
import '../services/copilot_sync_orchestrator.dart';
import '../storage/moonveil_database.dart';
import '../widgets/copilot_sync_hud.dart';

class CopilotSyncDashboardScreen extends StatefulWidget {
  const CopilotSyncDashboardScreen({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<CopilotSyncDashboardScreen> createState() => _CopilotSyncDashboardScreenState();
}

class _CopilotSyncDashboardScreenState extends State<CopilotSyncDashboardScreen> {
  CopilotSyncTelemetry? telemetry;
  bool checking = false;

  Future<void> check() async {
    setState(() => checking = true);
    final result = await CopilotSyncOrchestrator.instance.performLocalHealthSweep(widget.database);
    if (!mounted) return;
    setState(() { telemetry = result; checking = false; });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Copilot Diagnostics', style: Theme.of(context).textTheme.titleLarge),
      const Text('Copilot is not connected. This checks local SQLite WAL mode only. No save data is uploaded or changed.'),
      ElevatedButton(onPressed: checking ? null : check, child: Text(checking ? 'Checking...' : 'Check local storage')),
      if (telemetry != null) CopilotSyncHUD(telemetry: telemetry!),
    ],
  );
}
