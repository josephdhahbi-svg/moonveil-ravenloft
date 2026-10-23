import 'package:flutter/material.dart';

/// Storyboard-style cinematic transition without remote video dependencies.
/// A timed video renderer and recorded dialogue are future integrations.
class MoonveilCinematicScene extends StatefulWidget {
  const MoonveilCinematicScene({super.key, required this.title,
    required this.captions, this.onContinue});
  final String title;
  final List<String> captions;
  final VoidCallback? onContinue;

  @override
  State<MoonveilCinematicScene> createState() => _MoonveilCinematicSceneState();
}

class _MoonveilCinematicSceneState extends State<MoonveilCinematicScene> {
  int _frame = 0;

  @override
  Widget build(BuildContext context) {
    final captions = widget.captions;
    if (captions.isEmpty) return const SizedBox.shrink();
    final frame = _frame.clamp(0, captions.length - 1);
    return Card(
      key: const Key('moonveil-cinematic-scene'),
      color: const Color(0xFF171325),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('CINEMATIC STORYBOARD', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Container(
              key: ValueKey(frame),
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF1A1630), Color(0xFF443456), Color(0xFF161526),
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(captions[frame], textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Frame ${frame + 1} of ${captions.length}'),
          Row(children: [
            OutlinedButton(
              key: const Key('cinematic-back'),
              onPressed: frame == 0 ? null : () => setState(() => _frame--),
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('cinematic-next'),
              onPressed: frame + 1 < captions.length
                  ? () => setState(() => _frame++)
                  : widget.onContinue,
              child: Text(frame + 1 < captions.length ? 'Next Frame' : 'Continue'),
            ),
          ]),
        ]),
      ),
    );
  }
}
