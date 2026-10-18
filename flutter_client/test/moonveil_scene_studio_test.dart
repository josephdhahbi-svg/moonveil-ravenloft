import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/widgets/moonveil_battle_board.dart';
import 'package:moonveil_client/widgets/moonveil_four_panel_editor.dart';

void main() {
  testWidgets('Battle board bounds-checks tokens and draws a grid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SizedBox(width: 600, child: MoonveilBattleBoard(
        backgroundAsset: 'assets/images/missing.png',
        tokens: [
          MoonveilBattlePlacement(x: 2, y: 2,
            assetPath: 'assets/images/missing-token.png', label: 'Vesper'),
          MoonveilBattlePlacement(x: 20, y: 20,
            assetPath: 'assets/images/outside.png', label: 'Outside'),
        ],
      )),
    )));
    await tester.pump();
    expect(find.text('Vesper'), findsOneWidget);
    expect(find.text('Outside'), findsNothing);
  });

  testWidgets('Four panel editor keeps five ordered choices', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: MoonveilFourPanelEditor()),
    )));
    await tester.pump();
    for (final label in [
      '1. Lawful Good', '2. Neutral Good', '3. Chaotic Good',
      '4. Utility', '5. Action',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('4. Utility'));
    await tester.pump();
    expect(find.text('4. Utility (preview selected)'), findsOneWidget);
  });
}
