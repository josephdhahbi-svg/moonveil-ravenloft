import 'package:flutter/material.dart';

enum MoonveilBubbleKind { hero, villain, ally, narration, system }

/// Blank, reusable speech bubble: text is always a separate editable overlay.
/// No text is baked into scene artwork.
class MoonveilSpeechBubble extends StatelessWidget {
  const MoonveilSpeechBubble({
    super.key,
    required this.text,
    this.speaker,
    this.kind = MoonveilBubbleKind.hero,
    this.onEdit,
  });

  final String text;
  final String? speaker;
  final MoonveilBubbleKind kind;
  final ValueChanged<String>? onEdit;

  Color get borderColor => switch (kind) {
    MoonveilBubbleKind.hero => const Color(0xFF72B7F3),
    MoonveilBubbleKind.villain => const Color(0xFFE36B6B),
    MoonveilBubbleKind.ally => const Color(0xFF81C8AA),
    MoonveilBubbleKind.narration => const Color(0xFFD5B77A),
    MoonveilBubbleKind.system => const Color(0xFF87B8FF),
  };

  Future<void> _edit(BuildContext context) async {
    if (onEdit == null) return;
    final controller = TextEditingController(text: text);
    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${speaker ?? 'dialogue'}'),
        content: TextField(
          controller: controller, autofocus: true, maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Script or dialogue', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Apply')),
        ],
      ),
    );
    controller.dispose();
    if (updated != null) onEdit!(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${speaker ?? 'Narrator'}: $text',
      child: InkWell(
        onTap: onEdit == null ? null : () => _edit(context),
        child: CustomPaint(
          painter: _BubbleOutline(color: borderColor),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 18, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (speaker != null) Text(speaker!,
                  style: TextStyle(color: borderColor,
                    fontWeight: FontWeight.bold)),
                if (speaker != null) const SizedBox(height: 5),
                Text(text.isEmpty ? (onEdit == null ? '' : 'Tap to write dialogue')
                    : text,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleOutline extends CustomPainter {
  const _BubbleOutline({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 14),
      const Radius.circular(13));
    canvas.drawRRect(bounds, Paint()..color = const Color(0xEF101522));
    canvas.drawRRect(bounds, Paint()
      ..color = color ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
    final tail = Path()
      ..moveTo(24, size.height - 14)
      ..lineTo(38, size.height - 14)
      ..lineTo(28, size.height - 2)
      ..close();
    canvas.drawPath(tail, Paint()..color = const Color(0xEF101522));
    canvas.drawPath(tail, Paint()
      ..color = color ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _BubbleOutline oldDelegate) =>
      oldDelegate.color != color;
}
