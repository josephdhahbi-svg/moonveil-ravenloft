import 'dart:math';
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
  final Random _dice = Random();
  final TextEditingController _enemyName = TextEditingController(text: 'Skeleton');
  final TextEditingController _enemyHp = TextEditingController(text: '13');
  final TextEditingController _enemyAc = TextEditingController(text: '13');
  final TextEditingController _enemyModifier = TextEditingController(text: '2');
  bool _includeEnemy = false;
  bool _rollInitiative = true;

  @override
  void dispose() {
    _enemyName.dispose();
    _enemyHp.dispose();
    _enemyAc.dispose();
    _enemyModifier.dispose();
    super.dispose();
  }

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
      final participants = <MoonveilCombatant>[
        MoonveilCombatant(
          id: character.id, name: character.name,
          initiative: _rollInitiative ? _dice.nextInt(20) + 1 : 10,
          maxHp: character.maxHp, hp: character.hp, ac: character.ac,
          characterId: character.characterId,
        ),
      ];
      if (_includeEnemy) {
        final name = _enemyName.text.trim();
        final hp = int.tryParse(_enemyHp.text);
        final ac = int.tryParse(_enemyAc.text);
        final modifier = int.tryParse(_enemyModifier.text);
        if (name.isEmpty || hp == null || hp < 1 || ac == null || ac < 0 || modifier == null) {
          setState(() => _message = 'Enter valid enemy name, HP, AC and initiative modifier.');
          return;
        }
        participants.add(MoonveilCombatant(
          id: 'enemy-1', name: name,
          initiativeModifier: modifier,
          initiative: (_rollInitiative ? _dice.nextInt(20) + 1 : 10) + modifier,
          maxHp: hp, hp: hp, ac: ac, isEnemy: true,
        ));
      }
      setState(() {
        _encounter = MoonveilEncounter(participants);
        _message = _rollInitiative
            ? 'Initiative rolled for encounter preview.'
            : 'Initiative preview uses placeholder 10 plus enemy modifier.';
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
          if (encounter == null) ...[
            SwitchListTile(
              title: const Text('Roll initiative (d20)'),
              value: _rollInitiative,
              onChanged: (v) => setState(() => _rollInitiative = v),
            ),
            SwitchListTile(
              key: const Key('include-enemy'),
              title: const Text('Add enemy to encounter'),
              value: _includeEnemy,
              onChanged: (v) => setState(() => _includeEnemy = v),
            ),
            if (_includeEnemy) ...[
              TextField(controller: _enemyName, decoration: const InputDecoration(labelText: 'Enemy name')),
              TextField(controller: _enemyHp, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Enemy HP')),
              TextField(controller: _enemyAc, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Enemy AC')),
              TextField(controller: _enemyModifier, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Enemy initiative modifier')),
            ],
            FilledButton.icon(
              key: const Key('start-encounter'),
              onPressed: _start,
              icon: const Icon(Icons.sports_martial_arts),
              label: const Text('Start Encounter Preview'),
            ),
          ] else ...[
            Text('Round ${encounter.round} · Turn: ${encounter.active.name}',
                key: const Key('encounter-turn')),
            for (final combatant in encounter.state)
              ListTile(
                key: Key('combatant-${combatant.id}'),
                title: Text(combatant.name),
                subtitle: Text('HP ${combatant.hp}/${combatant.maxHp} · AC ${combatant.ac} · Initiative ${combatant.initiative}'
                    '${combatant.isEnemy ? " · Enemy" : ""}'
                    '${combatant.conditions.isNotEmpty ? " · ${combatant.conditions.join(", ")}" : ""}'),
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
            for (final combatant in encounter.state)
              CheckboxListTile(
                key: Key('poisoned-${combatant.id}'),
                title: Text('Poisoned: ${combatant.name}'),
                value: combatant.conditions.contains('Poisoned'),
                onChanged: (enabled) => setState(() => encounter.setCondition(
                    combatant.id, 'Poisoned', enabled: enabled ?? false)),
              ),
            Text('History: ${encounter.history.length} events',
                key: const Key('encounter-history')),
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
