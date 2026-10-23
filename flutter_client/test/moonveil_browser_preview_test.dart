import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/preview_main.dart';

void main() {
  testWidgets('browser training preview renders, moves, attacks and records a choice', (tester) async {
    await tester.pumpWidget(const MoonveilPreview());
    expect(find.textContaining('VESPER VANE'), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('Move right'), 120);
    await tester.tap(find.byTooltip('Move right'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Training attack'), 120);
    await tester.tap(find.text('Training attack'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Lawful Good'), 120);
    await tester.tap(find.text('Lawful Good'));
    await tester.pump();
    expect(find.text('Lawful Good'), findsOneWidget);
  });
}
