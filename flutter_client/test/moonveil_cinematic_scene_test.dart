import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/widgets/moonveil_cinematic_scene.dart';

void main() {
  testWidgets('four-frame cinematic advances and continues only at the end',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MoonveilCinematicScene(
        title: 'The Silver Threshold',
        captions: const ['Door', 'Rune', 'Guardian', 'Choice'],
        onContinue: () => completed = true,
      ),
    )));
    expect(find.text('Frame 1 of 4'), findsOneWidget);
    for (var i = 2; i <= 4; i++) {
      await tester.tap(find.byKey(const Key('cinematic-next')));
      await tester.pumpAndSettle();
      expect(find.text('Frame $i of 4'), findsOneWidget);
    }
    expect(completed, isFalse);
    await tester.tap(find.byKey(const Key('cinematic-next')));
    expect(completed, isTrue);
  });
}
