import 'package:flutter/material.dart';

class CampaignCompanionHud extends StatelessWidget {
  const CampaignCompanionHud({
    super.key, required this.character, required this.inventory,
  });

  final Map<String, dynamic>? character;
  final List<Map<String, Object?>> inventory;

  @override
  Widget build(BuildContext context) {
    if (character == null) {
      return const Card(child: ListTile(
        leading: Icon(Icons.shield_outlined),
        title: Text('Vesper checkpoint not imported'),
        subtitle: Text('No HP, conditions or equipment will be invented.'),
      ));
    }
    final equipped = inventory.where((row) => row['owned'] == 1).toList();
    final conditions = character!['conditions'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(child: ListTile(
        leading: const Icon(Icons.favorite),
        title: Text('${character!['name'] ?? 'Vesper'} · Level ${character!['level'] ?? '?'}'),
        subtitle: Text('HP ${character!['hp'] ?? '?'} · AC ${character!['ac'] ?? '?'}'),
      )),
      Card(child: ListTile(
        leading: const Icon(Icons.psychology),
        title: const Text('Sanity / Madness'),
        subtitle: Text(conditions == null ? 'Not recorded' : '$conditions'),
      )),
      ExpansionTile(
        title: Text('Owned inventory (${equipped.length})'),
        children: equipped.isEmpty
            ? [const ListTile(title: Text('No owned items recorded'))]
            : equipped.map((row) => ListTile(
                title: Text(row['item_id'].toString()),
                trailing: row['attuned'] == 1
                    ? const Icon(Icons.auto_awesome) : null,
              )).toList(),
      ),
    ]);
  }
}
