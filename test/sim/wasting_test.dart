import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/death.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// GŁÓD MIERZY SIĘ W TYGODNIACH (§2.3, §1.3, §9).
///
/// ⚠️ **§2.3 had one thing to say about hunger and it was the wrong length.**
///
/// "0% przez > 24 h" is a rule about a *reserve* — a day's worth of food — and
/// the game read it as a death. So a character with nothing to eat was at
/// nought from the second morning of a famine, dead by the third, and day
/// three of a famine was identical to day thirty. That is the wrong shape for
/// the one axis in §2 a person really does survive for weeks on, and it made
/// hunger deadlier than thirst in a section that says in as many words that
/// water must be the harsher of the two.
///
/// The long axis is the body. A deficit is paid from it at
/// [kKcalPerKgOfBody]; a surplus goes back at [kSurplusStorageEfficiency];
/// death arrives at [kFatalMassLoss] of the starting weight, which is where
/// the clinical literature puts it and about six to ten weeks of a complete
/// fast. Everything §1.3 derives from mass follows it down — the carry limits
/// of §18.1a, the energy requirement, the daily water, Nadler's blood volume.
void main() {
  const spec = BodySpec(
    sex: Sex.male,
    ageYears: 35,
    heightCm: 180,
    weightKg: 80,
  );
  final body = BodyProfile.from(spec);
  final constants = body.toSimConstants();

  SimState fresh({double? massKg, double caloriesKcal = 0}) => SimState.fresh(
    at: DateTime.utc(2026),
    constants: constants,
    massKg: massKg ?? spec.weightKg,
  ).copyWith(caloriesKcal: caloriesKcal);

  group('§2.3: the tiers are weeks apart', () {
    StarvationState at(double massKg) =>
        starvationState(massKg: massKg, startingMassKg: 80);

    test('a week of nothing costs nothing yet', () {
      // Two and a half kilos on a complete fast. It should be an
      // inconvenience, and the whole point of this axis is that it takes weeks
      // to be anything else.
      expect(at(77.5).actionTimeMultiplier, 1.0);
      expect(at(77.5).extraMoa, 0);
    });

    test('a month is a slower character', () {
      expect(at(69).actionTimeMultiplier, greaterThan(1.0));
    });

    test('and past a fifth the hands go too', () {
      expect(at(64).extraMoa, greaterThan(0));
    });

    test('a third of the starting weight is the end (§9)', () {
      expect(at(80 * (1 - kFatalMassLoss) - 0.1).fatal, isTrue);
      expect(at(80 * (1 - kFatalMassLoss) + 0.1).fatal, isFalse);
    });

    test('and it is measured against where this body started', () {
      // ⚠️ A fifty-five kilogram character at fifty is in trouble; a ninety-
      // five kilogram one at fifty is dead. The fraction is the only reading
      // that works for both, which is why the starting weight is kept.
      expect(starvationState(massKg: 50, startingMassKg: 55).fatal, isFalse);
      expect(starvationState(massKg: 50, startingMassKg: 95).fatal, isTrue);
    });

    test('putting weight back on undoes it', () {
      expect(at(80).lostFraction, 0);
      expect(at(85).actionTimeMultiplier, 1.0);
    });
  });

  group('§2.3: what the balance does to the body', () {
    SimState run(Duration total, {double eatKcal = 0, bool offline = false}) =>
        advanceInChunks(
          state: fresh(caloriesKcal: 0).copyWith(pendingKcal: eatKcal),
          constants: constants,
          input: TickInput(offline: offline),
          elapsed: total,
        ).state;

    test('a complete fast takes about a third of a kilo a day', () {
      final after = run(const Duration(days: 1));
      final lost = 80 - after.bodyMassKg;

      expect(lost, closeTo(0.3, 0.15));
    });

    test('a week of it is a few kilograms, not a corpse', () {
      // The answer to "bez jedzenia da się funkcjonować dłuższy czas", as a
      // number rather than as a comment.
      final after = run(const Duration(days: 7));

      expect(80 - after.bodyMassKg, closeTo(2.4, 1.0));
      expect(
        statusOf(state: after, constants: constants).wasting.fatal,
        isFalse,
      );
    });

    test('and the whole way down takes somewhere near two months', () {
      // ⚠️ The figure this stage exists for. Six to ten weeks is what the
      // literature gives for a complete fast; anything much under a month
      // would mean the model is still a countdown wearing a body.
      var state = fresh(caloriesKcal: 0);
      var days = 0;

      while (days < 200) {
        state = advanceInChunks(
          state: state,
          constants: constants,
          input: const TickInput(),
          elapsed: const Duration(days: 1),
        ).state;
        days++;

        if (starvationState(
          massKg: state.bodyMassKg,
          startingMassKg: 80,
        ).fatal) {
          break;
        }
      }

      expect(days, greaterThan(35), reason: 'still a countdown');
      expect(days, lessThan(120), reason: 'nobody lives this long on nothing');
    });

    test('§2.1.1: nothing is taken off the body with the app closed', () {
      // The offline floor exists so a phone in a drawer cannot kill anybody,
      // and a fortnight of unwatched wasting would walk straight through it.
      final watched = run(const Duration(days: 14));
      final away = run(const Duration(days: 14), offline: true);

      expect(away.bodyMassKg, 80);
      expect(watched.bodyMassKg, lessThan(80));
    });

    test('a surplus goes into the body instead of being thrown away', () {
      // ⚠️ Everything above the day's reserve used to be discarded, so four
      // tins on a full stomach banked nothing and there was never a reason to
      // eat before a journey.
      final full = advanceInChunks(
        state: fresh(
          massKg: 70,
          caloriesKcal: constants.caloriesDailyKcal,
        ).copyWith(pendingKcal: 4000),
        constants: constants,
        input: const TickInput(sleeping: true),
        elapsed: const Duration(hours: 12),
      ).state;

      expect(full.bodyMassKg, greaterThan(70));
    });

    test('but storing is lossy, so it is not a free undo', () {
      expect(kSurplusStorageEfficiency, lessThan(1));
    });
  });

  group('§1.3: the rest of the body follows the mass', () {
    test('carry limits shrink with it (§18.1a)', () {
      final lighter = body.at(60);

      expect(lighter.carryMaxKg, lessThan(body.carryMaxKg));
      expect(lighter.carryComfortKg, closeTo(0.30 * 60, 0.001));
    });

    test('so does the daily requirement, which slows the fall', () {
      // Adaptive thermogenesis, for free: a lighter body burns less, so the
      // deficit shrinks as the character does. Nobody had to write a curve.
      final lighter = body.at(60);

      expect(lighter.dailyEnergyKcal, lessThan(body.dailyEnergyKcal));
      expect(lighter.baseWaterMlPerDay, closeTo(35 * 60, 0.001));
    });

    test('and Nadler follows too (§2.6)', () {
      expect(body.at(60).bloodVolumeMl, lessThan(body.bloodVolumeMl));
    });

    test('but the starting weight never moves', () {
      // ⚠️ It is what "how much of me is gone" is measured against, and a
      // profile re-derived at a lighter weight has to remember it — otherwise
      // every rebuild would quietly declare the new weight healthy and nobody
      // would ever starve.
      expect(body.at(60).startingMassKg, 80);
      expect(body.at(60).at(50).startingMassKg, 80);
      expect(body.at(60).toSimConstants().startingMassKg, 80);
    });
  });

  test('§9: the spent body is what kills, not the empty larder', () {
    final emptyLarder = statusOf(
      state: fresh(
        caloriesKcal: 0,
      ).copyWith(starvedStreakSeconds: const Duration(days: 5).inSeconds),
      constants: constants,
    );

    expect(emptyLarder.hunger.losingConsciousness, isTrue);
    expect(emptyLarder.isIncapacitated, isTrue);
    expect(
      fatalCause(emptyLarder),
      isNull,
      reason: 'five days without food is not five days without a body',
    );

    final spent = statusOf(
      state: fresh(massKg: 80 * (1 - kFatalMassLoss) - 1),
      constants: constants,
    );

    expect(fatalCause(spent), DeathCause.starvation);
  });
}
