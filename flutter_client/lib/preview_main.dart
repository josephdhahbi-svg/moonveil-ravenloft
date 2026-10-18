import 'package:flutter/material.dart';

/// Isolated browser preview. Never opens, resets, or writes campaign databases.
/// The production app entrypoint remains lib/main.dart.
void main() => runApp(const MoonveilPreview());

class MoonveilPreview extends StatelessWidget {
  const MoonveilPreview({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Moonveil — Development Preview',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const PreviewTabletop(),
  );
}

class PreviewTabletop extends StatefulWidget {
  const PreviewTabletop({super.key});
  @override
  State<PreviewTabletop> createState() => _PreviewTabletopState();
}

class _PreviewTabletopState extends State<PreviewTabletop> {
  int x = 2, y = 3, guardianHp = 8, round = 1;
  String choice = '';
  final log = <String>['Training simulation only — no campaign saves are changed.'];
  void move(int dx, int dy) => setState(() {
    x = (x + dx).clamp(0, 9);
    y = (y + dy).clamp(0, 5);
    log.insert(0, 'Vesper moves to (${x + 1}, ${y + 1})');
  });
  void attack() => setState(() {
    if (guardianHp == 0) return;
    guardianHp = (guardianHp - 2).clamp(0, 8);
    round++;
    log.insert(0, guardianHp == 0
      ? 'Training guardian defeated! No items or XP awarded.'
      : 'Training strike: 2 damage. Guardian HP $guardianHp/8');
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🌙 MOONVEIL • Development Tabletop')),
    body: ListView(padding: const EdgeInsets.all(12), children: [
      const Card(child: ListTile(title: Text('VESPER VANE • Dhampir Undead Warlock'),
        subtitle: Text('Level 1/30 · HP 10/10 · AC 13 · Pact 1/1 · Training simulation'))),
      Text('Forgotten Archive • Round $round', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      AspectRatio(aspectRatio: 10 / 6, child: LayoutBuilder(builder: (context, size) =>
        Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF151B31))),
          Positioned.fill(child: CustomPaint(painter: PreviewGrid())),
          Positioned(left: x * size.maxWidth / 10, top: y * size.maxHeight / 6,
            width: size.maxWidth / 10, height: size.maxHeight / 6,
            child: const Center(child: Text('🌙', style: TextStyle(fontSize: 24)))),
          Positioned(left: 7 * size.maxWidth / 10, top: 2 * size.maxHeight / 6,
            width: size.maxWidth / 10, height: size.maxHeight / 6,
            child: Center(child: Text(guardianHp > 0 ? '👁️' : '✦',
              style: const TextStyle(fontSize: 24)))),
        ]))),
      Text('Guardian HP $guardianHp/8', textAlign: TextAlign.center),
      Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
        IconButton(tooltip: 'Move left', onPressed: () => move(-1, 0), icon: const Icon(Icons.arrow_back)),
        IconButton(tooltip: 'Move up', onPressed: () => move(0, -1), icon: const Icon(Icons.arrow_upward)),
        IconButton(tooltip: 'Move down', onPressed: () => move(0, 1), icon: const Icon(Icons.arrow_downward)),
        IconButton(tooltip: 'Move right', onPressed: () => move(1, 0), icon: const Icon(Icons.arrow_forward)),
        FilledButton(onPressed: guardianHp > 0 ? attack : null, child: const Text('Training attack')),
      ]),
      const Divider(),
      const Text('Archive approach — select one'),
      for (final option in ['Lawful Good', 'Neutral Good', 'Chaotic Good', 'Utility', 'Action'])
        ListTile(title: Text(option), leading: Icon(choice == option
          ? Icons.radio_button_checked : Icons.radio_button_unchecked),
          onTap: () => setState(() {
            choice = option;
            log.insert(0, 'Preview choice: $choice');
          })),
      const Divider(),
      const Text('Encounter log'),
      for (final entry in log.take(8)) Text('• $entry'),
    ]),
  );
}

class PreviewGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x88B9C7FF)..strokeWidth = 0.7;
    for (var i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var i = 0; i <= 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
