import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/screens/moonveil_master_gui_and_ai_hub.dart';

void main() {
  testWidgets('Command notes do not claim webhook connectivity', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MoonveilMasterGuiAndAiHub()));
    expect(find.textContaining('No AI webhook connected'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Inspect Sector D');
    await tester.tap(find.byTooltip('Add local note'));
    await tester.pump();
    expect(find.text('Inspect Sector D'), findsOneWidget);
    expect(find.textContaining('Processed prompt via Node.js'), findsNothing);
  });

  testWidgets('Command notes do not survive widget recreation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MoonveilMasterGuiAndAiHub()));
    await tester.enterText(find.byType(TextField), 'Uncommitted note');
    await tester.tap(find.byTooltip('Add local note'));
    await tester.pump();
    expect(find.text('Uncommitted note'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: MoonveilMasterGuiAndAiHub()));
    expect(find.text('Uncommitted note'), findsNothing);
  });
}
