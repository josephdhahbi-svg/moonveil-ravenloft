import 'package:flutter/material.dart';
import '../widgets/moonveil_scene_stage.dart';

/// Preview library for scenery and battles. Selecting a scene never moves
/// the player, starts combat, or modifies saved campaign state.
class MoonveilSceneLibraryScreen extends StatefulWidget {
  const MoonveilSceneLibraryScreen({super.key});
  @override
  State<MoonveilSceneLibraryScreen> createState() =>
      _MoonveilSceneLibraryScreenState();
}

class _MoonveilSceneLibraryScreenState extends State<MoonveilSceneLibraryScreen> {
  static const scenes = <(String, String, bool)>[
    ('Krezk Abbey', 'locations/krezk_abbey.png', false),
    ('Barovia', 'locations/barovia.png', false),
    ('Svalich Road', 'locations/svalich_road.png', false),
    ('Forgotten Ruins', 'locations/ruins.png', false),
    ('Castle Ravenloft', 'locations/castle_ravenloft.png', false),
    ('Abbey Encounter', 'locations/krezk_abbey.png', true),
    ('Road Ambush', 'locations/svalich_road.png', true),
    ('Castle Confrontation', 'locations/castle_ravenloft.png', true),
  ];
  int selected = 0;
  final Map<int, String> drafts = {};

  @override
  Widget build(BuildContext context) {
    final scene = scenes[selected];
    return ListView(children: [
      const Text('Scenery, Battle Backdrops and Dialogue Studio',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const Text('Select a background and tap the blank bubble to write dialogue. '
        'Edits are temporary previews; campaign saves are not modified.'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < scenes.length; i++)
          ChoiceChip(label: Text(scenes[i].$1),
            selected: selected == i,
            onSelected: (_) => setState(() => selected = i)),
      ]),
      const SizedBox(height: 12),
      MoonveilSceneStage(
        key: ValueKey(selected),
        title: scene.$1,
        backgroundAsset: 'assets/images/moonveil_v4/${scene.$2}',
        battle: scene.$3,
        initialDialogue: drafts[selected] ?? '',
        onDialogueChanged: (text) => drafts[selected] = text,
      ),
      const SizedBox(height: 8),
      const Text('Battle backdrops are visual previews, not tactical maps. '
        'A battle requires a separate grid, tokens, initiative and combat state.'),
    ]);
  }
}
