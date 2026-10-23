import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'artwork_installer_service.dart';

enum ArtCategory { portrait, environment, creature, relic, spell, scene }
enum ArtStatus { queued, inProduction, review, approved, archived }

class ArtRequestRecord {
  ArtRequestRecord({required this.requestId, required this.title,
    required this.category, required this.priority,
    this.status = ArtStatus.queued, this.checksum, this.assetPath})
    : assert(priority >= 1 && priority <= 5);
  final String requestId;
  final String title;
  final ArtCategory category;
  final int priority;
  ArtStatus status;
  String? checksum;
  String? assetPath;
}

/// In-memory production queue only; approved counts are not bundled PNG counts.
class ArtProductionService {
  final List<ArtRequestRecord> _queue = [];
  final Map<String, String> _checksums = {};
  final ArtworkInstallerService _validator = ArtworkInstallerService();

  void addRequest(ArtRequestRecord record) {
    if (_queue.any((r) => r.requestId == record.requestId)) {
      throw StateError('Duplicate artwork request ID');
    }
    _queue.add(record);
    _queue.sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<Map<String, Object>> validateAndIngestAsset({
    required String requestId, required Uint8List bytes,
    required int width, required int height,
  }) async {
    final index = _queue.indexWhere((r) => r.requestId == requestId);
    if (index < 0) return {'status': 'UNKNOWN_REQUEST'};
    if (width <= 0 || height <= 0 || !_validator.verifyPngStructure(bytes)) {
      return {'status': 'INVALID_PNG'};
    }
    final ratio = width / height;
    if ((ratio - 16 / 9).abs() > 0.1 && (ratio - 1).abs() > 0.1) {
      return {'status': 'INVALID_ASPECT_RATIO'};
    }
    final hashBytes = await Sha256().hash(bytes);
    final hash = hashBytes.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (_checksums.values.contains(hash) && _checksums[requestId] != hash) {
      return {'status': 'DUPLICATE_WARNING', 'checksum': hash};
    }
    _checksums[requestId] = hash;
    _queue[index].checksum = hash;
    _queue[index].status = ArtStatus.review;
    return {'status': 'READY_FOR_REVIEW', 'checksum': hash};
  }

  bool approve(String requestId, String bundledAssetPath) {
    final index = _queue.indexWhere((r) => r.requestId == requestId);
    if (index < 0 || _queue[index].status != ArtStatus.review ||
        !bundledAssetPath.startsWith('assets/images/') ||
        !bundledAssetPath.endsWith('.png') ||
        bundledAssetPath.split('/').contains('..')) return false;
    _queue[index].assetPath = bundledAssetPath;
    _queue[index].status = ArtStatus.approved;
    return true;
  }

  int get reviewedCount => _queue.where((r) => r.status == ArtStatus.review).length;
  int get approvedRequestCount => _queue.where((r) => r.status == ArtStatus.approved).length;
  List<ArtRequestRecord> get queue => List.unmodifiable(_queue);
}
