import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/moonveil_ambient_soundtrack.dart';

void main() {
  test('generated soundtrack has valid WAV PCM header and audio payload', () {
    final bytes = MoonveilAmbientSoundtrack.generate();
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
    final header = ByteData.sublistView(bytes);
    expect(header.getUint32(24, Endian.little), MoonveilAmbientSoundtrack.sampleRate);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint16(34, Endian.little), 16);
    expect(header.getUint32(40, Endian.little), bytes.length - 44);
    expect(bytes.length, greaterThan(200000));
  });

  test('soundtrack generation is deterministic and non-silent', () {
    final a = MoonveilAmbientSoundtrack.generate();
    final b = MoonveilAmbientSoundtrack.generate();
    expect(a, orderedEquals(b));
    expect(a.skip(44).any((sample) => sample != 0), isTrue);
  });
}
