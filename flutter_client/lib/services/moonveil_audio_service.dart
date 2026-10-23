import 'package:flutter/services.dart';

/// Non-blocking platform UI sound effects; no third-party audio assets needed.
/// Background music and voice/video tracks require licensed media assets.
class MoonveilAudioService {
  const MoonveilAudioService();

  Future<void> playUiCue({bool enabled = true}) async {
    if (!enabled) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } on MissingPluginException {
      // Browsers/platforms without a system sound implementation stay playable.
    } on PlatformException {
      // Audio failure must never interrupt encounter state.
    }
  }
}
