import 'package:flutter/foundation.dart';

/// Resolves shorthand image requests into prompts. Does not render or save images.
class MultiversalGenerationCommandBridge {
  static const Map<String, String> _commands = {
    'A': 'photorealistic cinematic portrait of a female dhampir undead warlock with pale skin, silver hair, dark gothic velvet coat, candlelit ancient stone chamber, realistic skin texture, 35mm photography',
    'B': 'photorealistic cinematic gothic medieval castle on a jagged mountain cliff, thick Barovian fog, moonlight, dramatic natural lighting, realistic stone textures',
    'C': 'photorealistic futuristic emblem with purple and amber circuit lines, metallic sheen, dark cosmic background, cinematic studio lighting',
    'D': 'photorealistic silver and purple multiversal crest with intricate runes, ethereal light, finely worked metal, cinematic studio photography',
    'E': 'photorealistic futuristic mobile HUD control plate, dark purple and amber interface, metallic frame, tactical instrumentation, cinematic product photography',
  };

  static const Map<String, String> _aliases = {
    'ART FOR DHAMPIR WARLOCK PORTRAIT': 'A',
    'ART FOR RAVENLOFT SECTOR CARD ICON': 'B',
    'ART FOR COPILOT SYNC CORE EMBLEM': 'C',
    'ART FOR MOONVEIL MULTIVERSE LOGO': 'D',
    'ART FOR VESPER CHARACTER SHEET HUD': 'E',
  };

  static String resolveCommandQuery(String userCommand) {
    final cleaned = userCommand.trim();
    if (cleaned.isEmpty) throw ArgumentError.value(userCommand, 'userCommand', 'Prompt must not be empty');
    final key = cleaned.toUpperCase();
    final resolvedKey = _aliases[key] ?? key;
    return _commands[resolvedKey] ??
        'photorealistic cinematic image of $cleaned, realistic materials, natural textures, dramatic lighting, 35mm photography';
  }

  static void logBridgeCommandExecution(String command) {
    debugPrint('[GenerationBridge] Prompt resolved for: ${command.trim()}');
  }
}
