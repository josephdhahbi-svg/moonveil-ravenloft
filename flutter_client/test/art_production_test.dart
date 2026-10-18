import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/art_production_service.dart';

void main() {
  test('Priority ordering and unique request IDs', () {
    final service = ArtProductionService();
    service.addRequest(ArtRequestRecord(requestId: 'p', title: 'Portrait',
      category: ArtCategory.portrait, priority: 4));
    service.addRequest(ArtRequestRecord(requestId: 'r', title: 'Ruins',
      category: ArtCategory.environment, priority: 1));
    expect(service.queue.first.requestId, 'r');
    expect(() => service.addRequest(ArtRequestRecord(requestId: 'r',
      title: 'Again', category: ArtCategory.scene, priority: 2)), throwsStateError);
  });

  test('Rejects invalid artwork without approving it', () async {
    final service = ArtProductionService();
    service.addRequest(ArtRequestRecord(requestId: 'x', title: 'Relic',
      category: ArtCategory.relic, priority: 2));
    final result = await service.validateAndIngestAsset(
      requestId: 'x', bytes: Uint8List.fromList([1, 2, 3, 4]),
      width: 1024, height: 1024);
    expect(result['status'], 'INVALID_PNG');
    expect(service.approvedRequestCount, 0);
    expect(service.reviewedCount, 0);
    expect(service.approve('x', 'assets/images/items/x.png'), isFalse);
  });
}
