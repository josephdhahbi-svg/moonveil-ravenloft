import 'dart:convert';
import 'package:flutter/services.dart';

/// Read-only V4 registry. Never writes game saves or unlocks items.
class MoonveilV4Registry {
  MoonveilV4Registry({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<Map<String, dynamic>>? _cache;

  Future<Map<String, dynamic>> get catalog => _cache ??= _read();

  Future<Map<String, dynamic>> _read() async {
    final decoded = jsonDecode(
        await _bundle.loadString('assets/data/moonveil_v4_index.json'));
    if (decoded is! Map<String, dynamic> || decoded['assets'] is! List) {
      throw const FormatException('Invalid Moonveil V4 registry');
    }
    return decoded;
  }

  Future<String?> find(String category, String id) async {
    final data = await catalog;
    for (final item in data['assets'] as List) {
      if (item is Map && item['path'] == '$category/$id.png') {
        final value = item['flutter_asset'];
        if (value is String &&
            value.startsWith('assets/images/moonveil_v4/')) return value;
      }
    }
    return null;
  }

  void refresh() => _cache = null;
}
