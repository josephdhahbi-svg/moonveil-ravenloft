import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/widgets/moonveil_image_navigation.dart';

void main() {
  testWidgets('Image navigation opens the requested tab even when art is missing',
      (tester) async {
    String? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: MoonveilImageNavigation(onOpenTab: (tab) => opened = tab),
      )),
    ));
    await tester.pump();
    await tester.tap(find.text('Locations').first);
    expect(opened, 'Atlas');
    await tester.ensureVisible(find.text('Items').first);
    await tester.tap(find.text('Items').first);
    expect(opened, 'Inventory');
  });
}
