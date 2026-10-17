import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/multiversal_router_service.dart';
import '../models/character_profile.dart';
import '../screens/character_sheet_screen.dart';
import '../screens/admin_console_screen.dart';
import '../services/visual_codex_service.dart';
import '../storage/moonveil_database.dart';
import '../widgets/campaign_companion_hud.dart';
import '../widgets/interactive_dice_roller_modal.dart';

/// Visual shell only: no fabricated checkpoint, equipment, or stat changes.
class MultiversalDashboardScreen extends StatefulWidget {
  const MultiversalDashboardScreen({super.key});
  @override
  State<MultiversalDashboardScreen> createState() => _MultiversalDashboardState();
}

class _StoryPanel {
  const _StoryPanel(this.title, this.story, this.asset, this.networkUrl, this.icon);
  final String title;
  final String story;
  final String asset;
  final String networkUrl;
  final IconData icon;
}

class _MultiversalDashboardState extends State<MultiversalDashboardScreen> {
  static const _panels = [
    _StoryPanel('The Silver Threshold',
        'A moonlit rune door stands between Barovia and a forgotten Netherese archive.',
        VisualCodexService.panelImageMap[1]!, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23', Icons.door_front_door_outlined),
    _StoryPanel('Vaelthara’s Warning',
        'The silver-haired archlich speaks through the Weave: “Trust the light beyond the mists.”',
        VisualCodexService.panelImageMap[2]!, 'https://images.unsplash.com/photo-1534447677768-be436bb09401', Icons.auto_awesome),
    _StoryPanel('The Three Relics',
        'Sight of Vaelthara, Hand of the Weave, and Silver Strand Codex resonate in the dark.',
        VisualCodexService.panelImageMap[3]!, 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f', Icons.diamond_outlined),
    _StoryPanel('An Unwritten Fate',
        'Deep below Barovia, an ancient mechanism begins to turn.',
        VisualCodexService.panelImageMap[4]!, 'https://images.unsplash.com/photo-1514539079130-25950c84af65', Icons.brightness_3_outlined),
  ];
  static const _choices = [
    ('Lawful Good', 'Secure the archive and protect anyone trapped within.'),
    ('Neutral Good', 'Seek survivors and offer assistance.'),
    ('Chaotic Good', 'Defy the corrupted seal.'),
    ('Utility', 'Study the runes and document their resonance.'),
    ('Action', 'Advance cautiously through the threshold.'),
  ];
  static const _tabs = ['Adventure', 'Character', 'Inventory', 'Journal', 'Atlas', 'Admin', 'Dice'];

  late final Future<PanelArtAudit> _artAudit = VisualCodexAudit.checkUniquePanels();
  MoonveilDatabase? _db;
  Map<String, dynamic>? _vesper;
  List<Map<String, Object?>> _inventory = [];
  String? _error;
  bool _loading = true;
  String _tab = 'Adventure';
  String? _selectedChoice;

  static int _abilityModifier(Map<String, dynamic>? state) {
    if (state == null) return 0;
    final direct = state['charisma_modifier'];
    if (direct is int) return direct;
    final attrs = state['attributes'];
    if (attrs is Map) {
      final score = attrs['charisma'] ?? attrs['CHA'];
      if (score is num) return ((score - 10) / 2).floor();
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final db = _db ?? await MultiversalRouterService.openSector('vesper');
      final character = await db.loadCharacter('vesper-vane');
      final inventory = await db.db.query('inventory_entries',
          where: 'campaign_id = ? AND character_id = ?',
          whereArgs: ['vesper', 'vesper-vane']);
      if (!mounted) {
        if (_db == null) await db.close();
        return;
      }
      setState(() {
        _db = db;
        _vesper = character;
        _inventory = inventory;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  void _roll() => InteractiveDiceRollerModal.show(
      context, modifier: _abilityModifier(_vesper));

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD7B7FF);
    return Scaffold(
      backgroundColor: const Color(0xFF100E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF19132D),
        title: const Text('☾ MOONVEIL · RAVENLOFT',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh),
              tooltip: 'Reload verified save'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7552AB),
        foregroundColor: Colors.white,
        onPressed: _roll,
        icon: const Icon(Icons.casino),
        label: const Text('Roll d20'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: SelectableText('Storage error: $_error'))
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFF302244), Color(0xFF151126), Color(0xFF0C0B18)],
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Text('VESPER VANE · THE SHATTERED WEAVE',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: accent, fontFamily: 'serif')),
                      const SizedBox(height: 10),
                      CampaignCompanionHud(character: _vesper, inventory: _inventory),
                      const SizedBox(height: 12),
                      if (_vesper == null)
                        const Card(child: ListTile(
                          leading: Icon(Icons.shield_outlined),
                          title: Text('Verified checkpoint not imported'),
                          subtitle: Text('No character level, HP, AC, or items will be invented.'),
                        )),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final tab in _tabs)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(tab),
                                selected: _tab == tab,
                                onSelected: (_) {
                                  if (tab == 'Dice') {
                                    _roll();
                                  } else {
                                    setState(() => _tab = tab);
                                  }
                                },
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      if (_tab == 'Adventure') ...[
                        Text('The Forgotten Archive',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'serif', color: accent)),
                        const SizedBox(height: 12),
                        LayoutBuilder(builder: (context, constraints) {
                          final wide = constraints.maxWidth > 700;
                          final width = wide
                              ? (constraints.maxWidth - 14) / 2
                              : constraints.maxWidth;
                          return Wrap(spacing: 14, runSpacing: 14, children: [
                            for (var i = 0; i < _panels.length; i++)
                              SizedBox(
                                width: width,
                                child: _VisualStoryCard(index: i + 1, panel: _panels[i], artAudit: _artAudit),
                              ),
                          ]);
                        }),
                        const SizedBox(height: 16),
                        Card(
                          color: const Color(0xFF231A3C),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('What does Vesper do?',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontFamily: 'serif', color: accent)),
                                const SizedBox(height: 10),
                                for (var i = 0; i < _choices.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: OutlinedButton(
                                      onPressed: () => setState(() =>
                                          _selectedChoice = _choices[i].$1),
                                      style: OutlinedButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.all(14),
                                        side: BorderSide(color: _selectedChoice == _choices[i].$1
                                            ? accent : const Color(0xFF79639B)),
                                      ),
                                      child: Text('${i + 1}. ${_choices[i].$1} — ${_choices[i].$2}'),
                                    ),
                                  ),
                                if (_selectedChoice != null)
                                  Text('Selected: $_selectedChoice. Story consequences are not yet connected to the campaign engine.',
                                      style: const TextStyle(color: accent)),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_tab == 'Character') ...[
                        Text('Character Record', style: Theme.of(context).textTheme.titleLarge),
                        CharacterSheetScreen(character: _vesper == null ? null : CharacterProfile.fromJson(_vesper!, ownedItems: _inventory.where((row) => row['owned'] == 1).map((row) { final item = row['item_json']; if (item is String) { try { final decoded = jsonDecode(item); if (decoded is Map && decoded['name'] is String) return decoded['name'] as String; } catch (_) {} } return row['item_id'].toString(); }).toList())),
                      ] else if (_tab == 'Inventory') ...[
                        Text('Inventory', style: Theme.of(context).textTheme.titleLarge),
                        if (_inventory.isEmpty) const Text('No verified inventory imported'),
                        for (final item in _inventory)
                          Card(child: ListTile(title: Text(item['item_id']?.toString() ?? 'Item'),
                              subtitle: Text(item.toString()))),
                      ] else if (_tab == 'Journal') ...[
                        const Text('Campaign journal integration pending; no events fabricated.'),
                      ] else if (_tab == 'Admin') ...[
                        if (_db != null) AdminConsoleScreen(database: _db!),
                      ] else if (_tab == 'Atlas') ...[
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
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _VisualStoryCard extends StatelessWidget {
  const _VisualStoryCard({required this.index, required this.panel, required this.artAudit});
  final int index;
  final _StoryPanel panel;
  final Future<PanelArtAudit> artAudit;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9274B6)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(fit: StackFit.expand, children: [
        // Local art first. A network image is optional; a painted fallback
        // remains visible offline when both sources are unavailable.
        FutureBuilder<PanelArtAudit>(
          future: artAudit,
          builder: (context, snapshot) {
            final uniqueLocal = snapshot.hasData &&
                (snapshot.data!.usable[index] ?? false);
            Widget remoteOrFallback() => Image.network(
              panel.networkUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF4B3267),
                          const Color(0xFF164456), index / 4)!,
                      const Color(0xFF100B22),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(child: Icon(panel.icon, size: 96,
                    color: const Color(0xAAD7B7FF))),
              ),
            );
            if (!uniqueLocal) return remoteOrFallback();
            return Image.asset(panel.asset, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    remoteOrFallback());
          },
        ),
        const DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0x88000000), Color(0xF0080712)],
            stops: [0.25, 0.6, 1],
          ),
        )),
        Positioned(left: 16, right: 16, bottom: 16, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PANEL $index', style: const TextStyle(
                color: Color(0xFFD7B7FF), letterSpacing: 1.4, fontSize: 11)),
            const SizedBox(height: 5),
            Text(panel.title, style: const TextStyle(
                fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(panel.story, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    ),
  );
}
