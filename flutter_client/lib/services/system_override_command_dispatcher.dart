import 'package:flutter/foundation.dart';

/// Process-local safety gate. Default OFF: image generation is disabled.
/// No claim of locking SQLite, GitHub, or other devices.
class SystemOverrideCommandDispatcher {
  static final ValueNotifier<bool> imageGenerationBlocked = ValueNotifier<bool>(true);
  static bool get isImageGenerationBlocked => imageGenerationBlocked.value;

  static void executeSystemOverride() {
    imageGenerationBlocked.value = true;
    debugPrint('[SystemOverride] Image generation disabled in this app process.');
  }
}
