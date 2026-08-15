import 'package:arls_za/combat/ballistics.dart';
import 'package:test/test.dart';

/// §5.1, §5.1.5. The calibration table, held to.
///
/// §5.1.2 is not illustration: those seven rows are the balance of the whole
/// game. They say a calm still novice hits a torso at 150 m half the time and
/// a running one hits nothing at all, and every judgement about ammunition
/// economy in §5.1.5 follows from them. An edit to any constant here has to be
/// a deliberate act with the table redone, not a quiet tweak.
///
/// ⚠️ MOA is the diameter of the group. Reading it as a radius moves every
/// number below by about a factor of three.
void main() {
  // §5.1.2's own rifle, and the body the sim uses in its worked examples.
  const weaponMoa = 3.0;
  const rest = 70.0;
  const maxHr = 187.0;

  ShotError budget({
    double skill = 0,
    double heartRate = rest,
    double speedKmh = 0,
    double targetKmh = 0,
  }) => ShotError(
    weapon: weaponMoa,
    skill: skillMoa(skill),
    heart: heartMoa(heartRate, rest: rest, max: maxHr),
    movement: movementMoa(speedKmh),
    target: targetMoa(targetKmh),
  );

  int percent(double moa, double distanceM) =>
      (hitChance(moa: moa, distanceM: distanceM) * 100).round();

  group('§5.1.2, row by row', () {
    test('a novice standing still and calm, against a still target', () {
      final moa = budget().total;
      expect(moa, closeTo(25, 0.5));

      expect(percent(moa, 30), 100);
      expect(percent(moa, 80), closeTo(89, 1));
      expect(percent(moa, 150), closeTo(49, 1));
      expect(percent(moa, 250), closeTo(22, 1));
    });

    test('the same novice at 160 bpm, target sprinting', () {
      // §6.1's Walker at sixteen kilometres an hour.
      final moa = budget(heartRate: 160, targetKmh: 16).total;
      expect(moa, closeTo(45, 1));

      expect(percent(moa, 80), closeTo(53, 2));
      expect(percent(moa, 150), closeTo(20, 2));
    });

    test('walking at five kilometres an hour ruins it', () {
      final moa = budget(heartRate: 160, speedKmh: 5, targetKmh: 16).total;
      expect(moa, closeTo(71, 1));

      expect(percent(moa, 80), closeTo(26, 2));
      expect(percent(moa, 150), closeTo(8, 2));
    });

    test('running at twelve, there is no shot at all', () {
      final moa = budget(heartRate: 175, speedKmh: 12, targetKmh: 16).total;
      expect(moa, closeTo(167, 2));

      expect(percent(moa, 30), closeTo(32, 2));
      expect(percent(moa, 80), closeTo(5, 1));
    });

    test('mastery standing at 100 bpm', () {
      final moa = budget(skill: 1, heartRate: 100, targetKmh: 16).total;
      expect(moa, closeTo(12, 1));

      expect(percent(moa, 150), closeTo(94, 2));
      expect(percent(moa, 250), closeTo(68, 3));
    });

    test('mastery at 160 bpm is worse than a calm novice', () {
      // The conclusion §5.1.1 states outright: the body beats the training.
      final skilled = budget(skill: 1, heartRate: 160, targetKmh: 16).total;
      final novice = budget().total;

      expect(skilled, closeTo(37, 1));
      expect(skilled, greaterThan(novice));
    });

    test('and running, mastery is worth nothing whatever', () {
      final skilled = budget(skill: 1, heartRate: 175, speedKmh: 12).total;
      final novice = budget(heartRate: 175, speedKmh: 12).total;

      expect(skilled, closeTo(165, 3));
      expect((novice - skilled) / novice, lessThan(0.05));
    });
  });

  group('the components (§5.1.1)', () {
    test('skill runs 25 to 4 and no further', () {
      expect(skillMoa(0), 25);
      expect(skillMoa(1), 4);
      expect(skillMoa(0.5), closeTo(14.5, 0.01));
      expect(skillMoa(2), 4, reason: 'nobody is better than practised');
    });

    test('the pulse does nothing until it matters, then everything', () {
      // Squared, so 60% of the way up costs a third of what 100% costs.
      final low = heartMoa(rest + 0.6 * (maxHr - rest), rest: rest, max: maxHr);
      final high = heartMoa(maxHr, rest: rest, max: maxHr);

      expect(low, closeTo(21.6, 0.1));
      expect(high, closeTo(60, 0.1));
      expect(heartMoa(rest, rest: rest, max: maxHr), 0);
    });

    test('a slower resting heart is a steadier shot at the same bpm', () {
      // §2.4: the user's own bradycardia. A player whose heart sits at 58 is
      // further from their ceiling at 120 than one whose heart sits at 72.
      final slow = heartMoa(120, rest: 58, max: maxHr);
      final average = heartMoa(120, rest: 72, max: maxHr);

      expect(slow, greaterThan(average));
    });

    test('walking is 55 MOA and running is 165', () {
      expect(movementMoa(5), closeTo(55, 1));
      expect(movementMoa(12), closeTo(157, 2));
      expect(movementMoa(0), 0);
    });

    test('a target running at you barely moves across your sights', () {
      expect(targetMoa(16), closeTo(9.6, 0.01));
      expect(targetMoa(16), lessThan(movementMoa(5) / 5));
    });

    test('errors compose as the root of the sum of squares', () {
      // Five sources of one MOA are not five MOA: they are 2.2. Summing them
      // instead would make a walking novice unable to hit a wall.
      const error = ShotError(
        weapon: 3,
        skill: 4,
        heart: 0,
        movement: 0,
        target: 0,
      );

      expect(error.total, closeTo(5, 0.001));
    });
  });

  group('what the HUD names (§5.1.4)', () {
    test('the largest source, so a miss can be understood', () {
      final walking = budget(heartRate: 160, speedKmh: 5, targetKmh: 16);

      expect(walking.dominant, ErrorSource.movement);
    });

    test('standing still at a high pulse, it is the pulse', () {
      expect(budget(heartRate: 175).dominant, ErrorSource.heart);
    });

    test('and standing still and calm, it is the shooter being a novice', () {
      expect(budget().dominant, ErrorSource.skill);
    });

    test('a practised shooter, calm and still, is held back by the rifle', () {
      final error = ShotError(
        weapon: 8,
        skill: skillMoa(1),
        heart: 0,
        movement: 0,
        target: 0,
      );

      expect(error.dominant, ErrorSource.weapon);
    });
  });

  group('the shot itself', () {
    test('MOA is a diameter, and reading it as a radius doubles the group', () {
      // §5.1's bold warning, as arithmetic: 1 MOA is 2.9 cm at 100 m.
      expect(spreadDiameterM(1, 100), closeTo(0.0291, 0.0002));
    });

    test('a silhouette is easier to hit than a torso', () {
      expect(
        hitChance(moa: 45, distanceM: 150, target: TargetSize.silhouette),
        greaterThan(hitChance(moa: 45, distanceM: 150)),
      );
    });

    test('twice the distance is much worse than half the chance', () {
      final near = hitChance(moa: 45, distanceM: 80);
      final far = hitChance(moa: 45, distanceM: 160);

      expect(far, lessThan(near / 2));
    });

    test('a shot with no spread at all cannot miss', () {
      expect(hitChance(moa: 0, distanceM: 200), 1);
    });
  });

  group('what a hit does (§5.1.5)', () {
    // §5.1.5's own table, calibre by calibre.
    void expectMl(double energy, double factor, double expected) => expect(
      bloodLossMl(energyJ: energy, woundFactor: factor),
      closeTo(expected, expected * 0.03),
      reason: '$energy J at $factor',
    );

    test('the table of calibres comes back out', () {
      expectMl(160, 0.70, 75);
      expectMl(500, 1.00, 212);
      expectMl(1350, 1.25, 482);
      expectMl(2000, 1.20, 585);
      expectMl(2400, 1.25, 680);
      expectMl(3000, 1.50, 933);
    });

    test('a Walker takes about three rounds of 5.45 and seven of 9 mm', () {
      // §5.1.5's weapon hierarchy, which is the reason for the exponent.
      const walker = 1530.0;
      final carbine = walker / bloodLossMl(energyJ: 1350, woundFactor: 1.25);
      final pistol = walker / bloodLossMl(energyJ: 500, woundFactor: 1);

      expect(carbine, closeTo(3.2, 0.15));
      expect(pistol, closeTo(7.2, 0.3));
    });

    test('the relation is under a root, so small calibres are not written off',
        () {
      // Twenty times the energy is about six times the wound, not twenty.
      final small = bloodLossMl(energyJ: 160, woundFactor: 1);
      final large = bloodLossMl(energyJ: 3200, woundFactor: 1);

      expect(large / small, closeTo(6.03, 0.1));
    });

    test('a head is four times a torso (§2.6)', () {
      expect(
        bloodLossMl(energyJ: 1350, woundFactor: 1.25, locationMultiplier: 4),
        closeTo(4 * bloodLossMl(energyJ: 1350, woundFactor: 1.25), 0.01),
      );
    });

    test('armour takes its share off the top', () {
      expect(
        bloodLossMl(energyJ: 500, woundFactor: 1, protection: 0.5),
        closeTo(bloodLossMl(energyJ: 500, woundFactor: 1) / 2, 0.01),
      );
    });

    test('and armour that stops it entirely stops it entirely', () {
      expect(
        bloodLossMl(energyJ: 3500, woundFactor: 1.35, protection: 1),
        0,
      );
    });
  });
}
