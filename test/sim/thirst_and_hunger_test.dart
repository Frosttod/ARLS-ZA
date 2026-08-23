import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/death.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// BEZ WODY CIĘŻKO, BEZ JEDZENIA DA SIĘ (§2.3, §9).
///
/// ⚠️ **Both of §2.3's lethal rules were unreachable.**
///
/// `hungerState` has taken a `timeAtZero` and `thirstState` a
/// `timeWithoutWater` since they were written. `statusOf` passed neither, and
/// `SimState` had nowhere to keep them — so `losingConsciousness` and `lethal`
/// were permanently false, and two of the three `DeathCause` values named
/// states the game could not enter. A character could go for ever without food
/// or water.
///
/// The asymmetry is the point of §2.3 and it is not a designed curve: it falls
/// out of the constants. The reserve is a day of water and a day of calories,
/// but the *thresholds* are fractions of body mass — and a body carries months
/// of fat and about three days of water. So thirst runs its whole course while
/// hunger is barely started, which is why §2.3 says in as many words that
/// water must be the harsher of the two.
void main() {
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 35, heightCm: 180, weightKg: 80),
  );
  final constants = body.toSimConstants();

  SimStatus statusAfter({
    Duration dry = Duration.zero,
    Duration starved = Duration.zero,
    double? waterMl,
    double? caloriesKcal,
    bool underExertion = false,
  }) => statusOf(
    state: SimState.fresh(at: DateTime.utc(2026), constants: constants)
        .copyWith(
          waterMl: waterMl ?? constants.waterDailyMl,
          caloriesKcal: caloriesKcal ?? constants.caloriesDailyKcal,
          dryStreakSeconds: dry.inSeconds,
          starvedStreakSeconds: starved.inSeconds,
        ),
    constants: constants,
    underExertion: underExertion,
  );

  group('§2.3: the clocks reach the rules at all', () {
    test('the state carries how long since the last swallow', () {
      final status = statusAfter(dry: const Duration(hours: 50));

      // Nothing yet — the reserve is full, which is the case somebody who has
      // been drip-fed water is in.
      expect(status.thirst.lethal, isFalse);
    });

    test('forty-eight hours dry and walking is fatal (§2.3)', () {
      // ⚠️ The rule as §2.3 words it, and the first time it can fire.
      final status = statusAfter(
        dry: const Duration(hours: 49),
        waterMl: 0,
        underExertion: true,
      );

      expect(status.thirst.lethal, isTrue);
      expect(fatalCause(status), DeathCause.thirst);
    });

    test('and forty-seven is not', () {
      expect(
        statusAfter(
          dry: const Duration(hours: 47),
          waterMl: 0,
          underExertion: true,
        ).thirst.lethal,
        isFalse,
      );
    });

    test('standing still buys time, and it is not for ever', () {
      // §2.3 qualifies its only lethal rule with "w warunkach wysiłku", which
      // taken alone makes somebody sitting in a shelter immortal — the reserve
      // floors at ten per cent of body mass and stays there.
      //
      // ⚠️ [kCriticalThirstGrace] is an extension and named as one. Half a day
      // at ten per cent of body mass in deficit is where the literature stops
      // discussing performance.
      final deficit = -0.10 * constants.bodyMassKg * 1000;

      final justCritical = statusAfter(
        dry: const Duration(hours: 6),
        waterMl: deficit,
      );
      final heldThere = statusAfter(
        dry: kCriticalThirstGrace + const Duration(hours: 1),
        waterMl: deficit,
      );

      expect(justCritical.thirst.critical, isTrue);
      expect(justCritical.thirst.lethal, isFalse, reason: 'not yet');
      expect(heldThere.thirst.lethal, isTrue);
    });

    test('a day at nought calories is fatal (§2.3)', () {
      final status = statusAfter(
        caloriesKcal: 0,
        starved: const Duration(hours: 25),
      );

      expect(status.hunger.losingConsciousness, isTrue);
      expect(fatalCause(status), DeathCause.starvation);
    });
  });

  group('§2.3: harsher than hunger, and in both directions', () {
    test('five per cent of body mass costs more than an empty larder', () {
      // §2.3's own instruction: thirst "musi być ostrzejszy niż głód". It was
      // the other way round — hunger was the only one of the two that slowed
      // anybody down, because five and ten per cent had no consequence
      // attached to them at all.
      final starving = statusAfter(caloriesKcal: 0);
      final parched = statusAfter(waterMl: -0.05 * constants.bodyMassKg * 1000);

      expect(parched.thirst.severelyWeakened, isTrue);
      expect(
        parched.actionTimeMultiplier,
        greaterThan(starving.actionTimeMultiplier),
      );
    });

    test('and the critical state costs more again', () {
      final severe = statusAfter(waterMl: -0.05 * constants.bodyMassKg * 1000);
      final critical = statusAfter(
        waterMl: -0.10 * constants.bodyMassKg * 1000,
      );

      expect(
        critical.actionTimeMultiplier,
        greaterThan(severe.actionTimeMultiplier),
      );
    });

    test('a watered character pays nothing', () {
      expect(statusAfter().thirst.actionTimeMultiplier, 1.0);
    });
  });

  group('the clocks over a real run', () {
    SimState run(Duration total, {double drinkMl = 0, double eatKcal = 0}) {
      var state = SimState.fresh(
        at: DateTime.utc(2026),
        constants: constants,
      ).copyWith(pendingWaterMl: drinkMl, pendingKcal: eatKcal);

      return advanceInChunks(
        state: state,
        constants: constants,
        input: const TickInput(),
        elapsed: total,
      ).state;
    }

    test('a day of not drinking is a day on the clock', () {
      final state = run(const Duration(hours: 24));

      expect(state.dryFor.inHours, closeTo(24, 1));
    });

    test('and a swallow puts it back to nought (§2.3)', () {
      // ⚠️ Reset by a mouthful rather than by a full reserve, which is what
      // "brak wody" says. A sip really does restart the countdown to dying of
      // thirst — and does nothing whatever to the deficit, which goes on
      // climbing towards the thresholds underneath. The two rules do not
      // interfere, which is why neither of them is exploitable.
      final state = run(const Duration(hours: 30), drinkMl: 250);

      expect(state.dryFor, lessThan(const Duration(hours: 30)));
      expect(
        state.waterMl,
        lessThan(constants.waterDailyMl),
        reason: 'a sip is not a day of water',
      );
    });

    test('the empty-reserve clock only runs while it is empty', () {
      final fed = run(const Duration(hours: 2));

      expect(fed.starvedFor, Duration.zero, reason: 'the reserve started full');
    });

    test('a fresh character owes nothing on either clock (§11.1.4)', () {
      // What a v26 row loads as. Nought has to read as somebody who has just
      // eaten and drunk, never as somebody two days dry.
      final fresh = SimState.fresh(
        at: DateTime.utc(2026),
        constants: constants,
      );

      expect(fresh.dryFor, Duration.zero);
      expect(fresh.starvedFor, Duration.zero);
      expect(fatalCause(statusOf(state: fresh, constants: constants)), isNull);
    });
  });

  test('the asymmetry the design asks for, in days', () {
    // ⚠️ The answer to "bez jedzenia da się funkcjonować dłuższy czas, ale bez
    // wody ciężko", held as a number rather than as a comment. Neither figure
    // is designed — both fall out of §1.3's constants and §2.3's thresholds.
    //
    // Water: 35 ml/kg is the daily reserve, and ten per cent of body mass is
    // the critical deficit — for this character 2800 ml against 8000, so about
    // three days of complete abstinence at rest, less while walking.
    final criticalDeficitMl = 0.10 * constants.bodyMassKg * 1000;
    final daysToCritical = criticalDeficitMl / constants.waterDailyMl;

    expect(daysToCritical, closeTo(2.9, 0.3));

    // Hunger, by contrast, reaches its own worst tier the day the reserve
    // empties and then stops having anything more to say — which is exactly
    // the gap the body-mass model of the next stage exists to fill.
    expect(
      statusAfter(caloriesKcal: 0, starved: const Duration(days: 30)).hunger,
      isA<HungerState>().having(
        (state) => state.actionTimeMultiplier,
        'a month of starving',
        statusAfter(
          caloriesKcal: 0,
          starved: const Duration(hours: 25),
        ).hunger.actionTimeMultiplier,
      ),
    );
  });
}
