import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'system_override_command_dispatcher.dart';

/// Optional AUTOMATIC1111 bridge. Does not claim that images are saved to the app bundle.
class PhotorealisticGenerationPipelineService {
  static const String defaultEndpoint = 'http://127.0.0.1:7860/sdapi/v1/txt2img';

  static String getMasterPhotorealPromptDirective({required String subjectName, required String environmentDetails}) =>
      'Photorealistic cinematic film still of $subjectName. $environmentDetails. '
      'Natural skin and fabric detail, gothic atmosphere, volumetric light, realistic 35mm photography.';

  static Future<Uint8List> requestPhotorealisticAssetGeneration({
    required String assetKey,
    required String promptDescription,
    required String endpoint,
    http.Client? client,
  }) async {
    if (SystemOverrideCommandDispatcher.isImageGenerationBlocked) {
      throw StateError('Image generation blocked by system override.');
    }
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Enter a valid HTTP(S) Stable Diffusion endpoint.');
    }
    final transport = client ?? http.Client();
    try {
      final response = await transport.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': getMasterPhotorealPromptDirective(subjectName: assetKey, environmentDetails: promptDescription),
          'negative_prompt': 'cartoon, anime, illustration, painting, sketch, plastic skin, blurry, low resolution',
          'steps': 30, 'width': 768, 'height': 768, 'cfg_scale': 7,
        }),
      ).timeout(const Duration(minutes: 4));
      if (response.statusCode != 200) {
        throw StateError('Image server returned HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['images'] is! List || (decoded['images'] as List).isEmpty) {
        throw const FormatException('Image server response contains no images.');
      }
      final encoded = (decoded['images'] as List).first;
      if (encoded is! String) throw const FormatException('Unexpected image response type.');
      final bytes = base64Decode(encoded.contains(',') ? encoded.split(',').last : encoded);
      if (bytes.isEmpty) throw const FormatException('Image response is empty.');
      return bytes;
    } finally {
      if (client == null) transport.close();
    }
  }
}
