import 'package:flutter/material.dart';
import '../storage/moonveil_database.dart';
import '../services/admin_sync_bridge_service.dart';

/// Honest manual export control. Not a ChatGPT memory bridge or cloud sync.
class AdminPersistentSyncScreen extends StatefulWidget {
  const AdminPersistentSyncScreen({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<AdminPersistentSyncScreen> createState() => _AdminPersistentSyncScreenState();
}

class _AdminPersistentSyncScreenState extends State<AdminPersistentSyncScreen> {
  final _endpoint = TextEditingController();
  final _token = TextEditingController();
  bool _busy = false;
  String _status = 'No remote server configured. Local saves remain on this device.';

  Future<void> _export() async {
    final url = Uri.tryParse(_endpoint.text.trim());
    if (url == null || url.scheme != 'https' || url.host.isEmpty ||
        _token.text.trim().isEmpty) {
      setState(() => _status = 'Provide a trusted HTTPS endpoint and access token.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export campaign snapshot?'),
        content: Text('Send local ${widget.database.campaignId} campaign data to ${url.host}? This is a one-way export, not cloud synchronization.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Export')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _status = 'Sending snapshot…'; });
    try {
      await AdminSyncBridgeService(widget.database).exportSnapshot(
        endpoint: url, bearerToken: _token.text.trim());
      if (mounted) setState(() => _status = 'Server accepted the export. Durable cloud storage is not verified.');
    } catch (error) {
      if (mounted) setState(() => _status = 'Export failed or unconfirmed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const ListTile(
          leading: Icon(Icons.cloud_upload_outlined),
          title: Text('Manual Snapshot Export'),
          subtitle: Text('Optional HTTPS transfer; no ChatGPT memory connection or automatic sync.'),
        ),
        TextField(controller: _endpoint, decoration: const InputDecoration(labelText: 'Trusted HTTPS endpoint')),
        TextField(controller: _token, obscureText: true, decoration: const InputDecoration(labelText: 'Access token (not stored)')),
        const SizedBox(height: 8),
        FilledButton(onPressed: _busy ? null : _export,
          child: Text(_busy ? 'Exporting…' : 'Export snapshot')),
        Text(_status),
      ]),
    ),
  );
}
