import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/pursuit.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// POŚCIG MUSI STYGNĄĆ (§5.6.2, §6.1a).
///
/// ⚠️ **A shot fired from a distance made a permanent hunter.**
///
/// Reported from a walk: "przeciwnicy tak długo mnie szukają, jeśli strzelę i
/// są daleko — po zamknięciu i wznowieniu gry nadal szukają". They did not
/// search for a long time. They searched for ever, and two separate defects
/// each had to hold for that to happen.
///
/// **One.** `investigateLeft` counts down only once the body has *arrived* at
/// the noise, which is right for searching a street corner and wrong for
/// getting there. A gunshot carries seven hundred metres (§5.6.1) and §6.1a's
/// leash will not let anything wander more than four hundred from home — so a
/// distant shot is a sound most of them can never reach. Beyond the leash they
/// are sent home, go idle, remember the same noise, and set off again. The
/// thirty seconds never start, so the noise is never forgotten.
///
/// **Two.** The interface fed §5.6.2's hunt from "anything not idle and not
/// going home", which includes exactly those oscillating bodies. So `until`
/// was pushed fifteen minutes into the future on every tick, the street never
/// went cold, and reopening the game put hunters back — every time.
void main() {
  const home = GeoPoint(52.4084, 16.9342);

  GeoPoint north(double metres) =>
      GeoPoint(home.latitude + metres / metresPerDegreeLat, home.longitude);

  Enemy spawn() => Enemy.spawn(
    id: 'e1',
    kind: EnemyKind.walker,
    at: home,
    home: home,
    random: Random(1),
  );

  /// Runs the machine a second at a time, which is what the game does.
  Enemy run(Enemy enemy, {required GeoPoint playerAt, required Duration for_}) {
    var current = enemy;
    for (var second = 0; second < for_.inSeconds; second++) {
      current = advanceEnemy(
        current,
        playerAt: playerAt,
        elapsed: const Duration(seconds: 1),
      );
    }
    return current;
  }

  group('§5.6.2: a sound it cannot reach is a sound it gives up on', () {
    test('a noise beyond the leash is forgotten inside the walk clock', () {
      // ⚠️ The whole bug in one case. Six hundred metres out is past §6.1a's
      // four-hundred-metre leash, so it can never arrive — and before
      // [kWalkToNoiseFor] existed, that meant it never stopped trying.
      final heard = spawn().hears(north(600));
      final after = run(
        heard,
        playerAt: north(2000),
        for_: kWalkToNoiseFor + const Duration(seconds: 30),
      );

      expect(after.heardAt, isNull);
      expect(after.investigateLeft, Duration.zero);
    });

    test('and it is not still trying an hour later', () {
      final after = run(
        spawn().hears(north(600)),
        playerAt: north(2000),
        for_: const Duration(hours: 1),
      );

      expect(after.heardAt, isNull);
      expect(
        after.state,
        anyOf(EnemyState.idle, EnemyState.returning),
        reason: 'it is still hunting a sound from an hour ago',
      );
    });

    test('a noise it can reach is still searched properly (§5.6.2)', () {
      // The rule this is not allowed to break: something that arrives gets its
      // thirty seconds of looking, which is what makes a shot cost anything.
      final heard = spawn().hears(north(40));
      final soon = run(
        heard,
        playerAt: north(2000),
        for_: const Duration(seconds: 20),
      );

      expect(soon.heardAt, isNotNull, reason: 'it gave up on the way');
    });

    test('and a fresh sound starts a fresh walk', () {
      // Otherwise a body that gave up on one noise would give up on the next
      // one instantly.
      final tired = run(
        spawn().hears(north(600)),
        playerAt: north(2000),
        for_: kWalkToNoiseFor,
      );

      expect(tired.hears(north(50)).walkedToNoise, Duration.zero);
    });
  });

  group('§5.6.2: who counts as being onto the player', () {
    Enemy at(double metres, EnemyState state) =>
        spawn().copyWith(position: north(metres), state: state);

    test('something coming for you does', () {
      expect(at(30, EnemyState.chase).isOnto(home), isTrue);
      expect(at(300, EnemyState.spent).isOnto(home), isTrue);
    });

    test('and something alert and close enough to see you does', () {
      expect(at(30, EnemyState.alert).isOnto(home), isTrue);
    });

    test('but something alert three streets away does not', () {
      // ⚠️ The second half of the bug. It is busy, it is not idle, and it is
      // not on anybody — a Walker sees a hundred and twenty metres (§6.2).
      expect(at(400, EnemyState.alert).isOnto(home), isFalse);
    });

    test('nor does anything going home or standing about', () {
      expect(at(30, EnemyState.idle).isOnto(home), isFalse);
      expect(at(30, EnemyState.returning).isOnto(home), isFalse);
    });
  });

  group('§5.6.2: the street goes cold', () {
    final t0 = DateTime.utc(2026, 8, 24, 20);

    test('a body walking to a distant noise does not keep it warm', () {
      final walking = spawn().copyWith(
        position: north(400),
        state: EnemyState.alert,
      );

      final hunt = pursuitAfter(
        current: null,
        near: [walking],
        at: home,
        now: t0,
      );

      expect(hunt, isNull, reason: 'the hunt was refreshed by a rumour');
    });

    test('but something actually on you does', () {
      final onto = spawn().copyWith(
        position: north(30),
        state: EnemyState.chase,
      );

      final hunt = pursuitAfter(current: null, near: [onto], at: home, now: t0);

      expect(hunt, isNotNull);
      expect(hunt!.count, 1);
    });

    test('and one that has run out is dropped rather than carried', () {
      final cold = Pursuit(at: home, until: t0, count: 3);

      expect(
        pursuitAfter(
          current: cold,
          near: const [],
          at: home,
          now: t0.add(const Duration(seconds: 1)),
        ),
        isNull,
      );
    });

    test('a warm one with nobody about is left alone to run out', () {
      // §5.6.2's fifteen minutes are the player's escape window, and a tick
      // with nothing in sight is not the same as the street forgetting.
      final warm = Pursuit(
        at: home,
        until: t0.add(const Duration(minutes: 10)),
        count: 3,
      );

      expect(
        pursuitAfter(current: warm, near: const [], at: home, now: t0),
        same(warm),
      );
    });

    test('§11.1: and it is what a restart puts back', () {
      // The figure the reported bug was actually about: reopening the game
      // seeds hunters from this, so a hunt that never cools is hunters for
      // ever.
      final cold = Pursuit(at: home, until: t0, count: 4);

      expect(cold.resumedAt(home, t0.add(const Duration(minutes: 1))), 0);
    });
  });
}
