import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// The character sheet from §15.4: male, 30, 180 cm, 80 kg.
const constants = SimConstants(
  bloodMaxMl: 5319,
  waterDailyMl: 2800,
  caloriesDailyKcal: 2450,
  restingHeartRate: 70,
  maxHeartRate: 187,
  startingMassKg: 80,
);

SimState freshState({
  MetabolicZone zone = MetabolicZone.open,
  double heartRate = 70,
}) => SimState(
  lastUpdate: DateTime.utc(2026, 8, 9, 12),
  bloodMl: constants.bloodMaxMl,
  waterMl: constants.waterDailyMl,
  caloriesKcal: constants.caloriesDailyKcal,
  heartRateBpm: heartRate,
  bodyMassKg: 80,
  sleepDebtSeconds: 0,
  zone: zone,
  rngCursor: 0,
);

void main() {
  group('advance', () {
    test('a zero-length tick changes nothing', () {
      final state = freshState();
      final outcome = advance(
        state: state,
        constants: constants,
        elapsed: Duration.zero,
      );

      expect(outcome.secondsApplied, 0);
      expect(outcome.state.sameValues(state), isTrue);
      expect(outcome.state.lastUpdate, state.lastUpdate);
    });

    test('a negative tick is refused', () {
      final state = freshState();
      final outcome = advance(
        state: state,
        constants: constants,
        elapsed: const Duration(seconds: -60),
      );

      expect(outcome.secondsApplied, 0);
      expect(outcome.state.sameValues(state), isTrue);
    });

    test('lastUpdate advances by exactly the elapsed time', () {
      final state = freshState();
      final outcome = advance(
        state: state,
        constants: constants,
        elapsed: const Duration(hours: 3),
      );

      expect(
        outcome.state.lastUpdate,
        state.lastUpdate.add(const Duration(hours: 3)),
      );
    });

    test('is idempotent — replaying from the same lastUpdate repeats', () {
      final state = freshState();

      final first = advance(
        state: state,
        constants: constants,
        elapsed: const Duration(minutes: 30),
      );
      final replay = advance(
        state: state,
        constants: constants,
        elapsed: const Duration(minutes: 30),
      );

      expect(first.state.sameValues(replay.state), isTrue);
      expect(first.state.lastUpdate, replay.state.lastUpdate);
    });

    test('one day of resting metabolism burns the daily requirement', () {
      final outcome = advance(
        state: freshState(),
        constants: constants,
        elapsed: const Duration(days: 1),
      );

      // Open ground is the 100% zone, so a full day at rest consumes the
      // whole daily budget (§2.1).
      expect(outcome.state.caloriesKcal, closeTo(0, 1e-6));
      expect(outcome.state.waterMl, closeTo(0, 1e-6));
    });

    test('metabolic zones scale consumption as specified in §2.1', () {
      Duration day() => const Duration(days: 1);

      double burnedIn(MetabolicZone zone) {
        final outcome = advance(
          state: freshState(zone: zone),
          constants: constants,
          elapsed: day(),
        );
        return constants.caloriesDailyKcal - outcome.state.caloriesKcal;
      }

      final open = burnedIn(MetabolicZone.open);

      expect(burnedIn(MetabolicZone.camp) / open, closeTo(0.50, 1e-9));
      expect(burnedIn(MetabolicZone.shelter) / open, closeTo(0.35, 1e-9));
      expect(burnedIn(MetabolicZone.sleep) / open, closeTo(0.20, 1e-9));
    });

    test('heart rate relaxes towards resting with a ~90 s constant', () {
      final outcome = advance(
        state: freshState(heartRate: 170),
        constants: constants,
        elapsed: const Duration(seconds: 90),
      );

      // One time constant covers ~63% of the gap: 170 -> ~107.
      expect(outcome.state.heartRateBpm, closeTo(106.8, 0.5));
    });

    test('heart rate never overshoots resting', () {
      final outcome = advance(
        state: freshState(heartRate: 180),
        constants: constants,
        elapsed: const Duration(hours: 2),
      );

      expect(
        outcome.state.heartRateBpm,
        greaterThanOrEqualTo(constants.restingHeartRate),
      );
      expect(outcome.state.heartRateBpm, closeTo(70, 0.001));
    });

    group('offline floor (§2.1.1)', () {
      test('two weeks away never drops a resource below 10%', () {
        final outcome = advance(
          state: freshState(zone: MetabolicZone.shelter),
          constants: constants,
          elapsed: const Duration(days: 14),
          offline: true,
        );

        expect(
          outcome.state.caloriesKcal,
          closeTo(constants.caloriesDailyKcal * 0.10, 1e-6),
        );
        expect(
          outcome.state.waterMl,
          closeTo(constants.waterDailyMl * 0.10, 1e-6),
        );
        expect(outcome.floored, isTrue);
      });

      test(
        'blood is never touched by the floor logic when already above it',
        () {
          final outcome = advance(
            state: freshState(),
            constants: constants,
            elapsed: const Duration(days: 14),
            offline: true,
          );

          expect(outcome.state.bloodMl, constants.bloodMaxMl);
        },
      );

      test('the floor never refills a resource that is already below it', () {
        final starving = freshState().copyWith(caloriesKcal: 50);

        final outcome = advance(
          state: starving,
          constants: constants,
          elapsed: const Duration(days: 3),
          offline: true,
        );

        expect(
          outcome.state.caloriesKcal,
          lessThanOrEqualTo(50),
          reason: 'coming back must not be a free meal',
        );
      });

      test('online ticks are not floored', () {
        final outcome = advance(
          state: freshState(),
          constants: constants,
          elapsed: const Duration(days: 2),
        );

        expect(outcome.state.caloriesKcal, 0);
        expect(outcome.floored, isFalse);
      });
    });
  });

  group('advanceInChunks', () {
    test('chunked catch-up matches a single step', () {
      const elapsed = Duration(hours: 30);

      final single = advance(
        state: freshState(zone: MetabolicZone.shelter),
        constants: constants,
        elapsed: elapsed,
      );
      final chunked = advanceInChunks(
        state: freshState(zone: MetabolicZone.shelter),
        constants: constants,
        elapsed: elapsed,
        chunk: const Duration(hours: 1),
      );

      expect(chunked.secondsApplied, single.secondsApplied);
      expect(chunked.state.lastUpdate, single.state.lastUpdate);
      expect(
        chunked.state.caloriesKcal,
        closeTo(single.state.caloriesKcal, 1e-6),
        reason: 'consumption must be linear in elapsed time',
      );
      expect(chunked.state.waterMl, closeTo(single.state.waterMl, 1e-6));
    });

    test('second-by-second replay matches a single step', () {
      const elapsed = Duration(minutes: 10);

      final single = advance(
        state: freshState(),
        constants: constants,
        elapsed: elapsed,
      );
      final ticked = advanceInChunks(
        state: freshState(),
        constants: constants,
        elapsed: elapsed,
        chunk: const Duration(seconds: 1),
      );

      expect(ticked.state.lastUpdate, single.state.lastUpdate);
      expect(
        ticked.state.caloriesKcal,
        closeTo(single.state.caloriesKcal, 1e-6),
      );
      expect(
        ticked.state.heartRateBpm,
        closeTo(single.state.heartRateBpm, 1e-6),
        reason: 'exponential relaxation must compose across steps',
      );
    });
  });

  group('SimState serialisation', () {
    test('round-trips through JSON', () {
      final state = freshState(
        zone: MetabolicZone.camp,
        heartRate: 132.5,
      ).copyWith(sleepDebtSeconds: 4200, rngCursor: 918);

      final restored = SimState.fromJson(state.toJson());

      expect(restored.sameValues(state), isTrue);
      expect(restored.lastUpdate, state.lastUpdate);
      expect(restored.zone, MetabolicZone.camp);
      expect(restored.sleepDebtSeconds, 4200);
      expect(restored.rngCursor, 918);
    });

    test('an unknown zone falls back to open rather than throwing', () {
      expect(MetabolicZone.fromWire('bunker'), MetabolicZone.open);
    });
  });
}
