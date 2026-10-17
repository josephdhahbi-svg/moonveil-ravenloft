import 'package:flutter/material.dart';
import '../services/admin_sync_bridge_service.dart';
import '../storage/moonveil_database.dart';

/// Local audit viewer with explicitly configured, opt-in remote export.
class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  late final _service = AdminSyncBridgeService(widget.database);
  List<Map<String, Object?>> _logs = [];
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final logs = await _service.fetchAuditLogs();
      if (mounted) setState(() { _logs = logs; _message = null; });
    } catch (e) {
      if (mounted) setState(() => _message = 'Local audit unavailable: $e');
    }
  }

  Future<void> _export() async {
    if (_busy) return;
    final endpoint = Uri.tryParse(_url.text.trim());
    if (endpoint == null || endpoint.scheme != 'https' || _token.text.trim().isEmpty) {
      setState(() => _message = 'Enter a trusted HTTPS URL and an access token.');
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export campaign data?'),
        content: Text('Send the ${widget.database.campaignId} campaign snapshots, events and inventory to ${endpoint.host}? This sends personal game data over the network.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() { _busy = true; _message = null; });
    try {
      await _service.exportSnapshot(endpoint: endpoint, bearerToken: _token.text);
      if (mounted) setState(() => _message = 'Server accepted the export. Remote persistence has not been verified.');
    } catch (e) {
      if (mounted) setState(() => _message = 'Export not confirmed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ListTile(
        leading: Icon(Icons.admin_panel_settings, color: Color(0xFFD7B7FF)),
        title: Text('Multiversal Admin Console'),
        subtitle: Text('Local event audit and optional manual HTTPS export. No server is configured by default.'),
      ),
      TextField(controller: _url, keyboardType: TextInputType.url,
        decoration: const InputDecoration(labelText: 'Trusted HTTPS export endpoint')),
      TextField(controller: _token, obscureText: true, autocorrect: false,
        decoration: const InputDecoration(labelText: 'Access token (not saved)')),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        FilledButton.icon(onPressed: _busy ? null : _export,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: Text(_busy ? 'Exporting…' : 'Export manually')),
        OutlinedButton.icon(onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh), label: const Text('Refresh audit')),
      ]),
      if (_message != null) Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SelectableText(_message!)),
      const SizedBox(height: 12),
      const Text('LOCAL CAMPAIGN EVENT LOG', style: TextStyle(fontWeight: FontWeight.bold)),
      if (_logs.isEmpty) const Padding(
        padding: EdgeInsets.all(12), child: Text('No recorded campaign events')),
      for (final log in _logs)
        Card(child: ListTile(
          leading: const Icon(Icons.history),
          title: Text(log['event_type']?.toString() ?? 'Unknown event'),
          subtitle: Text('Revision ${log['revision']} · ${log['occurred_at']} · Actor: ${log['actor_id']}'),
        )),
    ],
  );
}
