import 'dart:math';
import 'package:flutter/material.dart';

/// Visual dice animation; the final random result is delivered once.
class MoonveilAnimatedDiceRoller extends StatefulWidget {
  const MoonveilAnimatedDiceRoller({
    super.key,
    this.diceSides = 20,
    required this.onRollComplete,
  }) : assert(diceSides >= 2);

  final int diceSides;
  final ValueChanged<int> onRollComplete;

  @override
  State<MoonveilAnimatedDiceRoller> createState() =>
      _MoonveilAnimatedDiceRollerState();
}

class _MoonveilAnimatedDiceRollerState extends State<MoonveilAnimatedDiceRoller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _rng = Random.secure();
  int _display = 1;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        if (mounted) {
          setState(() => _display = _rng.nextInt(widget.diceSides) + 1);
        }
      });
  }

  Future<void> _roll() async {
    if (_rolling) return;
    setState(() => _rolling = true);
    await _controller.forward(from: 0);
    if (!mounted) return;
    final result = _rng.nextInt(widget.diceSides) + 1;
    setState(() {
      _display = result;
      _rolling = false;
    });
    widget.onRollComplete(result);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF161124),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('D${widget.diceSides} · ANIMATED ROLL',
                style: const TextStyle(color: Colors.purpleAccent)),
            const SizedBox(height: 12),
            Text('$_display',
                style: const TextStyle(fontSize: 32, color: Colors.amberAccent)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _rolling ? null : _roll,
              icon: const Icon(Icons.casino),
              label: Text(_rolling ? 'Rolling...' : 'Roll'),
            ),
          ]),
        ),
      );
}
