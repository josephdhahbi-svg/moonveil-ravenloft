import 'package:flutter/material.dart';
import '../storage/moonveil_database.dart';
import '../services/copilot_build_timeline_service.dart';
import '../services/copilot_integrity_scanner.dart';

class CopilotBuildTimelineScreen extends StatefulWidget {
  const CopilotBuildTimelineScreen({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<CopilotBuildTimelineScreen> createState() => _CopilotBuildTimelineScreenState();
}

class _CopilotBuildTimelineScreenState extends State<CopilotBuildTimelineScreen> {
  late Future<List<Map<String, Object?>>> timeline;
  bool checking = false;
  String? error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    timeline = CopilotBuildTimelineService(widget.database).loadTimeline();
  }

  Future<void> scan() async {
    setState(() { checking = true; error = null; });
    try {
      final result = await CopilotIntegrityScanner(widget.database).runIntegrityScan();
      await CopilotBuildTimelineService(widget.database).logBuildEvent(result);
      if (!mounted) return;
      setState(reload);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Local Build & Integrity Timeline', style: Theme.of(context).textTheme.titleLarge),
      const Text('Records local diagnostics only. Does not run Flutter builds or Copilot jobs.'),
      ElevatedButton(onPressed: checking ? null : scan,
        child: Text(checking ? 'Checking SQLite...' : 'Run local SQLite integrity check')),
      if (error != null) Text('Error: $error'),
      FutureBuilder<List<Map<String, Object?>>>(
        future: timeline,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Timeline error: ${snapshot.error}');
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty) return const Text('No diagnostic events recorded yet.');
          return Column(children: [
            for (final event in snapshot.data!)
              Card(child: ListTile(
                title: Text(event['status']?.toString() ?? 'UNKNOWN'),
                subtitle: Text('${event['timestamp']}  •  SQLite: ${event['database_mode'] ?? 'unknown'}'),
              )),
          ]);
        },
      ),
    ],
  );
}
