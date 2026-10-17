import 'package:flutter/material.dart';
import '../services/multiversal_telemetry_service.dart';
import '../storage/moonveil_database.dart';

class AdminTelemetryScreen extends StatefulWidget {
  const AdminTelemetryScreen({super.key, required this.database});
  final MoonveilDatabase database;

  @override
  State<AdminTelemetryScreen> createState() => _AdminTelemetryScreenState();
}

class _AdminTelemetryScreenState extends State<AdminTelemetryScreen> {
  bool _running = false;
  Map<String, dynamic>? _audit;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    if (_running) return;
    setState(() => _running = true);
    final result = await MultiversalTelemetryService(widget.database).runDiagnosticAudit();
    if (!mounted) return;
    setState(() {
      _audit = result;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audit = _audit;
    final status = audit?['status']?.toString() ?? 'Not scanned';
    final healthy = status == 'HEALTHY';
    return Card(
      color: const Color(0xFF191426),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.monitor_heart_outlined, color: Colors.amber),
            title: const Text('Local SQLite Diagnostics'),
            subtitle: const Text('Read-only WAL, schema and integrity checks'),
            trailing: IconButton(
              tooltip: 'Re-scan',
              onPressed: _running ? null : _scan,
              icon: _running
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            ),
          ),
          Text('Status: $status', style: TextStyle(
            color: healthy ? Colors.greenAccent : Colors.amberAccent,
            fontWeight: FontWeight.bold)),
          if (audit != null) ...[
            _metric('Journal mode', audit['journal_mode']),
            _metric('Schema version', audit['schema_version']),
            _metric('Foreign keys enabled', audit['foreign_key_enabled']),
            _metric('Foreign-key violations', audit['foreign_key_violations']),
            _metric('SQLite quick_check', audit['quick_check']),
            _metric('Diagnostic duration', "${audit['latency_ms']} ms"),
            _metric('Verified tables', (audit['tables_verified'] as List).join(', ')),
            if ((audit['errors'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final error in audit['errors'] as List)
                Text('• $error', style: const TextStyle(color: Colors.orangeAccent)),
            ],
          ],
        ]),
      ),
    );
  }

  Widget _metric(String label, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('$label: ${value ?? 'unknown'}', softWrap: true),
  );
}
