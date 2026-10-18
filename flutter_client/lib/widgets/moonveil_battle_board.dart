import 'package:flutter/material.dart';
import 'moonveil_comic_scene.dart';

/// Read-only battle board preview. Combat engine owns HP, rolls, initiative.
class MoonveilBattleBoard extends StatelessWidget {
  const MoonveilBattleBoard({
    super.key,
    required this.backgroundAsset,
    this.columns = 10,
    this.rows = 6,
    this.tokens = const [],
  });
  final String backgroundAsset;
  final int columns;
  final int rows;
  final List<MoonveilBattlePlacement> tokens;

  @override
  Widget build(BuildContext context) {
    final cols = columns.clamp(1, 40);
    final lines = rows.clamp(1, 40);
    return AspectRatio(
      aspectRatio: cols / lines,
      child: LayoutBuilder(builder: (context, constraints) {
        final tile = constraints.maxWidth / cols;
        return Stack(children: [
          Positioned.fill(child: Image.asset(backgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF151827)))),
          Positioned.fill(child: CustomPaint(
            painter: _GridPainter(cols, lines))),
          for (final token in tokens)
            if (token.x >= 0 && token.y >= 0 &&
                token.x + token.footprint <= cols &&
                token.y + token.footprint <= lines)
              Positioned(
                left: token.x * tile, top: token.y * tile,
                width: tile * token.footprint,
                height: tile * token.footprint,
                child: FittedBox(fit: BoxFit.contain,
                  child: MoonveilMapToken(
                    assetPath: token.assetPath,
                    label: token.label,
                    gridFootprint: token.footprint)),
              ),
        ]);
      }),
    );
  }
}

class MoonveilBattlePlacement {
  const MoonveilBattlePlacement({
    required this.x, required this.y,
    required this.assetPath, required this.label,
    this.footprint = 1,
  });
  final int x, y, footprint;
  final String assetPath, label;
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.columns, this.rows);
  final int columns, rows;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = 0.7;
    for (var x = 0; x <= columns; x++) {
      final dx = size.width * x / columns;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = size.height * y / rows;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.columns != columns || oldDelegate.rows != rows;
}
