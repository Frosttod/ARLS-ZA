import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/engagement.dart' show kMeleeM;
import 'package:arls_za/combat/target_reading.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// CO MÓWI PANEL OGNIA (§5.1.4, §5.5.1, §8.1).
///
/// ⚠️ **Forty arguments, assembled in a build method.** The panel was built
/// inline in the largest widget tree in the codebase, and the facts behind it
/// were recomputed on the spot: the distance to the target four times over,
/// the magazine size twice, "am I in my own safe zone" three times, "am I
/// inside the grace window" three times. Every one of those is a rule of §5 or
/// §8.1 — and a rule written four times in a build method is a rule that will
/// be four different rules the next time one of them is edited.
///
/// None of it could be tested where it stood. All of it can be tested here.
void main() {
  const here = GeoPoint(52.4084, 16.9342);

  Enemy walkerAt(double metres) => Enemy.spawn(
    id: 'w1',
    kind: EnemyKind.walker,
    at: GeoPoint(here.latitude + metres / metresPerDegreeLat, here.longitude),
    home: here,
    random: Random(7),
  );

  TargetReading read({
    double metres = 80,
    String? weaponName = 'Karabinek',
    int magazine = 30,
    int loaded = 30,
    bool hasRound = true,
    bool reloading = false,
    bool inOwnZone = false,
    bool inGrace = false,
  }) => readTarget(
    target: walkerAt(metres),
    from: here,
    targetName: 'Szwędacz',
    error: null,
    weaponName: weaponName,
    magazine: magazine,
    loaded: loaded,
    hasRound: hasRound,
    reloading: reloading,
    settling: false,
    inOwnZone: inOwnZone,
    inGrace: inGrace,
  );

  group('§5.5.1: the distance, worked out once', () {
    test('and it is the distance to the thing being aimed at', () {
      expect(read(metres: 120).distanceM, closeTo(120, 1));
    });

    test('with nothing in hand there is no chance to state (§5.1.4)', () {
      // A number about a shot nobody can take is worse than no number.
      expect(read(weaponName: null).chance, isNull);
      expect(read(weaponName: null).dominant, isNull);
    });
  });

  group('§5.5.4, §8.1: why the trigger is not available', () {
    test('standing in your own zone outranks everything else', () {
      // ⚠️ The order is the rule. A full magazine in your own doorway is still
      // a refusal, and the reason has to be the doorway — §8.1's fifty metres
      // keeps them out and keeps the player's fire in, and a player told
      // "no ammunition" would go looking for ammunition.
      expect(
        read(
          inOwnZone: true,
          inGrace: true,
          weaponName: null,
          loaded: 0,
        ).refusal,
        CombatRefusal.insideOwnZone,
      );
    });

    test('then the grace window (§9.2)', () {
      expect(
        read(inGrace: true, weaponName: null, loaded: 0).refusal,
        CombatRefusal.grace,
      );
    });

    test('then empty hands', () {
      expect(read(weaponName: null, loaded: 0).refusal, CombatRefusal.noWeapon);
    });

    test('and only then the ammunition', () {
      expect(read(loaded: 0, hasRound: false).refusal, CombatRefusal.noAmmo);
    });

    test('an empty magazine with a round in the pack is not a refusal', () {
      // There is something to do about it, and §5.3 is how.
      expect(read(loaded: 0, hasRound: true).refusal, isNull);
      expect(read(loaded: 0, hasRound: true).canReload, isTrue);
    });

    test('a loaded rifle in the open refuses nothing', () {
      expect(read().refusal, isNull);
      expect(read().canFire, isTrue);
    });
  });

  group('§5.3: what may be reloaded', () {
    test('not while one is already going in', () {
      expect(read(loaded: 0, reloading: true).canReload, isFalse);
    });

    test('and not into a full magazine', () {
      // §5.3's seconds are for filling a magazine, and a full one has no room.
      expect(read(loaded: 30, magazine: 30).canReload, isFalse);
      expect(read(loaded: 29, magazine: 30).canReload, isTrue);
    });

    test('nor with nothing to put in it', () {
      expect(read(loaded: 0, hasRound: false).canReload, isFalse);
    });

    test('nor with nothing to put it into', () {
      expect(read(weaponName: null, loaded: 0).canReload, isFalse);
    });
  });

  group('§5.2, §5.4: what may be swung at', () {
    test('anything inside twenty metres', () {
      expect(read(metres: kMeleeM - 1).canStrike, isTrue);
      expect(read(metres: kMeleeM + 5).canStrike, isFalse);
    });

    test('bare hands included', () {
      // ⚠️ Deliberately not gated on a weapon. Below §5.2's twenty metres the
      // fight stops being about distance and becomes about what is in your
      // hands — and empty hands are an answer to that question.
      expect(read(metres: 5, weaponName: null, loaded: 0).canStrike, isTrue);
    });

    test('but never out of your own doorway or the grace window', () {
      expect(read(metres: 5, inOwnZone: true).canStrike, isFalse);
      expect(read(metres: 5, inGrace: true).canStrike, isFalse);
    });
  });

  group('§5.5.4: what may be fired', () {
    test('not with an empty magazine, however much is in the pack', () {
      expect(read(loaded: 0, hasRound: true).canFire, isFalse);
    });

    test('not mid-reload', () {
      expect(read(reloading: true).canFire, isFalse);
    });

    test('and not from inside your own zone (§8.1)', () {
      expect(read(inOwnZone: true).canFire, isFalse);
      expect(read(inGrace: true).canFire, isFalse);
    });
  });

  test('§5: and the screen no longer decides any of it', () {
    // ⚠️ Source-level. Every one of these rules used to live in a build method
    // where none of it could be tested, and the value of moving it is exactly
    // that it cannot drift back.
    final main = File('lib/main.dart').readAsStringSync();
    final panel = File('lib/ui/combat_panel.dart').readAsStringSync();

    expect(main.contains('reading: readTarget('), isTrue);
    expect(
      main.contains('hitChance('),
      isFalse,
      reason: 'the odds belong to the model, not to the screen',
    );
    expect(
      panel.contains('reading.canFire ? onFire : null'),
      isTrue,
      reason: 'a dead button inferred from a null callback is a second rule',
    );
  });
}
