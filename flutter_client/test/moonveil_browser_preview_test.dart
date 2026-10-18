import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/preview_main.dart';

void main() {
  testWidgets('browser training preview moves, attacks and records a choice', (tester) async {
    await tester.pumpWidget(const MoonveilPreview());
    expect(find.textContaining('VESPER VANE'), findsOneWidget);
    expect(find.textContaining('Guardian HP'), findsOneWidget);
    await tester.tap(find.byTooltip('Move right'));
    await tester.pump();
    expect(find.textContaining('Vesper moves to (4, 4)'), findsOneWidget);
    await tester.tap(find.text('Training attack'));
    await tester.pump();
    expect(find.textContaining('Guardian HP'), findsOneWidget);
    await tester.ensureVisible(find.text('Lawful Good'));
    await tester.tap(find.text('Lawful Good'));
    await tester.pump();
    expect(find.textContaining('Preview choice: Lawful Good'), findsOneWidget);
  });
}
