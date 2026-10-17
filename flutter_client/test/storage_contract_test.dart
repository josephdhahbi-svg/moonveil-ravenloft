import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/storage/moonveil_database.dart';
import 'package:moonveil_client/storage/moonveil_backup.dart';

void main() {
  test('campaign allowlist excludes unexpected save partitions', () {
    expect(MoonveilDatabase.allowedCampaigns, containsAll(['vesper', 'alice']));
    expect(MoonveilDatabase.allowedCampaigns, isNot(contains('default')));
  });

  test('encrypted backup declares a versioned format', () {
    expect(MoonveilBackup.format, 'moonveil-logical-backup-v1');
  });
}
