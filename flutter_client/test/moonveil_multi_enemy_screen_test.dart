import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/screens/moonveil_encounter_screen.dart';

void main() {
  testWidgets('Queues multiple enemies and records conditions in expandable history',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: MoonveilEncounterScreen(
          character: const {'hp': 10, 'maxHp': 10, 'ac': 13},
        ),
      ),
    )));
    await tester.tap(find.byKey(const Key('include-enemy')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('add-enemy')));
    await tester.tap(find.byKey(const Key('add-enemy')));
    await tester.pump();
    expect(find.byKey(const Key('queued-enemy-1')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('add-enemy')));
    await tester.tap(find.byKey(const Key('add-enemy')));
    await tester.pump();
    expect(find.byKey(const Key('queued-enemy-2')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('start-encounter')));
    await tester.tap(find.byKey(const Key('start-encounter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('combatant-enemy-1')), findsOneWidget);
    expect(find.byKey(const Key('combatant-enemy-2')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('conditions-vesper-vane')));
    await tester.tap(find.byKey(const Key('conditions-vesper-vane')));
    await tester.pumpAndSettle();
    final poisoned = find.byKey(const Key('condition-vesper-vane-poisoned'));
    await tester.ensureVisible(poisoned);
    await tester.tap(poisoned);
    await tester.pumpAndSettle();
    expect(find.textContaining('Poisoned'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('combat-history')));
    await tester.tap(find.byKey(const Key('combat-history')));
    await tester.pumpAndSettle();
    expect(find.textContaining('condition_added:Poisoned'), findsOneWidget);
  });
}
