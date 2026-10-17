import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/photorealistic_generation_pipeline_service.dart';

class PhotorealisticGeneratorHubScreen extends StatefulWidget {
  const PhotorealisticGeneratorHubScreen({super.key});
  @override
  State<PhotorealisticGeneratorHubScreen> createState() => _PhotorealisticGeneratorHubScreenState();
}

class _PhotorealisticGeneratorHubScreenState extends State<PhotorealisticGeneratorHubScreen> {
  final endpoint = TextEditingController(text: PhotorealisticGenerationPipelineService.defaultEndpoint);
  final queue = const [
    ('vesper_portrait', 'Female dhampir warlock Vesper Vane, silver hair, gothic velvet coat, candlelit dark chamber'),
    ('castle_ravenloft', 'Towering gothic medieval castle on jagged cliff, moonlight and dense Barovian fog'),
    ('relic_sight', 'Ancient enchanted glass eye, ethereal silver runes, weathered stone altar'),
    ('shrine_mystra', 'Mystra shrine, blue arcane weave energy and crystalline architecture, candlelight'),
  ];
  final Map<String, Uint8List> previews = {};
  final Map<String, String> statuses = {};
  bool running = false;

  @override
  void dispose() { endpoint.dispose(); super.dispose(); }

  Future<void> renderQueue() async {
    setState(() { running = true; statuses.clear(); });
    for (final item in queue) {
      if (!mounted) return;
      setState(() => statuses[item.$1] = 'Rendering...');
      try {
        final bytes = await PhotorealisticGenerationPipelineService.requestPhotorealisticAssetGeneration(
          assetKey: item.$1, promptDescription: item.$2, endpoint: endpoint.text.trim());
        if (!mounted) return;
        setState(() { previews[item.$1] = bytes; statuses[item.$1] = 'Rendered in memory — not yet saved to project assets'; });
      } catch (error) {
        if (!mounted) return;
        setState(() => statuses[item.$1] = 'Failed: $error');
      }
    }
    if (mounted) setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Photorealistic Generator Hub', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Requires your own running AUTOMATIC1111 server. 127.0.0.1 refers to this device, not your PC when using a phone. Rendered previews are not saved to Flutter assets or GitHub.'),
      const SizedBox(height: 12),
      TextField(controller: endpoint, enabled: !running,
        decoration: const InputDecoration(labelText: 'Stable Diffusion API URL', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      ElevatedButton.icon(onPressed: running ? null : renderQueue,
        icon: const Icon(Icons.camera_enhance), label: Text(running ? 'Rendering queue...' : 'Render four images')),
      for (final item in queue) Card(child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(item.$2),
          Text(statuses[item.$1] ?? 'Not rendered'),
          if (previews[item.$1] != null) Image.memory(previews[item.$1]!, height: 220, fit: BoxFit.contain),
        ]),
      )),
    ],
  );
}
