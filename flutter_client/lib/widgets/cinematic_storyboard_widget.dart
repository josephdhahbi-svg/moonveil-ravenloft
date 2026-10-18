import 'package:flutter/material.dart';
import '../models/cinematic_storyboard_model.dart';
import 'missing_image_fallback_widget.dart';

class CinematicStoryboardWidget extends StatelessWidget {
  const CinematicStoryboardWidget({super.key, required this.scene,
    required this.onChoiceSelected});
  final CinematicScene scene;
  final ValueChanged<int> onChoiceSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(scene.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth < 450 ? 1 : 2,
            childAspectRatio: 16 / 10,
            crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 4,
          itemBuilder: (context, index) {
            final panel = scene.panels[index];
            return Stack(fit: StackFit.expand, children: [
              MissingImageFallbackWidget(assetPath: panel.assetPath,
                width: double.infinity, height: double.infinity),
              Align(alignment: Alignment.bottomCenter,
                child: Container(width: double.infinity, color: Colors.black87,
                  padding: const EdgeInsets.all(8),
                  child: Text(panel.caption, maxLines: 3,
                    overflow: TextOverflow.ellipsis))),
            ]);
          }),
        const SizedBox(height: 16),
        for (var i = 0; i < 5; i++)
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              onPressed: () => onChoiceSelected(i),
              child: Text('${i + 1}. ${scene.decisionChoices[i]}'))),
      ],
    ));
}
