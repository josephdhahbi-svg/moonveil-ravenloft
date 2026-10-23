import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reference-art catalog. Never modifies equipment, attunement, or campaign saves.
class MoonveilV11InventoryAlbum extends StatefulWidget {
  const MoonveilV11InventoryAlbum({super.key});
  @override
  State<MoonveilV11InventoryAlbum> createState() => _MoonveilV11InventoryAlbumState();
}

class _MoonveilV11InventoryAlbumState extends State<MoonveilV11InventoryAlbum> {
  late final Future<List<Map<String, dynamic>>> _assets = _load();
  String category = 'eyes';
  String filter = '';

  static const categories = <String>[
    'eyes', 'hands', 'longswords', 'staffs', 'cloaks', 'gems',
    'spells', 'focuses', 'books', 'scrolls', 'cards', 'miscellaneous',
  ];

  Future<List<Map<String, dynamic>>> _load() async {
    final raw = jsonDecode(await rootBundle.loadString(
        'assets/data/moonveil_item_albums_v11_index.json'));
    if (raw is! Map || raw['atlas_id'] != 'moonveil-item-albums-v11' ||
        raw['assets'] is! List) {
      throw const FormatException('Invalid V11 item catalog');
    }
    final records = <Map<String, dynamic>>[];
    for (final item in raw['assets'] as List) {
      if (item is! Map || item['id'] is! String ||
          item['category'] is! String || item['path'] is! String) {
        throw const FormatException('Invalid V11 item record');
      }
      final id = item['id'] as String;
      final group = item['category'] as String;
      final path = item['path'] as String;
      if (!RegExp(r'^[A-Z]{2}-[0-9]{3}$').hasMatch(id) ||
          !categories.contains(group) ||
          path != '$group/$id.png') {
        throw const FormatException('Unsafe V11 asset reference');
      }
      records.add(Map<String, dynamic>.from(item));
    }
    if (records.length != 120 || records.map((e) => e['id']).toSet().length != 120) {
      throw const FormatException('Expected 120 unique V11 images');
    }
    return records;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _assets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SelectableText('V11 catalog unavailable: ${snapshot.error}');
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final matches = snapshot.data!.where((item) =>
            item['category'] == category &&
            ('${item['id']} ${item['label']}'.toLowerCase()
                .contains(filter.toLowerCase()))).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('V11 Item Albums — Reference Artwork',
              style: Theme.of(context).textTheme.titleLarge),
          const Text('Images are catalog references, not acquired or equipped items.'),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: category, isExpanded: true,
            items: [for (final c in categories)
              DropdownMenuItem(value: c, child: Text(c.toUpperCase()))],
            onChanged: (value) {
              if (value != null) setState(() => category = value);
            },
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search album by ID or label',
              prefixIcon: Icon(Icons.search)),
            onChanged: (value) => setState(() => filter = value),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160, mainAxisExtent: 172,
              mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemBuilder: (context, index) {
              final item = matches[index];
              final path = 'assets/images/moonveil_item_albums_v11/${item['path']}';
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  Expanded(child: Image.asset(path, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Art pending installation',
                        textAlign: TextAlign.center)))),
                  Padding(padding: const EdgeInsets.all(5),
                    child: Text('${item['id']} — ${item['label']}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center)),
                ]),
              );
            },
          ),
        ]);
      },
    );
  }
}
