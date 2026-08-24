import 'dart:io';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/hotspot.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// OGNISKA DAJĄ SIĘ ZWALCZAĆ (§6.5.4).
///
/// ⚠️ **Killing things inside a circle did nothing to the circle.**
///
/// Faza A gave hotspots somewhere to be, a row to live in and a clock that
/// runs with the app shut. It did not give the player any way to push back —
/// so the pressure was real, growing and permanent, which is half a mechanic
/// and the worse half.
///
/// §6.5.4's whole trade is here: a body dropped inside the circle is worth
/// twice one lured out, integrity comes back while nobody is working on it,
/// and knocking a level off buys ten minutes of something considerably angrier
/// than what was there before.
void main() {
  const centre = GeoPoint(52.4084, 16.9342);
  final t0 = DateTime.utc(2026, 8, 24, 20);

  GeoPoint north(double metres) =>
      GeoPoint(centre.latitude + metres / metresPerDegreeLat, centre.longitude);

  Hotspot at(int level) => Hotspot(
    id: '1.0',
    seed: 7,
    centre: centre,
    level: level,
    integrity: integrityMaxAt(level).toDouble(),
    bornAt: t0,
    nextLevelAt: t0.add(const Duration(hours: 8)),
  );

  group('§6.5.4: what a body is worth', () {
    test('inside the circle it is worth full price', () {
      final spot = at(5);
      final hurt = spot.damagedBy(EnemyKind.walker, at: centre);

      expect(spot.integrity - hurt.integrity, 10);
    });

    test('and outside it exactly half (§6.5.4)', () {
      // ⚠️ The trade the whole mechanic turns on: luring them out is safer and
      // exactly twice as slow. Rounded down, so a Walker dragged into the open
      // is worth five and not five and a half.
      final spot = at(5);
      final hurt = spot.damagedBy(
        EnemyKind.walker,
        at: north(spot.radiusM + 50),
      );

      expect(spot.integrity - hurt.integrity, 5);
    });

    test('a Brute is worth three and a half Walkers', () {
      final spot = at(5);

      expect(
        spot.integrity - spot.damagedBy(EnemyKind.brute, at: centre).integrity,
        35,
      );
    });

    test('and integrity never goes below nought', () {
      var spot = at(1);
      for (var i = 0; i < 50; i++) {
        spot = spot.damagedBy(EnemyKind.brute, at: centre);
      }

      expect(spot.integrity, 0);
    });
  });

  group('§6.5.4: through the wall', () {
    test('a level comes off, and the wall is rebuilt at the new one', () {
      // ⚠️ Full at the new level rather than carried over. Arriving at a
      // *lower* level already damaged would make a hotspot easiest at the
      // moment the player had just made it hardest to reach.
      final after = at(5).demoted(at: t0, restFor: const Duration(hours: 24));

      expect(after.level, 4);
      expect(after.integrity, integrityMaxAt(4));
    });

    test('and it is furious for ten minutes', () {
      final after = at(5).demoted(at: t0, restFor: const Duration(hours: 24));

      expect(after.isAgitatedAt(t0.add(const Duration(minutes: 9))), isTrue);
      expect(after.isAgitatedAt(t0.add(const Duration(minutes: 11))), isFalse);
    });

    test('fury is more of them, sooner, and one rung worse', () {
      final calm = at(5);
      final angry = calm.demoted(at: t0, restFor: const Duration(hours: 24));
      final during = t0.add(const Duration(minutes: 5));

      expect(angry.enemyCapAt(during), greaterThan(levelRow(4).enemyCap));
      expect(angry.respawnAt(during), lessThan(levelRow(4).respawn));

      // §6.5.4: every Walker becomes a Leaper. That is what makes knocking a
      // level off a victory that has to be survived.
      expect(angry.compositionNow(during), isNot(contains(EnemyKind.walker)));
    });

    test('the last level empties the slot for a day or two', () {
      final cleared = at(1).demoted(at: t0, restFor: const Duration(hours: 30));

      expect(cleared.isResting, isTrue);
      expect(cleared.enemyCapAt(t0), 0);
      expect(cleared.restingUntil, t0.add(const Duration(hours: 30)));
    });
  });

  group('§6.5.4: and the ground heals while nobody is on it', () {
    test('five per cent of the maximum an hour', () {
      final hurt = at(5).copyWith(integrity: 10);
      final after = hurt.regenerated(const Duration(hours: 2));

      expect(
        after.integrity - 10,
        closeTo(integrityMaxAt(5) * kIntegrityRegenPerHour * 2, 0.01),
      );
    });

    test('and never past full', () {
      expect(
        at(5).regenerated(const Duration(days: 7)).integrity,
        integrityMaxAt(5),
      );
    });

    test('a resting slot does not heal into existence', () {
      final resting = at(1).demoted(at: t0, restFor: const Duration(hours: 30));

      expect(resting.regenerated(const Duration(days: 1)).integrity, 0);
    });
  });

  group("§6.5.4's valve: fury does not follow somebody who left", () {
    test('walking four hundred metres out drops it', () {
      // ⚠️ The one rule in §6.5.4 that exists to let a player *lose*.
      // Agitation is meant to be hard, not a spiral with no way out —
      // withdrawing has to work, or the mechanic punishes the attempt rather
      // than the mistake.
      final angry = at(5).demoted(at: t0, restFor: const Duration(hours: 24));

      expect(
        angry.settledIfAbandoned(north(kAgitationEscapeM + 50)).agitatedUntil,
        isNull,
      );
    });

    test('but standing in it does not', () {
      final angry = at(5).demoted(at: t0, restFor: const Duration(hours: 24));

      expect(angry.settledIfAbandoned(centre).agitatedUntil, isNotNull);
    });
  });

  test('§6.5.4: and the game actually asks all of it', () {
    // ⚠️ Source-level, because every one of these was a method on a model
    // nothing called — which is exactly the state the whole of §6.5 was in
    // before stage 6 started.
    final main = File('lib/main.dart').readAsStringSync();
    final controller = File(
      'lib/game/controllers/hotspot_controller.dart',
    ).readAsStringSync();

    expect(main.contains('_fires.killed(enemy'), isTrue);
    expect(main.contains('_fires.settle('), isTrue);

    for (final rule in [
      'damagedBy(', // §6.5.4's kill points
      'demoted(', // through the wall
      'regenerated(', // five per cent an hour
      'settledIfAbandoned(', // the escape valve
    ]) {
      expect(
        controller.contains(rule),
        isTrue,
        reason: '$rule is a rule nothing asks for again',
      );
    }
  });

  test('§6.5.4: a kill belongs to where the body came from', () {
    // The spawner stamps a hotspot's centre onto everything it makes as that
    // enemy's home, and that is what a kill is matched on — otherwise luring
    // something out would mean it counted for nothing at all rather than for
    // half.
    final controller = File(
      'lib/game/controllers/hotspot_controller.dart',
    ).readAsStringSync();

    expect(controller.contains('distanceTo(enemy.home)'), isTrue);
    expect(
      controller.contains('at: enemy.position'),
      isTrue,
      reason: 'the half-price rule needs where it fell, not where it lived',
    );
  });
}
