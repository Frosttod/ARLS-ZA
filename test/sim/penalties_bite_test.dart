import 'dart:io';

import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/action_pace.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/metabolism.dart';
import 'package:arls_za/sim/physiology.dart';
import 'package:arls_za/sim/tick.dart';
import 'package:test/test.dart';

/// KARY ZA STAN MUSZĄ GRYŹĆ (§2.3, §2.5.4, §5.1.1).
///
/// ⚠️ **Three penalties in §2 were computed every tick and reached nothing.**
///
/// Found while planning the long-term physiology, and worth writing down
/// because all three had the same shape — a figure with no consumer:
///
///   1. `conditionMoa` on `aimError` had a default of nought and no call site
///      ever passed it, so §2.5.4's three minutes of arc for a day without
///      sleep and §2.6's for blood loss were drawn on the profile screen and
///      thrown away before a shot was resolved.
///   2. `SimStatus.actionTimeMultiplier` was read by the HUD and by the status
///      notes, and by nothing that measures a duration. "+20% to the time of
///      every action" lengthened no action.
///   3. `BodyProfile.toSimConstants` left `bodyMassKg` out, and it defaults to
///      eighty — so §2.3's dehydration thresholds, which are fractions of body
///      mass, measured every character against an eighty-kilogram person.
///
/// A number nobody reads is worse than a missing feature: the interface says
/// the penalty is happening, so the player plays around a rule that is not
/// there. These tests hold each of the three to a consumer.
void main() {
  group('§2.3, §2.5.4: the multiplier meets a clock', () {
    test('a worn-out body credits less than a second per second', () {
      // The status side of it: a fifth longer is four fifths the rate.
      final status = SimStatus(
        blood: bloodState(volumeMl: 5000, maxMl: 5000),
        hunger: hungerState(caloriesKcal: 100, dailyKcal: 2500),
        thirst: ThirstState.healthy,
        sleep: sleepState(const Duration(hours: 18)),
        heartRate: heartRatePenalty(currentHr: 60, maxHr: 190),
      );

      expect(status.actionTimeMultiplier, closeTo(1.20 * 1.50, 0.0001));
      expect(status.workRate, closeTo(1 / (1.20 * 1.50), 0.0001));
    });

    test('a healthy body is exactly one, never nearly one', () {
      // ⚠️ Exactly, because this multiplies every duration in the game. A
      // rate of 0.999 would make a healthy character quietly slower than the
      // figures printed on every screen.
      const status = SimStatus(
        blood: BloodState(
          volumeMl: 5000,
          lossFraction: 0,
          shockClass: ShockClass.none,
          extraMoa: 0,
          carryPenalty: 1,
          canRunWithoutDizziness: true,
        ),
        hunger: HungerState.healthy,
        thirst: ThirstState.healthy,
        sleep: SleepState.rested,
        heartRate: HeartRatePenalty.none,
      );

      expect(status.workRate, 1);
    });

    test('and a search really does take longer for it (§10.2)', () {
      // The consumer. This is the assertion the three dead figures were
      // missing: a duration that changes when the body does.
      const at = GeoPoint(52.4, 16.9);

      Search after(Duration wall, double rate) {
        var search = Search.area(at: at, now: DateTime.utc(2026));
        for (var i = 0; i < wall.inSeconds; i++) {
          search = search.advance(
            const Duration(seconds: 1),
            at: at,
            rate: rate,
          );
        }
        return search;
      }

      final rested = after(const Duration(seconds: 30), 1);
      final wrecked = after(const Duration(seconds: 30), 1 / 1.5);

      expect(wrecked.elapsed.inSeconds, lessThan(rested.elapsed.inSeconds));
      expect(wrecked.elapsed.inSeconds, closeTo(20, 1));
    });

    test('but standing still is still standing still', () {
      // ⚠️ The strike rule counts real seconds. Being worn out does not make
      // a player less present — it makes their work worth less, which is a
      // different thing, and conflating them would have a tired character
      // failing §10.2's stillness test by standing perfectly still.
      const at = GeoPoint(52.4, 16.9);
      const away = GeoPoint(52.41, 16.9);

      var search = Search.area(at: at, now: DateTime.utc(2026));
      for (var i = 0; i < kStillnessStrikes; i++) {
        search = search.advance(
          const Duration(seconds: 1),
          at: away,
          rate: 1 / 1.5,
        );
      }

      expect(search.state, SearchState.cancelledByMovement);
    });

    test('a rate of nought stops the clock rather than reversing it', () {
      const at = GeoPoint(52.4, 16.9);

      final search = Search.area(
        at: at,
        now: DateTime.utc(2026),
      ).advance(const Duration(seconds: 10), at: at, rate: 0);

      expect(search.elapsed, Duration.zero);
      expect(search.isRunning, isTrue);
    });
  });

  group('§2.3, §2.5.4: the body slows its own hands too', () {
    test('the pace rate carries the body as well as the world', () {
      // Both, multiplied. A hungry person dressing a wound while walking is
      // slowed by two different things happening to the same hands.
      final walking = rateFor(
        ActionPace.handsOn,
        const PaceContext(speedKmh: 4, bodyRate: 0.5),
      );

      expect(walking, closeTo(1 / kPaceWalking * 0.5, 0.0001));
    });

    test('and a stopped clock stays stopped', () {
      // Nought times anything is nought: a search away from where it started
      // is not a slower search.
      expect(
        rateFor(
          ActionPace.onTheSpot,
          const PaceContext(atStartingPlace: false, bodyRate: 0.5),
        ),
        0,
      );
    });

    test('a body nobody asked about changes nothing', () {
      // The default has to be the identity, or every existing call site would
      // quietly become a penalty.
      expect(rateFor(ActionPace.unattended, const PaceContext()), 1);
    });
  });

  group('§2.3: the thresholds belong to this character', () {
    BodyProfile profileOf(double weightKg) => BodyProfile.from(
      BodySpec(
        sex: Sex.female,
        ageYears: 30,
        heightCm: 165,
        weightKg: weightKg,
      ),
    );

    test('body mass reaches the simulation at all', () {
      expect(profileOf(55).toSimConstants().bodyMassKg, 55);
      expect(profileOf(95).toSimConstants().bodyMassKg, 95);
    });

    test('and a lighter character reaches two per cent sooner (§2.3)', () {
      // ⚠️ The whole point of the missing field. Two per cent of body mass is
      // 1100 ml for a 55 kg character and 1900 for a 95 kg one — most of a
      // day of difference, and every character was being given the heavier
      // figure.
      ThirstState after(double weightKg, double drunkMl) {
        final constants = profileOf(weightKg).toSimConstants();
        return thirstState(
          waterMl: drunkMl,
          dailyMl: constants.waterDailyMl,
          bodyMassKg: constants.bodyMassKg,
        );
      }

      // A deficit of 1300 ml: past two per cent for the lighter character and
      // not for the heavier one.
      final light = after(55, 55 * 35 - 1300);
      final heavy = after(95, 95 * 35 - 1300);

      expect(light.accuracyPenalty, lessThan(1));
      expect(heavy.accuracyPenalty, 1);
    });
  });

  test('§5.1.1: nothing may take the body out of the shot again', () {
    // ⚠️ Source-level, in the same spirit as the one-action and sticky-
    // position budgets. The defect was not a wrong number, it was a parameter
    // with a harmless default that nobody filled in — which no test of the
    // function itself can catch, because the function was always right.
    final main = File('lib/main.dart').readAsStringSync();

    expect(
      main.contains('conditionMoa: '),
      isTrue,
      reason: 'the body stopped contributing to the aim error again',
    );
    expect(
      main.contains('rate: snapshot?.status.workRate'),
      isTrue,
      reason: 'hunger and sleep debt stopped lengthening anything again',
    );
  });
}
