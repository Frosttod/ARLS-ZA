import 'package:arls_za/combat/combat_session.dart';
import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/enemy_spawner.dart' show kActiveRadiusM;
import 'package:arls_za/game/controllers/combat_controller.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

/// WALKA MA WŁAŚCICIELA (§5.5, §5.5.6, §6.1a).
///
/// ⚠️ **Not persisted, and that is a rule rather than an omission.** §6.4 makes
/// the Walkers afresh every time the game runs — a Walker is not a place — so
/// writing them down would only mean loading yesterday's fight onto a street
/// the player has already left.
void main() {
  const here = GeoPoint(52.4064, 16.9252);

  Enemy walker(
    String id,
    double metresAway, {
    EnemyState? state,
    bool dead = false,
  }) {
    final at = here.offsetBy(metres: metresAway, bearingDeg: 0);

    return Enemy(
      id: id,
      kind: EnemyKind.walker,
      position: at,
      home: at,
      bloodMl: 5000,
      walkKmh: 4,
      runKmh: 9,
      state: state ?? EnemyState.idle,
      // §5.5.1: dead is a share of blood lost, not a flag.
      bloodLostMl: dead ? 5000 : 0,
    );
  }

  late CombatController fight;

  setUp(() => fight = CombatController());
  tearDown(() => fight.dispose());

  group('§5.5.6: what the map draws, without flickering', () {
    test('something inside the radius is drawn', () {
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 100)]);

      expect(fight.visible(here).map((e) => e.id), ['a']);
    });

    test('and something well outside it is not', () {
      fight.session = CombatSession(
        seed: 1,
        enemies: [walker('a', kActiveRadiusM + 200)],
      );

      expect(fight.visible(here), isEmpty);
    });

    test('one already drawn stays drawn a little further out', () {
      // ⚠️ The whole reason this method exists. Standing exactly on the edge,
      // an enemy would otherwise appear and vanish with every step — which on
      // a phone reads as the game being broken, not as a Walker being far off.
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 290)]);
      expect(fight.visible(here), hasLength(1));

      // A step back. Past the radius, inside the wider ring it earned.
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 330)]);
      expect(fight.visible(here), hasLength(1));

      // Properly gone now.
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 400)]);
      expect(fight.visible(here), isEmpty);

      // And having gone, it has to come all the way back to reappear.
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 330)]);
      expect(fight.visible(here), isEmpty);
    });

    test('the dead are not drawn', () {
      fight.session = CombatSession(
        seed: 1,
        enemies: [walker('a', 50, dead: true)],
      );

      expect(fight.visible(here), isEmpty);
    });

    test('nowhere at all draws nothing rather than throwing', () {
      // §2.1a.4 switches the receiver off under a roof.
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 50)]);

      expect(fight.visible(null), isEmpty);
    });
  });

  group('§5.5: how bad it is', () {
    test('a quiet street reads as nothing at all', () {
      // ⚠️ Something idle is scenery, not a threat. A reading that counted it
      // would be crying wolf on every street with anything on it.
      fight.session = CombatSession(seed: 1, enemies: [walker('a', 50)]);

      expect(fight.threatAt(here), isNull);
    });

    test('and one walking home is still not a threat', () {
      fight.session = CombatSession(
        seed: 1,
        enemies: [walker('a', 50, state: EnemyState.returning)],
      );

      expect(fight.threatAt(here), isNull);
    });

    test('something hunting is', () {
      fight.session = CombatSession(
        seed: 1,
        enemies: [walker('a', 40, state: EnemyState.chase)],
      );

      final reading = fight.threatAt(here)!;

      expect(reading.count, 1);
      expect(reading.nearestM, closeTo(40, 1));
    });

    test('the reading is of the nearest, and counts them all', () {
      fight.session = CombatSession(
        seed: 1,
        enemies: [
          walker('far', 120, state: EnemyState.chase),
          walker('near', 30, state: EnemyState.alert),
          walker('quiet', 20),
        ],
      );

      final reading = fight.threatAt(here)!;

      expect(reading.count, 2, reason: 'the idle one is not part of it');
      expect(reading.nearestM, closeTo(30, 1));
    });

    test('nowhere at all reads as nothing', () {
      fight.session = CombatSession(
        seed: 1,
        enemies: [walker('a', 40, state: EnemyState.chase)],
      );

      expect(fight.threatAt(null), isNull);
    });
  });

  group('§12: the last two minutes, in words', () {
    test('what was said comes back', () {
      // ⚠️ Kept because of one sentence after a walk: "I do not know how I
      // died". Every line of it was on screen at the time and gone by the time
      // it mattered.
      fight
        ..say('Trafienie w tors')
        ..say('Pudło');

      expect(fight.log, ['Trafienie w tors', 'Pudło']);
    });

    test('and it does not grow without end', () {
      for (var i = 0; i < 100; i++) {
        fight.say('line $i');
      }

      expect(fight.log, hasLength(30));
      expect(
        fight.log.last,
        'line 99',
        reason: 'how it ended, not how it began',
      );
    });

    test('the log cannot be edited from outside', () {
      fight.say('Trafienie');

      expect(() => fight.log.add('nie'), throwsUnsupportedError);
    });
  });

  test('a fresh street forgets who was being drawn', () {
    fight.session = CombatSession(seed: 1, enemies: [walker('a', 290)]);
    expect(fight.visible(here), hasLength(1));

    fight.reseed(7);
    fight.session = CombatSession(seed: 7, enemies: [walker('a', 330)]);

    expect(
      fight.visible(here),
      isEmpty,
      reason: 'the wider ring was earned by the fight that is over',
    );
  });
}
