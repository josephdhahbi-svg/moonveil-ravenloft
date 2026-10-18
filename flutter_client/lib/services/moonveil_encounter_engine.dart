/// Deterministic, save-independent encounter engine for Moonveil VTT.
///
/// Combat is kept in memory until an explicit persistence integration is
/// implemented. Never writes to either Vesper or Alice's save database.
class MoonveilCombatant {
  const MoonveilCombatant({
    required this.id, required this.name, required this.initiative,
    required this.maxHp, required this.hp, required this.ac,
    this.initiativeModifier = 0, this.temporaryHp = 0,
    this.conditions = const <String>[], this.characterId, this.isEnemy = false,
  });

  final String id, name;
  final int initiative, initiativeModifier, maxHp, hp, ac, temporaryHp;
  final List<String> conditions;
  final String? characterId;
  final bool isEnemy;

  MoonveilCombatant copyWith({
    int? hp, int? temporaryHp, List<String>? conditions,
  }) => MoonveilCombatant(
    id: id, name: name, initiative: initiative,
    initiativeModifier: initiativeModifier, maxHp: maxHp,
    hp: hp ?? this.hp, ac: ac, temporaryHp: temporaryHp ?? this.temporaryHp,
    conditions: conditions ?? this.conditions, characterId: characterId,
    isEnemy: isEnemy,
  );

  /// Preview a character snapshot without changing its stored revision.
  /// Only explicitly supplied values are used; missing values are not invented.
  factory MoonveilCombatant.fromCharacterSnapshot({
    required String id, required String name,
    required Map<String, dynamic> snapshot,
    required int initiative, int initiativeModifier = 0,
  }) {
    int requiredStat(String key) {
      final value = snapshot[key];
      if (value is! int) throw FormatException('Missing integer $key');
      return value;
    }
    return MoonveilCombatant(
      id: id, name: name, initiative: initiative,
      initiativeModifier: initiativeModifier,
      maxHp: requiredStat('maxHp'), hp: requiredStat('hp'),
      ac: requiredStat('ac'), characterId: id,
    );
  }
}

class MoonveilEncounter {
  MoonveilEncounter(Iterable<MoonveilCombatant> participants)
      : combatants = List<MoonveilCombatant>.unmodifiable(
          participants.toList()..sort((a, b) {
            final roll = b.initiative.compareTo(a.initiative);
            if (roll != 0) return roll;
            final mod = b.initiativeModifier.compareTo(a.initiativeModifier);
            return mod != 0 ? mod : a.id.compareTo(b.id);
          })) {
    if (combatants.isEmpty) throw ArgumentError('Encounter cannot be empty');
    final ids = combatants.map((c) => c.id).toSet();
    if (ids.length != combatants.length ||
        combatants.any((c) => c.id.isEmpty || c.maxHp < 1 ||
          c.hp < 0 || c.hp > c.maxHp || c.temporaryHp < 0 || c.ac < 0)) {
      throw ArgumentError('Invalid combatant ID or hit points');
    }
  }

  final List<MoonveilCombatant> combatants;
  int round = 1;
  int turnIndex = 0;
  final List<Map<String, Object?>> _history = [];
  List<Map<String, Object?>> get history =>
      List<Map<String, Object?>>.unmodifiable(_history);

  void _log(String action, String id, {int? amount}) {
    _history.add({'round': round, 'actor': id, 'action': action,
      if (amount != null) 'amount': amount});
  }

  MoonveilCombatant get active => _current[turnIndex];

  void nextTurn() {
    turnIndex++;
    if (turnIndex >= combatants.length) {
      turnIndex = 0;
      round++;
    }
    _log('next_turn', active.id);
  }

  void applyDamage(String id, int damage) {
    if (damage < 0) throw ArgumentError('Damage must be nonnegative');
    final index = combatants.indexWhere((c) => c.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Unknown combatant');
    final current = _current[index];
    final remaining = (damage - current.temporaryHp).clamp(0, damage);
    final updated = current.copyWith(
      temporaryHp: (current.temporaryHp - damage).clamp(0, current.temporaryHp),
      hp: (current.hp - remaining).clamp(0, current.maxHp),
    );
    _replace(index, updated);
    _log('damage', id, amount: damage);
  }

  void heal(String id, int amount) {
    if (amount < 0) throw ArgumentError('Healing must be nonnegative');
    final index = combatants.indexWhere((c) => c.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Unknown combatant');
    final current = _current[index];
    _replace(index, current.copyWith(
      hp: (current.hp + amount).clamp(0, current.maxHp),
    ));
    _log('heal', id, amount: amount);
  }

  void setCondition(String id, String condition, {required bool enabled}) {
    if (condition.trim().isEmpty) throw ArgumentError('Condition cannot be blank');
    final index = _current.indexWhere((c) => c.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Unknown combatant');
    final conditions = _current[index].conditions.toSet();
    if (enabled) {
      conditions.add(condition);
    } else {
      conditions.remove(condition);
    }
    _replace(index, _current[index].copyWith(conditions: conditions.toList()));
    _log(enabled ? 'condition_added:$condition' : 'condition_removed:$condition', id);
  }

  void _replace(int index, MoonveilCombatant value) {
    // An encounter is intentionally mutable; the input snapshot is not.
    _current[index] = value;
  }

  late final List<MoonveilCombatant> _current =
      List<MoonveilCombatant>.of(combatants);

  List<MoonveilCombatant> get state =>
      List<MoonveilCombatant>.unmodifiable(_current);
  MoonveilCombatant get activeState => _current[turnIndex];

  Map<String, Object?> exportPreview() => {
    'round': round, 'turnIndex': turnIndex,
    'combatants': [
      for (final c in state)
        {'id': c.id, 'name': c.name, 'initiative': c.initiative,
         'hp': c.hp, 'maxHp': c.maxHp, 'temporaryHp': c.temporaryHp,
         'ac': c.ac, 'conditions': c.conditions, 'isEnemy': c.isEnemy}
    ], 'history': history,
  };
}
