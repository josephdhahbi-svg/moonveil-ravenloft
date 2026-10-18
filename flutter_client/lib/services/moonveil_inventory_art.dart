import 'dart:convert';
import 'package:flutter/services.dart';

/// V10 item artwork registry. Cards are collection references, not owned items.
class MoonveilInventoryArt {
  MoonveilInventoryArt({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<List<Map<String, dynamic>>>? _cached;
  Future<List<Map<String, dynamic>>> get assets => _cached ??= _load();
  Future<List<Map<String, dynamic>>> _load() async {
    final data = jsonDecode(await _bundle.loadString(
        'assets/data/moonveil_inventory_v10_index.json'));
    if (data is! Map || data['atlas_id'] != 'moonveil-inventory-v10'
        || data['assets'] is! List) {
      throw const FormatException('Invalid V10 inventory index');
    }
    return (data['assets'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }
  Future<List<Map<String, dynamic>>> category(String category) async =>
      (await assets).where((item) => item['category'] == category).toList();
  Future<Map<String, dynamic>?> byId(String id) async {
    for (final item in await assets) {
      if (item['id'] == id.toUpperCase()) return item;
    }
    return null;
  }
  void refresh() => _cached = null;
}
