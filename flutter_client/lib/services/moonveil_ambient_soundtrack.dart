import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Original procedurally synthesized, royalty-free ambient loop.
/// Produces standard mono PCM WAV bytes, no remote files or licenses required.
class MoonveilAmbientSoundtrack {
  static const sampleRate = 16000;
  static const seconds = 8;

  static Uint8List generate() {
    final samples = sampleRate * seconds;
    final dataLength = samples * 2;
    final bytes = ByteData(44 + dataLength);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }
    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);
    const tones = [110.0, 164.81, 220.0, 329.63];
    for (var i = 0; i < samples; i++) {
      final t = i / sampleRate;
      // Loop boundaries fade to zero to avoid audible clicks.
      final envelope = math.pow(math.sin(math.pi * t / seconds), 2).toDouble();
      var wave = 0.0;
      for (var j = 0; j < tones.length; j++) {
        final phase = 2 * math.pi * tones[j] * t;
        wave += math.sin(phase) * (0.28 / (j + 1));
      }
      final shimmer = math.sin(2 * math.pi * 0.125 * t) * 0.12 + 0.88;
      final value = (wave * envelope * shimmer * 11000).round().clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, value, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}

/// Audio starts only after an explicit user tap (mobile/web autoplay safe).
class MoonveilMusicController {
  final AudioPlayer _player = AudioPlayer();
  bool playing = false;

  Future<void> start() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.24);
    await _player.play(BytesSource(MoonveilAmbientSoundtrack.generate()));
    playing = true;
  }

  Future<void> stop() async {
    await _player.stop();
    playing = false;
  }

  Future<void> dispose() async => _player.dispose();
}
