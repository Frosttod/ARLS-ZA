import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/blows_away.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/engagement.dart' show kMeleeM;
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// ZAMKNIĘCIE APLIKACJI W ZWARCIU (§5.5.3, §9.2, §11.1.2).
///
/// ⚠️ **It was a perfect escape.** The blows of §5.5.3 were only ever applied
/// on a live tick, so a player with three Walkers at arm's length could lock
/// the screen, walk home and come back untouched. Nothing in §5 or §6 costs
/// anything if the way out is free — the whole economy of those two sections
/// is that a fight has to be *left*.
///
/// Two figures hold the rule up and both are here: the window is the same five
/// minutes that make a street forgettable (§11.1.2), and the total never kills.
void main() {
  const here = GeoPoint(52.4084, 16.9342);
  const bloodMax = 5000.0;

  Enemy at(
    double metres, {
    EnemyKind kind = EnemyKind.walker,
    String id = 'w',
  }) => Enemy.spawn(
    id: id,
    kind: kind,
    at: GeoPoint(here.latitude + metres / metresPerDegreeLat, here.longitude),
    home: here,
    random: Random(3),
  );

  BlowsAway away({
    List<Enemy>? inReach,
    Duration gone = const Duration(minutes: 2),
    double blood = bloodMax,
    double protection = 0,
    bool mayGoDown = true,
  }) => blowsWhileAway(
    inReach: inReach ?? [at(2)],
    away: gone,
    bloodMl: blood,
    bloodMaxMl: bloodMax,
    protection: protection,
    mayGoDown: mayGoDown,
    random: Random(11),
  );

  group('§5.5.3: the way out is not free', () {
    test('a clinch left standing costs blood', () {
      final hurt = away();

      expect(hurt.any, isTrue);
      expect(hurt.blows, greaterThan(0));
      expect(hurt.bloodMl, greaterThan(0));
    });

    test('an empty street costs nothing', () {
      expect(away(inReach: const []).any, isFalse);
    });

    test('and neither does a gap too short to be a gap', () {
      expect(away(gone: Duration.zero).any, isFalse);
    });

    test('more of them is worse than one of them (§5.5.3)', () {
      // The player answers one and the rest swing freely, which is why letting
      // a group close is very nearly a sentence.
      final one = away(inReach: [at(2, id: 'a')]);
      final three = away(
        inReach: [
          at(2, id: 'a'),
          at(3, id: 'b'),
          at(4, id: 'c'),
        ],
        blood: bloodMax,
      );

      expect(three.blows, greaterThan(one.blows));
    });

    test('armour takes some of it (§4.4)', () {
      final bare = away(gone: const Duration(seconds: 20));
      final plated = away(gone: const Duration(seconds: 20), protection: 1);

      expect(plated.bloodMl, lessThan(bare.bloodMl));
    });
  });

  group('§11.1.2: five minutes of it, and no more', () {
    test('a longer gap is charged as five minutes', () {
      final five = away(gone: kBlowsAwayWindow);
      final night = away(gone: const Duration(hours: 8));

      expect(night.blows, five.blows);
    });

    test('and a shorter one only for what it was', () {
      expect(
        away(gone: const Duration(minutes: 1)).blows,
        lessThan(away(gone: kBlowsAwayWindow).blows),
      );
    });
  });

  group('§9.2: and it never kills', () {
    test('hardcore stops short of class IV (§2.6)', () {
      // ⚠️ A month-long run must not end in a pocket. Five minutes of a crowd
      // is arithmetically fatal several times over — realistic, and the kind
      // of realism that makes somebody delete the game.
      final hurt = away(
        inReach: [
          at(2, id: 'a'),
          at(2, id: 'b'),
          at(2, id: 'c'),
        ],
        gone: const Duration(hours: 1),
        mayGoDown: false,
      );

      final left = bloodMax - hurt.bloodMl;
      expect(left / bloodMax, greaterThan(1 - kClassFourLoss));
    });

    test('softcore may be taken to the edge, where §9.2 takes over', () {
      final hurt = away(
        inReach: [
          at(2, id: 'a'),
          at(2, id: 'b'),
          at(2, id: 'c'),
        ],
        gone: const Duration(hours: 1),
      );

      final left = bloodMax - hurt.bloodMl;
      expect(left / bloodMax, closeTo(1 - kClassFourLoss, 0.001));
    });

    test('somebody already past the line loses nothing more', () {
      // Woken at 65% and set upon again: the clamp is a floor, not a target.
      final hurt = away(blood: bloodMax * 0.55, mayGoDown: false);

      expect(hurt.bloodMl, 0);
    });
  });

  group('§5.5.3: who is close enough to swing', () {
    test('anything inside the melee band', () {
      final near = enemiesInReach([at(kMeleeM - 1)], here);

      expect(near, hasLength(1));
    });

    test('and nothing outside it', () {
      expect(enemiesInReach([at(kMeleeM + 5)], here), isEmpty);
    });

    test('nor anything already down', () {
      final dead = at(2).copyWith(bloodLostMl: 99999);

      expect(dead.isDead, isTrue);
      expect(enemiesInReach([dead], here), isEmpty);
    });
  });

  test('§5.5.3: and the game actually charges for it', () {
    // ⚠️ Source-level, because the model can be perfect and the exploit still
    // open — which is exactly what it was until now: `_takeBlows` ran only on
    // a live tick, and the branch that handles a gap threw the street away
    // without asking what it had been doing.
    final main = File('lib/main.dart').readAsStringSync();

    expect(main.contains('_settleBlowsAway(elapsed'), isTrue);
    expect(main.contains('_fight.settleAway('), isTrue);

    // ⚠️ The parsed mode, not the wire string. `profile.deathMode` is the text
    // on disk and comparing it to a `DeathMode` is always true — which made
    // "hardcore never dies in a pocket" always false. The analyzer caught it;
    // this keeps it caught.
    expect(
      main.contains('character.deathMode != DeathMode.hardcore'),
      isTrue,
      reason: 'the clamp is reading the wire name again',
    );
    expect(
      main.contains('if (elapsed > kAwayGap)'),
      isTrue,
      reason: 'a gap has to be recognised before it can be charged for',
    );
    expect(
      main.indexOf('_settleBlowsAway(elapsed') <
          main.indexOf('gap == CombatGap.forgotten'),
      isTrue,
      reason:
          'charged before the street is thrown away, or it is charged for '
          'a crowd that is no longer there to have done it',
    );
  });
}
