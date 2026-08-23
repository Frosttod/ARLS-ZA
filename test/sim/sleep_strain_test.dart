import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// KILKA ZARWANYCH NOCY POD RZĄD (§2.5.4, §2.5.5, §2.4, §2.6).
///
/// ⚠️ **Three weeks of short nights read exactly like one late evening.**
///
/// §2.5.4's debt is capped at a day, clears in a day, and — because it only
/// accrues while the character is *awake* — settles at break-even on six-hour
/// nights. Sixteen waking hours are worth five hours and twenty minutes of
/// debt, the night pays six, and the number never moves. So a character a
/// fortnight into sleeping badly was in the same state as one who stayed up
/// once, and there was no long axis at all.
///
/// The second clock counts against the wall rather than against waking time,
/// which is what §2.5.3's own formula says: a day needs eight hours whatever
/// you did with it. Over twenty-four hours with S hours slept the strain moves
/// by `1 − S/8`.
///
/// The physiology it models is well documented and makes an unusually good
/// mechanic: under chronic restriction **subjective sleepiness plateaus while
/// performance goes on falling**. So its penalties are deliberately ones the
/// sleep bar does not show — healing, the heart settling, the hands — and the
/// status screen carries a note of its own, because a penalty nobody can see
/// the reason for is a bug however real it is.
void main() {
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 35, heightCm: 180, weightKg: 80),
  );
  final constants = body.toSimConstants();

  /// Runs [days] days, sleeping [sleptHours] of each.
  SimState nights(int days, {required double sleptHours}) {
    var state = SimState.fresh(
      at: DateTime.utc(2026),
      constants: constants,
      massKg: 80,
    );

    final asleep = Duration(minutes: (sleptHours * 60).round());

    for (var day = 0; day < days; day++) {
      state = advanceInChunks(
        state: state,
        constants: constants,
        input: const TickInput(sleeping: true),
        elapsed: asleep,
      ).state;

      state = advanceInChunks(
        state: state,
        constants: constants,
        input: TickInput.resting,
        elapsed: const Duration(hours: 24) - asleep,
      ).state;
    }

    return state;
  }

  group('§2.5.5: what one bad night is worth, and what a fortnight is', () {
    test('a single two-hour shortfall is a quarter of a night', () {
      // ⚠️ The report this tier answers, in its own words: "samo nieprzespanie
      // 2h jednej nocy nie jest tak tragiczne jak kilka zarwanych pod rząd".
      final after = nights(1, sleptHours: 6);

      expect(after.sleepStrain, closeTo(0.25, 0.02));
      expect(sleepStrainState(after.sleepStrain).extraMoa, 0);
      expect(sleepStrainState(after.sleepStrain).healingMultiplier, 1.0);
    });

    test('four short nights in a row are a different animal', () {
      final after = nights(4, sleptHours: 4);

      expect(after.sleepStrain, closeTo(2.0, 0.1));
      expect(
        sleepStrainState(after.sleepStrain).learningRateMultiplier,
        lessThan(1),
      );
    });

    test('a fortnight of six-hour nights is three and a half', () {
      final after = nights(14, sleptHours: 6);

      expect(after.sleepStrain, closeTo(3.5, 0.2));

      final state = sleepStrainState(after.sleepStrain);
      expect(state.extraMoa, greaterThan(0));
      expect(state.healingMultiplier, lessThan(1));
    });

    test('and two months of them hit the floor of the hole', () {
      final after = nights(60, sleptHours: 6);

      expect(after.sleepStrain, kMaxSleepStrain);
      expect(sleepStrainState(after.sleepStrain).microsleepsAnyway, isTrue);
    });

    test('the hole has a bottom, for the same reason the debt does', () {
      // Past the last tier there is nothing worse to be, so everything beyond
      // the cap is only a longer climb out — a punishment nobody asked for and
      // one no interface can draw. The acute debt learned this from a walk
      // reported as "sleep does not regenerate in the shelter".
      expect(nights(200, sleptHours: 0).sleepStrain, kMaxSleepStrain);
    });
  });

  group('§2.5.3: getting out of it is seasonal, with no modifier', () {
    test('eight hours holds the line and does not clear it', () {
      // ⚠️ Recovery from chronic restriction needs *extra* sleep, not merely
      // adequate sleep. A night that exactly meets the requirement leaves the
      // strain where it is.
      var state = nights(14, sleptHours: 6);
      final before = state.sleepStrain;

      for (var day = 0; day < 5; day++) {
        state = advanceInChunks(
          state: state,
          constants: constants,
          input: const TickInput(sleeping: true),
          elapsed: const Duration(hours: 8),
        ).state;
        state = advanceInChunks(
          state: state,
          constants: constants,
          input: TickInput.resting,
          elapsed: const Duration(hours: 16),
        ).state;
      }

      expect(state.sleepStrain, closeTo(before, 0.05));
    });

    test('and December clears a summer of it', () {
      // Poznań gives 16.6 hours of darkness on the solstice. Four of those
      // take off four nights of strain — which is exactly the seasonality
      // §2.5.3 is built around, arrived at without a single modifier.
      var state = nights(14, sleptHours: 6);
      expect(state.sleepStrain, greaterThan(3));

      for (var day = 0; day < 4; day++) {
        state = advanceInChunks(
          state: state,
          constants: constants,
          input: const TickInput(sleeping: true),
          elapsed: const Duration(hours: 16, minutes: 36),
        ).state;
        state = advanceInChunks(
          state: state,
          constants: constants,
          input: TickInput.resting,
          elapsed: const Duration(hours: 7, minutes: 24),
        ).state;
      }

      expect(state.sleepStrain, lessThan(0.5));
    });

    test('and sleeping in is never credit (§2.5.3)', () {
      // ⚠️ §2.5.3 forbids a bank outright: "nadmiar nocy w schronie ponad
      // zapotrzebowanie nie kumuluje zapasu". The state keeps one night of
      // arithmetic headroom below nought so that a night-then-day cycle lands
      // where the daily figure says it should — and nothing below nought is
      // ever readable as anything but rested.
      final state = nights(20, sleptHours: 12);

      expect(state.sleepStrain, greaterThanOrEqualTo(kSleepStrainFloor));
      expect(sleepStrainState(state.sleepStrain).strain, 0);
    });
  });

  group('§2.5.5: the penalties are the ones the bar does not show', () {
    test('the debt is clear and the character is still worse off', () {
      // ⚠️ The plateau, held as an assertion. This is the whole design: sleep
      // well for one night, watch the bar fill, and find that the numbers have
      // not come back with it.
      var state = nights(21, sleptHours: 6);

      state = advanceInChunks(
        state: state,
        constants: constants,
        input: const TickInput(sleeping: true),
        elapsed: const Duration(hours: 9),
      ).state;

      final status = statusOf(state: state, constants: constants);

      expect(status.sleep.extraMoa, 0, reason: 'last night was fine');
      expect(status.chronicSleep.extraMoa, greaterThan(0));
      expect(status.totalExtraMoa, greaterThan(0));
    });

    test('§2.6: a worn-out body puts blood back more slowly', () {
      SimState regenOver(double strain) {
        final start = SimState.fresh(
          at: DateTime.utc(2026),
          constants: constants,
          massKg: 80,
        ).copyWith(bloodMl: constants.bloodMaxMl * 0.75, sleepStrain: strain);

        return advanceInChunks(
          state: start,
          constants: constants,
          input: TickInput.resting,
          elapsed: const Duration(hours: 12),
        ).state;
      }

      expect(regenOver(7).bloodMl, lessThan(regenOver(0).bloodMl));
    });

    test('§2.4: and takes longer to get its breath back', () {
      // In a game with no stamina bar the heart *is* the stamina, so a slower
      // recovery is more time spent unable to aim after a run.
      SimState afterRunning(double strain) {
        final start = SimState.fresh(
          at: DateTime.utc(2026),
          constants: constants,
          massKg: 80,
        ).copyWith(heartRateBpm: 170, sleepStrain: strain);

        return advanceInChunks(
          state: start,
          constants: constants,
          input: TickInput.resting,
          elapsed: const Duration(minutes: 3),
        ).state;
      }

      expect(
        afterRunning(7).heartRateBpm,
        greaterThan(afterRunning(0).heartRateBpm),
      );
    });

    test('a rested character pays none of it', () {
      final status = statusOf(
        state: SimState.fresh(
          at: DateTime.utc(2026),
          constants: constants,
          massKg: 80,
        ),
        constants: constants,
      );

      expect(status.chronicSleep.extraMoa, 0);
      expect(status.chronicSleep.healingMultiplier, 1.0);
      expect(status.chronicSleep.heartRecoveryMultiplier, 1.0);
    });
  });

  test('§11.1.4: a row written before this reads as rested', () {
    final old = SimState.fromJson({
      'lastUpdate': '2026-01-01T00:00:00.000Z',
      'bloodMl': 5000.0,
      'waterMl': 2800.0,
      'caloriesKcal': 2500.0,
      'heartRateBpm': 60.0,
      'sleepDebtSeconds': 0,
      'zone': 'open',
    });

    expect(old.sleepStrain, 0);
    expect(sleepStrainState(old.sleepStrain).extraMoa, 0);
  });
}
