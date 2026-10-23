import 'package:flutter/material.dart';
import '../models/multiversal_command_button_catalog.dart';

/// Only enabled modules navigate to implemented dashboard tabs.
class MultiversalCommandDeckScreen extends StatelessWidget {
  const MultiversalCommandDeckScreen({super.key, required this.onOpenTab});
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Moonveil Command Deck · 38 modules',
          style: Theme.of(context).textTheme.titleLarge),
      const Text('Available modules open real screens. Others are planned, not active.'),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 720 ? 4 : constraints.maxWidth > 420 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: MultiversalCommandButtonCatalog.masterButtonDatabase.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns, crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final module = MultiversalCommandButtonCatalog.masterButtonDatabase[index];
            return Card(
              color: const Color(0xFF231A3C),
              child: InkWell(
                onTap: module.isAvailable ? () => onOpenTab(module.route!) : null,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(module.isAvailable ? Icons.auto_awesome : Icons.lock_outline,
                          color: module.isAvailable ? Colors.amberAccent : Colors.white38),
                      const SizedBox(height: 6),
                      Text(module.title, textAlign: TextAlign.center,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: module.isAvailable ? Colors.white : Colors.white54)),
                      Text(module.isAvailable ? 'OPEN' : 'PLANNED',
                          style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    ],
  );
}
