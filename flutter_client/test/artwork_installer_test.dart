import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/artwork_installer_service.dart';

void main() {
  final service = ArtworkInstallerService();
  test('Rejects missing PNG payload and unsafe paths', () async {
    final header = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    expect(service.verifyPngSignature(header), isTrue);
    expect(service.verifyPngStructure(header), isFalse);
    final invalid = await service.processArtworkAsset(
      relativePath: 'assets/images/fake.png', imageBytes: header);
    expect(invalid['status'], 'INVALID_PNG');
    final unsafe = await service.processArtworkAsset(
      relativePath: 'assets/images/../bad.png', imageBytes: header);
    expect(unsafe['status'], 'INVALID_PATH');
  });
}
