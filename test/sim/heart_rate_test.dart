import 'package:arls_za/sim/body.dart';
import 'package:arls_za/sim/metabolism.dart';
import 'package:test/test.dart';

/// §2.4. The heart rate is the game's stamina bar, and everything measured
/// against it — the accuracy penalties, the bleeding rate of §2.6, the wait
/// before a shot is worth taking — is measured from where it settles. Getting
/// that floor wrong is not a cosmetic error.
void main() {
  BodyProfile profileOf({int? measuredRestingHr}) => BodyProfile.from(
    BodySpec(
      sex: Sex.male,
      ageYears: 40,
      heightCm: 180,
      weightKg: 80,
      measuredRestingHr: measuredRestingHr,
    ),
  );

  group('where the heart settles', () {
    test('§1.3 estimates it when nobody has said otherwise', () {
      expect(profileOf().restingHeartRate, closeTo(71.8, 0.5));
    });

    test('a player who knows their own is believed', () {
      // Bradycardia is common and the estimate has no way to see it. Told 58,
      // the model uses 58.
      expect(profileOf(measuredRestingHr: 58).restingHeartRate, 58);
    });

    test('and it changes what recovery means, not just the number', () {
      // The complaint that started this: "my heart rate falls too slowly."
      // The rate was right — the floor was 14 bpm too high, and an exponential
      // curve crawls once it is near its target. Same 90 s constant, same one
      // minute of standing still, two very different readings.
      final estimated = relaxHeartRate(
        current: 100,
        target: profileOf().restingHeartRate,
        elapsed: const Duration(minutes: 1),
      );
      final measured = relaxHeartRate(
        current: 100,
        target: profileOf(measuredRestingHr: 58).restingHeartRate,
        elapsed: const Duration(minutes: 1),
      );

      expect(estimated, greaterThan(85));
      expect(measured, lessThan(80));
    });
  });

  group('recovery after effort (§2.4)', () {
    test('is faster than the clinical figure for a healthy person', () {
      // HRR1 — the drop in the first minute — is 15 to 25 bpm in a healthy
      // adult and 25 to 40 in an athlete. From a hard effort the model gives
      // more than either, which is the right side to err on for a game.
      final after = relaxHeartRate(
        current: 160,
        target: 72,
        elapsed: const Duration(minutes: 1),
      );

      expect(160 - after, greaterThan(40));
    });

    test('and slows as it approaches, because that is what hearts do', () {
      final fromHard =
          160 -
          relaxHeartRate(
            current: 160,
            target: 72,
            elapsed: const Duration(minutes: 1),
          );
      final fromEasy =
          100 -
          relaxHeartRate(
            current: 100,
            target: 72,
            elapsed: const Duration(minutes: 1),
          );

      expect(fromHard, greaterThan(fromEasy * 2));
    });

    test('composes, so a catch-up lands where the seconds would have', () {
      var stepwise = 160.0;
      for (var i = 0; i < 300; i++) {
        stepwise = relaxHeartRate(
          current: stepwise,
          target: 60,
          elapsed: const Duration(seconds: 1),
        );
      }
      final atOnce = relaxHeartRate(
        current: 160,
        target: 60,
        elapsed: const Duration(minutes: 5),
      );

      expect(stepwise, closeTo(atOnce, 0.01));
    });
  });

  group('asleep', () {
    test('the heart goes below waking rest, not down to it', () {
      // A sleeping heart is not a resting one. Claiming otherwise told a
      // player their pulse never drops below the figure used for somebody
      // standing in a kitchen.
      expect(sleepingHeartRate(72), 58);
      expect(sleepingHeartRate(60), 46);
    });

    test('but never below what a person survives', () {
      expect(sleepingHeartRate(40), kSleepHeartRateFloorBpm);
      expect(sleepingHeartRate(35), kSleepHeartRateFloorBpm);
    });

    test('a slow-hearted player sleeps slower still, within reason', () {
      final ordinary = sleepingHeartRate(profileOf().restingHeartRate);
      final bradycardic = sleepingHeartRate(
        profileOf(measuredRestingHr: 58).restingHeartRate,
      );

      expect(bradycardic, lessThan(ordinary));
      expect(bradycardic, greaterThanOrEqualTo(kSleepHeartRateFloorBpm));
    });
  });
}
