import 'dart:convert';
import 'package:flutter/services.dart';

class MoonveilAssetGateway {
  MoonveilAssetGateway({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<Map<String, dynamic>>? _cached;
  Future<Map<String, dynamic>> get index => _cached ??= _load();

  Future<Map<String, dynamic>> _load() async {
    final data = jsonDecode(await _bundle.loadString('assets/data/vesper_v3_index.json'));
    if (data is! Map<String, dynamic> || data['assets'] is! List) {
      throw const FormatException('Invalid asset index');
    }
    return data;
  }

  Future<String?> resolve(String category, String name) async {
    final data = await index;
    for (final entry in data['assets'] as List) {
      if (entry is Map && entry['path'] == '$category/$name.png') {
        final asset = entry['flutter_asset'];
        if (asset is String && asset.startsWith('assets/images/vesper_v3/')) {
          return asset;
        }
      }
    }
    return null;
  }

  void refresh() => _cached = null;
}
