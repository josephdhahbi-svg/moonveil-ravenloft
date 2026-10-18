import 'dart:convert';
import 'package:flutter/services.dart';

/// Offline deterministic art selector. It does not call an AI API or mutate
/// campaign state. An AI narrator can request an asset by category/keywords.
class MoonveilArtDirector {
  MoonveilArtDirector({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<List<MoonveilArtRecord>>? _cache;

  Future<List<MoonveilArtRecord>> get records => _cache ??= _load();

  Future<List<MoonveilArtRecord>> _load() async {
    final raw = jsonDecode(await _bundle.loadString(
      'assets/data/moonveil_v5_index.json'));
    if (raw is! Map || raw['atlas_id'] != 'moonveil-v5' ||
        raw['assets'] is! List) {
      throw const FormatException('Invalid Moonveil V5 art registry');
    }
    return (raw['assets'] as List).map((entry) {
      if (entry is! Map) throw const FormatException('Invalid art record');
      return MoonveilArtRecord(
        id: entry['id'] as String,
        category: entry['category'] as String,
        label: entry['label'] as String,
        assetPath: entry['flutter_asset'] as String,
      );
    }).toList(growable: false);
  }

  Future<MoonveilArtRecord?> byId(String id) async {
    for (final record in await records) {
      if (record.id.toUpperCase() == id.toUpperCase()) return record;
    }
    return null;
  }

  Future<List<MoonveilArtRecord>> suggest({
    required String category,
    required String prompt,
    int limit = 5,
  }) async {
    final terms = prompt.toLowerCase().split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.length > 2).toSet();
    final matches = (await records)
        .where((record) => record.category == category).toList();
    matches.sort((a, b) {
      int score(MoonveilArtRecord r) => terms
          .where((term) => r.label.toLowerCase().contains(term)).length;
      final difference = score(b).compareTo(score(a));
      return difference != 0 ? difference : a.id.compareTo(b.id);
    });
    return matches.take(limit.clamp(0, 81)).toList();
  }

  void refresh() => _cache = null;
}

class MoonveilArtRecord {
  const MoonveilArtRecord({
    required this.id, required this.category,
    required this.label, required this.assetPath,
  });
  final String id, category, label, assetPath;
}
