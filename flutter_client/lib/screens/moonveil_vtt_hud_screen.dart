import 'package:flutter/material.dart';

/// Displays verified save data without modifying or inventing character state.
class MoonveilVttHudScreen extends StatelessWidget {
  const MoonveilVttHudScreen({
    super.key,
    required this.character,
    required this.ownedItems,
    required this.onDice,
    required this.onInventory,
    required this.onAtlas,
    required this.onCodex,
  });

  final Map<String, dynamic>? character;
  final int ownedItems;
  final VoidCallback onDice;
  final VoidCallback onInventory;
  final VoidCallback onAtlas;
  final VoidCallback onCodex;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF161124),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('VESPER VANE · DHAMPIR UNDEAD WARLOCK',
          style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        const Text('Patron: Vaelthara · Faith: Mystra',
          style: TextStyle(color: Colors.amberAccent)),
        const Text('Forgotten Netherese-Barovian Archive · Link 2 · Sector D'),
        if (character == null)
          const Text('Verified local checkpoint not loaded; no save changed.')
        else ...[
          Text('Level: ${character!['level'] ?? 'Not recorded'}'),
          Text('HP: ${character!['hp'] ?? 'Not recorded'}'),
          Text('AC: ${character!['ac'] ?? 'Not recorded'}'),
          Text('Pact slots: ${character!['pact_slots'] ?? 'Not recorded'}'),
        ],
        Text('Owned inventory entries: $ownedItems'),
        Wrap(spacing: 8, children: [
          TextButton(onPressed: onCodex, child: const Text('Codex')),
          TextButton(onPressed: onDice, child: const Text('Dice')),
          TextButton(onPressed: onInventory, child: const Text('Inventory')),
          TextButton(onPressed: onAtlas, child: const Text('Atlas')),
        ]),
      ]),
    ),
  );
}
