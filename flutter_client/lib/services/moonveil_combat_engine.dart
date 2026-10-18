import 'dart:math';

/// Deterministic when a seeded Random is supplied; combat does not write saves.
class CombatEntity {
  CombatEntity({
    required this.id,
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.armorClass,
    required this.initiativeBonus,
  }) {
    if (maxHp <= 0 || hp < 0 || hp > maxHp) {
      throw ArgumentError('HP must be between zero and maxHp');
    }
  }

  final String id;
  final String name;
  int hp;
  final int maxHp;
  final int armorClass;
  final int initiativeBonus;
  bool get isAlive => hp > 0;
}

class MoonveilCombatEngine {
  MoonveilCombatEngine({Random? random}) : _rng = random ?? Random.secure();
  final Random _rng;

  Map<String, dynamic> executeAttack({
    required CombatEntity attacker,
    required CombatEntity defender,
    required int attackBonus,
    required int damageDiceCount,
    required int damageDiceFaces,
    required int damageBonus,
  }) {
    if (damageDiceCount < 0 || damageDiceCount > 100 ||
        damageDiceFaces < 1 || damageDiceFaces > 1000) {
      throw ArgumentError('Invalid damage dice');
    }
    if (!attacker.isAlive) throw StateError('Defeated attacker cannot attack');
    if (!defender.isAlive) throw StateError('Defeated defender cannot be attacked');
    final roll = _rng.nextInt(20) + 1;
    final total = roll + attackBonus;
    final critical = roll == 20;
    final fumble = roll == 1;
    final hit = !fumble && (critical || total >= defender.armorClass);
    final diceRolls = <int>[];
    if (hit) {
      for (var i = 0; i < damageDiceCount * (critical ? 2 : 1); i++) {
        diceRolls.add(_rng.nextInt(damageDiceFaces) + 1);
      }
    }
    final rolledDamage = diceRolls.fold<int>(0, (sum, die) => sum + die);
    final requestedDamage = hit ? max(0, rolledDamage + damageBonus) : 0;
    final damageDealt = min(defender.hp, requestedDamage);
    defender.hp -= damageDealt;
    return {
      'attacker_id': attacker.id,
      'defender_id': defender.id,
      'attacker': attacker.name,
      'defender': defender.name,
      'd20_roll': roll,
      'total_attack': total,
      'target_ac': defender.armorClass,
      'is_critical': critical,
      'is_fumble': fumble,
      'hit': hit,
      'damage_rolls': diceRolls,
      'damage_bonus': hit ? damageBonus : 0,
      'damage_dealt': damageDealt,
      'defender_remaining_hp': defender.hp,
    };
  }
}
