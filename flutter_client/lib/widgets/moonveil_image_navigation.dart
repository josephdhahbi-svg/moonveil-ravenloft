import 'package:flutter/material.dart';

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
        final path = 'assets/images/moonveil_ui_buttons/$file';
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
