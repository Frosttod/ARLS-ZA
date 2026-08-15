import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// §6.1, §6.1a, §6.2. What comes towards the player, and what stops it.
///
/// The sprint budget is the whole design: a player's speed is their real
/// speed, so without a stopwatch on the enemies, running away — the first
/// tactic in any survival game — would not exist. These tests are about that
/// stopwatch holding, about the two rules that stop a player towing a train of
/// enemies across a city, and about the one enemy §6.1 deliberately makes
/// impossible to escape.
void main() {
  const home = GeoPoint(52.4084, 16.9342);

  GeoPoint north(double metres) =>
      GeoPoint(home.latitude + metres / metresPerDegreeLat, home.longitude);

  Enemy spawn(EnemyKind kind, {double at = 0, int seed = 1}) => Enemy.spawn(
    id: 'e1',
    kind: kind,
    at: north(at),
    home: home,
    random: Random(seed),
  );

  /// Runs the machine a second at a time, which is what the game does.
  Enemy run(
    Enemy enemy, {
    required GeoPoint playerAt,
    required Duration total,
    bool heardShot = false,
  }) {
    var current = enemy;
    for (var i = 0; i < total.inSeconds; i++) {
      current = advanceEnemy(
        current,
        playerAt: playerAt,
        elapsed: const Duration(seconds: 1),
        heardShot: heardShot && i == 0,
      );
    }
    return current;
  }

  group('the table of §6.2', () {
    test('a Walker comes in twos to fours, the others alone', () {
      expect(EnemyKind.walker.packSize, (2, 4));
      expect(EnemyKind.leaper.packSize, (1, 1));
      expect(EnemyKind.brute.packSize, (1, 1));
    });

    test('damage is the base row times the multiplier, or it is nothing', () {
      expect(EnemyKind.walker.damageMl, closeTo(189, 0.5));
      expect(EnemyKind.leaper.damageMl, closeTo(108, 0.5));
      expect(EnemyKind.brute.damageMl, closeTo(480, 0.5));
    });

    test('each notices at its own distance', () {
      expect(EnemyKind.leaper.detectionM, 120);
      expect(EnemyKind.walker.detectionM, 80);
      expect(EnemyKind.brute.detectionM, 60);
    });

    test('and charges inside sixty per cent of it', () {
      expect(EnemyKind.walker.chaseM, closeTo(48, 0.01));
    });

    test('two of a kind are not the same one', () {
      // §6.2's ranges are rolled at spawn: one is a little faster, one bleeds
      // a little longer.
      final a = spawn(EnemyKind.walker, seed: 1);
      final b = spawn(EnemyKind.walker, seed: 2);

      expect(a.runKmh, isNot(closeTo(b.runKmh, 0.001)));
      expect(a.bloodMl, isNot(closeTo(b.bloodMl, 0.001)));
    });

    test('everything rolled stays inside the table', () {
      for (var seed = 0; seed < 50; seed++) {
        final walker = spawn(EnemyKind.walker, seed: seed);

        expect(walker.runKmh, inInclusiveRange(15, 18));
        expect(walker.walkKmh, inInclusiveRange(3, 4));
        expect(walker.bloodMl, inInclusiveRange(3200, 3600));
      }
    });
  });

  group('the sprint budget (§6.1)', () {
    test('a Walker sprints for ninety seconds and no longer', () {
      final chasing = run(
        spawn(EnemyKind.walker),
        playerAt: north(40),
        total: const Duration(seconds: 89),
      );
      expect(chasing.state, EnemyState.chase);

      final spent = advanceEnemy(
        chasing,
        playerAt: north(40),
        elapsed: const Duration(seconds: 2),
      );
      expect(spent.state, EnemyState.spent);
    });

    test('exhaustion is a slower approach, never a stop (§6.1a)', () {
      // The rule that makes shooting one enemy cost ground against every
      // other one: nothing in a chase ever stands still.
      final spent = spawn(
        EnemyKind.walker,
        at: 30,
      ).copyWith(state: EnemyState.spent, sprintLeft: Duration.zero);

      final before = spent.position.distanceTo(north(60));
      final after = advanceEnemy(
        spent,
        playerAt: north(60),
        elapsed: const Duration(seconds: 5),
      );

      expect(after.position.distanceTo(north(60)), lessThan(before));
      expect(after.speedKmh, closeTo(spent.runKmh * 0.4, 0.01));
    });

    test('the budget comes back while it is not sprinting', () {
      final tired = spawn(
        EnemyKind.walker,
      ).copyWith(state: EnemyState.spent, sprintLeft: Duration.zero);

      // Forty-five seconds of walking is the whole ninety back (§6.1).
      final rested = run(
        tired,
        playerAt: north(5000),
        total: const Duration(seconds: 45),
      );

      expect(rested.budget, EnemyKind.walker.sprintBudget);
    });

    test('and never past full', () {
      final rested = run(
        spawn(EnemyKind.walker),
        playerAt: north(5000),
        total: const Duration(minutes: 5),
      );

      expect(rested.budget, EnemyKind.walker.sprintBudget);
    });

    test('a human outlasts a Walker, which is the point of the whole rule', () {
      // Ninety seconds at about sixteen km/h is four hundred metres. A player
      // who keeps moving is not caught by it.
      final walker = spawn(EnemyKind.walker, at: 40);
      final covered = walker.runKmh * 90 / 3.6;

      expect(covered, lessThan(kLeashM + 60));
    });

    test('but nothing outruns a Leaper (§6.1)', () {
      // Twenty-five seconds at thirty km/h is about two hundred metres, and it
      // sees the player at a hundred and twenty. Detection means contact.
      final leaper = spawn(EnemyKind.leaper);
      final sprint = leaper.runKmh * 25 / 3.6;

      expect(sprint, greaterThan(EnemyKind.leaper.detectionM));
    });
  });

  group('the states (§6.1a)', () {
    test('nothing happens while the player is out of sight', () {
      final quiet = advanceEnemy(
        spawn(EnemyKind.walker),
        playerAt: north(400),
        elapsed: const Duration(seconds: 10),
      );

      expect(quiet.state, EnemyState.idle);
      expect(quiet.position.latitude, home.latitude);
    });

    test('inside its detection it walks, and pays nothing for it', () {
      // §6.1a: the alert state spends no budget, which is what makes a slow
      // approach survivable — and §5.1.3 what makes it the only good one.
      final alert = run(
        spawn(EnemyKind.walker, at: 10),
        playerAt: north(70),
        total: const Duration(seconds: 3),
      );

      expect(alert.state, EnemyState.alert);
      expect(alert.budget, EnemyKind.walker.sprintBudget);
    });

    test('inside sixty per cent of it, it runs', () {
      final chase = advanceEnemy(
        spawn(EnemyKind.walker),
        playerAt: north(40),
        elapsed: const Duration(seconds: 1),
      );

      expect(chase.state, EnemyState.chase);
      expect(chase.budget, lessThan(EnemyKind.walker.sprintBudget));
    });

    test('a shot starts a chase at any distance (§5.6)', () {
      // What makes noise the cost of shooting rather than a flavour text.
      final chase = advanceEnemy(
        spawn(EnemyKind.walker),
        playerAt: north(300),
        elapsed: const Duration(seconds: 1),
        heardShot: true,
      );

      expect(chase.state, EnemyState.chase);
    });

    test('it closes the distance while chasing', () {
      final start = spawn(EnemyKind.walker, at: 0);
      final after = run(
        start,
        playerAt: north(40),
        total: const Duration(seconds: 5),
      );

      expect(
        after.position.distanceTo(north(40)),
        lessThan(start.position.distanceTo(north(40))),
      );
    });
  });

  group('the two rules that prevent a train of enemies', () {
    test('past four hundred metres from home it turns round (§6.1a)', () {
      final far = spawn(EnemyKind.walker, at: 450);

      final turned = advanceEnemy(
        far,
        playerAt: north(460),
        elapsed: const Duration(seconds: 1),
      );

      expect(turned.state, EnemyState.returning);
    });

    test('and walks home rather than after the player', () {
      final far = spawn(EnemyKind.walker, at: 450);
      final walking = run(
        far,
        playerAt: north(600),
        total: const Duration(seconds: 20),
      );

      expect(
        walking.position.distanceTo(home),
        lessThan(far.position.distanceTo(home)),
      );
    });

    test('forty-five seconds without the player near ends it (§6.1a)', () {
      // Contact is the player coming near, not the enemy trying: a chase the
      // player has walked away from is over.
      final chasing = spawn(
        EnemyKind.walker,
        at: 100,
      ).copyWith(state: EnemyState.chase);

      final given = run(
        chasing,
        playerAt: north(320),
        total: const Duration(seconds: 46),
      );

      expect(given.state, EnemyState.returning);
    });

    test('but coming back within a hundred and fifty metres resets it', () {
      final chasing = spawn(EnemyKind.walker, at: 100);

      final kept = run(
        chasing,
        playerAt: north(200),
        total: const Duration(seconds: 30),
      );

      expect(kept.sinceContact, Duration.zero);
      expect(kept.state, isNot(EnemyState.returning));
    });

    test('home again, it goes back to wandering', () {
      final returning = spawn(
        EnemyKind.walker,
        at: 3,
      ).copyWith(state: EnemyState.returning, sinceContact: kContactLost);

      final done = run(
        returning,
        playerAt: north(900),
        total: const Duration(seconds: 10),
      );

      expect(done.state, EnemyState.idle);
    });
  });

  group('killing one (§6.2)', () {
    test('a Walker dies at 45% of its blood, not at all of it', () {
      final walker = spawn(EnemyKind.walker);

      expect(walker.hit(walker.bloodMl * 0.44).isDead, isFalse);
      expect(walker.hit(walker.bloodMl * 0.46).isDead, isTrue);
    });

    test('a Brute takes half of its own, which is far more blood', () {
      final brute = spawn(EnemyKind.brute);
      final walker = spawn(EnemyKind.walker);

      expect(
        brute.bloodMl * EnemyKind.brute.deathAtLoss,
        greaterThan(2 * walker.bloodMl * EnemyKind.walker.deathAtLoss),
      );
    });

    test('the dead stop moving', () {
      final dead = spawn(EnemyKind.walker, at: 20).hit(9000);
      final after = advanceEnemy(
        dead,
        playerAt: north(30),
        elapsed: const Duration(seconds: 5),
      );

      expect(after.position.latitude, dead.position.latitude);
    });

    test('wounds add up across shots', () {
      final walker = spawn(EnemyKind.walker);
      final twice = walker.hit(200).hit(300);

      expect(twice.bloodLostMl, 500);
    });
  });
}
