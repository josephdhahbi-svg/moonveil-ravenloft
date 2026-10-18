import 'package:flutter/material.dart';
import '../services/moonveil_encounter_engine.dart';

/// Interactive encounter sandbox. No database or save writes.
class MoonveilEncounterScreen extends StatefulWidget {
  const MoonveilEncounterScreen({super.key, required this.character});
  final Map<String, dynamic>? character;

  @override
  State<MoonveilEncounterScreen> createState() => _MoonveilEncounterScreenState();
}

class _MoonveilEncounterScreenState extends State<MoonveilEncounterScreen> {
  MoonveilEncounter? _encounter;
  String? _message;

  void _start() {
    final snapshot = widget.character;
    if (snapshot == null) {
      setState(() => _message = 'Load a verified character checkpoint first.');
      return;
    }
    try {
      final character = MoonveilCombatant.fromCharacterSnapshot(
        id: 'vesper-vane', name: 'Vesper Vane',
        snapshot: {
          'hp': snapshot['hp'] ?? snapshot['current_hp'],
          'maxHp': snapshot['maxHp'] ?? snapshot['max_hp'],
          'ac': snapshot['ac'] ?? snapshot['armor_class'],
        },
        initiative: 10,
      );
      setState(() {
        _encounter = MoonveilEncounter([character]);
        _message = 'Preview started. Initiative 10 is a placeholder, not a roll.';
      });
    } catch (_) {
      setState(() => _message =
          'Character HP, maximum HP or AC is missing. No values were invented.');
    }
  }

  void _changeHp(String id, int amount, {required bool heal}) {
    final encounter = _encounter;
    if (encounter == null) return;
    setState(() {
      if (heal) {
        encounter.heal(id, amount);
      } else {
        encounter.applyDamage(id, amount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final encounter = _encounter;
    return Card(
      key: const Key('moonveil-encounter'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Encounter Sandbox', style: Theme.of(context).textTheme.titleLarge),
          const Text('Preview only. Does not change campaign saves or inventory.'),
          const SizedBox(height: 12),
          if (encounter == null)
            FilledButton.icon(
              key: const Key('start-encounter'),
              onPressed: _start,
              icon: const Icon(Icons.sports_martial_arts),
              label: const Text('Start Encounter Preview'),
            )
          else ...[
            Text('Round ${encounter.round} · Turn: ${encounter.active.name}',
                key: const Key('encounter-turn')),
            for (final combatant in encounter.state)
              ListTile(
                key: Key('combatant-${combatant.id}'),
                title: Text(combatant.name),
                subtitle: Text('HP ${combatant.hp}/${combatant.maxHp} · AC ${combatant.ac} · Initiative ${combatant.initiative}'),
                trailing: Wrap(spacing: 4, children: [
                  IconButton(
                    key: Key('damage-${combatant.id}'),
                    tooltip: 'Deal 1 damage to ${combatant.name}',
                    onPressed: () => _changeHp(combatant.id, 1, heal: false),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    key: Key('heal-${combatant.id}'),
                    tooltip: 'Heal ${combatant.name} by 1',
                    onPressed: () => _changeHp(combatant.id, 1, heal: true),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              ),
            FilledButton(
              key: const Key('next-turn'),
              onPressed: () => setState(encounter.nextTurn),
              child: const Text('Next Turn'),
            ),
            TextButton(
              onPressed: () => setState(() => _encounter = null),
              child: const Text('Discard Preview'),
            ),
          ],
          if (_message != null) Text(_message!),
        ]),
      ),
    );
  }
}
