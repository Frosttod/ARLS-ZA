import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
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
    test('it mills about its own patch while nobody is in sight (§6.1a)', () {
      // Idle is random movement, not standing to attention — and it stays
      // near where it belongs rather than wandering off across the city.
      var quiet = spawn(EnemyKind.walker);
      for (var i = 0; i < 120; i++) {
        quiet = advanceEnemy(
          quiet,
          playerAt: north(400),
          elapsed: const Duration(seconds: 1),
        );
      }

      expect(quiet.state, EnemyState.idle);
      expect(quiet.position.distanceTo(home), lessThan(kWanderRadiusM * 2));
      expect(
        quiet.position.distanceTo(home),
        greaterThan(1),
        reason: 'it moved at all',
      );
    });

    test('and it does not jink about (§6.1a)', () {
      // A marker that changes direction every second is unreadable, and reads
      // as a bug rather than as a body.
      var quiet = spawn(EnemyKind.walker);
      var previous = 0.0;
      var worst = 0.0;

      for (var i = 0; i < 60; i++) {
        quiet = advanceEnemy(
          quiet,
          playerAt: north(900),
          elapsed: const Duration(seconds: 1),
        );
        final heading = quiet.headingDeg ?? previous;
        if (i > 1) {
          var turn = (heading - previous).abs();
          if (turn > 180) turn = 360 - turn;
          if (turn > worst) worst = turn;
        }
        previous = heading;
      }

      expect(worst, lessThan(90));
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

  group('which way it is facing (§3.6)', () {
    // ⚠️ Where it is going, never what it can see. §6.2 gives an enemy a
    // detection radius and nothing directional, so a cone read as vision would
    // be a lie the player would plan around.
    GeoPoint east(double metres) => GeoPoint(
      home.latitude,
      home.longitude + metres / metresPerDegreeLon(home.latitude),
    );

    test('something wandering faces where it is wandering', () {
      final quiet = advanceEnemy(
        spawn(EnemyKind.walker),
        playerAt: north(900),
        elapsed: const Duration(seconds: 5),
      );

      expect(quiet.headingDeg, isNotNull);
    });

    test('walking north reads as north', () {
      final chasing = run(
        spawn(EnemyKind.walker),
        playerAt: north(40),
        total: const Duration(seconds: 3),
      );

      expect(chasing.headingDeg, closeTo(0, 2));
    });

    test('and walking east reads as ninety degrees', () {
      final chasing = run(
        spawn(EnemyKind.walker),
        playerAt: east(40),
        total: const Duration(seconds: 3),
      );

      expect(chasing.headingDeg, closeTo(90, 2));
    });

    test('walking away is a hundred and eighty', () {
      // Sent home after losing contact: it turns its back.
      final far = spawn(EnemyKind.walker, at: 450);
      final going = run(
        far,
        playerAt: north(900),
        total: const Duration(seconds: 20),
      );

      expect(going.state, EnemyState.returning);
      expect(going.headingDeg, closeTo(180, 2));
    });

    test('one that loses the player turns away gradually, not on the spot', () {
      // §6.1a: it goes back to milling about, and a marker that spins where it
      // stands reads as a bug rather than as a body.
      final chasing = run(
        spawn(EnemyKind.walker),
        playerAt: north(40),
        total: const Duration(seconds: 3),
      );
      final stopped = advanceEnemy(
        chasing,
        playerAt: north(900),
        elapsed: const Duration(seconds: 1),
      );

      var turn = ((stopped.headingDeg ?? 0) - (chasing.headingDeg ?? 0)).abs();
      if (turn > 180) turn = 360 - turn;

      expect(turn, lessThanOrEqualTo(kWanderTurnPerSecond + 0.01));
    });
  });

  group('what it can notice, where it is standing (§5.6.1)', () {
    test('a street of blocks costs it a third of its sight', () {
      final field = spawn(EnemyKind.walker);
      final town = Enemy.spawn(
        id: 'w2',
        kind: EnemyKind.walker,
        at: home,
        home: home,
        random: Random(1),
        sightFactor: 0.7,
      );

      expect(field.sightM, 80);
      expect(town.sightM, closeTo(56, 0.01));
    });

    test('and it charges from inside sixty per cent of that', () {
      final town = Enemy.spawn(
        id: 'w2',
        kind: EnemyKind.walker,
        at: home,
        home: home,
        random: Random(1),
        sightFactor: 0.7,
      );

      expect(town.chaseM, closeTo(33.6, 0.01));
    });

    test('a player at seventy metres is seen in a field and not in a town', () {
      // The same distance, the same Walker, two different streets.
      final field = advanceEnemy(
        spawn(EnemyKind.walker),
        playerAt: north(70),
        elapsed: const Duration(seconds: 1),
      );
      final town = advanceEnemy(
        Enemy.spawn(
          id: 'w2',
          kind: EnemyKind.walker,
          at: home,
          home: home,
          random: Random(1),
          sightFactor: 0.7,
        ),
        playerAt: north(70),
        elapsed: const Duration(seconds: 1),
      );

      expect(field.state, EnemyState.alert);
      expect(town.state, EnemyState.idle);
    });
  });

  group('what it will not walk through (§6.3)', () {
    /// A lake between the enemy and the player.
    MapFeature lake() => MapFeature(
      tags: const {'natural': 'water'},
      shape: FeatureShape.area,
      geometry: [
        GeoPoint(north(20).latitude, home.longitude - 0.002),
        GeoPoint(north(20).latitude, home.longitude + 0.002),
        GeoPoint(north(45).latitude, home.longitude + 0.002),
        GeoPoint(north(45).latitude, home.longitude - 0.002),
      ],
    );

    test('it does not swim a lake to reach somebody', () {
      // A thing that swims a lake is a thing nobody believes in, and the cost
      // of not believing in it is the whole atmosphere.
      var enemy = spawn(EnemyKind.walker);
      final ground = SpawnFilter([lake()]);

      // Long enough to walk into it: a Walker covers about a metre a second.
      for (var i = 0; i < 60; i++) {
        enemy = advanceEnemy(
          enemy,
          playerAt: north(70),
          elapsed: const Duration(seconds: 1),
          ground: ground,
        );
      }

      expect(ground.refuse(enemy.position), isNull);
    });

    test('it goes round rather than stopping dead at the edge', () {
      var enemy = spawn(EnemyKind.walker);
      final ground = SpawnFilter([lake()]);

      for (var i = 0; i < 60; i++) {
        enemy = advanceEnemy(
          enemy,
          playerAt: north(70),
          elapsed: const Duration(seconds: 1),
          ground: ground,
        );
      }

      // It has moved off the line it started on, which is what going round
      // looks like from above.
      expect(
        (enemy.position.longitude - home.longitude).abs(),
        greaterThan(0.0001),
      );
    });

    test('with nothing in the way it still walks straight at them', () {
      final after = run(
        spawn(EnemyKind.walker),
        playerAt: north(70),
        total: const Duration(seconds: 5),
      );

      expect(
        (after.position.longitude - home.longitude).abs(),
        lessThan(1e-6),
      );
    });
  });

  group('what can be told about one (§5.5.1, §5.5.2)', () {
    test('untouched reads as healthy', () {
      expect(spawn(EnemyKind.walker).condition, EnemyCondition.healthy);
    });

    test('a third of the way to dead reads as wounded', () {
      final walker = spawn(EnemyKind.walker);
      final hurt = walker.hit(walker.bloodMl * walker.kind.deathAtLoss * 0.4);

      expect(hurt.condition, EnemyCondition.wounded);
    });

    test('and most of the way reads as critical', () {
      final walker = spawn(EnemyKind.walker);
      final nearly = walker.hit(walker.bloodMl * walker.kind.deathAtLoss * 0.8);

      expect(nearly.condition, EnemyCondition.critical);
    });

    test('it is measured against what kills it, not against all its blood', () {
      // A Walker dies at 45% and a Brute at 50%, so half a Brute's blood is
      // not half a Brute.
      final brute = spawn(EnemyKind.brute);
      final walker = spawn(EnemyKind.walker);

      final bruteWound = brute.hit(brute.bloodMl * 0.2);
      final walkerWound = walker.hit(walker.bloodMl * 0.2);

      expect(bruteWound.condition, walkerWound.condition);
    });

    test('a full stopwatch reads as a full bar (§5.5.2)', () {
      expect(spawn(EnemyKind.walker).sprintLeftFraction, 1);
    });

    test('and a burned one as empty', () {
      final spent = spawn(
        EnemyKind.walker,
      ).copyWith(sprintLeft: Duration.zero);

      expect(spent.sprintLeftFraction, 0);
    });
  });
}
