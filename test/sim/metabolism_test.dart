import 'package:arls_za/sim/metabolism.dart';
import 'package:test/test.dart';

/// The MET table and heart-rate model of §2.2 and §2.4. Every number here is
/// quoted from the design document.
void main() {
  group('MET bands (§2.2)', () {
    test('map speeds to the published values', () {
      expect(metForSpeed(0), 1.0);
      expect(metForSpeed(2.0), 2.0);
      expect(metForSpeed(4.0), 3.5);
      expect(metForSpeed(5.5), 5.0);
      expect(metForSpeed(7.0), 8.3);
      expect(metForSpeed(9.0), 9.8);
      expect(metForSpeed(10.5), 11.0);
      expect(metForSpeed(15.0), 14.0);
    });

    test('any movement at all is at least a slow walk', () {
      expect(bandForSpeed(0), ActivityBand.standing);
      expect(bandForSpeed(0.1), ActivityBand.slowWalk);
    });

    test('band boundaries fall on the lower band', () {
      expect(metForSpeed(3.2), 2.0);
      expect(metForSpeed(3.21), 3.5);
      expect(metForSpeed(11.3), 11.0);
      expect(metForSpeed(11.31), 14.0);
    });

    test('MET never decreases as speed rises', () {
      var previous = 0.0;
      for (var kmh = 0.0; kmh <= 20; kmh += 0.1) {
        final met = metForSpeed(kmh);
        expect(met, greaterThanOrEqualTo(previous));
        previous = met;
      }
    });
  });

  group('load (§2.2)', () {
    test('20 kg on an 80 kg character costs 20 per cent more', () {
      final loaded = effectiveMet(met: 3.5, loadKg: 20, bodyMassKg: 80);

      expect(loaded / 3.5, closeTo(1.2, 1e-9));
    });

    test('carrying nothing changes nothing', () {
      expect(effectiveMet(met: 5.0, loadKg: 0, bodyMassKg: 80), 5.0);
    });

    test('load raises cost but is never applied to speed', () {
      // The pillar of §0: the game cannot slow a real person down, so the only
      // thing load may touch is the metabolic price of the same distance.
      final light = effectiveMet(met: 3.5, loadKg: 5, bodyMassKg: 80);
      final heavy = effectiveMet(met: 3.5, loadKg: 30, bodyMassKg: 80);

      expect(heavy, greaterThan(light));
      expect(bandForSpeed(4.0), ActivityBand.walk);
    });
  });

  group('energy burn (§2.2)', () {
    test('kcal/min follows the published formula', () {
      // 3.5 MET, 80 kg: 3.5 × 3.5 × 80 / 200 = 4.9 kcal/min
      expect(kcalPerMinute(met: 3.5, bodyMassKg: 80), closeTo(4.9, 1e-9));
    });

    test('an hour of walking burns 294 kcal for an 80 kg character', () {
      final burned = kcalOver(
        met: 3.5,
        bodyMassKg: 80,
        elapsed: const Duration(hours: 1),
      );

      expect(burned, closeTo(294, 0.01));
    });

    test('burn is linear in time', () {
      final one = kcalOver(
        met: 5,
        bodyMassKg: 80,
        elapsed: const Duration(minutes: 30),
      );
      final two = kcalOver(
        met: 5,
        bodyMassKg: 80,
        elapsed: const Duration(hours: 1),
      );

      expect(two, closeTo(one * 2, 1e-9));
    });
  });

  group('heart rate (§2.4)', () {
    const resting = 70.0;
    const max = 187.0;

    test('resting effort targets the resting rate', () {
      expect(
        targetHeartRate(met: 1.0, restingHr: resting, maxHr: max),
        closeTo(resting, 1e-9),
      );
    });

    test('a full sprint targets maximum', () {
      expect(
        targetHeartRate(met: kMetMax, restingHr: resting, maxHr: max),
        closeTo(max, 1e-9),
      );
    });

    test('walking sits between the two', () {
      final walking = targetHeartRate(met: 3.5, restingHr: resting, maxHr: max);

      expect(walking, greaterThan(resting));
      expect(walking, lessThan(max));
      // (3.5 − 1) / 13 = 19.2% of the way from 70 to 187.
      expect(walking, closeTo(92.5, 0.5));
    });

    test('intensity is clamped at both ends', () {
      expect(intensityFraction(0.5), 0);
      expect(intensityFraction(100), 1);
    });
  });

  group('heart-rate recovery (§2.4)', () {
    test('one time constant covers about 63 per cent of the gap', () {
      final after = relaxHeartRate(
        current: 170,
        target: 70,
        elapsed: kHeartRateTau,
      );

      expect(after, closeTo(106.8, 0.5));
    });

    test('never overshoots the target', () {
      final after = relaxHeartRate(
        current: 180,
        target: 70,
        elapsed: const Duration(hours: 2),
      );

      expect(after, greaterThanOrEqualTo(70));
      expect(after, closeTo(70, 0.001));
    });

    test('composes — one big step equals many small ones', () {
      const total = Duration(minutes: 10);

      final single = relaxHeartRate(current: 170, target: 70, elapsed: total);

      var stepwise = 170.0;
      for (var i = 0; i < 600; i++) {
        stepwise = relaxHeartRate(
          current: stepwise,
          target: 70,
          elapsed: const Duration(seconds: 1),
        );
      }

      expect(
        stepwise,
        closeTo(single, 1e-6),
        reason: 'catch-up after an absence depends on this',
      );
    });

    test('a zero-length step changes nothing', () {
      expect(
        relaxHeartRate(current: 150, target: 70, elapsed: Duration.zero),
        150,
      );
    });

    test('the recovery constant is why waiting is not a tactic', () {
      // §5.1.3: dropping from 170 to 130 takes ~46 s, in which a Leaper at
      // 30 km/h covers nearly 400 m.
      var hr = 170.0;
      var seconds = 0;
      while (hr > 130 && seconds < 600) {
        hr = relaxHeartRate(
          current: hr,
          target: 70,
          elapsed: const Duration(seconds: 1),
        );
        seconds++;
      }

      expect(seconds, closeTo(46, 4));
    });
  });

  group('heart-rate penalties (§2.4)', () {
    const max = 187.0;

    HeartRatePenalty at(double fraction) =>
        heartRatePenalty(currentHr: max * fraction, maxHr: max);

    test('below 60 per cent there is no penalty', () {
      expect(at(0.5).extraMoa, 0);
      expect(at(0.59).canAimPrecisely, isTrue);
    });

    test('the published bands', () {
      expect(at(0.65).extraMoa, 0.5);
      expect(at(0.80).extraMoa, 1.5);
      expect(at(0.80).reloadTimeMultiplier, closeTo(1.15, 1e-9));
      expect(at(0.90).extraMoa, 3.0);
      expect(at(0.97).extraMoa, 5.0);
    });

    test('precise aiming is gone above 85 per cent', () {
      expect(at(0.84).canAimPrecisely, isTrue);
      expect(at(0.86).canAimPrecisely, isFalse);
    });

    test('fainting is only a risk above 95 per cent', () {
      expect(at(0.94).faintRisk, isFalse);
      expect(at(0.96).faintRisk, isTrue);
    });

    test('penalties never act on speed', () {
      // The one thing §0 forbids. Every field of the penalty is about aiming,
      // reloading or collapsing — none of them is a movement modifier.
      final penalty = at(0.99);

      expect(penalty.extraMoa, greaterThan(0));
      expect(penalty.reloadTimeMultiplier, greaterThan(1));
    });
  });
}
