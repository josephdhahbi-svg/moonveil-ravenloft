import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Validates artwork without changing any campaign or save data.
class ArtworkInstallerService {
  final Map<String, String> _manifest = {};
  static const _signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

  bool verifyPngSignature(Uint8List bytes) =>
      bytes.length >= 8 &&
      List.generate(8, (i) => bytes[i] == _signature[i]).every((ok) => ok);

  /// Checks the PNG signature, IHDR chunk, dimensions, and IEND marker.
  /// This is structural validation, not a full pixel decoder.
  bool verifyPngStructure(Uint8List bytes) {
    if (!verifyPngSignature(bytes) || bytes.length < 45) return false;
    final data = ByteData.sublistView(bytes);
    if (data.getUint32(8) != 13 ||
        String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR' ||
        data.getUint32(16) == 0 ||
        data.getUint32(20) == 0) return false;
    var offset = 8;
    var sawEnd = false;
    while (offset + 12 <= bytes.length) {
      final length = data.getUint32(offset);
      if (length > bytes.length - offset - 12) return false;
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      offset += length + 12;
      if (type == 'IEND') {
        if (length != 0 || offset != bytes.length) return false;
        sawEnd = true;
        break;
      }
    }
    return sawEnd;
  }

  Future<Map<String, String>> processArtworkAsset({
    required String relativePath,
    required Uint8List imageBytes,
  }) async {
    if (!relativePath.startsWith('assets/images/') ||
        !relativePath.endsWith('.png') ||
        relativePath.split('/').contains('..')) {
      return {'status': 'INVALID_PATH', 'path': relativePath};
    }
    if (!verifyPngStructure(imageBytes)) {
      return {'status': 'INVALID_PNG', 'path': relativePath};
    }
    final hashBytes = await Sha256().hash(imageBytes);
    final hash = hashBytes.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (_manifest.containsValue(hash) && _manifest[relativePath] != hash) {
      return {'status': 'DUPLICATE_CONTENT_DETECTED', 'path': relativePath, 'hash': hash};
    }
    _manifest[relativePath] = hash;
    return {'status': 'SUCCESS', 'path': relativePath, 'hash': hash};
  }

  Map<String, String> get manifest => Map.unmodifiable(_manifest);
}
