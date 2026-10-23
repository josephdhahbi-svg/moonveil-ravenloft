import 'package:flutter/material.dart';

/// Local command scratchpad. No network requests or save writes are performed.
class MoonveilMasterGuiAndAiHub extends StatefulWidget {
  const MoonveilMasterGuiAndAiHub({super.key});

  @override
  State<MoonveilMasterGuiAndAiHub> createState() => _MoonveilMasterGuiAndAiHubState();
}

class _MoonveilMasterGuiAndAiHubState extends State<MoonveilMasterGuiAndAiHub> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _notes = [];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _recordNote() {
    final note = _promptController.text.trim();
    if (note.isEmpty) return;
    setState(() {
      _notes.add(note);
      _promptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0B14),
    appBar: AppBar(title: const Text('Moonveil Command Notes')),
    body: Column(children: [
      const ListTile(
        leading: Icon(Icons.shield_outlined, color: Colors.amberAccent),
        title: Text('Offline command scratchpad'),
        subtitle: Text('No AI webhook connected. Notes are temporary and never alter the campaign save.'),
      ),
      Expanded(child: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.notes, color: Colors.purpleAccent),
          title: Text(_notes[index]),
        ),
      )),
      SafeArea(child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _promptController,
            decoration: const InputDecoration(hintText: 'Draft a command (not sent)'),
            onSubmitted: (_) => _recordNote(),
          )),
          IconButton(
            tooltip: 'Add local note',
            onPressed: _recordNote,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ]),
      )),
    ]),
  );
}
