import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../models/moonveil_category_registry.dart';
import '../storage/moonveil_database.dart';

/// Explicit local bindings only. Missing files are reported, never fabricated.
class MoonveilAssetRegistryService {
  MoonveilAssetRegistryService(this.database);
  final MoonveilDatabase database;

  Future<void> _ensureTable() => database.db.execute('''
    CREATE TABLE IF NOT EXISTS moonveil_category_assets (
      campaign_id TEXT NOT NULL,
      category_key TEXT NOT NULL,
      asset_id TEXT NOT NULL,
      title TEXT NOT NULL,
      asset_path TEXT NOT NULL,
      PRIMARY KEY (campaign_id, category_key, asset_id)
    )
  ''');

  Future<void> bindAsset({
    required MoonveilCategory category,
    required String assetId,
    required String title,
    required String assetPath,
  }) async {
    if (!assetPath.startsWith('assets/images/') || !assetPath.toLowerCase().endsWith('.png')) {
      throw ArgumentError.value(assetPath, 'assetPath', 'Expected a bundled PNG under assets/images/');
    }
    await _ensureTable();
    await database.db.insert('moonveil_category_assets', {
      'campaign_id': database.campaignId,
      'category_key': category.dbKey,
      'asset_id': assetId,
      'title': title,
      'asset_path': assetPath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> fetchAssetsForCategory(MoonveilCategory category) async {
    await _ensureTable();
    final rows = await database.db.query('moonveil_category_assets',
      where: 'campaign_id = ? AND category_key = ?',
      whereArgs: [database.campaignId, category.dbKey],
      orderBy: 'title ASC');
    final results = <Map<String, dynamic>>[];
    for (final row in rows) {
      final path = row['asset_path'] as String;
      bool available = false;
      try {
        final bytes = await rootBundle.load(path);
        available = bytes.lengthInBytes > 0;
      } catch (_) {
        available = false;
      }
      results.add({
        'id': row['asset_id'],
        'category': category.dbKey,
        'title': row['title'],
        'path': path,
        'exists': available,
        'is_photorealistic': 'NOT_VERIFIED',
      });
    }
    return results;
  }
}
