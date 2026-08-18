import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// §2.2, §2.3. What has been eaten is not yet in the blood.
///
/// The point is not fidelity to digestion — one rate standing in for a whole
/// system is not that — it is the decision it creates. Food that lands
/// instantly is a button pressed when a bar turns red. Food that takes an hour
/// is something a player carries and takes *before* they need it, which is the
/// only version of the choice worth having.
void main() {
  const constants = SimConstants(
    bloodMaxMl: 5319,
    waterDailyMl: 2800,
    caloriesDailyKcal: 2450,
    restingHeartRate: 70,
    maxHeartRate: 187,
  );

  final t0 = DateTime.utc(2026, 8, 15, 12);

  SimState resting({double pendingKcal = 0, double pendingWaterMl = 0}) =>
      SimState.fresh(at: t0, constants: constants).copyWith(
        caloriesKcal: constants.caloriesDailyKcal * 0.5,
        waterMl: constants.waterDailyMl * 0.5,
        pendingKcal: pendingKcal,
        pendingWaterMl: pendingWaterMl,
      );

  SimState run(SimState from, Duration elapsed) => advance(
    state: from,
    constants: constants,
    input: const TickInput(speedKmh: 0),
    elapsed: elapsed,
  ).state;

  group('what has been swallowed arrives over time', () {
    test('a tin of beans is not a meal the instant it is opened', () {
      final after = run(resting(pendingKcal: 520), const Duration(minutes: 1));

      // One minute in, most of it is still in the stomach.
      expect(after.pendingKcal, closeTo(512, 1));
    });

    test('and is gone from the stomach about an hour later', () {
      final after = run(resting(pendingKcal: 520), const Duration(minutes: 70));

      expect(after.pendingKcal, 0);
    });

    test('half a litre of water takes about twenty minutes', () {
      final part = run(
        resting(pendingWaterMl: 500),
        const Duration(minutes: 10),
      );
      final done = run(
        resting(pendingWaterMl: 500),
        const Duration(minutes: 21),
      );

      expect(part.pendingWaterMl, closeTo(250, 1));
      expect(done.pendingWaterMl, 0);
    });

    test('nothing is absorbed that was never eaten', () {
      final after = run(resting(), const Duration(hours: 2));

      expect(after.pendingKcal, 0);
      expect(after.pendingWaterMl, 0);
    });
  });

  group('it reaches the reserve', () {
    test('calories arrive rather than vanishing', () {
      final before = resting(pendingKcal: 400);
      final after = run(before, const Duration(hours: 2));

      // Two hours of resting burn, plus everything that was waiting.
      final burned =
          before.caloriesKcal -
          run(resting(), const Duration(hours: 2)).caloriesKcal;

      expect(
        after.caloriesKcal,
        closeTo(before.caloriesKcal - burned + 400, 1),
      );
    });

    test('water does too', () {
      final before = resting(pendingWaterMl: 500);
      final after = run(before, const Duration(hours: 1));
      final without = run(resting(), const Duration(hours: 1));

      expect(after.waterMl - without.waterMl, closeTo(500, 1));
    });
  });

  group('the properties the tick engine depends on', () {
    test('absorption composes, so a catch-up lands where seconds would', () {
      // §11.1.2: replaying a gap in one step and in many has to agree, and
      // absorption is now part of what a step does.
      var stepwise = resting(pendingKcal: 520, pendingWaterMl: 500);
      for (var i = 0; i < 30; i++) {
        stepwise = run(stepwise, const Duration(minutes: 1));
      }
      final atOnce = run(
        resting(pendingKcal: 520, pendingWaterMl: 500),
        const Duration(minutes: 30),
      );

      expect(stepwise.caloriesKcal, closeTo(atOnce.caloriesKcal, 0.5));
      expect(stepwise.waterMl, closeTo(atOnce.waterMl, 0.5));
      expect(stepwise.pendingKcal, closeTo(atOnce.pendingKcal, 0.5));
    });

    test('a stomach never goes negative', () {
      final after = run(resting(pendingKcal: 10), const Duration(hours: 4));

      expect(after.pendingKcal, 0);
      expect(after.pendingWaterMl, 0);
    });

    test('it survives being written down and read back', () {
      // A player who eats and closes the app has food in them.
      final state = resting(pendingKcal: 300, pendingWaterMl: 200);
      final restored = SimState.fromJson(state.toJson());

      expect(restored.pendingKcal, 300);
      expect(restored.pendingWaterMl, 200);
    });

    test('a save written before this existed reads as an empty stomach', () {
      final old = SimState.fresh(at: t0, constants: constants).toJson()
        ..remove('pendingKcal')
        ..remove('pendingWaterMl');

      expect(SimState.fromJson(old).pendingKcal, 0);
    });
  });

  group('a stomach is not a warehouse (§2.2, §2.3)', () {
    test('eating past full banks nothing', () {
      // Found on a phone: calories sat at a hundred per cent for hours while a
      // hidden surplus drained, which reads as calories that have stopped
      // working.
      final full = SimState.fresh(
        at: t0,
        constants: constants,
      ).copyWith(pendingKcal: 3000);

      final after = run(full, const Duration(hours: 2));

      expect(
        after.caloriesKcal,
        lessThanOrEqualTo(constants.caloriesDailyKcal),
      );
    });

    test('nor does drinking past full', () {
      final full = SimState.fresh(
        at: t0,
        constants: constants,
      ).copyWith(pendingWaterMl: 5000);

      final after = run(full, const Duration(hours: 1));

      expect(after.waterMl, lessThanOrEqualTo(constants.waterDailyMl));
    });

    test('and what fits still arrives', () {
      // The cap is a ceiling, not a refusal: a hungry player still eats.
      final hungry = SimState.fresh(at: t0, constants: constants).copyWith(
        caloriesKcal: constants.caloriesDailyKcal * 0.4,
        pendingKcal: 500,
      );

      final after = run(hungry, const Duration(hours: 2));

      expect(
        after.caloriesKcal,
        greaterThan(constants.caloriesDailyKcal * 0.4),
      );
    });
  });

  group('what the HUD tick promises (§2.3)', () {
    test('half a litre is through in about twenty minutes', () {
      // The figure §2.3 names, and the one the `+` on the water bar is a
      // promise about. If this drifts, the mark on screen becomes a lie.
      final drunk = resting(pendingWaterMl: 500);

      final after = run(drunk, const Duration(minutes: 20));

      expect(after.pendingWaterMl, closeTo(0, 1));

      // What left the stomach arrived in the body, less the twenty minutes of
      // ordinary sweat and breath that went out while it did.
      final dry = run(resting(), const Duration(minutes: 20));
      expect(after.waterMl - dry.waterMl, closeTo(500, 1));
    });

    test('and a tin of stew takes rather longer (§2.2)', () {
      // Which is the whole point: food is something carried and taken before
      // it is needed, not a button pressed when a bar turns red.
      final eaten = resting(pendingKcal: 500);

      expect(
        run(eaten, const Duration(minutes: 20)).pendingKcal,
        greaterThan(300),
      );
      expect(
        run(eaten, const Duration(minutes: 63)).pendingKcal,
        closeTo(0, 1),
      );
    });

    test('the reserve climbs while it is arriving', () {
      // The bar has to move, or the tick beside it says nothing.
      final drunk = resting(pendingWaterMl: 500);

      final five = run(drunk, const Duration(minutes: 5));
      final ten = run(drunk, const Duration(minutes: 10));

      expect(ten.waterMl, greaterThan(five.waterMl));
      expect(ten.pendingWaterMl, lessThan(five.pendingWaterMl));
    });
  });
}
