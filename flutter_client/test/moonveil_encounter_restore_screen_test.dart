import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/screens/moonveil_encounter_screen.dart';
import 'package:moonveil_client/services/moonveil_encounter_codec.dart';
import 'package:moonveil_client/services/moonveil_encounter_engine.dart';

void main() {
  testWidgets('restores a copied encounter snapshot in the UI', (tester) async {
    final encounter = MoonveilEncounter([const MoonveilCombatant(
      id: 'vesper', name: 'Vesper Vane', initiative: 15,
      maxHp: 10, hp: 7, ac: 13,
    )]);
    final snapshot = MoonveilEncounterCodec.encode(encounter);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: MoonveilEncounterScreen(character: null),
      ),
    )));
    await tester.enterText(find.byKey(const Key('encounter-import-json')), snapshot);
    await tester.ensureVisible(find.byKey(const Key('restore-encounter')));
    await tester.tap(find.byKey(const Key('restore-encounter')));
    await tester.pumpAndSettle();
    expect(find.textContaining('HP 7/10'), findsOneWidget);
    expect(find.byKey(const Key('copy-encounter-json')), findsOneWidget);
  });
}
