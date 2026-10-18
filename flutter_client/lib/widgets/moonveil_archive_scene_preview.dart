import 'package:flutter/material.dart';

/// A deterministic scene preview for the Forgotten Archive.
/// Story actions are previews; this widget never mutates campaign storage.
class MoonveilArchiveScenePreview extends StatelessWidget {
  const MoonveilArchiveScenePreview({
    super.key, required this.choice, required this.onEncounter,
  });
  final String? choice;
  final VoidCallback onEncounter;

  static const Map<String, ({String title, String story})> outcomes = {
    'Lawful Good': (
      title: 'The Ward of Three Lights',
      story: 'Vesper traces a protective silver circle around the archive doorway. The runes settle, revealing a safer route for any survivors beyond.',
    ),
    'Neutral Good': (
      title: 'A Voice Beyond the Door',
      story: 'A faint voice answers Vesper from behind the Netherese seal. Someone may still be alive inside, but the passage remains guarded.',
    ),
    'Chaotic Good': (
      title: 'Defiance of the Broken Seal',
      story: 'Vesper rejects the corrupted command carved into the door. Silver sparks race across the lock as an ancient guardian stirs.',
    ),
    'Utility': (
      title: 'Resonance Analysis',
      story: 'The Sight of Vaelthara catches a repeating pattern in the Weave. Vesper records the rhythm, preserving the clue for later study.',
    ),
    'Action': (
      title: 'Into the Forgotten Archive',
      story: 'Vesper advances into the threshold. Stone gears turn in the dark, and the sound of an approaching guardian echoes through the hall.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final scene = outcomes[choice];
    if (scene == null) return const SizedBox.shrink();
    return Card(
      key: const Key('archive-scene-preview'),
      color: const Color(0xFF251D38),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('NEXT SCENE · PREVIEW', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(scene.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(scene.story),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('scene-open-encounter'),
            onPressed: onEncounter,
            icon: const Icon(Icons.sports_martial_arts),
            label: const Text('Open Encounter'),
          ),
          const Text('Narrative preview only. No quest rewards or character stats changed.'),
        ]),
      ),
    );
  }
}
