import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/moonveil_art_director.dart';
import 'moonveil_speech_bubble.dart';

/// Numbered art and scripted dialogue remain independent data layers.
class MoonveilNumberedSceneCard extends StatefulWidget {
  const MoonveilNumberedSceneCard({
    super.key, required this.assetId, required this.scriptId,
    required this.speaker, required this.dialogue,
    this.kind = MoonveilBubbleKind.hero,
  });
  final String assetId, scriptId, speaker, dialogue;
  final MoonveilBubbleKind kind;

  @override
  State<MoonveilNumberedSceneCard> createState() =>
      _MoonveilNumberedSceneCardState();
}

class _MoonveilNumberedSceneCardState extends State<MoonveilNumberedSceneCard> {
  final MoonveilArtDirector director = MoonveilArtDirector();
  late String draft;

  @override
  void initState() {
    super.initState();
    draft = widget.dialogue;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MoonveilArtRecord?>(
      future: director.byId(widget.assetId),
      builder: (context, snapshot) {
        final art = snapshot.data;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 16 / 9,
                child: art == null
                  ? const ColoredBox(color: Color(0xFF171827),
                      child: Center(child: Text('Artwork not installed')))
                  : Image.asset(art.assetPath, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Text('Image unavailable')))),
              Padding(padding: const EdgeInsets.all(10),
                child: Text('${widget.assetId} / ${widget.scriptId}'
                    '${art == null ? '' : ' - ${art.label}'}')),
              MoonveilSpeechBubble(
                text: draft, speaker: widget.speaker, kind: widget.kind,
                onEdit: (value) => setState(() => draft = value)),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy numbered script'),
                onPressed: () => Clipboard.setData(ClipboardData(
                  text: jsonEncode({
                    'asset_id': widget.assetId,
                    'script_id': widget.scriptId,
                    'speaker': widget.speaker,
                    'dialogue': draft,
                  }))),
              ),
            ],
          ),
        );
      },
    );
  }
}
