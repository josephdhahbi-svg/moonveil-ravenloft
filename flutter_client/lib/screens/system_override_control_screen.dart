import 'package:flutter/material.dart';
import '../services/system_override_command_dispatcher.dart';

class SystemOverrideControlScreen extends StatefulWidget {
  const SystemOverrideControlScreen({super.key});
  @override
  State<SystemOverrideControlScreen> createState() => _SystemOverrideControlScreenState();
}

class _SystemOverrideControlScreenState extends State<SystemOverrideControlScreen> {
  @override
  void initState() {
    super.initState();
    SystemOverrideCommandDispatcher.executeSystemOverride();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SystemOverrideCommandDispatcher.imageGenerationBlocked,
    builder: (context, blocked, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Command & Control', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.block, color: Colors.redAccent),
          title: Text(blocked ? 'Image generation: BLOCKED' : 'Image generation: AVAILABLE'),
          subtitle: const Text('Generation requests are blocked by default in this app process.'),
        )),
        ElevatedButton.icon(
          onPressed: SystemOverrideCommandDispatcher.executeSystemOverride,
          icon: const Icon(Icons.lock),
          label: const Text('Enforce image generation block'),
        ),
        const ListTile(
          leading: Icon(Icons.storage),
          title: Text('SQLite WAL'),
          subtitle: Text('Existing campaign databases are unchanged; no database lock is asserted.'),
        ),
        const ListTile(
          leading: Icon(Icons.extension),
          title: Text('Module registry'),
          subtitle: Text('Remote synchronization is not verified or locked.'),
        ),
      ],
    ),
  );
}
