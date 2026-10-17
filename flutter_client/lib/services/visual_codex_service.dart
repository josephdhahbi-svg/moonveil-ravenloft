import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Canonical offline artwork paths. Missing art is reported, never invented.
class VisualCodexService {
  static const defaultVesperPortrait = 'assets/images/portraits/vesper_vane.png';
  static const baroviaBackground = 'assets/images/backgrounds/barovia_mists.png';
  static const panelImageMap = <int, String>{
    1: 'assets/images/panels/panel_1_threshold.png',
    2: 'assets/images/panels/panel_2_vaelthara.png',
    3: 'assets/images/panels/panel_3_relics.png',
    4: 'assets/images/panels/panel_4_fate.png',
  };

  static String? getPanelImage(int panelNumber) => panelImageMap[panelNumber];

  static Future<bool> exists(String path, {AssetBundle? bundle}) async {
    try {
      await (bundle ?? rootBundle).load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<int, bool>> auditPanels({AssetBundle? bundle}) async {
    final results = <int, bool>{};
    for (final entry in panelImageMap.entries) {
      results[entry.key] = await exists(entry.value, bundle: bundle);
    }
    return results;
  }
}
