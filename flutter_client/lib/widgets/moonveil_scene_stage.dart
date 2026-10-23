import 'package:flutter/material.dart';
import 'moonveil_speech_bubble.dart';

/// Reusable scenery and combat backdrop, with optional editable speech.
/// Background art and text are separate composited layers.
class MoonveilSceneStage extends StatefulWidget {
  const MoonveilSceneStage({
    super.key,
    required this.backgroundAsset,
    this.title = 'Scene',
    this.speaker = 'Vesper Vane',
    this.initialDialogue = '',
    this.kind = MoonveilBubbleKind.hero,
    this.battle = false,
    this.onDialogueChanged,
  });

  final String backgroundAsset;
  final String title;
  final String speaker;
  final String initialDialogue;
  final MoonveilBubbleKind kind;
  final bool battle;
  final ValueChanged<String>? onDialogueChanged;

  @override
  State<MoonveilSceneStage> createState() => _MoonveilSceneStageState();
}

class _MoonveilSceneStageState extends State<MoonveilSceneStage> {
  late String dialogue;

  @override
  void initState() {
    super.initState();
    dialogue = widget.initialDialogue;
  }

  @override
  void didUpdateWidget(covariant MoonveilSceneStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDialogue != widget.initialDialogue ||
        oldWidget.backgroundAsset != widget.backgroundAsset) {
      dialogue = widget.initialDialogue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(widget.backgroundAsset, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF191724),
              child: const Center(child: Text('Background art not installed')))),
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xDD080A13)]))),
          Align(alignment: Alignment.topLeft,
            child: Padding(padding: const EdgeInsets.all(12),
              child: Text(widget.title,
                style: const TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.bold)))),
          if (widget.battle)
            const Align(alignment: Alignment.topRight,
              child: Padding(padding: EdgeInsets.all(12),
                child: Chip(label: Text('Battle scene preview')))),
          Align(alignment: Alignment.bottomCenter,
            child: Padding(padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: MoonveilSpeechBubble(
                  text: dialogue,
                  speaker: widget.speaker,
                  kind: widget.kind,
                  onEdit: (value) {
                    setState(() => dialogue = value);
                    widget.onDialogueChanged?.call(value);
                  },
                )))),
        ]),
      ),
    );
  }
}
