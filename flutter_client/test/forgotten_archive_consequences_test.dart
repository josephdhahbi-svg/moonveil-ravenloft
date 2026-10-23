import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/models/forgotten_archive_consequences.dart';

void main() {
  test('each of the five archive choices has a unique narrative outcome', () {
    const choices = [
      'Lawful Good', 'Neutral Good', 'Chaotic Good', 'Utility', 'Action',
    ];
    final outcomes = choices.map(ForgottenArchiveConsequences.describe).toList();
    expect(outcomes.every((outcome) => outcome != null && outcome.isNotEmpty), isTrue);
    expect(outcomes.toSet().length, choices.length);
    expect(ForgottenArchiveConsequences.describe('Unknown'), isNull);
  });
}
