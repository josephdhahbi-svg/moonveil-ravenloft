import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/screens/moonveil_encounter_screen.dart';

void main() {
  testWidgets('Encounter controls change preview HP and round only', (tester) async {
    final snapshot = <String, dynamic>{'hp': 10, 'maxHp': 10, 'ac': 13};
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MoonveilEncounterScreen(character: snapshot),
    )));
    await tester.tap(find.byKey(const Key('start-encounter')));
    await tester.pump();
    expect(find.textContaining('HP 10/10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('damage-vesper-vane')));
    await tester.pump();
    expect(find.textContaining('HP 9/10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('damage-vesper-vane')));
    await tester.pump();
    expect(find.textContaining('HP 8/10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('heal-vesper-vane')));
    await tester.pump();
    expect(find.textContaining('HP 9/10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next-turn')));
    await tester.pump();
    expect(find.textContaining('Round 2'), findsOneWidget);
    expect(snapshot['hp'], 10);
  });

  testWidgets('Missing checkpoint cannot start encounter', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MoonveilEncounterScreen(character: null),
    )));
    await tester.tap(find.byKey(const Key('start-encounter')));
    await tester.pump();
    expect(find.textContaining('Load a verified character'), findsOneWidget);
    expect(find.byKey(const Key('next-turn')), findsNothing);
  });
}
