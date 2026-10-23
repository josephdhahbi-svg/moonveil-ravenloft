import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Planning catalog. Sample image paths are references, NOT proof of existence.
class AssetCategoryModel {
  final int categoryId;
  final String categoryName;
  final String description;
  final String sampleAssetPath;
  const AssetCategoryModel({required this.categoryId, required this.categoryName, required this.description, required this.sampleAssetPath});
  bool get isAudioCategory => categoryId >= 18;
}

class MultiversalAssetRegistryService {
  static const List<AssetCategoryModel> master25Categories = [
    AssetCategoryModel(categoryId: 1, categoryName: "Warlock & Witch Avatars", description: "Dhampir & archlich character portraits", sampleAssetPath: "assets/images/portraits/vesper_vane.png"),
    AssetCategoryModel(categoryId: 2, categoryName: "Companion & Party Members", description: "Traveling party member tokens", sampleAssetPath: "assets/images/portraits/vesper_vane.png"),
    AssetCategoryModel(categoryId: 3, categoryName: "NPC Faction Leaders", description: "Strahd & political figures", sampleAssetPath: "assets/images/panels/panel_2_vaelthara.png"),
    AssetCategoryModel(categoryId: 4, categoryName: "Bestiary Creature Renderings", description: "Barovian beasts & undead", sampleAssetPath: "assets/images/panels/panel_3_relics.png"),
    AssetCategoryModel(categoryId: 5, categoryName: "Customizable Token Sprites", description: "Grid-snapping VTT tokens", sampleAssetPath: "assets/images/portraits/vesper_vane.png"),
    AssetCategoryModel(categoryId: 6, categoryName: "Castles & Spires", description: "Ravenloft stronghold graphics", sampleAssetPath: "assets/images/panels/panel_1_threshold.png"),
    AssetCategoryModel(categoryId: 7, categoryName: "Thresholds & Gateways", description: "Moonlit rune doors & portals", sampleAssetPath: "assets/images/panels/panel_1_threshold.png"),
    AssetCategoryModel(categoryId: 8, categoryName: "Towns & Settlements", description: "Vallaki & village squares", sampleAssetPath: "assets/images/panels/panel_2_vaelthara.png"),
    AssetCategoryModel(categoryId: 9, categoryName: "Abbeys & Sanctuaries", description: "Cliffside monasteries & shrines", sampleAssetPath: "assets/images/panels/panel_3_relics.png"),
    AssetCategoryModel(categoryId: 10, categoryName: "Temples & Vaults", description: "The Amber Temple & catacombs", sampleAssetPath: "assets/images/panels/panel_4_fate.png"),
    AssetCategoryModel(categoryId: 11, categoryName: "Roads & Outskirts", description: "Fog-veiled forest trails", sampleAssetPath: "assets/images/panels/panel_1_threshold.png"),
    AssetCategoryModel(categoryId: 12, categoryName: "Streets & Interiors", description: "Tavern interiors & alleys", sampleAssetPath: "assets/images/panels/panel_2_vaelthara.png"),
    AssetCategoryModel(categoryId: 13, categoryName: "The Three Relics", description: "Sight, Hand, and Codex assets", sampleAssetPath: "assets/images/panels/panel_3_relics.png"),
    AssetCategoryModel(categoryId: 14, categoryName: "Spellbooks & Tomes", description: "Divine & arcane grimoires", sampleAssetPath: "assets/images/panels/panel_4_fate.png"),
    AssetCategoryModel(categoryId: 15, categoryName: "Tarokka & Hidden Decks", description: "Prophecy card sets", sampleAssetPath: "assets/images/portraits/vesper_vane.png"),
    AssetCategoryModel(categoryId: 16, categoryName: "Armor & Equipment", description: "Plate, cloaks & accessories", sampleAssetPath: "assets/images/panels/panel_1_threshold.png"),
    AssetCategoryModel(categoryId: 17, categoryName: "Consumables & Reagents", description: "Potions & ritual items", sampleAssetPath: "assets/images/panels/panel_2_vaelthara.png"),
    AssetCategoryModel(categoryId: 18, categoryName: "Ambient Environmental Audio", description: "Howling mists & wind loops", sampleAssetPath: "assets/images/panels/panel_3_relics.png"),
    AssetCategoryModel(categoryId: 19, categoryName: "Synthetic Browser Narration", description: "Speech synthesis voice tracks", sampleAssetPath: "assets/images/panels/panel_4_fate.png"),
    AssetCategoryModel(categoryId: 20, categoryName: "Combat & Spell Audio", description: "Invocation & dice sound effects", sampleAssetPath: "assets/images/portraits/vesper_vane.png"),
    AssetCategoryModel(categoryId: 21, categoryName: "UI Feedback Audio", description: "Click & WAL sync chimes", sampleAssetPath: "assets/images/panels/panel_1_threshold.png"),
    AssetCategoryModel(categoryId: 22, categoryName: "Exploration Soundtracks", description: "Sector travel background music", sampleAssetPath: "assets/images/panels/panel_2_vaelthara.png"),
    AssetCategoryModel(categoryId: 23, categoryName: "Encounter & Combat Themes", description: "Boss battle orchestration", sampleAssetPath: "assets/images/panels/panel_3_relics.png"),
    AssetCategoryModel(categoryId: 24, categoryName: "Shrine & Sanctuary Hymns", description: "Deity devotion audio loops", sampleAssetPath: "assets/images/panels/panel_4_fate.png"),
    AssetCategoryModel(categoryId: 25, categoryName: "Omni-Play Sync Telemetry Tones", description: "Cross-device status chimes", sampleAssetPath: "assets/images/portraits/vesper_vane.png"),
  ];

  /// Checks only bundled sample thumbnails. Audio availability is separate.
  static Future<Map<int, bool>> auditSampleImages({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final byPath = <String, bool>{};
    final results = <int, bool>{};
    for (final category in master25Categories) {
      final path = category.sampleAssetPath;
      if (!byPath.containsKey(path)) {
        try {
          final data = await source.load(path);
          byPath[path] = data.lengthInBytes > 0;
        } catch (_) {
          byPath[path] = false;
        }
      }
      results[category.categoryId] = byPath[path]!;
    }
    return results;
  }
}
