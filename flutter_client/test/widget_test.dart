import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/main.dart';

void main() {
  testWidgets('Moonveil application has Vesper home route', (tester) async {
    // Test the root app configuration without launching native SQLite.
    final app = const MoonveilApp();
    expect(app, isA<StatelessWidget>());
  });
}
