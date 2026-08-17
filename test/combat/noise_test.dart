import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/noise.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// §5.6. What a sound reaches, and who walks towards it.
///
/// The system exists for one rule: enemies go to where the sound was, not to
/// the player. A shot that summoned everything straight onto the shooter would
/// leave nothing to decide; a shot that pulls six of them to a corner three
/// hundred metres away leaves room to move, watch and shoot again. That is the
/// tactical loop §0.1 calls the point of the game.
void main() {
  const here = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 15, 21);

  GeoPoint north(double metres) =>
      GeoPoint(here.latitude + metres / metresPerDegreeLat, here.longitude);

  Enemy walkerAt(double metres, {String id = 'e', EnemyState? state}) {
    final enemy = Enemy.spawn(
      id: id,
      kind: EnemyKind.walker,
      at: north(metres),
      home: north(metres),
      random: Random(1),
    );
    return state == null ? enemy : enemy.copyWith(state: state);
  }

  NoiseEvent shot({double radiusM = 700, GeoPoint? at, DateTime? when}) =>
      NoiseEvent(
        at: at ?? here,
        radiusM: radiusM,
        startedAt: when ?? now,
      );

  group('§5.6.1, how far it carries', () {
    test('the table, as written', () {
      expect(NoiseKind.shotgun.baseM, 900);
      expect(NoiseKind.rifle.baseM, 700);
      expect(NoiseKind.pistol.baseM, 450);
      expect(NoiseKind.melee.baseM, 25);
      expect(NoiseKind.walking.baseM, 15);
    });

    test('a suppressor is worth about three and a half times', () {
      // §5.6.3: the long-term prize, because it changes how the game is played
      // rather than adding a percentage to something.
      expect(
        NoiseKind.rifle.baseM / NoiseKind.suppressedRifle.baseM,
        closeTo(3.5, 0.01),
      );
      expect(
        NoiseKind.pistol.baseM / NoiseKind.suppressedPistol.baseM,
        closeTo(3.75, 0.01),
      );
    });

    test('night carries a shot further, not less far', () {
      // The one most games get backwards: less background noise and a
      // temperature inversion.
      expect(noiseRadiusM(700, night: true), closeTo(910, 0.5));
    });

    test('a built-up street in daylight swallows some of it', () {
      expect(noiseRadiusM(700, denseUrban: true), closeTo(490, 0.5));
    });

    test('open ground gives it back', () {
      expect(noiseRadiusM(700, openGround: true), closeTo(840, 0.5));
    });

    test('rain and wind take a quarter', () {
      expect(noiseRadiusM(700, badWeather: true), closeTo(525, 0.5));
    });

    test('and they compose', () {
      // A shot on open ground at night in the rain.
      expect(
        noiseRadiusM(700, night: true, openGround: true, badWeather: true),
        closeTo(700 * 1.3 * 1.2 * 0.75, 0.5),
      );
    });

    test('a knife is quieter than a walk is loud at night', () {
      expect(NoiseKind.melee.baseM, lessThan(noiseRadiusM(40, night: true)));
    });
  });

  group('§5.6.2, who answers', () {
    test('inside a third of the radius they place the player themselves', () {
      expect(reactionAt(100, 600), NoiseReaction.chase);
    });

    test('out to the full radius they walk to the sound', () {
      expect(reactionAt(400, 600), NoiseReaction.alert);
    });

    test('and past it nothing happens at all', () {
      expect(reactionAt(700, 600), NoiseReaction.none);
    });

    test('what answers walks to the sound, not to the player', () {
      // The rule the whole system rests on.
      final enemies = [walkerAt(500)];
      final after = respondToNoise(
        enemies,
        event: shot(),
        playerAt: north(900),
      );

      expect(after.single.heardAt!.latitude, closeTo(here.latitude, 1e-9));
      expect(after.single.state, EnemyState.alert);
    });

    test('but a sound made under their nose gives the player away', () {
      final after = respondToNoise(
        [walkerAt(100)],
        event: shot(),
        playerAt: north(120),
      );

      expect(after.single.state, EnemyState.chase);
      expect(after.single.heardAt!.latitude, closeTo(north(120).latitude, 1e-9));
    });

    test('a second shot pulls them to the second shot', () {
      // The economy of shooting, in one test. Every round pulls the street to
      // wherever the player is standing now, so a firearm is for a fight that
      // can be finished rather than for keeping one going.
      final first = respondToNoise(
        [walkerAt(500)],
        event: shot(),
        playerAt: north(900),
      );
      expect(first.single.state, EnemyState.alert);

      final elsewhere = north(400);
      final second = respondToNoise(
        first,
        event: NoiseEvent(
          at: elsewhere,
          radiusM: 600,
          startedAt: DateTime.utc(2026, 8, 16, 12, 1),
        ),
        playerAt: north(400),
      );

      expect(
        second.single.heardAt!.latitude,
        closeTo(elsewhere.latitude, 1e-9),
        reason: 'walking towards the last shot while the next one goes off '
            'somewhere else is how a thing behaves that cannot hear',
      );
    });

    test('but one already coming for you does not stop to listen', () {
      // §5.6.2: something that has the player does not change target, or a
      // group could be led away by dropping a tin.
      final chasing = [
        walkerAt(100).hears(north(120), chasing: true),
      ];

      final after = respondToNoise(
        chasing,
        event: NoiseEvent(
          at: north(900),
          radiusM: 600,
          startedAt: DateTime.utc(2026, 8, 16, 12, 1),
        ),
        playerAt: north(120),
      );

      expect(after.single.state, EnemyState.chase);
      expect(
        after.single.heardAt!.latitude,
        closeTo(north(120).latitude, 1e-9),
      );
    });

    test('never more than six of them (§5.6.2)', () {
      // One shot beside a level-ten hotspot would otherwise bring twelve and
      // turn every mistake into a sentence.
      final crowd = [
        for (var i = 0; i < 12; i++) walkerAt(200.0 + i * 10, id: 'e$i'),
      ];

      final after = respondToNoise(crowd, event: shot(), playerAt: north(900));
      final answering = after.where((e) => e.heardAt != null);

      expect(answering, hasLength(6));
    });

    test('and it is the nearest six', () {
      final crowd = [
        for (var i = 0; i < 12; i++) walkerAt(200.0 + i * 10, id: 'e$i'),
      ];

      final after = respondToNoise(crowd, event: shot(), playerAt: north(900));

      expect(after.take(6).every((e) => e.heardAt != null), isTrue);
      expect(after.skip(6).every((e) => e.heardAt == null), isTrue);
    });

    test('one already chasing does not turn aside', () {
      // §5.6.2: an enemy in pursuit keeps its target, or a group could be
      // escaped by throwing something.
      final chasing = walkerAt(200, state: EnemyState.chase);
      final after = respondToNoise(
        [chasing],
        event: shot(),
        playerAt: north(900),
      );

      expect(after.single.state, EnemyState.chase);
      expect(after.single.heardAt, isNull);
    });

    test('the dead hear nothing', () {
      final dead = walkerAt(200).hit(9000);
      final after = respondToNoise([dead], event: shot(), playerAt: north(900));

      expect(after.single.heardAt, isNull);
    });

    test('a knife brings nobody from three hundred metres', () {
      final after = respondToNoise(
        [walkerAt(300)],
        event: shot(radiusM: NoiseKind.melee.baseM),
        playerAt: here,
      );

      expect(after.single.heardAt, isNull);
      expect(after.single.state, EnemyState.idle);
    });
  });

  group('a burst is one sound (§5.6.2)', () {
    test('a second shot inside thirty seconds does not call a second crowd', () {
      final first = shot();
      final second = shot(when: now.add(const Duration(seconds: 5)));

      expect(accumulate(first, second).shots, 2);
    });

    test('it makes the one event a little louder', () {
      final folded = accumulate(shot(), shot(when: now.add(const Duration(seconds: 2))));

      expect(folded.radiusM, closeTo(700 * 1.15, 0.5));
    });

    test('and no louder again for a third and a fourth', () {
      var event = shot();
      for (var i = 1; i < 5; i++) {
        event = accumulate(
          event,
          shot(when: now.add(Duration(seconds: i * 2))),
        );
      }

      expect(event.shots, 5);
      expect(event.radiusM, closeTo(700 * 1.15, 0.5));
    });

    test('the point moves to where the last shot came from', () {
      final moved = accumulate(
        shot(),
        shot(at: north(200), when: now.add(const Duration(seconds: 3))),
      );

      expect(moved.at.latitude, closeTo(north(200).latitude, 1e-9));
    });

    test('past thirty seconds it is a new sound', () {
      final later = shot(when: now.add(const Duration(seconds: 31)));

      expect(accumulate(shot(), later).shots, 1);
      expect(accumulate(shot(), later).radiusM, 700);
    });
  });

  group('what they do when they get there', () {
    Enemy run(Enemy enemy, {required GeoPoint playerAt, required int seconds}) {
      var current = enemy;
      for (var i = 0; i < seconds; i++) {
        current = advanceEnemy(
          current,
          playerAt: playerAt,
          elapsed: const Duration(seconds: 1),
        );
      }
      return current;
    }

    test('they walk to the place, with the player nowhere near it', () {
      final heard = walkerAt(300).hears(here);
      final after = run(heard, playerAt: north(900), seconds: 60);

      expect(
        after.position.distanceTo(here),
        lessThan(heard.position.distanceTo(here)),
      );
    });

    test('they search it for about a minute, then give up (§5.6.2)', () {
      final standing = walkerAt(0).hears(here);

      final halfway = run(standing, playerAt: north(900), seconds: 50);
      expect(halfway.heardAt, isNotNull, reason: 'still turning it over');
      expect(halfway.state, EnemyState.alert);

      final after = run(standing, playerAt: north(900), seconds: 61);
      expect(after.heardAt, isNull);
      expect(after.state, isNot(EnemyState.alert));
    });

    test('and §6.1a does not cut the search short at forty-five', () {
      // The two rules contradict each other unless one gives: an enemy sent to
      // a sound is *supposed* to be somewhere the player is not. The leash
      // still holds, since that one is about distance from home.
      final searching = walkerAt(0).hears(here);
      final after = run(searching, playerAt: north(900), seconds: 46);

      expect(after.state, EnemyState.alert);
    });

    test('a player who walks into them while they search is seen', () {
      final searching = walkerAt(0).hears(here);
      final after = run(searching, playerAt: north(30), seconds: 2);

      expect(after.state, EnemyState.chase);
      expect(after.heardAt, isNull, reason: 'something in front beats a sound');
    });

    test('shooting, moving and watching is a real tactic', () {
      // The loop the whole system exists for: the sound is at the old
      // position, the player is somewhere else, and the enemy commits to the
      // sound rather than to them.
      final enemies = respondToNoise(
        [walkerAt(400)],
        event: shot(),
        playerAt: here,
      );

      final moved = north(-200);
      final after = run(enemies.single, playerAt: moved, seconds: 30);

      expect(
        after.position.distanceTo(here),
        lessThan(after.position.distanceTo(moved)),
      );
    });
  });
}
