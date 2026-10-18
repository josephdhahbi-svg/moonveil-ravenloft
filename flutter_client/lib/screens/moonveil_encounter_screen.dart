import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/moonveil_encounter_codec.dart';
import '../services/moonveil_encounter_store.dart';
import '../services/moonveil_audio_service.dart';
import '../services/moonveil_ambient_soundtrack.dart';
import '../services/moonveil_encounter_engine.dart';

/// Encounter sandbox. Checkpoints live in separate campaign-scoped preferences.
class MoonveilEncounterScreen extends StatefulWidget {
  const MoonveilEncounterScreen({super.key, required this.character,
    this.campaignId = 'vesper'});
  final Map<String, dynamic>? character;
  final String campaignId;

  @override
  State<MoonveilEncounterScreen> createState() => _MoonveilEncounterScreenState();
}

class _MoonveilEncounterScreenState extends State<MoonveilEncounterScreen> {
  MoonveilEncounter? _encounter;
  bool _soundEnabled = false;
  bool _musicEnabled = false;
  final MoonveilMusicController _music = MoonveilMusicController();
  final MoonveilAudioService _audio = const MoonveilAudioService();
  String? _message;
  final Random _dice = Random();
  final TextEditingController _importJson = TextEditingController();
  final TextEditingController _enemyName = TextEditingController(text: 'Skeleton');
  final TextEditingController _enemyHp = TextEditingController(text: '13');
  final TextEditingController _enemyAc = TextEditingController(text: '13');
  final TextEditingController _enemyModifier = TextEditingController(text: '2');
  bool _includeEnemy = false;
  final List<({String name, int hp, int ac, int modifier})> _enemies = [];
  static const _conditions = <String>[
    'Blinded', 'Charmed', 'Deafened', 'Exhaustion', 'Frightened',
    'Grappled', 'Incapacitated', 'Invisible', 'Paralyzed',
    'Petrified', 'Poisoned', 'Prone', 'Restrained', 'Stunned',
    'Unconscious',
  ];

  void _addEnemy() {
    final name = _enemyName.text.trim();
    final hp = int.tryParse(_enemyHp.text);
    final ac = int.tryParse(_enemyAc.text);
    final modifier = int.tryParse(_enemyModifier.text);
    if (name.isEmpty || hp == null || hp < 1 || ac == null || ac < 0 ||
        modifier == null) {
      setState(() => _message = 'Enter valid enemy name, HP, AC and initiative modifier.');
      return;
    }
    setState(() {
      _enemies.add((name: name, hp: hp, ac: ac, modifier: modifier));
      _message = null;
    });
  }
  bool _rollInitiative = true;

