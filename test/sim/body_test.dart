import 'package:arls_za/sim/body.dart';
import 'package:test/test.dart';

/// The worked example the design document uses throughout (§1.3, §15.4):
/// male, 30 years, 180 cm, 80 kg. Every figure below is quoted from there, so
/// a failure here means the code and the document have diverged.
const reference = BodySpec(
  sex: Sex.male,
  ageYears: 30,
  heightCm: 180,
  weightKg: 80,
);

void main() {
  group('BodyProfile — the design document worked example', () {
    final profile = BodyProfile.from(reference);

    test('blood volume, Nadler: 5319 ml', () {
      expect(profile.bloodVolumeMl, closeTo(5319, 1));
    });

    test('daily water requirement: 2800 ml', () {
      expect(profile.baseWaterMlPerDay, 2800);
    });

    test('daily energy requirement: 2450 kcal', () {
      expect(profile.dailyEnergyKcal, closeTo(2450, 25));
    });

    test('basal metabolic rate, Mifflin–St Jeor: 1780 kcal', () {
      expect(profile.basalMetabolicRateKcal, closeTo(1780, 1));
    });

    test('maximum heart rate, Tanaka: 187 bpm', () {
      expect(profile.maxHeartRate, closeTo(187, 0.5));
    });

    test('carry weight: 24 kg comfortable, 36 kg limit', () {
      expect(profile.carryComfortKg, 24);
      expect(profile.carryMaxKg, 36);
    });
  });

  group('formulas', () {
    test('sex changes blood volume and metabolic rate', () {
      final male = BodyProfile.from(reference);
      final female = BodyProfile.from(reference.copyWith(sex: Sex.female));

      expect(female.bloodVolumeMl, lessThan(male.bloodVolumeMl));
      expect(
        female.basalMetabolicRateKcal,
        closeTo(male.basalMetabolicRateKcal - 166, 0.1),
      );
    });

    test('carry weight is the same regardless of sex', () {
      final male = BodyProfile.from(reference);
      final female = BodyProfile.from(reference.copyWith(sex: Sex.female));

      expect(
        female.carryComfortKg,
        male.carryComfortKg,
        reason:
            'carry weight is a fraction of body mass and nothing else — '
            'a deliberate design decision, not an omission',
      );
      expect(female.carryMaxKg, male.carryMaxKg);
    });

    test('water scales linearly with mass', () {
      final light = BodyProfile.from(reference.copyWith(weightKg: 50));
      final heavy = BodyProfile.from(reference.copyWith(weightKg: 100));

      expect(light.baseWaterMlPerDay, 1750);
      expect(heavy.baseWaterMlPerDay, 3500);
    });

    test('maximum heart rate falls with age', () {
      final young = BodyProfile.from(reference.copyWith(ageYears: 20));
      final old = BodyProfile.from(reference.copyWith(ageYears: 70));

      expect(young.maxHeartRate, closeTo(194, 0.5));
      expect(old.maxHeartRate, closeTo(159, 0.5));
    });

    test('resting heart rate stays inside 50–95 bpm', () {
      for (final spec in [
        reference,
        reference.copyWith(ageYears: 16, weightKg: 40, heightCm: 200),
        reference.copyWith(ageYears: 80, weightKg: 190, heightCm: 160),
      ]) {
        final hr = BodyProfile.from(spec).restingHeartRate;
        expect(hr, inInclusiveRange(50, 95));
      }
    });

    test('produces usable SimConstants', () {
      final constants = BodyProfile.from(reference).toSimConstants();

      expect(constants.bloodMaxMl, closeTo(5319, 1));
      expect(constants.waterDailyMl, 2800);
      expect(constants.maxHeartRate, closeTo(187, 0.5));
    });
  });

  group('validation — physiology (§1.2)', () {
    test('accepts the reference character', () {
      expect(BodyValidation.ofSpec(reference).isValid, isTrue);
    });

    test('rejects an age outside 16–80', () {
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(ageYears: 15),
        ).has(BodyValidationIssue.ageOutOfRange),
        isTrue,
      );
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(ageYears: 81),
        ).has(BodyValidationIssue.ageOutOfRange),
        isTrue,
      );
      expect(
        BodyValidation.ofSpec(reference.copyWith(ageYears: 16)).isValid,
        isTrue,
      );
    });

    test('rejects a height outside 120–220 cm', () {
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(heightCm: 119),
        ).has(BodyValidationIssue.heightOutOfRange),
        isTrue,
      );
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(heightCm: 221),
        ).has(BodyValidationIssue.heightOutOfRange),
        isTrue,
      );
    });

    test('rejects a weight outside 35–200 kg', () {
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(weightKg: 34),
        ).has(BodyValidationIssue.weightOutOfRange),
        isTrue,
      );
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(weightKg: 201),
        ).has(BodyValidationIssue.weightOutOfRange),
        isTrue,
      );
    });

    test('rejects the 200 cm / 35 kg combination the document names', () {
      final absurd = BodyValidation.ofSpec(
        reference.copyWith(heightCm: 200, weightKg: 35),
      );

      expect(absurd.isValid, isFalse);
      expect(
        absurd.has(BodyValidationIssue.bmiTooLow),
        isTrue,
        reason: 'each field is in range; only the cross-check catches this',
      );
    });

    test('rejects a BMI above 60', () {
      expect(
        BodyValidation.ofSpec(
          reference.copyWith(heightCm: 150, weightKg: 190),
        ).has(BodyValidationIssue.bmiTooHigh),
        isTrue,
      );
    });

    test('does not report BMI when height or weight is already invalid', () {
      final issues = BodyValidation.ofSpec(
        reference.copyWith(weightKg: 5),
      ).issues;

      expect(issues, contains(BodyValidationIssue.weightOutOfRange));
      expect(
        issues,
        isNot(contains(BodyValidationIssue.bmiTooLow)),
        reason: 'one mistake should produce one message',
      );
    });
  });

  group('validation — name (§1.2)', () {
    test('accepts an ordinary name', () {
      expect(BodyValidation.ofName('Ocalały').isValid, isTrue);
      expect(BodyValidation.ofName('Anna Kowalska').isValid, isTrue);
      expect(BodyValidation.ofName('Zośka 7').isValid, isTrue);
    });

    test('enforces the 4–16 character length', () {
      expect(
        BodyValidation.ofName('Jan').has(BodyValidationIssue.nameTooShort),
        isTrue,
      );
      expect(
        BodyValidation.ofName(
          'Bardzo Długa Nazwa Postaci',
        ).has(BodyValidationIssue.nameTooLong),
        isTrue,
      );
    });

    test('rejects leading, trailing and doubled spaces', () {
      expect(
        BodyValidation.ofName(
          ' Anna',
        ).has(BodyValidationIssue.nameHasEdgeSpaces),
        isTrue,
      );
      expect(
        BodyValidation.ofName(
          'Anna ',
        ).has(BodyValidationIssue.nameHasEdgeSpaces),
        isTrue,
      );
      expect(
        BodyValidation.ofName(
          'Anna  Kowal',
        ).has(BodyValidationIssue.nameHasDoubleSpaces),
        isTrue,
      );
    });

    test('rejects punctuation and symbols', () {
      expect(
        BodyValidation.ofName(
          'Anna<script>',
        ).has(BodyValidationIssue.nameHasInvalidCharacters),
        isTrue,
      );
      expect(
        BodyValidation.ofName(
          'Ala_Ma_Kota',
        ).has(BodyValidationIssue.nameHasInvalidCharacters),
        isTrue,
      );
    });

    test('accepts Polish diacritics', () {
      expect(
        BodyValidation.ofName('Żółć Gęślą').isValid,
        isTrue,
        reason: 'the game ships in Polish; refusing "Zośka" would be a bug',
      );
    });
  });

  group('sweat (§2.3)', () {
    test('resting at 20 °C loses the base rate', () {
      expect(sweatMlPerHour(met: 1, ambientTempC: 20), 400);
    });

    test('effort raises the loss', () {
      final walking = sweatMlPerHour(met: 3.5, ambientTempC: 20);
      final running = sweatMlPerHour(met: 9.8, ambientTempC: 20);

      expect(walking, 900);
      expect(running, greaterThan(walking));
    });

    test('heat raises the loss above 20 °C only', () {
      expect(sweatMlPerHour(met: 1, ambientTempC: 10), 400);
      expect(sweatMlPerHour(met: 1, ambientTempC: 30), 900);
    });

    test('a winter jacket in thirty degrees is measurably a mistake', () {
      final bare = sweatMlPerHour(met: 3.5, ambientTempC: 30);
      final coated = sweatMlPerHour(
        met: 3.5,
        ambientTempC: 30,
        clothingClo: 3.5,
      );

      expect(coated - bare, 350);
    });

    test('clothing costs nothing at or below 22 °C', () {
      expect(
        sweatMlPerHour(met: 1, ambientTempC: 22, clothingClo: 3.5),
        sweatMlPerHour(met: 1, ambientTempC: 22),
      );
    });
  });
}
