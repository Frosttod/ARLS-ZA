import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/death.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// ŚMIERĆ I UTRATA PRZYTOMNOŚCI (§9).
///
/// Found in the field: a character with no blood left went on looting shops
/// while a Walker chewed on them. Nothing had ever asked whether they were
/// alive, so nothing behaved as though they were not.
void main() {
  final constants = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  ).toSimConstants();

  final t0 = DateTime.utc(2026, 8, 16, 12);

  SimStatus statusWith({
    double bloodFraction = 1,
    double waterFraction = 1,
    double calorieFraction = 1,
  }) => statusOf(
    state: SimState.fresh(at: t0, constants: constants).copyWith(
      bloodMl: constants.bloodMaxMl * bloodFraction,
      waterMl: constants.waterDailyMl * waterFraction,
      caloriesKcal: constants.caloriesDailyKcal * calorieFraction,
    ),
    constants: constants,
  );

  group('what puts a character down (§2.6, §2.2, §2.3)', () {
    test('nothing, while the body is holding', () {
      expect(fatalCause(statusWith()), isNull);
    });

    test('past forty per cent of blood, class IV', () {
      expect(fatalCause(statusWith(bloodFraction: 0.55)), DeathCause.bloodLoss);
    });
  });

  group('the two refusals of §9.1', () {
    // Neither is balance. Permadeath caused by a phone in a pocket losing
    // signal is a one-star review, and the document says so in as many words.
    test('nothing dies asleep', () {
      expect(mayDie(asleep: true, positionKnown: true), isFalse);
    });

    test('nothing dies with the sky lost', () {
      expect(mayDie(asleep: false, positionKnown: false), isFalse);
    });

    test('and on a street, awake, it can happen', () {
      expect(mayDie(asleep: false, positionKnown: true), isTrue);
    });
  });

  group('which mode does what (§9)', () {
    test('hardcore ends the character', () {
      expect(outcomeFor(DeathMode.hardcore), DownState.dead);
    });

    test('softcore puts them on the ground', () {
      expect(outcomeFor(DeathMode.softcore), DownState.unconscious);
    });
  });

  group('what is left on waking (§9.2)', () {
    final woken = wokenFrom(
      SimState.fresh(at: t0, constants: constants),
      constants,
    );

    test('class III shock, and alive (§9.2)', () {
      // ⚠️ §9.2's row says "25% of maximum (class III shock)" and those two
      // halves disagree: §2.6 puts class III at 30–40% lost. A quarter
      // remaining is class IV, which is unconsciousness leading to death — so
      // taken literally the character woke up and went straight back down,
      // for ever. The class wins over the figure.
      final left = woken.bloodMl / constants.bloodMaxMl;

      expect(left, closeTo(0.65, 0.001));
      expect(
        fatalCause(
          statusOf(
            state: SimState.fresh(
              at: t0,
              constants: constants,
            ).copyWith(bloodMl: woken.bloodMl),
            constants: constants,
          ),
        ),
        isNull,
        reason: 'waking up must not itself be fatal',
      );
    });

    test('and fifteen per cent of everything else', () {
      expect(woken.waterMl / constants.waterDailyMl, closeTo(0.15, 0.001));
      expect(
        woken.caloriesKcal / constants.caloriesDailyKcal,
        closeTo(0.15, 0.001),
      );
    });

    test('with nothing left in the stomach', () {
      expect(woken.pendingKcal, 0);
      expect(woken.pendingWaterMl, 0);
    });
  });

  group('waking up in a vehicle (§9.2.1)', () {
    // A deferral rather than a punishment. Waking somebody on a bus would put
    // the character where the player is not, and §0 makes that the one thing
    // this game may never do.
    test('not while moving faster than anybody walks', () {
      expect(mayWake(speedKmh: 40, positionKnown: true), isFalse);
    });

    test('not without a position either', () {
      expect(mayWake(speedKmh: 0, positionKnown: false), isFalse);
    });

    test('but a walk home is fine', () {
      expect(mayWake(speedKmh: 5, positionKnown: true), isTrue);
    });
  });

  test('the hour and the grace window are the ones §9.2 names', () {
    expect(kUnconsciousFor, const Duration(minutes: 60));
    expect(kGraceAfterWaking, const Duration(minutes: 10));
    expect(kWakeLossFraction, 0.50);
  });
}
