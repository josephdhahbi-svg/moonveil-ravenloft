import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/character_profile.dart';
import '../storage/moonveil_database.dart';

class CharacterLibraryService {
  static const assetPath = 'assets/data/characters_ravenloft.json';

  /// Optional reference catalog, not authoritative player saves.
  /// Missing or malformed assets are reported, not replaced with invented heroes.
  static Future<List<CharacterProfile>> loadCharacterLibrary() async {
    final source = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! List) throw const FormatException('Character catalog must be a JSON list');
    return decoded.map((entry) {
      if (entry is! Map<String, dynamic>) throw const FormatException('Invalid character catalog entry');
      return CharacterProfile.fromJson(entry,
        characterId: entry['id']?.toString() ?? 'unknown');
    }).toList(growable: false);
  }

  static Future<CharacterProfile?> loadVesper(MoonveilDatabase database) async {
    if (database.campaignId != 'vesper') throw ArgumentError('Expected Vesper database');
    final state = await database.loadCharacter('vesper-vane');
    if (state == null) return null;
    final rows = await database.db.query('inventory_entries',
      columns: ['item_id', 'item_json'], where: 'campaign_id = ? AND character_id = ? AND owned = 1',
      whereArgs: ['vesper', 'vesper-vane'], orderBy: 'item_id');
    final items = rows.map((row) {
      final decoded = jsonDecode(row['item_json'] as String);
      if (decoded is Map && decoded['name'] is String) return decoded['name'] as String;
      return row['item_id'] as String;
    }).toList(growable: false);
    return CharacterProfile.fromJson(state, ownedItems: items);
  }

  static const vesperPortrait = 'assets/images/portraits/vesper_vane.png';
}
