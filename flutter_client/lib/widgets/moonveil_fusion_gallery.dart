import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual-only fusion preview. No database access, inventory consumption,
/// or campaign progression changes are performed by this widget.
class MoonveilFusionGallery extends StatefulWidget {
  const MoonveilFusionGallery({super.key});
  @override
  State<MoonveilFusionGallery> createState() => _MoonveilFusionGalleryState();
}

class _MoonveilFusionGalleryState extends State<MoonveilFusionGallery> {
  late final Future<Map<String, dynamic>> _recipes = _load();
  String? selected;

  Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await rootBundle.loadString(
        'assets/data/moonveil_visual_fusion_recipes.json')) as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _recipes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Visual recipes unavailable: ${snapshot.error}');
        }
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!;
        final recipes = (data['recipes'] as List<dynamic>).cast<Map<String, dynamic>>();
        final chosen = recipes.firstWhere((r) => r['id'] == selected,
          orElse: () => recipes.first);
        final layers = (chosen['layers'] as List<dynamic>).cast<String>();
        final prefix = data['asset_prefix'] as String;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Ritual and Fusion Visual Studio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Preview only. No items consumed or abilities unlocked.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final recipe in recipes)
              ChoiceChip(
                label: Text('${recipe['name']} (${recipe['status']})'),
                selected: chosen['id'] == recipe['id'],
                onSelected: (_) => setState(() => selected = recipe['id'] as String),
              ),
          ]),
          const SizedBox(height: 12),
          SizedBox(height: 230, child: Stack(fit: StackFit.expand, children: [
            for (var i = 0; i < layers.length; i++)
              Opacity(
                opacity: i == 0 ? 1 : (0.22 + i * 0.08).clamp(0.0, 0.65),
                child: Image.asset(prefix + layers[i], fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
          ])),
          const SizedBox(height: 8),
          Text('${chosen['mechanics']}',
            style: const TextStyle(color: Colors.amberAccent)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final path in layers)
              SizedBox(width: 86, child: Column(children: [
                Image.asset(prefix + path, width: 76, height: 76, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                    const SizedBox(height: 76, child: Icon(Icons.image_not_supported))),
                Text(path.split('/').last.replaceAll('.png','').replaceAll('_',' '),
                  textAlign: TextAlign.center, maxLines: 2,
                  style: const TextStyle(fontSize: 10)),
              ])),
          ]),
        ]);
      },
    );
  }
}
