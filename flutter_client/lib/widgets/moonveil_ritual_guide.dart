import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual ritual guide. All operations are previews; never grants powers.
class MoonveilRitualGuide extends StatefulWidget {
  const MoonveilRitualGuide({super.key});
  @override
  State<MoonveilRitualGuide> createState() => _MoonveilRitualGuideState();
}

class _MoonveilRitualGuideState extends State<MoonveilRitualGuide> {
  late final Future<Map<String, String>> assets = _load();
  int selected = 0;
  static const entries = [
    (
      title: 'Relic Resonance',
      level: 1,
      site: 'RS-007', circle: 'RC-003', component: 'RI-003',
      book: 'BK-005', spell: 'SP-004', token: 'TK-004',
      steps: ['Confirm relic identities and provenance',
        'Align the Silver Strand Codex with the Weave',
        'Channel the existing starlight resonance',
        'Record the completed harmonization'],
      status: 'Completed at the established checkpoint'
    ),
    (
      title: 'Lich Ascension',
      level: 17,
      site: 'RS-003', circle: 'RC-001', component: 'RI-001',
      book: 'BK-001', spell: 'SP-007', token: 'TK-001',
      steps: ['Obtain the required story milestone',
        'Verify prerequisites and campaign authorization',
        'Prepare a protected ritual site',
        'Resolve the transformation through the game engine'],
      status: 'Locked until level 17'
    ),
    (
      title: 'Archlich Ascension',
      level: 20,
      site: 'RS-002', circle: 'RC-002', component: 'RI-005',
      book: 'BK-002', spell: 'SP-005', token: 'TK-002',
      steps: ['Complete heroic lich progression',
        'Reach level 20 and fulfill narrative prerequisites',
        'Secure the consecrated ascension site',
        'Resolve the archlich ceremony through the game engine'],
      status: 'Locked until level 20'
    ),
    (
      title: 'Gem Dragon Conclave',
      level: 1,
      site: 'RS-006', circle: 'RC-003', component: 'RI-007',
      book: 'BK-008', spell: 'SP-010', token: 'TK-004',
      steps: ['Identify the gem dragon and its chronology',
        'Obtain an invitation or earned audience',
        'Prepare the diplomatic offerings',
        'Negotiate without assuming a reward'],
      status: 'Future encounter concept'
    ),
  ];

  Future<Map<String, String>> _load() async {
    final raw = jsonDecode(await rootBundle.loadString(
      'assets/data/moonveil_ritual_v9_index.json'));
    if (raw is! Map || raw['atlas_id'] != 'moonveil-ritual-v9'
        || raw['assets'] is! List) {
      throw const FormatException('Invalid ritual art index');
    }
    return {
      for (final a in raw['assets'] as List)
        if (a is Map && a['id'] is String && a['flutter_asset'] is String)
          a['id'] as String: a['flutter_asset'] as String
    };
  }

  Widget _image(Map<String, String> index, String id) {
    final path = index[id];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(height: 92, child: path == null
        ? const Center(child: Icon(Icons.image_not_supported))
        : Image.asset(path, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.image_not_supported)))),
      Text(id, style: const TextStyle(fontSize: 12)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ritual = entries[selected];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Ritual Sites, Scrolls and Spell Tokens',
        style: Theme.of(context).textTheme.titleLarge),
      const Text('Reference-only diagrams. No ritual can be performed here.'),
      Wrap(spacing: 6, children: [
        for (var i=0; i<entries.length; i++)
          ChoiceChip(label: Text(entries[i].title),
            selected: i==selected,
            onSelected: (_) => setState(() => selected=i)),
      ]),
      const SizedBox(height: 10),
      Text(ritual.status, style: Theme.of(context).textTheme.titleMedium),
      FutureBuilder<Map<String, String>>(
        future: assets,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(padding: EdgeInsets.all(12),
              child: Text('Ritual images pending installation'));
          }
          final index = snapshot.data!;
          return GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              _image(index, ritual.site), _image(index, ritual.circle),
              _image(index, ritual.component), _image(index, ritual.book),
              _image(index, ritual.spell), _image(index, ritual.token),
            ],
          );
        },
      ),
      for (var i=0; i<ritual.steps.length; i++)
        ListTile(dense: true,
          leading: CircleAvatar(radius: 13, child: Text('${i+1}')),
          title: Text(ritual.steps[i])),
    ]);
  }
}
