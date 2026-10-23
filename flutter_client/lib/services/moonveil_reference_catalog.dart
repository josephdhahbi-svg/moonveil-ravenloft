import 'dart:convert';
import 'package:flutter/services.dart';

/// Read-only, memoized access to approved Moonveil context and ritual catalogs.
class MoonveilReferenceCatalog {
  MoonveilReferenceCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final Map<String, Future<Map<String, dynamic>>> _memo = {};

  Future<Map<String, dynamic>> _load(String path) =>
      _memo.putIfAbsent(path, () async {
        final raw = jsonDecode(await _bundle.loadString(path));
        if (raw is! Map<String, dynamic>) throw const FormatException('Invalid catalog');
        return raw;
      });

  Future<Map<String, dynamic>> context() =>
      _load('assets/data/moonveil_verified_context.json');

  Future<Map<String, dynamic>> fusion() =>
      _load('assets/data/moonveil_visual_fusion_recipes.json');

  Future<List<Map<String, dynamic>>> tasks() async {
    final data = await context();
    return (data['tasks'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>?> findRecipe(String id) async {
    final data = await fusion();
    for (final item in data['recipes'] as List) {
      if (item is Map && item['id'] == id) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  void invalidate() => _memo.clear();
}
