import 'package:flutter/material.dart';
import '../models/moonveil_category_registry.dart';
import '../services/moonveil_asset_registry_service.dart';
import '../storage/moonveil_database.dart';

class MoonveilCategoryBrowser extends StatefulWidget {
  const MoonveilCategoryBrowser({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<MoonveilCategoryBrowser> createState() => _MoonveilCategoryBrowserState();
}

class _MoonveilCategoryBrowserState extends State<MoonveilCategoryBrowser> {
  MoonveilCategory selected = MoonveilCategory.localMobileArchitecture;
  late Future<List<Map<String, dynamic>>> assets;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    assets = MoonveilAssetRegistryService(widget.database).fetchAssetsForCategory(selected);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Moonveil VTT Categories', style: Theme.of(context).textTheme.titleLarge),
      DropdownButton<MoonveilCategory>(
        value: selected,
        isExpanded: true,
        items: [for (final category in MoonveilCategory.values)
          DropdownMenuItem(value: category, child: Text(category.displayName))],
        onChanged: (value) {
          if (value != null) setState(() { selected = value; refresh(); });
        },
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: assets,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Asset registry error: ${snapshot.error}');
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty) return const Text('No assets bound to this category.');
          return Column(children: [
            for (final item in snapshot.data!)
              ListTile(
                leading: Icon(item['exists'] == true ? Icons.image : Icons.image_not_supported),
                title: Text(item['title'].toString()),
                subtitle: Text(item['exists'] == true ? item['path'].toString() : 'Missing bundled PNG: ${item['path']}'),
              ),
          ]);
        },
      ),
    ],
  );
}
