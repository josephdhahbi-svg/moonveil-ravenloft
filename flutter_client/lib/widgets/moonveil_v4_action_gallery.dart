import 'package:flutter/material.dart';
import '../services/moonveil_v4_registry.dart';

/// Catalog-backed visual navigation. Buttons open real dashboard tabs,
/// while locked rituals remain preview-only in the Fusion Studio.
class MoonveilV4ActionGallery extends StatefulWidget {
  const MoonveilV4ActionGallery({super.key, required this.onOpenTab});
  final ValueChanged<String> onOpenTab;

  @override
  State<MoonveilV4ActionGallery> createState() => _MoonveilV4ActionGalleryState();
}

class _MoonveilV4ActionGalleryState extends State<MoonveilV4ActionGallery> {
  final MoonveilV4Registry registry = MoonveilV4Registry();

  static const groups = <String, List<(String, String, String)>>{
    'Inventory': [
      ('Sight of Vaelthara', 'sight_of_vaelthara', 'Inventory'),
      ('Hand of the Weave', 'hand_of_weave', 'Inventory'),
      ('Silver Strand Codex', 'silver_strand_codex', 'Inventory'),
      ('Bone-Hilt Dagger', 'bone_hilt_dagger', 'Inventory'),
      ('Leather Armor', 'leather_armor', 'Inventory'),
      ('Potions', 'potions', 'Inventory'),
      ('Scrolls', 'scrolls', 'Inventory'),
      ('Gems', 'gems', 'Inventory'),
    ],
    'Spells': [
      ('Eldritch Blast', 'eldritch_blast', 'Character'),
      ('Hex', 'hex', 'Character'),
      ('Misty Step', 'mist_step', 'Character'),
      ('Shield', 'shield', 'Character'),
      ('Summon', 'summon', 'Character'),
      ('Counterspell', 'counterspell', 'Character'),
    ],
    'Factions': [
      ('Selune', 'selune', 'Journal'),
      ('Mystra', 'mystra', 'Journal'),
      ('Harpers', 'harpers', 'Journal'),
      ('Gauntlet', 'gauntlet', 'Journal'),
      ('Silver Moon', 'silver_moon', 'Journal'),
      ('Ravenloft', 'ravenloft', 'Journal'),
    ],
    'Rituals': [
      ('Lich Ascension', 'lich_ascension', 'Fusion Studio'),
      ('Archlich Ascension', 'archlich_ascension', 'Fusion Studio'),
      ('Relic Resonance', 'relic_resonance', 'Fusion Studio'),
      ('Codex Gem Fusion', 'codex_gem_fusion', 'Fusion Studio'),
      ('Custom Fusion', 'custom_fusion', 'Fusion Studio'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Moonveil Visual Controls',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const Text('Artwork is illustrative; spells and items are not granted by tapping.'),
      for (final group in groups.entries) ...[
        const SizedBox(height: 14),
        Text(group.key, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.value.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170, mainAxisExtent: 155,
            mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemBuilder: (context, index) {
            final (title, id, tab) = group.value[index];
            final category = switch (group.key) {
              'Inventory' => 'items',
              'Spells' => 'abilities',
              'Factions' => 'factions',
              _ => 'rituals',
            };
            return OutlinedButton(
              onPressed: () => widget.onOpenTab(tab),
              child: Column(children: [
                Expanded(child: FutureBuilder<String?>(
                  future: registry.find(category, id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Icon(Icons.image_not_supported));
                    }
                    return Image.asset(snapshot.data!,
                      width: double.infinity, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.image_not_supported)));
                  },
                )),
                Padding(padding: const EdgeInsets.all(5),
                  child: Text(title, textAlign: TextAlign.center,
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
            );
          },
        ),
      ],
    ]);
  }
}
