import 'package:arls_za/game/home_status.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// §13.1. A 4×1 widget has room for four numbers and one short line, so what
/// goes on it is a ranking rather than a dump — and the ranking has to hold
/// when a character is having a very bad evening.
void main() {
  final profile = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );
  final constants = profile.toSimConstants();
  final t0 = DateTime.utc(2026, 9, 4, 21);

  SimState stateOf({
    double? waterMl,
    double? kcal,
    Duration sleepDebt = Duration.zero,
  }) {
    var state = SimState.fresh(at: t0, constants: constants, massKg: 80);
    return state.copyWith(
      waterMl: waterMl ?? state.waterMl,
      caloriesKcal: kcal ?? state.caloriesKcal,
      sleepDebtSeconds: sleepDebt.inSeconds,
    );
  }

  SimStatus statusFor(SimState state) =>
      statusOf(state: state, constants: constants);

  group('the three bars are the ones that fail slowly', () {
    test('a rested character reads full, and the pulse is a whole number', () {
      final state = stateOf();
      final status = HomeStatus.of(
        state: state,
        status: statusFor(state),
        bleeding: BleedTier.none,
      );

      expect(status.waterPct, 100);
      expect(status.kcalPct, 100);
      expect(status.sleepPct, 100);
      expect(status.bpm, greaterThan(40));
      expect(status.ailments, isEmpty);
    });

    test('and half a day without water is half a bar', () {
      final state = stateOf(waterMl: constants.waterDailyMl / 2);
      final status = HomeStatus.of(
        state: state,
        status: statusFor(state),
        bleeding: BleedTier.none,
      );

      expect(status.waterPct, closeTo(50, 1));
    });

    test('a bar never goes over a hundred, however much was drunk', () {
      // ⚠️ §2.2 allows more than a day's water after a long drink, and a
      // progress bar handed 108 draws as *empty* on some launchers.
      final state = stateOf(waterMl: constants.waterDailyMl * 1.4);
      final status = HomeStatus.of(
        state: state,
        status: statusFor(state),
        bleeding: BleedTier.none,
      );

      expect(status.waterPct, 100);
    });
  });

  group('what is wrong, worst first', () {
    test('bleeding outranks everything, including something nearby', () {
      final state = stateOf(sleepDebt: const Duration(hours: 30));
      final wrong = ailmentsOf(
        status: statusFor(state),
        bleeding: BleedTier.moderate,
        nearestEnemyM: 40,
      );

      expect(wrong.first, Ailment.bleeding);
      expect(wrong, contains(Ailment.enemy));
    });

    test('an enemy counts inside 150 m and not a metre past it', () {
      final state = stateOf();

      List<Ailment> at(double metres) => ailmentsOf(
        status: statusFor(state),
        bleeding: BleedTier.none,
        nearestEnemyM: metres,
      );

      expect(at(kEnemyNearM), [Ailment.enemy]);
      expect(at(kEnemyNearM + 1), isEmpty);
    });

    test('nobody looked is not the same answer as nobody there', () {
      final state = stateOf();

      expect(
        ailmentsOf(status: statusFor(state), bleeding: BleedTier.none),
        isEmpty,
        reason: 'a null distance means no position, and silence is honest',
      );
    });

    test('three fit, and the rest are counted', () {
      final state = stateOf(
        waterMl: 200,
        kcal: 100,
        sleepDebt: const Duration(hours: 40),
      );
      final status = HomeStatus.of(
        state: state,
        status: statusFor(state),
        bleeding: BleedTier.moderate,
        nearestEnemyM: 30,
      );

      expect(status.ailments.length, greaterThan(kAilmentsShown));
      expect(status.shown(now: t0).length, kAilmentsShown);
      expect(status.over(now: t0), status.ailments.length - kAilmentsShown);
    });
  });

  group('a stale reading stops claiming things about the street', () {
    test('an enemy nearby is dropped once the reading is old', () {
      final state = stateOf(sleepDebt: const Duration(hours: 30));
      final status = HomeStatus.of(
        state: state,
        status: statusFor(state),
        bleeding: BleedTier.none,
        nearestEnemyM: 20,
      );

      expect(status.shown(now: t0), contains(Ailment.enemy));

      // ⚠️ Where a Walker stood ten minutes ago is not information. The body,
      // meanwhile, is still exactly as tired as it was.
      final later = t0.add(kFreshFor + const Duration(minutes: 1));
      expect(status.shown(now: later), isNot(contains(Ailment.enemy)));
      expect(
        status.shown(now: later),
        contains(Ailment.microsleeps),
        reason: 'a body that was falling asleep ten minutes ago still is',
      );
    });

    test('and the overflow count follows the same rule', () {
      final state = stateOf(
        waterMl: 200,
        kcal: 100,
        sleepDebt: const Duration(hours: 40),
      );
      final status = HomeStatus.of(
        state: state,
        status: statusFor(state),
        bleeding: BleedTier.moderate,
        nearestEnemyM: 30,
      );

      final fresh = status.over(now: t0);
      final stale = status.over(
        now: t0.add(kFreshFor + const Duration(minutes: 1)),
      );

      expect(
        stale,
        lessThan(fresh),
        reason: 'dropping the live facts cannot leave the "+2" unchanged',
      );
    });
  });
}
