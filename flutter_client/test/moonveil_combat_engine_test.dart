import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonveil_client/services/moonveil_combat_engine.dart';

void main() {
  CombatEntity entity(String id, int hp, int ac) => CombatEntity(
    id: id, name: id, hp: hp, maxHp: hp, armorClass: ac, initiativeBonus: 0);

  test('Natural 20 always hits, doubles damage dice, and caps HP loss', () {
    final engine = MoonveilCombatEngine(random: _FixedRandom(19));
    final target = entity('target', 3, 99);
    final result = engine.executeAttack(
      attacker: entity('hero', 10, 13), defender: target,
      attackBonus: 0, damageDiceCount: 1, damageDiceFaces: 6,
      damageBonus: 5);
    expect(result['d20_roll'], 20);
    expect(result['is_critical'], true);
    expect((result['damage_rolls'] as List).length, 2);
    expect(result['damage_dealt'], 3);
    expect(target.hp, 0);
  });

  test('Natural 1 always misses regardless of bonus', () {
    final target = entity('target', 10, 1);
    final result = MoonveilCombatEngine(random: _FixedRandom(0)).executeAttack(
      attacker: entity('hero', 10, 13), defender: target,
      attackBonus: 100, damageDiceCount: 1, damageDiceFaces: 6,
      damageBonus: 0);
    expect(result['hit'], false);
    expect(target.hp, 10);
  });

  test('Invalid dice and defeated attackers cannot act', () {
    final engine = MoonveilCombatEngine(random: _FixedRandom(5));
    final attacker = entity('hero', 10, 13);
    final defender = entity('target', 10, 13);
    expect(() => engine.executeAttack(attacker: attacker, defender: defender,
      attackBonus: 0, damageDiceCount: -1, damageDiceFaces: 6,
      damageBonus: 0), throwsArgumentError);
    attacker.hp = 0;
    expect(() => engine.executeAttack(attacker: attacker, defender: defender,
      attackBonus: 0, damageDiceCount: 1, damageDiceFaces: 6,
      damageBonus: 0), throwsStateError);
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}
