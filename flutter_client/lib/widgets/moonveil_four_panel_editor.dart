import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'moonveil_speech_bubble.dart';

/// Four photographic panels, four independent editable scripts, five choices.
/// This editor only manages local draft state; no save database writes.
class MoonveilFourPanelEditor extends StatefulWidget {
  const MoonveilFourPanelEditor({super.key});
  @override
  State<MoonveilFourPanelEditor> createState() => _MoonveilFourPanelEditorState();
}

class _MoonveilFourPanelEditorState extends State<MoonveilFourPanelEditor> {
  static const backgrounds = [
    'assets/images/moonveil_v4/locations/ruins.png',
    'assets/images/moonveil_v4/locations/krezk_abbey.png',
    'assets/images/moonveil_v4/locations/svalich_road.png',
    'assets/images/moonveil_v4/locations/castle_ravenloft.png',
  ];
  final scripts = <String>[
    'The Forgotten Archive lies beyond the threshold.',
    'Vaelthara warns Vesper of the unstable Weave.',
    'Silver moonlight illuminates the ancient stones.',
    'The next choice belongs to Vesper.',
  ];
  final choices = const [
    'Lawful Good', 'Neutral Good', 'Chaotic Good', 'Utility', 'Action'
  ];
  int? previewChoice;

  String exportDraft() => const JsonEncoder.withIndent('  ').convert({
    'schema_version': 1,
    'kind': 'visual_storyboard_draft',
    'campaign': 'vesper',
    'panels': [
      for (var i = 0; i < 4; i++)
        {'background': backgrounds[i], 'speaker': 'Vesper Vane',
          'dialogue': scripts[i]},
    ],
    'choices': choices,
    'preview_choice': previewChoice,
    'save_game_modified': false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Four-Panel Storyboard Editor',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const Text('Editable scripts are separate from the scenery artwork.'),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 650 ? 1 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.15,
            mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemBuilder: (context, i) => Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(backgrounds[i], fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF151827))),
              Align(alignment: Alignment.bottomCenter,
                child: Padding(padding: const EdgeInsets.all(8),
                  child: MoonveilSpeechBubble(
                    speaker: 'Vesper Vane', text: scripts[i],
                    onEdit: (text) => setState(() => scripts[i] = text),
                  ))),
            ]),
          ),
        );
      }),
      const SizedBox(height: 12),
      for (var i = 0; i < 5; i++)
        Padding(padding: const EdgeInsets.only(bottom: 6),
          child: OutlinedButton(
            onPressed: () => setState(() => previewChoice = i),
            child: Text('${i + 1}. ${choices[i]}'
              '${previewChoice == i ? ' (preview selected)' : ''}'),
          )),
      TextButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: exportDraft()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storyboard JSON copied')));
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copy storyboard script JSON'),
      ),
    ]);
  }
}
