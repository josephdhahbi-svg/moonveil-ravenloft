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

/// Detects missing and byte-for-byte duplicated panel art before rendering.
/// A duplicate is rejected rather than being presented as a different scene.
class PanelArtAudit {
  const PanelArtAudit(this.usable, this.issues);
  final Map<int, bool> usable;
  final Map<int, String> issues;
}

extension VisualCodexAudit on VisualCodexService {
  static Future<PanelArtAudit> checkUniquePanels({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final seen = <String, int>{};
    final usable = <int, bool>{};
    final issues = <int, String>{};
    for (final entry in VisualCodexService.panelImageMap.entries) {
      try {
        final bytes = (await source.load(entry.value)).buffer.asUint8List();
        if (bytes.isEmpty) throw StateError('Empty image');
        // 32-bit FNV-1a fingerprint: web-safe integer arithmetic.
        // Used only for duplicate detection, not security.
        var hash = 0x811c9dc5;
        for (final byte in bytes) {
          hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
        }
        final signature = '${bytes.length}:${hash.toRadixString(16)}';
        final previous = seen[signature];
        if (previous != null) {
          usable[entry.key] = false;
          issues[entry.key] = 'Same image bytes as panel $previous';
        } else {
          seen[signature] = entry.key;
          usable[entry.key] = true;
        }
      } catch (_) {
        usable[entry.key] = false;
        issues[entry.key] = 'Missing or unreadable: ${entry.value}';
      }
    }
    return PanelArtAudit(usable, issues);
  }
}
