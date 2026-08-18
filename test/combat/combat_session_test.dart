import 'dart:math';

import 'package:arls_za/combat/combat_session.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/enemy_spawner.dart';
import 'package:arls_za/combat/noise.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// §5.5, §6.1a, §6.4. The three combat models, meeting.
///
/// The session is where "what exists", "what each of them is doing" and "who
/// heard that" come together. It has no clock of its own on purpose: it is a
/// function of where the player is and how long has passed, which is what
/// §11's tick already provides — and a fight that ran on its own timer would
/// keep running while the app was closed.
void main() {
  const player = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 16, 14);

  GeoPoint north(double metres) =>
      GeoPoint(player.latitude + metres / metresPerDegreeLat, player.longitude);

  CombatSession run(
    CombatSession session, {
    GeoPoint? at,
    Duration total = const Duration(seconds: 1),
  }) {
    var current = session;
    for (var i = 0; i < total.inSeconds; i++) {
      current = current.advance(
        playerAt: at ?? player,
        elapsed: const Duration(seconds: 1),
        now: now,
      );
    }
    return current;
  }

  group('what is out there', () {
    test('a street with nobody on it fills up on its own (§6.4)', () {
      final session = run(const CombatSession(seed: 3));

      expect(session.enemies, isNotEmpty);
    });

    test('and the ambient trickle is Walkers, alone', () {
      final session = run(const CombatSession(seed: 3));

      expect(
        session.enemies.every((enemy) => enemy.kind == EnemyKind.walker),
        isTrue,
      );
    });

    test('none of them start on top of the player (§6.4)', () {
      for (var seed = 0; seed < 20; seed++) {
        final session = run(CombatSession(seed: seed));

        for (final enemy in session.enemies) {
          expect(
            enemy.position.distanceTo(player),
            greaterThanOrEqualTo(kSpawnMinM),
            reason: 'seed $seed',
          );
        }
      }
    });

    test('the same seed gives the same street', () {
      // §11: closing the app mid-walk must not reshuffle the neighbourhood.
      final a = run(const CombatSession(seed: 9));
      final b = run(const CombatSession(seed: 9));

      expect(a.enemies.length, b.enemies.length);
      expect(
        a.enemies.first.position.latitude,
        closeTo(b.enemies.first.position.latitude, 1e-12),
      );
    });

    test('the dead are cleared away rather than carried', () {
      final session = run(const CombatSession(seed: 4));
      final killed = session.wound(session.enemies.first.id, 99999);

      expect(killed.enemies.any((enemy) => enemy.isDead), isTrue);
      expect(run(killed).enemies.any((enemy) => enemy.isDead), isFalse);
    });

    test('only what is close counts as being in the fight (§5.5.6)', () {
      final far = Enemy.spawn(
        id: 'far.1',
        kind: EnemyKind.walker,
        at: north(900),
        home: north(900),
        random: Random(1),
      );
      final session = CombatSession(seed: 1, enemies: [far]);

      expect(session.enemies, hasLength(1));
      expect(session.near(player), isEmpty);
    });
  });

  group('what they are doing', () {
    test('one that can see the player closes the distance (§6.1a)', () {
      final walker = Enemy.spawn(
        id: 'w1',
        kind: EnemyKind.walker,
        at: north(60),
        home: north(60),
        random: Random(1),
      );

      final after = run(
        CombatSession(seed: 1, enemies: [walker]),
        total: const Duration(seconds: 10),
      );

      final moved = after.enemies.firstWhere((enemy) => enemy.id == 'w1');
      expect(
        moved.position.distanceTo(player),
        lessThan(walker.position.distanceTo(player)),
      );
    });

    test('and one that cannot stays where it is', () {
      final walker = Enemy.spawn(
        id: 'w1',
        kind: EnemyKind.walker,
        at: north(400),
        home: north(400),
        random: Random(1),
      );

      final after = run(
        CombatSession(seed: 1, enemies: [walker]),
        total: const Duration(seconds: 10),
      );

      final still = after.enemies.firstWhere((enemy) => enemy.id == 'w1');
      expect(still.state, EnemyState.idle);
      // §6.1a: it mills about its own patch rather than closing on anybody.
      expect(still.position.distanceTo(walker.position), lessThan(30));
    });
  });

  group('a shot, and who answers it (§5.6)', () {
    CombatSession withWalkerAt(double metres) => CombatSession(
      seed: 1,
      enemies: [
        Enemy.spawn(
          id: 'w1',
          kind: EnemyKind.walker,
          at: north(metres),
          home: north(metres),
          random: Random(1),
        ),
      ],
    );

    NoiseEvent shot({DateTime? when}) => NoiseEvent(
      at: player,
      radiusM: NoiseKind.rifle.baseM,
      startedAt: when ?? now,
    );

    test('they walk to the sound rather than to the player', () {
      final after = withWalkerAt(500).heard(shot(), playerAt: player);

      expect(after.enemies.single.heardAt, isNotNull);
      expect(after.enemies.single.state, EnemyState.alert);
    });

    test('a second shot inside the window folds into the first', () {
      final first = withWalkerAt(500).heard(shot(), playerAt: player);
      final second = first.heard(
        shot(when: now.add(const Duration(seconds: 4))),
        playerAt: player,
      );

      expect(second.open!.shots, 2);
    });

    test('and past the window it is a new sound', () {
      final first = withWalkerAt(500).heard(shot(), playerAt: player);
      final later = first.heard(
        shot(when: now.add(const Duration(seconds: 40))),
        playerAt: player,
      );

      expect(later.open!.shots, 1);
    });

    test('a sound that has stopped ringing is forgotten on the next tick', () {
      final heard = withWalkerAt(500).heard(
        shot(when: now.subtract(const Duration(minutes: 2))),
        playerAt: player,
      );

      expect(run(heard).open, isNull);
    });

    test('a knife brings nobody (§5.6.3)', () {
      final after = withWalkerAt(300).heard(
        NoiseEvent(at: player, radiusM: NoiseKind.melee.baseM, startedAt: now),
        playerAt: player,
      );

      expect(after.enemies.single.heardAt, isNull);
    });
  });

  group('hitting one (§5.1.5)', () {
    test('a wound lands on the one that was shot at', () {
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      final after = session.wound(target.id, 400);

      expect(
        after.enemies.firstWhere((enemy) => enemy.id == target.id).bloodLostMl,
        400,
      );
      expect(
        after.enemies.where((enemy) => enemy.bloodLostMl > 0),
        hasLength(1),
      );
    });

    test('wounds add up until one of them is enough', () {
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      var after = session;
      for (var i = 0; i < 5; i++) {
        after = after.wound(target.id, 400);
      }

      expect(
        after.enemies.firstWhere((enemy) => enemy.id == target.id).isDead,
        isTrue,
      );
    });

    test('being hit is the plainest way there is to find the shooter', () {
      // §6.1a's two ways into a chase are sight and sound, and being shot is
      // better evidence than either: it does not have to work out where the
      // person is, it has just been told. Without this a wounded Walker went
      // on searching the place the *noise* came from, which made the second
      // round cheaper than the first.
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      final after = session
          .wound(target.id, 100, from: player)
          .enemies
          .firstWhere((enemy) => enemy.id == target.id);

      expect(after.state, EnemyState.chase);
      expect(after.heardAt, player);
    });

    test('but nothing chases anything once it is down', () {
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      final after = session
          .wound(target.id, 99999, from: player)
          .enemies
          .firstWhere((enemy) => enemy.id == target.id);

      expect(after.isDead, isTrue);
      expect(after.state, isNot(EnemyState.chase));
    });

    test('a shot at nobody changes nothing', () {
      final session = run(const CombatSession(seed: 5));

      expect(
        session.wound('nobody', 400).enemies.length,
        session.enemies.length,
      );
    });
  });

  group('what the game stops thinking about', () {
    test('something the player walked away from is forgotten', () {
      // Otherwise a three-kilometre walk ends with every street the player
      // crossed still being simulated.
      final left = Enemy.spawn(
        id: 'w1',
        kind: EnemyKind.walker,
        at: north(300),
        home: north(300),
        random: Random(1),
      );

      final after = CombatSession(seed: 1, enemies: [left]).advance(
        playerAt: north(1400),
        elapsed: const Duration(seconds: 1),
        now: now,
      );

      expect(after.enemies.any((enemy) => enemy.id == 'w1'), isFalse);
    });

    test('and something still nearby is not', () {
      final close = Enemy.spawn(
        id: 'w1',
        kind: EnemyKind.walker,
        at: north(300),
        home: north(300),
        random: Random(1),
      );

      final after = CombatSession(seed: 1, enemies: [close]).advance(
        playerAt: player,
        elapsed: const Duration(seconds: 1),
        now: now,
      );

      expect(after.enemies.any((enemy) => enemy.id == 'w1'), isTrue);
    });

    test('a long walk does not leave a trail of them behind it', () {
      var session = const CombatSession(seed: 2);
      for (var step = 0; step < 12; step++) {
        session = session.advance(
          playerAt: north(step * 200),
          elapsed: const Duration(seconds: 30),
          now: now,
        );
      }

      // Whatever is out there is out there *here*, not spread over two
      // kilometres of streets nobody is on.
      for (final enemy in session.enemies) {
        expect(
          enemy.position.distanceTo(north(11 * 200)),
          lessThanOrEqualTo(kForgetEnemiesM),
        );
      }
    });

    test('the population does not grow without bound', () {
      var session = const CombatSession(seed: 2);
      for (var step = 0; step < 20; step++) {
        session = session.advance(
          playerAt: north(step * 150),
          elapsed: const Duration(seconds: 30),
          now: now,
        );
      }

      // §6.4's ambient trickle over a 600 m disc is a handful, not a horde.
      expect(session.enemies.length, lessThanOrEqualTo(12));
    });
  });
  group('a wound outlives the session that made it (§2.6, §11.1.2)', () {
    test('what would bleed out over the gap is reported', () {
      // ⚠️ Reported from a walk three times as "the skull does not always
      // appear". §11.1.2 throws the street away after a five-minute gap,
      // because what a Walker *did* is not knowable — but a wound is not a
      // walk. Something with a hole in it and a known rate has exactly one
      // future, and it was being deleted.
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      // Enough to kill it in about a minute, not instantly.
      final left = target.bloodMl * target.kind.deathAtLoss;
      final hit = session.wound(target.id, 0, bleeding: left / 60);

      expect(
        hit.bledOutOver(const Duration(seconds: 10)),
        isEmpty,
        reason: 'ten seconds is not enough to finish it',
      );

      final dying = hit.bledOutOver(const Duration(minutes: 5));

      expect(dying.map((e) => e.id), contains(target.id));
    });

    test('something merely wounded is not reported', () {
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      // A scratch: three millilitres a second against thousands.
      final hit = session.wound(target.id, 50, bleeding: 3);

      expect(hit.bledOutOver(const Duration(minutes: 5)), isEmpty);
    });

    test('and nothing that is not bleeding at all', () {
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      final hit = session.wound(target.id, 400);

      expect(hit.bledOutOver(const Duration(hours: 8)), isEmpty);
    });

    test('nor anything already down', () {
      final session = run(const CombatSession(seed: 5));
      final target = session.enemies.first;

      final killed = session.wound(target.id, 99999, bleeding: 50);

      expect(killed.bledOutOver(const Duration(minutes: 5)), isEmpty);
    });
  });
}
