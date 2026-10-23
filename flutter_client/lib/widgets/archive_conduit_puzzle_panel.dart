import 'package:flutter/material.dart';
import '../models/archive_conduit_puzzle.dart';
import '../storage/moonveil_database.dart';

/// Puzzle state is reconstructed from append-only Vesper campaign events.
class ArchiveConduitPuzzlePanel extends StatefulWidget {
  const ArchiveConduitPuzzlePanel({super.key, required this.database});
  final MoonveilDatabase database;

  @override
  State<ArchiveConduitPuzzlePanel> createState() => _ArchiveConduitPuzzlePanelState();
}

class _ArchiveConduitPuzzlePanelState extends State<ArchiveConduitPuzzlePanel> {
  List<String> _sequence = [];
  bool _solved = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final events = await widget.database.events();
      final solved = events.any((e) => e['event_type'] == 'ARCHIVE_CONDUIT_SOLVED');
      if (mounted) setState(() {
        _solved = solved;
        _busy = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _error = '$error';
        _busy = false;
      });
    }
  }

  Future<void> _press(String symbol) async {
    if (_busy || _solved) return;
    final next = [..._sequence, symbol];
    if (next.length < 3) {
      setState(() => _sequence = next);
      return;
    }
    if (!ArchiveConduitPuzzle.isSolved(next)) {
      setState(() => _sequence = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ArchiveConduitPuzzle.feedback(next))));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.database.appendEvent(
        eventId: 'archive-conduit-solved-v1',
        actorId: 'vesper-vane',
        type: 'ARCHIVE_CONDUIT_SOLVED',
        payload: {'sector': 'D', 'link': 2, 'sequence': next},
      );
      if (mounted) setState(() {
        _solved = true;
        _sequence = next;
      });
    } catch (error) {
      // An already-saved completion must be restored, not duplicated.
      await _restore();
      if (mounted && !_solved) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF231A3C),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('LUNAR–WEAVE CONDUIT',
            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        const Text('Clue: Moonlight awakens the Weave; the Star follows its path.'),
        const SizedBox(height: 8),
        Text(_solved ? ArchiveConduitPuzzle.feedback(ArchiveConduitPuzzle.solution)
            : 'Glyphs: ${_sequence.join(' → ')}'),
        if (_error != null) Text('Save error: $_error',
            style: const TextStyle(color: Colors.redAccent)),
        Wrap(spacing: 8, children: [
          for (final symbol in ArchiveConduitPuzzle.symbols)
            OutlinedButton(
              onPressed: _busy || _solved ? null : () => _press(symbol),
              child: Text(symbol),
            ),
          TextButton(
            onPressed: _busy || _solved ? null : () => setState(() => _sequence = []),
            child: const Text('Reset glyphs'),
          ),
        ]),
      ]),
    ),
  );
}
