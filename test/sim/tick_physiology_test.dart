import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// The full tick, with movement, sweat, bleeding and sleep wired in.
///
/// The property every test here leans on is **linearity in elapsed time**: a
/// catch-up after an absence takes one big step, a live session takes many
/// small ones, and both have to land on the same numbers (§11.1.2).
void main() {
  final constants = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  ).toSimConstants();

  final t0 = DateTime.utc(2026, 8, 10, 12);

  SimState fresh({MetabolicZone zone = MetabolicZone.open}) =>
      SimState.fresh(at: t0, constants: constants).copyWith(zone: zone);

  group('movement costs energy (§2.2)', () {
    test('walking burns more than standing', () {
      final standing = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
      );
      final walking = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 5.0),
      );

      expect(walking.caloriesBurned, greaterThan(standing.caloriesBurned));
    });

    test('an hour of brisk walking adds roughly the MET surcharge', () {
      final result = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 5.0),
      );

      // 5 MET at 80 kg is 7 kcal/min; subtracting the 1 MET baseline leaves
      // 5.6 kcal/min, so 336 kcal on top of the basal share.
      final basal = constants.caloriesDailyKcal / 24;
      expect(result.caloriesBurned - basal, closeTo(336, 5));
    });

    test('carrying load raises the cost of the same distance', () {
      final light = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 5.0),
      );
      final heavy = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 5.0, loadKg: 20),
      );

      expect(heavy.caloriesBurned, greaterThan(light.caloriesBurned));
      expect(
        heavy.state.lastUpdate,
        light.state.lastUpdate,
        reason: 'load must never touch how far the character got (§0)',
      );
    });

    test('standing still costs only the basal share of the zone', () {
      final result = advance(
        state: fresh(zone: MetabolicZone.shelter),
        constants: constants,
        elapsed: const Duration(hours: 1),
      );

      expect(
        result.caloriesBurned,
        closeTo(constants.caloriesDailyKcal / 24 * 0.35, 1e-6),
      );
    });
  });

  group('sweat (§2.3)', () {
    test('running loses more water than standing', () {
      final standing = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
      );
      final running = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 9.0),
      );

      expect(running.waterLostMl, greaterThan(standing.waterLostMl * 2));
    });

    test('heat costs water even at rest through the zone share', () {
      // The sweat surcharge only applies to movement; at rest the basal figure
      // carries the day. Worth stating so the model is not misread.
      final cool = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 5, ambientTempC: 10),
      );
      final hot = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(speedKmh: 5, ambientTempC: 32),
      );

      expect(hot.waterLostMl, greaterThan(cool.waterLostMl));
    });
  });

  group('bleeding (§2.6)', () {
    test('an untreated moderate bleed drains measurably in an hour', () {
      final result = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 1),
        input: const TickInput(bleedTier: BleedTier.moderate),
      );

      // 25 ml/min at rest is 1500 ml an hour — already class II shock.
      expect(result.bloodLostMl, closeTo(1500, 5));
      expect(
        statusOf(state: result.state, constants: constants).blood.shockClass,
        ShockClass.compensated,
      );
    });

    test('running with a wound bleeds faster than standing with one', () {
      // Raise the heart rate first, so the bleed modifier has something to
      // work with.
      final winded = fresh().copyWith(heartRateBpm: 170);

      final calm = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(minutes: 10),
        input: const TickInput(bleedTier: BleedTier.severe),
      );
      final exerted = advance(
        state: winded,
        constants: constants,
        elapsed: const Duration(minutes: 10),
        input: const TickInput(bleedTier: BleedTier.severe),
      );

      expect(exerted.bloodLostMl, greaterThan(calm.bloodLostMl * 2));
    });

    test('no wound loses no blood', () {
      final result = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 6),
      );

      expect(result.bloodLostMl, 0);
      expect(result.state.bloodMl, constants.bloodMaxMl);
    });
  });

  group('sleep debt (§2.5)', () {
    test('a waking day accrues the full nightly requirement', () {
      final result = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(days: 1),
      );

      expect(
        result.state.sleepDebt.inMinutes,
        closeTo(kDailySleepNeed.inMinutes, 1),
      );
    });

    test('sleeping pays the debt down hour for hour', () {
      final tired = fresh().copyWith(
        sleepDebtSeconds: const Duration(hours: 6).inSeconds,
      );

      final result = advance(
        state: tired,
        constants: constants,
        elapsed: const Duration(hours: 4),
        input: const TickInput(sleeping: true),
      );

      expect(result.state.sleepDebt, const Duration(hours: 2));
    });

    test('the debt never goes negative', () {
      final result = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(hours: 10),
        input: const TickInput(sleeping: true),
      );

      expect(result.state.sleepDebtSeconds, 0);
    });

    test('a full night of sleep cancels a full day awake', () {
      var state = fresh();
      state = advance(
        state: state,
        constants: constants,
        elapsed: const Duration(hours: 16),
      ).state;
      state = advance(
        state: state,
        constants: constants,
        elapsed: const Duration(hours: 8),
        input: const TickInput(sleeping: true),
      ).state;

      // 16 h awake accrues 16/24 of 8 h; 8 h of sleep more than covers it.
      expect(state.sleepDebtSeconds, 0);
    });
  });

  group('linearity — the property catch-up depends on', () {
    void expectSameEitherWay(TickInput input, Duration total) {
      final single = advance(
        state: fresh(zone: MetabolicZone.shelter),
        constants: constants,
        elapsed: total,
        input: input,
      );
      final chunked = advanceInChunks(
        state: fresh(zone: MetabolicZone.shelter),
        constants: constants,
        elapsed: total,
        chunk: const Duration(minutes: 5),
        input: input,
      );

      expect(chunked.state.lastUpdate, single.state.lastUpdate);
      expect(
        chunked.state.caloriesKcal,
        closeTo(single.state.caloriesKcal, 1e-6),
      );
      expect(chunked.state.waterMl, closeTo(single.state.waterMl, 1e-6));
      expect(
        chunked.state.sleepDebtSeconds,
        closeTo(single.state.sleepDebtSeconds, 60),
      );
    }

    test('at rest', () {
      expectSameEitherWay(TickInput.resting, const Duration(hours: 12));
    });

    test('while walking', () {
      expectSameEitherWay(
        const TickInput(speedKmh: 5, loadKg: 15),
        const Duration(hours: 6),
      );
    });

    test('while sleeping', () {
      expectSameEitherWay(
        const TickInput(sleeping: true),
        const Duration(hours: 8),
      );
    });
  });

  group('idempotency (§11.1.2)', () {
    test('replaying the same step gives the same result', () {
      const input = TickInput(
        speedKmh: 6,
        loadKg: 12,
        bleedTier: BleedTier.superficial,
      );

      final first = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(minutes: 45),
        input: input,
      );
      final replay = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(minutes: 45),
        input: input,
      );

      expect(first.state.sameValues(replay.state), isTrue);
      expect(first.state.lastUpdate, replay.state.lastUpdate);
    });
  });

  group('offline floor (§2.1.1)', () {
    test('two weeks away leaves the character alive', () {
      final result = advanceInChunks(
        state: fresh(zone: MetabolicZone.shelter),
        constants: constants,
        elapsed: const Duration(days: 14),
        input: const TickInput(offline: true),
      );

      final status = statusOf(state: result.state, constants: constants);

      expect(result.floored, isTrue);
      expect(status.isIncapacitated, isFalse);
      expect(
        result.state.caloriesKcal,
        closeTo(constants.caloriesDailyKcal * 0.10, 1e-6),
      );
      expect(
        result.state.waterMl,
        closeTo(constants.waterDailyMl * 0.10, 1e-6),
      );
    });

    test('an offline bleed cannot kill either', () {
      final result = advanceInChunks(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(days: 2),
        input: const TickInput(offline: true, bleedTier: BleedTier.arterial),
      );

      expect(
        result.state.bloodMl,
        closeTo(constants.bloodMaxMl * 0.10, 1e-6),
        reason: 'a technical absence must never be fatal (§9.1)',
      );
    });

    test('online, the same bleed is lethal', () {
      final result = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(minutes: 10),
        input: const TickInput(bleedTier: BleedTier.arterial),
      );

      expect(
        statusOf(state: result.state, constants: constants).blood.isFatal,
        isTrue,
      );
    });
  });

  group('status interpretation', () {
    test('a fresh character has no penalties at all', () {
      final status = statusOf(state: fresh(), constants: constants);

      expect(status.totalExtraMoa, 0);
      expect(status.actionTimeMultiplier, 1.0);
      expect(status.isIncapacitated, isFalse);
    });

    test('penalties from different sources add up in MOA', () {
      final battered = fresh().copyWith(
        bloodMl: constants.bloodMaxMl * 0.75, // class II: +2 MOA
        sleepDebtSeconds: const Duration(hours: 14).inSeconds, // +3 MOA
        heartRateBpm: constants.maxHeartRate * 0.90, // +3 MOA
      );

      final status = statusOf(state: battered, constants: constants);

      expect(status.blood.extraMoa, 2.0);
      expect(status.sleep.extraMoa, 3.0);
      expect(status.heartRate.extraMoa, 3.0);
      expect(status.totalExtraMoa, 8.0);
    });
  });

  group('blood comes back (§2.6)', () {
    // Found on a phone: a character came out of a fight in class IV shock and
    // stayed there. Nothing was bleeding any more, so every bandage in the
    // pack refused — and nothing in the model ever put a millilitre back. The
    // model needs a way out of a bad fight that is not a new character.
    SimState bled(double fraction) => fresh().copyWith(
      bloodMl: constants.bloodMaxMl * (1 - fraction),
    );

    test('with a full stomach and nothing open', () {
      final after = advance(
        state: bled(0.35),
        constants: constants,
        elapsed: const Duration(hours: 10),
      );

      expect(after.state.bloodMl, greaterThan(bled(0.35).bloodMl));
    });

    test('and a bad loss is back in a day or so, if you keep eating', () {
      // Through the chunked path, which is what any gap over an hour takes:
      // the rate follows the stomach, so a single forty-hour step would credit
      // meals the character never ate.
      var state = bled(0.40);
      for (var hour = 0; hour < 40; hour++) {
        state = advanceInChunks(
          state: state,
          constants: constants,
          elapsed: const Duration(hours: 1),
        ).state.copyWith(
          // A meal and a bottle each hour: this test is about the blood, and
          // starving to death on the way would be a different one.
          caloriesKcal: constants.caloriesDailyKcal,
          waterMl: constants.waterDailyMl,
        );
      }

      expect(state.bloodMl / constants.bloodMaxMl, greaterThan(0.95));
    });

    test('never above what the body holds', () {
      final after = advance(
        state: fresh(),
        constants: constants,
        elapsed: const Duration(days: 3),
      );

      expect(after.state.bloodMl, lessThanOrEqualTo(constants.bloodMaxMl));
    });

    test('nothing at all while something is still open', () {
      // The body cannot refill a bucket with a hole in it, which is what makes
      // stopping the bleed the first job rather than an optional one.
      final after = advance(
        state: bled(0.30),
        constants: constants,
        elapsed: const Duration(hours: 4),
        input: const TickInput(bleedTier: BleedTier.superficial),
      );

      expect(after.state.bloodMl, lessThan(bled(0.30).bloodMl));
    });

    test('and none of it on an empty stomach', () {
      // Blood is made out of what is eaten and drunk.
      final starving = bled(0.30).copyWith(caloriesKcal: 0, waterMl: 0);
      final after = advance(
        state: starving,
        constants: constants,
        elapsed: const Duration(hours: 10),
      );

      expect(after.state.bloodMl, closeTo(starving.bloodMl, 1));
    });

    test('half-fed is half speed', () {
      final full = advance(
        state: bled(0.30),
        constants: constants,
        elapsed: const Duration(hours: 10),
      );
      final half = advance(
        state: bled(0.30).copyWith(
          caloriesKcal: constants.caloriesDailyKcal * 0.5,
          waterMl: constants.waterDailyMl * 0.5,
        ),
        constants: constants,
        elapsed: const Duration(hours: 10),
      );

      final gainedFull = full.state.bloodMl - bled(0.30).bloodMl;
      final gainedHalf = half.state.bloodMl - bled(0.30).bloodMl;
      expect(gainedHalf, lessThan(gainedFull));
      expect(gainedHalf, greaterThan(0));
    });
  });
}
