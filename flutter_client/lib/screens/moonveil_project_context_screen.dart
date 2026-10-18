import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Read-only development context. Never opens, edits or seeds game save files.
/// Uses the bundled approved snapshot, not a claim of live CI or AI connectivity.
class MoonveilProjectContextScreen extends StatefulWidget {
  const MoonveilProjectContextScreen({super.key});

  @override
  State<MoonveilProjectContextScreen> createState() => _MoonveilProjectContextScreenState();
}

class _MoonveilProjectContextScreenState extends State<MoonveilProjectContextScreen> {
  late final Future<Map<String, dynamic>> _context = _load();
  String query = '';

  Future<Map<String, dynamic>> _load() async {
    final text = await rootBundle.loadString('assets/data/moonveil_verified_context.json');
    return jsonDecode(text) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _context,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Project context unavailable: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final entries = <MapEntry<String, dynamic>>[];
        for (final section in ['campaign', 'artwork', 'development']) {
          final values = data[section];
          if (values is Map) {
            for (final entry in values.entries) {
              entries.add(MapEntry('$section.${entry.key}', entry.value));
            }
          }
        }
        final matches = entries.where((entry) =>
          '${entry.key} ${entry.value}'.toLowerCase().contains(query.toLowerCase())).toList();
        return Column(children: [
          const ListTile(
            title: Text('MOONVEIL PROJECT MEMORY'),
            subtitle: Text('Approved snapshot · read-only · not live save state'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search checkpoint, artwork, tasks and branch',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(child: ListView.builder(
            itemCount: matches.length + 1,
            itemBuilder: (context, index) {
              if (index == matches.length) {
                final tasks = (data['tasks'] as List<dynamic>? ?? []);
                return ExpansionTile(
                  title: Text('Task backlog (${tasks.length})'),
                  children: [
                    for (final item in tasks)
                      ListTile(
                        title: Text('${item['title']}'),
                        subtitle: Text('Priority ${item['priority']} · Planned, not automatically executed'),
                      ),
                  ],
                );
              }
              final entry = matches[index];
              return ListTile(
                dense: true,
                title: Text(entry.key),
                subtitle: SelectableText('${entry.value}'),
              );
            },
          )),
        ]);
      },
    );
  }
}
