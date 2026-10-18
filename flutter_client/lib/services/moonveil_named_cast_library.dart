import 'dart:convert';
import 'package:flutter/services.dart';

/// Read-only numbered portrait/asset catalog. This service never alters saves.
class MoonveilNamedCastLibrary {
  MoonveilNamedCastLibrary({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<List<NamedCastAsset>>? _cache;

  Future<List<NamedCastAsset>> get entries => _cache ??= _load();

  Future<List<NamedCastAsset>> _load() async {
    final decoded = jsonDecode(await _bundle.loadString(
      'assets/data/moonveil_named_cast_v8_index.json'));
    if (decoded is! Map || decoded['atlas_id'] != 'moonveil-named-cast-v8'
        || decoded['assets'] is! List) {
      throw const FormatException('Invalid Moonveil cast asset index');
    }
    return (decoded['assets'] as List).map((entry) {
      if (entry is! Map || entry['id'] is! String ||
          entry['name'] is! String || entry['category'] is! String ||
          entry['flutter_asset'] is! String) {
        throw const FormatException('Invalid named cast asset');
      }
      final path = entry['flutter_asset'] as String;
      if (!RegExp(r'^assets/images/moonveil_named_cast_v8/[a-z_]+/[A-Z]{2}-[0-9]{3}\\.png$').hasMatch(path)) {
        throw const FormatException('Unsafe cast asset path');
      }
      return NamedCastAsset(
        id: entry['id'] as String,
        name: entry['name'] as String,
        category: entry['category'] as String,
        image: path,
      );
    }).toList(growable: false);
  }

  Future<NamedCastAsset?> find(String id) async {
    for (final item in await entries) {
      if (item.id == id.toUpperCase()) return item;
    }
    return null;
  }

  Future<List<NamedCastAsset>> search(String query) async {
    final q = query.toLowerCase().trim();
    return (await entries).where((item) =>
      item.id.toLowerCase().contains(q) ||
      item.name.toLowerCase().contains(q) ||
      item.category.toLowerCase().contains(q)).toList();
  }

  void invalidate() => _cache = null;
}

class NamedCastAsset {
  const NamedCastAsset({
    required this.id, required this.name,
    required this.category, required this.image,
  });
  final String id, name, category, image;
}
