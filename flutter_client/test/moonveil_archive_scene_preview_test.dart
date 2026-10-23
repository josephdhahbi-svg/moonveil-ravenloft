import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/widgets/moonveil_archive_scene_preview.dart';

void main() {
  testWidgets('each heroic choice previews a distinct scene and opens encounter',
      (tester) async {
    var opened = false;
    for (final choice in MoonveilArchiveScenePreview.outcomes.keys) {
      opened = false;
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: MoonveilArchiveScenePreview(
          choice: choice, onEncounter: () => opened = true),
      )));
      final scene = MoonveilArchiveScenePreview.outcomes[choice]!;
      expect(find.text(scene.title), findsNWidgets(2));
      expect(find.text(scene.story), findsOneWidget);
      await tester.tap(find.byKey(const Key('scene-open-encounter')));
      expect(opened, isTrue);
    }
  });

  testWidgets('no choice does not fabricate a scene', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MoonveilArchiveScenePreview(
        choice: null, onEncounter: () {}),
    )));
    expect(find.byKey(const Key('archive-scene-preview')), findsNothing);
  });
}