  @override
  void dispose() {
    _music.dispose();
    _importJson.dispose();
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
      for (var i = 0; i < _enemies.length; i++) {
        final enemy = _enemies[i];
        participants.add(MoonveilCombatant(
          id: 'enemy-${i + 1}', name: enemy.name,
          initiativeModifier: enemy.modifier,
          initiative: (_rollInitiative ? _dice.nextInt(20) + 1 : 10) + enemy.modifier,
          maxHp: enemy.hp, hp: enemy.hp, ac: enemy.ac, isEnemy: true,
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

  void _restore() {
    try {
      final restored = MoonveilEncounterCodec.decode(_importJson.text);
      setState(() {
        _encounter = restored;
        _message = 'Encounter restored from JSON preview. Campaign save unchanged.';
      });
    } catch (error) {
      setState(() => _message = 'Encounter import rejected: $error');
    }
  }

  Future<void> _toggleMusic(bool enabled) async {
    try {
      if (enabled) {
        await _music.start();
      } else {
        await _music.stop();
      }
      if (mounted) setState(() => _musicEnabled = enabled);
    } catch (error) {
      if (mounted) setState(() {
        _musicEnabled = false;
        _message = 'Background music unavailable on this device: $error';
      });
    }
  }

  Future<void> _saveCheckpoint() async {
    final encounter = _encounter;
    if (encounter == null) return;
    try {
      await MoonveilEncounterStore(widget.campaignId).save(encounter);
      if (mounted) setState(() => _message = 'Encounter checkpoint saved separately from character data.');
    } catch (error) {
      if (mounted) setState(() => _message = 'Encounter save failed: $error');
    }
  }

  Future<void> _loadCheckpoint() async {
    try {
      final encounter = await MoonveilEncounterStore(widget.campaignId).load();
      if (!mounted) return;
      setState(() {
        if (encounter != null) _encounter = encounter;
        _message = encounter == null ? 'No saved encounter for this campaign.'
            : 'Saved encounter loaded. Character save unchanged.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = 'Encounter load failed: $error');
    }
  }

  void _advanceTurn() {
    final encounter = _encounter;
    if (encounter == null) return;
    setState(encounter.nextTurn);
    _audio.playUiCue(enabled: _soundEnabled);
  }

  Future<void> _loadPreviousCheckpoint() async {
    try {
      final previous = await MoonveilEncounterStore(widget.campaignId).loadPrevious();
      if (!mounted) return;
      setState(() {
        if (previous != null) _encounter = previous;
        _message = previous == null ? 'No previous encounter checkpoint available.'
            : 'Previous encounter recovered. Current stored checkpoint preserved.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = 'Encounter recovery failed: $error');
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
    _audio.playUiCue(enabled: _soundEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final encounter = _encounter;
    return SingleChildScrollView(
      child: Card(
      key: const Key('moonveil-encounter'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Encounter Sandbox', style: Theme.of(context).textTheme.titleLarge),
          const Text('Encounter checkpoints are separate from character saves and inventory.'),
          SwitchListTile(
            key: const Key('encounter-music-toggle'),
            title: const Text('Moonveil ambient music'),
            subtitle: const Text('Original synthesized gothic ambience; tap to play or stop.'),
            value: _musicEnabled,
            onChanged: _toggleMusic,
          ),
          SwitchListTile(
            key: const Key('encounter-sound-toggle'),
            title: const Text('Combat UI sounds'),
            subtitle: const Text('Optional platform click cues; music and voices not installed.'),
            value: _soundEnabled,
            onChanged: (enabled) => setState(() => _soundEnabled = enabled),
          ),
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
              OutlinedButton.icon(
                key: const Key('add-enemy'),
                onPressed: _addEnemy,
                icon: const Icon(Icons.person_add), label: const Text('Queue Enemy'),
              ),
            ],
            for (var i = 0; i < _enemies.length; i++)
              ListTile(
                key: Key('queued-enemy-${i + 1}'),
                title: Text('${_enemies[i].name} · HP ${_enemies[i].hp} · AC ${_enemies[i].ac}'),
                trailing: IconButton(
                  tooltip: 'Remove queued enemy',
                  onPressed: () => setState(() => _enemies.removeAt(i)),
                  icon: const Icon(Icons.close),
                ),
              ),
            TextField(
              key: const Key('encounter-import-json'),
              controller: _importJson,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Paste encounter JSON to restore'),
            ),
            OutlinedButton.icon(
              key: const Key('load-encounter-checkpoint'),
              onPressed: _loadCheckpoint,
              icon: const Icon(Icons.folder_open),
              label: const Text('Load Saved Encounter'),
            ),
            OutlinedButton.icon(
              key: const Key('recover-previous-encounter'),
              onPressed: _loadPreviousCheckpoint,
              icon: const Icon(Icons.history),
              label: const Text('Recover Previous Encounter'),
            ),
            OutlinedButton(
              key: const Key('restore-encounter'),
              onPressed: _restore,
              child: const Text('Restore Encounter JSON'),
            ),
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
              ExpansionTile(
                key: Key('conditions-${combatant.id}'),
                title: Text('Conditions: ${combatant.name}'),
                children: [
                  for (final condition in _conditions)
                    CheckboxListTile(
                      key: Key('condition-${combatant.id}-${condition.toLowerCase()}'),
                      title: Text(condition),
                      value: combatant.conditions.contains(condition),
                      onChanged: (enabled) => setState(() => encounter.setCondition(
                        combatant.id, condition, enabled: enabled ?? false)),
                    ),
                ],
              ),
            ExpansionTile(
              key: const Key('combat-history'),
              title: Text('History: ${encounter.history.length} events'),
              children: [
                for (final event in encounter.history.reversed)
                  ListTile(
                    dense: true,
                    title: Text('${event['action']} · ${event['actor']}'),
                    subtitle: Text('Round ${event['round']}'
                        '${event['amount'] == null ? '' : ' · ${event['amount']}'}'),
                  ),
              ],
            ),
            FilledButton.icon(
              key: const Key('save-encounter-checkpoint'),
              onPressed: _saveCheckpoint,
              icon: const Icon(Icons.save),
              label: const Text('Save Encounter Checkpoint'),
            ),
            OutlinedButton.icon(
              key: const Key('copy-encounter-json'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(
                  text: MoonveilEncounterCodec.encode(encounter),
                ));
                if (mounted) setState(() => _message = 'Encounter JSON copied. Keep it somewhere safe to restore later.');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Encounter JSON'),
            ),
            FilledButton(
              key: const Key('next-turn'),
              onPressed: _advanceTurn,
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
      ),
    );
  }
}
