/// Catalog entries describe planned modules; only routes with a real screen are enabled.
class CommandButtonModel {
  const CommandButtonModel({required this.id, required this.title, this.route});
  final String id;
  final String title;
  final String? route;
  bool get isAvailable => route != null;
}

class MultiversalCommandButtonCatalog {
  static const masterButtonDatabase = <CommandButtonModel>[
    CommandButtonModel(id: 'mod_01', title: '🌙 PLAY RAVENLOFT', route: 'Adventure',),
    CommandButtonModel(id: 'mod_02', title: 'Story', route: 'Adventure',),
    CommandButtonModel(id: 'mod_03', title: 'Cities & Travel',),
    CommandButtonModel(id: 'mod_04', title: 'Shops',),
    CommandButtonModel(id: 'mod_05', title: 'People', route: 'Character',),
    CommandButtonModel(id: 'mod_06', title: 'Quests', route: 'Journal',),
    CommandButtonModel(id: 'mod_07', title: 'Lore & Collection', route: 'Atlas',),
    CommandButtonModel(id: 'mod_08', title: 'LUMA-01',),
    CommandButtonModel(id: 'mod_09', title: 'Districts',),
    CommandButtonModel(id: 'mod_10', title: 'Chapters', route: 'Journal',),
    CommandButtonModel(id: 'mod_11', title: 'E-STAM Academy',),
    CommandButtonModel(id: 'mod_12', title: 'Living Characters', route: 'Character',),
    CommandButtonModel(id: 'mod_13', title: 'Books & Relic Sets', route: 'Inventory',),
    CommandButtonModel(id: 'mod_14', title: 'Living Encounters',),
    CommandButtonModel(id: 'mod_15', title: 'Reactive World v9',),
    CommandButtonModel(id: 'mod_16', title: 'Civilization v10',),
    CommandButtonModel(id: 'mod_17', title: 'Connected Civ v11',),
    CommandButtonModel(id: 'mod_18', title: 'Unified Markets v12',),
    CommandButtonModel(id: 'mod_19', title: 'Visual Living World v13',),
    CommandButtonModel(id: 'mod_20', title: 'Streets & Interiors v14',),
    CommandButtonModel(id: 'mod_21', title: 'Animated Streets v15',),
    CommandButtonModel(id: 'mod_22', title: 'Immersive City v18',),
    CommandButtonModel(id: 'mod_23', title: 'Living City v17',),
    CommandButtonModel(id: 'mod_24', title: 'Living City v18',),
    CommandButtonModel(id: 'mod_25', title: 'City Life v20',),
    CommandButtonModel(id: 'mod_26', title: 'Connected City v21',),
    CommandButtonModel(id: 'mod_27', title: 'Regional Civ v22',),
    CommandButtonModel(id: 'mod_28', title: 'Regional Politics v23',),
    CommandButtonModel(id: 'mod_29', title: 'Neon Citadel v27',),
    CommandButtonModel(id: 'mod_30', title: 'Save Control v32', route: 'Admin',),
    CommandButtonModel(id: 'mod_31', title: 'Multiverse v31',),
    CommandButtonModel(id: 'mod_32', title: 'Multiverse Atlas v26', route: 'Atlas',),
    CommandButtonModel(id: 'mod_33', title: 'Divine Spell Codex v33',),
    CommandButtonModel(id: 'mod_34', title: 'Living Shrines v34',),
    CommandButtonModel(id: 'mod_35', title: 'Hidden Deck v36',),
    CommandButtonModel(id: 'mod_36', title: 'Core Quests v35',),
    CommandButtonModel(id: 'mod_37', title: 'Connected Gameplay v38',),
    CommandButtonModel(id: 'mod_38', title: 'Quest Consequences v41',),
  ];
}
