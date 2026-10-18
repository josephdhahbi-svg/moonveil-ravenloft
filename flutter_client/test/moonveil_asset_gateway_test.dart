import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/moonveil_asset_gateway.dart';

class CountingBundle extends CachingAssetBundle {
  CountingBundle(this.payload);
  final String payload;
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final bytes = utf8.encode(payload);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Gateway caches registry and resolves exact image IDs', () async {
    final bundle = CountingBundle(jsonEncode({
      'assets': [
        {
          'path': 'portraits/vesper_nordic.png',
          'flutter_asset': 'assets/images/vesper_v3/portraits/vesper_nordic.png',
        },
      ],
    }));
    final gateway = MoonveilAssetGateway(bundle: bundle);
    expect(await gateway.resolve('portraits', 'vesper_nordic'),
        'assets/images/vesper_v3/portraits/vesper_nordic.png');
    expect(await gateway.resolve('portraits', 'missing'), isNull);
    expect(bundle.loads, 1);
    gateway.refresh();
    expect(await gateway.resolve('portraits', 'vesper_nordic'), isNotNull);
    expect(bundle.loads, 2);
  });

  test('Gateway rejects invalid registry structure', () async {
    final gateway = MoonveilAssetGateway(bundle: CountingBundle('{"assets":{}}'));
    await expectLater(gateway.index, throwsFormatException);
  });
}
