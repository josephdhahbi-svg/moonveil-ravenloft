import 'package:flutter/material.dart';
import 'moonveil_asset_button.dart';

/// Clickable artwork-first navigation. Never changes character state.
/// Each image is optional until the verified PNG pack is installed.
class MoonveilImageNavigation extends StatelessWidget {
  const MoonveilImageNavigation({super.key, required this.onOpenTab});
  final ValueChanged<String> onOpenTab;

  static const destinations = <(String, String, String)>[
    ('Locations', 'navigation/locations.png', 'Atlas'),
    ('People', 'navigation/people.png', 'Character'),
    ('Monsters', 'navigation/monsters.png', 'Categories'),
    ('Items', 'navigation/items.png', 'Inventory'),
    ('Maps', 'navigation/maps.png', 'Atlas'),
    ('Tokens', 'navigation/tokens.png', 'Categories'),
    ('Story Panels', 'navigation/story_panels.png', 'Storyboard'),
    ('Cutscenes', 'navigation/cutscenes.png', 'Storyboard'),
    ('Battle Maps', 'navigation/battle_maps.png', 'Atlas'),
    ('Rest', 'actions/rest.png', 'Adventure'),
    ('Travel', 'actions/travel.png', 'Atlas'),
    ('Train', 'actions/train.png', 'Adventure'),
    ('Craft', 'actions/craft.png', 'Inventory'),
    ('Research', 'actions/research.png', 'Journal'),
    ('Community', 'actions/community.png', 'Journal'),
    ('Allies', 'actions/allies.png', 'Character'),
    ('Factions', 'actions/factions.png', 'Journal'),
    ('Options', 'actions/options.png', 'System Control'),
    ('Vesper Vane', 'party/vesper_vane.png', 'Character'),
    ('Alice', 'party/alice.png', 'Character'),
    ('Starweave', 'party/starweave.png', 'Character'),
    ('Aasimar Paladin', 'party/aasimar_paladin.png', 'Character'),
    ('Dr. Frankenstein', 'party/dr_frankenstein.png', 'Character'),
    ('Death Cleric', 'party/death_cleric.png', 'Character'),
    ('Spirits Bard', 'party/spirits_bard.png', 'Character'),
    ('Seraphine', 'party/seraphine.png', 'Character'),
    ('Thalara', 'party/thalara.png', 'Character'),
    ('Vesper Ashcroft', 'party/vesper_ashcroft.png', 'Character'),
    ('Vesper Profile', 'portraits/vesper_profile.png', 'Character'),
    ('Abbey', 'scenes/abbey_moonlit.png', 'Atlas'),
    ('Forgotten Archive', 'scenes/forgotten_archive_objective.png', 'Adventure'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190, mainAxisExtent: 154,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: destinations.length,
      itemBuilder: (context, i) {
        final (label, file, destination) = destinations[i];
        final v3Names = <String, String>{
          'Locations': 'navigation/maps.png',
          'People': 'navigation/characters.png',
          'Items': 'navigation/inventory.png',
          'Maps': 'navigation/maps.png',
          'Rest': 'actions/rest.png',
          'Travel': 'actions/travel.png',
          'Train': 'actions/train.png',
          'Craft': 'actions/craft.png',
          'Research': 'actions/research.png',
          'Community': 'actions/community.png',
          'Allies': 'navigation/allies.png',
          'Factions': 'navigation/factions.png',
          'Options': 'actions/options.png',
          'Vesper Vane': 'portraits/vesper_transylvania.png',
          'Vesper Profile': 'portraits/vesper_nordic.png',
        };
        final path = v3Names.containsKey(label)
            ? 'assets/images/vesper_v3/${v3Names[label]}'
            : 'assets/images/moonveil_ui_buttons/$file';
        if (v3Names.containsKey(label)) {
          final parts = v3Names[label]!.split('/');
          return MoonveilAssetButton(
            category: parts.first,
            assetName: parts.last.replaceAll('.png', ''),
            label: label,
            onPressed: () => onOpenTab(destination),
          );
        }
        return Semantics(
          button: true,
          label: 'Open $label',
          child: OutlinedButton(
            onPressed: () => onOpenTab(destination),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF1B1724),
              side: const BorderSide(color: Color(0xFF8D704A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Column(
              children: [
                Expanded(child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.asset(
                    path,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 32),
                    ),
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
