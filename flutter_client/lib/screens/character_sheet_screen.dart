import 'package:flutter/material.dart';
import '../models/character_profile.dart';
import '../services/character_library_service.dart';

class CharacterSheetScreen extends StatelessWidget {
  const CharacterSheetScreen({super.key, required this.character});
  final CharacterProfile? character;
  static const gold = Color(0xFFF1D6A4);

  @override
  Widget build(BuildContext context) {
    final c = character;
    if (c == null) {
      return const Card(child: ListTile(
        leading: Icon(Icons.shield_outlined),
        title: Text('Vesper checkpoint not imported'),
        subtitle: Text('Character stats and owned equipment are not yet verified.'),
      ));
    }
    String show(Object? value) => value?.toString() ?? 'Unverified';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(color: const Color(0xFF20172F), child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          ClipOval(child: Image.asset(CharacterLibraryService.vesperPortrait,
            width: 74, height: 74, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 74, height: 74,
              child: Icon(Icons.person_outline, size: 50, color: gold)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            Text(c.background ?? 'Background unverified'),
            Text('Patron: ${show(c.patron)}', style: const TextStyle(color: gold)),
          ])),
        ]),
      )),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _stat('LEVEL', show(c.level)),
        _stat('HP', c.hp == null || c.maxHp == null ? 'Unverified' : '${c.hp}/${c.maxHp}'),
        _stat('AC', show(c.armorClass)),
      ]),
      const SizedBox(height: 18),
      const Text('ABILITY SCORES & MODIFIERS', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (c.abilities.isEmpty) const Text('Ability scores not recorded in checkpoint'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final entry in c.abilities.entries)
          _stat(entry.key, '${entry.value} (${_modifier(entry.value)})'),
      ]),
      const SizedBox(height: 18),
      const Text('OWNED INVENTORY', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
      if (c.inventory.isEmpty) const Text('No owned items recorded'),
      for (final item in c.inventory)
        Card(child: ListTile(leading: const Icon(Icons.auto_awesome, color: gold), title: Text(item))),
    ]);
  }

  static String _modifier(int score) {
    final value = ((score - 10) / 2).floor();
    return value >= 0 ? '+$value' : '$value';
  }

  Widget _stat(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF241A37),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF7D639E))),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, color: gold)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]),
  );
}
