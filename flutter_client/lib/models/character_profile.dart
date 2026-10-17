/// Read-only presentation model. Missing stats remain unknown, never seeded.
class CharacterProfile {
  const CharacterProfile({required this.id, required this.name, this.level,
    this.hp, this.maxHp, this.armorClass, this.patron, this.background,
    this.abilities = const {}, this.inventory = const []});
  final String id, name;
  final int? level, hp, maxHp, armorClass;
  final String? patron, background;
  final Map<String, int> abilities;
  final List<String> inventory;

  static int? _number(dynamic value) => value is int ? value : null;
  factory CharacterProfile.fromJson(Map<String, dynamic> data, {
    String characterId = 'vesper-vane', List<String> ownedItems = const [],
  }) {
    final rawAbilities = data['abilities'] ?? data['attributes'];
    final abilities = <String, int>{};
    if (rawAbilities is Map) {
      for (final entry in rawAbilities.entries) {
        if (entry.value is int) abilities[entry.key.toString().toUpperCase()] = entry.value as int;
      }
    }
    return CharacterProfile(
      id: characterId,
      name: data['name'] is String ? data['name'] as String : 'Vesper Vane',
      level: _number(data['level']),
      hp: _number(data['hp']),
      maxHp: _number(data['max_hp'] ?? data['maxHp']),
      armorClass: _number(data['ac'] ?? data['armor_class']),
      patron: data['patron'] is String ? data['patron'] as String : null,
      background: data['background'] is String ? data['background'] as String : null,
      abilities: Map.unmodifiable(abilities),
      inventory: List.unmodifiable(ownedItems),
    );
  }
}
