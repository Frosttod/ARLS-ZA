import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/aim.dart';
import 'package:arls_za/combat/ballistics.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/engagement.dart';
import 'package:arls_za/combat/shot.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// §5.1, §5.1.5, §5.6. One shot, and the three things it costs.
///
/// A round, a wound that may not happen, and the noise — which is the one a
/// player forgets and the one §5.6.3 builds the whole weapon choice on. A miss
/// is heard exactly as well as a hit, and that is the price of firing at a
/// poor chance.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  const here = GeoPoint(52.4084, 16.9342);
  final walker = Enemy.spawn(
    id: 'w1',
    kind: EnemyKind.walker,
    at: here,
    home: here,
    random: Random(1),
  );

  ShotError budget({
    double skill = 0,
    double heartRate = 70,
    double playerSpeedKmh = 0,
    double targetSpeedKmh = 0,
    double spreadMultiplier = 1,
    String weapon = 'weapon_rifle_545',
  }) => aimError(
    weapon: catalogue[weapon]!,
    skill: skill,
    heartRate: heartRate,
    restingHr: 70,
    maxHr: 187,
    playerSpeedKmh: playerSpeedKmh,
    targetSpeedKmh: targetSpeedKmh,
    spreadMultiplier: spreadMultiplier,
  );

  ShotOutcome fire({
    String weapon = 'weapon_rifle_545',
    String? ammo = 'ammo_545x39',
    double distanceM = 80,
    ShotError? error,
    double roll = 0.0,
    bool suppressed = false,
    double protection = 0,
    double locationMultiplier = 1,
  }) => fireAt(
    weapon: catalogue[weapon]!,
    ammo: ammo == null ? null : catalogue[ammo],
    target: walker,
    distanceM: distanceM,
    error: error ?? budget(),
    random: _FixedRoll(roll),
    suppressed: suppressed,
    protection: protection,
    locationMultiplier: locationMultiplier,
  );

  group('the odds are the ones on the screen (§5.1.4)', () {
    test('the chance comes out of the same arithmetic the HUD shows', () {
      final error = budget(heartRate: 160, targetSpeedKmh: 16);
      final outcome = fire(error: error);

      expect(
        outcome.chance,
        closeTo(hitChance(moa: error.total, distanceM: 80), 1e-9),
      );
    });

    test('and the shot says which error was the largest', () {
      final walking = fire(
        error: budget(heartRate: 160, playerSpeedKmh: 5, targetSpeedKmh: 16),
      );

      expect(walking.dominant, ErrorSource.movement);
    });

    test('a roll under the chance hits, and over it misses', () {
      final error = budget();
      final chance = hitChance(moa: error.total, distanceM: 80);

      expect(fire(error: error, roll: chance - 0.01).hit, isTrue);
      expect(fire(error: error, roll: chance + 0.01).hit, isFalse);
    });
  });

  group('what a hit does (§5.1.5)', () {
    test('the wound comes from the round, not from the rifle', () {
      // The same barrel with a different load is a different wound.
      final buck = fire(
        weapon: 'weapon_shotgun_pump',
        ammo: 'ammo_12ga_buck',
      );
      final slug = fire(
        weapon: 'weapon_shotgun_pump',
        ammo: 'ammo_12ga_slug',
      );

      expect(slug.bloodLossMl, greaterThan(buck.bloodLossMl));
    });

    test('a carbine takes about three shots to a Walker (§5.1.5)', () {
      final outcome = fire();
      final shots = walker.bloodMl * walker.kind.deathAtLoss /
          outcome.bloodLossMl;

      expect(shots, closeTo(3.2, 0.4));
    });

    test('a pistol takes about seven', () {
      final outcome = fire(weapon: 'weapon_pistol_9mm', ammo: 'ammo_9x19');
      final shots = walker.bloodMl * walker.kind.deathAtLoss /
          outcome.bloodLossMl;

      expect(shots, closeTo(7.2, 0.8));
    });

    test('armour takes its share', () {
      final bare = fire().bloodLossMl;
      final vested = fire(protection: 0.5).bloodLossMl;

      expect(vested, closeTo(bare / 2, 0.5));
    });

    test('a head is worth four torsos (§2.6)', () {
      expect(
        fire(locationMultiplier: 4).bloodLossMl,
        closeTo(4 * fire().bloodLossMl, 0.5),
      );
    });

    test('a miss does nothing at all', () {
      expect(fire(roll: 0.999).bloodLossMl, 0);
    });
  });

  group('what it costs in attention (§5.6)', () {
    test('a rifle is heard from its own distance', () {
      expect(
        fire().noiseM,
        closeTo(
          (catalogue['weapon_rifle_545']!.props['noise_range_m'] as num)
              .toDouble(),
          0.5,
        ),
      );
    });

    test('a miss is heard exactly as well as a hit', () {
      // The whole price of firing at a poor chance.
      expect(fire(roll: 0.999).noiseM, fire(roll: 0.0).noiseM);
    });

    test('a suppressor is worth three and a half times (§5.6.3)', () {
      expect(fire(suppressed: true).noiseM, closeTo(fire().noiseM / 3.5, 0.5));
    });
  });

  group('holding the sights on something (§5.5.1, §5.3)', () {
    final now = DateTime.utc(2026, 8, 16, 12);

    test('taking a new target costs the time §5.5.1 says', () {
      final aim = const Aim().at('w1', now: now);

      expect(aim.targetId, 'w1');
      expect(
        aim.spreadMultiplierAt(now),
        closeTo(kSwitchingSpreadMultiplier, 0.01),
      );
    });

    test('and the sights are widest while it happens', () {
      final aim = const Aim().at('w1', now: now);
      final wide = aim.spreadMultiplierAt(
        now.add(const Duration(milliseconds: 600)),
      );

      expect(wide, closeTo(kSwitchingSpreadMultiplier, 0.01));
    });

    test('then they narrow over the two seconds of §5.3', () {
      final aim = const Aim().at('w1', now: now);
      final half = aim.spreadMultiplierAt(
        now.add(const Duration(milliseconds: 1200 + 1000)),
      );
      final settled = aim.spreadMultiplierAt(
        now.add(const Duration(milliseconds: 1200 + 2000)),
      );

      expect(half, greaterThan(1));
      expect(half, lessThan(kSwitchingSpreadMultiplier));
      expect(settled, 1);
    });

    test('a racing heart takes twice as long to settle (§5.3)', () {
      final rested = settleTime(heartRate: 70, rest: 70, max: 187);
      final spent = settleTime(heartRate: 187, rest: 70, max: 187);

      expect(rested, kSettleFast);
      expect(spent, kSettleSlow);
    });

    test('tapping the same target again changes nothing', () {
      // A player who taps the same marker twice has not changed their mind.
      final aim = const Aim().at('w1', now: now);
      final again = aim.at('w1', now: now.add(const Duration(seconds: 5)));

      expect(identical(aim, again), isTrue);
    });

    test('switching to another one pays the price again', () {
      final aim = const Aim().at('w1', now: now);
      final switched = aim.at('w2', now: now.add(const Duration(seconds: 10)));

      expect(
        switched.spreadMultiplierAt(now.add(const Duration(seconds: 10))),
        closeTo(kSwitchingSpreadMultiplier, 0.01),
      );
    });

    test('a dead target is let go, and nothing takes its place (§5.5.1)', () {
      // Automation would remove the decision and leave tapping.
      final aim = const Aim().at('w1', now: now).released;

      expect(aim.hasTarget, isFalse);
    });

    test('unsettled sights open every source of error at once', () {
      // The shooter is not making a new mistake — they are making all the old
      // ones larger.
      final settled = budget(heartRate: 160);
      final swinging = budget(heartRate: 160, spreadMultiplier: 2.5);

      expect(swinging.total, closeTo(settled.total * 2.5, 0.01));
      expect(swinging.dominant, settled.dominant);
    });
  });
}

/// A die that always lands the same way, so a test is about the model rather
/// than about luck.
class _FixedRoll implements Random {
  const _FixedRoll(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value < 0.5;

  @override
  int nextInt(int max) => (value * max).floor();
}
