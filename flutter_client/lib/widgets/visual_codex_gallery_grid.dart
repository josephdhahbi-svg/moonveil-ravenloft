import 'package:flutter/material.dart';
import '../services/visual_codex_service.dart';

/// Gallery shows actual bundled artwork, and reports missing files explicitly.
class VisualCodexGalleryGrid extends StatelessWidget {
  const VisualCodexGalleryGrid({super.key});

  static const titles = <int, String>{
    1: 'The Silver Threshold',
    2: "Vaelthara's Warning",
    3: 'The Three Relics',
    4: 'An Unwritten Fate',
  };

  void _inspect(BuildContext context, int number) {
    final path = VisualCodexService.panelImageMap[number]!;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(titles[number]!, style: Theme.of(ctx).textTheme.titleLarge)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: InteractiveViewer(
                child: Image.asset(path, fit: BoxFit.contain,
                  errorBuilder: (_, error, __) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Artwork missing: $path', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PanelArtAudit>(
    future: VisualCodexAudit.checkUniquePanels(),
    builder: (context, snapshot) {
      final audit = snapshot.data;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VISUAL CODEX', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (snapshot.connectionState != ConnectionState.done)
          const LinearProgressIndicator(),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth > 650
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final number in titles.keys)
              SizedBox(width: width, child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: audit?.usable[number] == true ? () => _inspect(context, number) : null,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 170, width: double.infinity,
                      child: audit?.usable[number] == true
                        ? Image.asset(VisualCodexService.panelImageMap[number]!, fit: BoxFit.cover)
                        : Container(color: const Color(0xFF191426),
                            child: Center(child: Text(audit?.issues[number] ??
                                'Checking image...', textAlign: TextAlign.center))),
                    Padding(padding: const EdgeInsets.all(12),
                      child: Text('PANEL $number · ${titles[number]}')),
                  ]),
                ),
              )),
          ]);
        }),
      ]);
    },
  );
}
