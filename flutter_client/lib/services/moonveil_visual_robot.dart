import 'dart:convert';
import 'package:flutter/services.dart';

/// AI-friendly, offline lookup of approved numbered art.
/// This selects existing images; it does not generate art or change saves.
class MoonveilVisualRobot {
  MoonveilVisualRobot({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<List<Map<String, dynamic>>>? _index;

  Future<List<Map<String, dynamic>>> get assets => _index ??= _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final data = jsonDecode(await _bundle.loadString(
        'assets/data/moonveil_v6_index.json'));
    if (data is! Map || data['atlas_id'] != 'moonveil-v6' ||
        data['assets'] is! List) {
      throw const FormatException('Invalid V6 image index');
    }
    return (data['assets'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    for (final asset in await assets) {
      if (asset['id'] == id.toUpperCase()) return asset;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> select({
    required String category,
    required String sceneDescription,
    int count = 4,
  }) async {
    final keywords = sceneDescription.toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.length >= 3).toSet();
    final candidates = (await assets)
        .where((e) => e['category'] == category).toList();
    int score(Map<String, dynamic> e) {
      final label = (e['label'] as String).toLowerCase();
      return keywords.where(label.contains).length;
    }
    candidates.sort((a, b) {
      final diff = score(b).compareTo(score(a));
      return diff == 0
          ? (a['id'] as String).compareTo(b['id'] as String) : diff;
    });
    return candidates.take(count.clamp(0, 100)).toList();
  }

  void refresh() => _index = null;
}
