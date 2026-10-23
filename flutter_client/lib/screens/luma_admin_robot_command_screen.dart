import 'package:flutter/material.dart';
import '../services/luma_autonomous_admin_core.dart';
import '../storage/moonveil_database.dart';

class LumaAdminRobotCommandScreen extends StatefulWidget {
  const LumaAdminRobotCommandScreen({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<LumaAdminRobotCommandScreen> createState() => _LumaAdminRobotCommandScreenState();
}

class _LumaAdminRobotCommandScreenState extends State<LumaAdminRobotCommandScreen> {
  bool running = false;
  Map<String, dynamic>? telemetry;

  Future<void> runSweep() async {
    setState(() => running = true);
    final result = await LumaAutonomousAdminCore.executeAutonomousAdminCycle(widget.database);
    if (!mounted) return;
    setState(() { telemetry = result; running = false; });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('LUMA-01 · Local Administration Diagnostics',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Read-only database check. No AI relay, backup, NPC tick, or cloud sync is performed.'),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: running ? null : runSweep,
        icon: running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.smart_toy_outlined),
        label: Text(running ? 'Checking local database...' : 'Run local diagnostics'),
      ),
      const SizedBox(height: 12),
      if (telemetry != null)
        for (final entry in telemetry!.entries)
          Card(child: ListTile(
            title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
            subtitle: Text(entry.value.toString()),
          )),
    ],
  );
}
