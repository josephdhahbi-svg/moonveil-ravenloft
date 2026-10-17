import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Planned image inventory. Paths are not proof that artwork is bundled.
class ExpandedMultiversalVisualLibrary {
  static const Map<String, String> masterVisualAssetCatalog = {
    'vesper_vane': 'assets/images/portraits/vesper_vane.png',
    'elara_priestess': 'assets/images/portraits/elara_priestess.png',
    'jaellat_dancer': 'assets/images/portraits/jaellat_dancer.png',
    'strahd_lord': 'assets/images/portraits/strahd_lord.png',
    'vaelthara_archlich': 'assets/images/portraits/vaelthara_archlich.png',
    'panel_1_threshold': 'assets/images/panels/panel_1_threshold.png',
    'panel_2_vaelthara': 'assets/images/panels/panel_2_vaelthara.png',
    'panel_3_relics': 'assets/images/panels/panel_3_relics.png',
    'panel_4_fate': 'assets/images/panels/panel_4_fate.png',
    'castle_ravenloft_spire': 'assets/images/panels/castle_ravenloft_spire.png',
    'barovia_village_gate': 'assets/images/panels/barovia_village_gate.png',
    'vallaki_square': 'assets/images/panels/vallaki_square.png',
    'krezk_abbey': 'assets/images/panels/krezk_abbey.png',
    'amber_temple_vault': 'assets/images/panels/amber_temple_vault.png',
    'mt_ghakis_peaks': 'assets/images/panels/mt_ghakis_peaks.png',
    'relic_sight_eye': 'assets/images/items/relic_sight_eye.png',
    'relic_hand_gauntlet': 'assets/images/items/relic_hand_gauntlet.png',
    'relic_netherese_codex': 'assets/images/items/relic_netherese_codex.png',
    'divine_spell_tome': 'assets/images/items/divine_spell_tome.png',
    'tarokka_prophecy_deck': 'assets/images/items/tarokka_prophecy_deck.png',
    'mystra_grimoire': 'assets/images/items/mystra_grimoire.png',
    'selune_moon_chalice': 'assets/images/items/selune_moon_chalice.png',
    'lathander_sun_crest': 'assets/images/items/lathander_sun_crest.png',
    'silver_runed_dagger': 'assets/images/items/silver_runed_dagger.png',
    'blessed_ash_stake': 'assets/images/items/blessed_ash_stake.png',
    'shrine_mystra_weave': 'assets/images/shrines/shrine_mystra_weave.png',
    'shrine_selune_moon': 'assets/images/shrines/shrine_selune_moon.png',
    'shrine_eilistraee_dance': 'assets/images/shrines/shrine_eilistraee_dance.png',
    'shrine_lathander_dawn': 'assets/images/shrines/shrine_lathander_dawn.png',
    'multiversal_portal_gate': 'assets/images/shrines/multiversal_portal_gate.png',
  };

  static int get totalAssetCount => masterVisualAssetCatalog.length;

  /// Audits the actual Flutter asset bundle without inventing success statuses.
  static Future<Map<String, bool>> auditBundledImages({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final result = <String, bool>{};
    for (final entry in masterVisualAssetCatalog.entries) {
      try {
        final data = await source.load(entry.value);
        result[entry.key] = data.lengthInBytes > 0;
      } catch (_) {
        result[entry.key] = false;
      }
    }
    return result;
  }
}
