import 'package:flutter/material.dart';
import '../services/multiversal_router_service.dart';
import '../storage/moonveil_database.dart';
import '../widgets/campaign_companion_hud.dart';
import '../widgets/interactive_dice_roller_modal.dart';

class MultiversalDashboardScreen extends StatefulWidget {
  const MultiversalDashboardScreen({super.key});
  @override
  State<MultiversalDashboardScreen> createState() =>
      _MultiversalDashboardState();
}

class _MultiversalDashboardState extends State<MultiversalDashboardScreen> {
  // Use an explicitly stored modifier or a recorded Charisma score only.
  // Unknown attributes never receive an invented bonus.
  static int _abilityModifier(Map<String, dynamic>? state) {
    if (state == null) return 0;
    final direct = state['charisma_modifier'];
    if (direct is int) return direct;
    final attributes = state['attributes'];
    if (attributes is Map) {
      final charisma = attributes['charisma'] ?? attributes['CHA'];
      if (charisma is num) return (charisma.toInt() - 10) ~/ 2;
    }
    return 0;
  }

  MoonveilDatabase? _db;
  Map<String, dynamic>? _vesper;
  List<Map<String, Object?>> _inventory = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final db = _db ?? await MultiversalRouterService.openSector('vesper');
      final vesper = await db.loadCharacter('vesper-vane');
      final inventory = await db.db.query('inventory_entries',
          where: 'campaign_id = ? AND character_id = ?',
          whereArgs: ['vesper', 'vesper-vane']);
      if (!mounted) {
        if (_db == null) await db.close();
        return;
      }
      setState(() {
        _db = db;
        _vesper = vesper;
        _inventory = inventory;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moonveil Multiverse'),
      actions: [IconButton(onPressed: _refresh,
        icon: const Icon(Icons.refresh), tooltip: 'Reload saved state')]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => InteractiveDiceRollerModal.show(context,
        modifier: _abilityModifier(_vesper)),
      icon: const Icon(Icons.casino), label: const Text('Roll')),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
        ? Center(child: SelectableText('Storage error: $_error'))
        : ListView(padding: const EdgeInsets.all(16), children: [
          CampaignCompanionHud(character: _vesper, inventory: _inventory),
          const SizedBox(height: 16),
          Text('Cosmological Sectors',
              style: Theme.of(context).textTheme.titleLarge),
          for (final entry in MultiversalRouterService.sectors.entries)
            Card(child: ListTile(
              leading: Icon(entry.key == 'vesper'
                  ? Icons.nightlight_round : Icons.menu_book),
              title: Text(entry.value),
              subtitle: Text(entry.key == 'vesper'
                  ? (_vesper == null
                      ? 'Awaiting verified checkpoint'
                      : 'Local checkpoint available')
                  : 'Quarantined reference sector'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => MultiversalRouterService.showSector(
                  context, entry.key),
            )),
          const SizedBox(height: 80),
        ]),
  );
}
