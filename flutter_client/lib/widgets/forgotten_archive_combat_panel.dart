import 'package:flutter/material.dart';
import '../services/moonveil_combat_engine.dart';
import '../storage/moonveil_database.dart';

/// Archive training encounter. Never changes the character snapshot.
class ForgottenArchiveCombatPanel extends StatefulWidget {
  const ForgottenArchiveCombatPanel({super.key, required this.database});
  final MoonveilDatabase database;
  @override
  State<ForgottenArchiveCombatPanel> createState() => _ArchiveCombatState();
}

class _ArchiveCombatState extends State<ForgottenArchiveCombatPanel> {
  final engine = MoonveilCombatEngine();
  late final CombatEntity guardian = CombatEntity(
    id: 'archive-training-guardian', name: 'Archive Training Guardian',
    hp: 8, maxHp: 8, armorClass: 12, initiativeBonus: 0);
  String status = 'Training encounter: no player HP or resources are changed.';
  bool busy = false;

  Future<void> attack() async {
    if (busy || !guardian.isAlive) return;
    setState(() => busy = true);
    final previousHp = guardian.hp;
    try {
      final result = engine.executeAttack(
        attacker: CombatEntity(id: 'vesper-vane', name: 'Vesper Vane',
          hp: 10, maxHp: 10, armorClass: 13, initiativeBonus: 0),
        defender: guardian, attackBonus: 2,
        damageDiceCount: 1, damageDiceFaces: 6, damageBonus: 0);
      await widget.database.appendEvent(
        eventId: 'archive-training-${DateTime.now().microsecondsSinceEpoch}',
        actorId: 'vesper-vane', type: 'ARCHIVE_TRAINING_ATTACK',
        payload: {'scene': 'forgotten-archive', 'training_only': true, ...result});
      if (mounted) setState(() => status =
        'd20 ${result['d20_roll']} · ${result['hit'] ? 'Hit' : 'Miss'} · '
        'Damage ${result['damage_dealt']} · Guardian HP ${guardian.hp}/8 · Saved');
    } catch (error) {
      guardian.hp = previousHp;
      if (mounted) setState(() => status = 'Attack not saved: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF21172D),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FORGOTTEN ARCHIVE · COMBAT TRAINING',
          style: TextStyle(color: Colors.amberAccent)),
        Text(status),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy || !guardian.isAlive ? null : attack,
          icon: const Icon(Icons.gps_fixed), label: const Text('Practice attack · d20'),
        ),
      ],
    )),
  );
}
