import 'package:flutter/material.dart';
import '../storage/moonveil_database.dart';

/// Read-only discovery until the conduit is solved; discoveries are append-only.
class ArchiveObservatoryPanel extends StatefulWidget {
  const ArchiveObservatoryPanel({super.key, required this.database});
  final MoonveilDatabase database;

  @override
  State<ArchiveObservatoryPanel> createState() => _ArchiveObservatoryPanelState();
}

class _ArchiveObservatoryPanelState extends State<ArchiveObservatoryPanel> {
  bool _unlocked = false;
  bool _discovered = false;
  bool _busy = true;
  String? _error;

  Future<void> _reload() async {
    try {
      final events = await widget.database.events();
      if (!mounted) return;
      setState(() {
        _unlocked = events.any((e) => e['event_type'] == 'ARCHIVE_CONDUIT_SOLVED');
        _discovered = events.any((e) => e['event_type'] == 'ARCHIVE_OBSERVATORY_DISCOVERED');
        _error = null;
        _busy = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = '$error'; _busy = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _explore() async {
    if (_busy || !_unlocked || _discovered) return;
    setState(() => _busy = true);
    try {
      // Recheck prerequisite against the authoritative event ledger.
      final events = await widget.database.events();
      if (!events.any((e) => e['event_type'] == 'ARCHIVE_CONDUIT_SOLVED')) {
        throw StateError('Conduit must be solved first');
      }
      await widget.database.appendEvent(
        eventId: 'archive-observatory-discovered-v1',
        actorId: 'vesper-vane',
        type: 'ARCHIVE_OBSERVATORY_DISCOVERED',
        payload: {'sector': 'D', 'link': 2, 'location': 'archive-observatory'},
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF211A35),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ARCHIVE OBSERVATORY',
          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        Text(_discovered
            ? 'Beyond the conduit, Vesper discovers a lunar orrery and a fractured Netherese star chart. The inscription points toward Vaelthara’s lost research.'
            : _unlocked
                ? 'The opened passage leads to a dark observatory. Investigate the star chart.'
                : 'A sealed passage waits behind the Lunar–Weave Conduit.'),
        if (_error != null) Text('Save error: $_error',
          style: const TextStyle(color: Colors.redAccent)),
        OutlinedButton.icon(
          onPressed: _busy || !_unlocked || _discovered ? null : _explore,
          icon: const Icon(Icons.explore),
          label: const Text('Investigate observatory'),
        ),
        if (_discovered) const Text('Discovery recorded in Vesper’s event ledger.',
          style: TextStyle(color: Colors.greenAccent)),
      ]),
    ),
  );
}
