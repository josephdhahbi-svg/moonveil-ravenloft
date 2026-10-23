import 'moonveil_animated_dice_roller.dart';
import 'package:flutter/material.dart';

class InteractiveDiceRollerModal extends StatefulWidget {
  const InteractiveDiceRollerModal({super.key, this.modifier = 0});
  final int modifier;

  static Future<void> show(BuildContext context, {int modifier = 0}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => InteractiveDiceRollerModal(modifier: modifier),
      );

  @override
  State<InteractiveDiceRollerModal> createState() => _DiceState();
}

class _DiceState extends State<InteractiveDiceRollerModal> {
  int? _die;
  int? _roll;
  int _modifier = 0;

  @override
  void initState() {
    super.initState();
    _modifier = widget.modifier;
  }

  void _rollDie(int sides) => setState(() {
    _die = sides;
    _roll = null;
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Arcane Dice', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(spacing: 12, children: [
          for (final sides in [20, 8, 6, 4])
            FilledButton.tonal(onPressed: () => _rollDie(sides),
              child: Text('d$sides')),
        ]),
        if (_die != null)
          MoonveilAnimatedDiceRoller(
            key: ValueKey(_die),
            diceSides: _die!,
            onRollComplete: (result) => setState(() => _roll = result),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () => setState(() => _modifier--),
              icon: const Icon(Icons.remove)),
          Text('Modifier: ${_modifier >= 0 ? '+' : ''}$_modifier'),
          IconButton(onPressed: () => setState(() => _modifier++),
              icon: const Icon(Icons.add)),
        ]),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _roll == null ? 'Choose a die' :
                'd$_die: $_roll  →  Total ${_roll! + _modifier}',
            key: ValueKey('$_roll:$_modifier:$_die'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 20),
      ]),
    ),
  );
}
