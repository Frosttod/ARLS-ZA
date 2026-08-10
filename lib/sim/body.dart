/// Character sheet and the clinical formulas derived from it (design doc §1.3).
///
/// The player enters four numbers — sex, age, height, weight — and everything
/// physiological follows from them. No character classes, no stat points: the
/// pillar of §0 says the body is the controller, so the body's real parameters
/// are the character sheet.
///
/// ⚠️ Sex enters only the blood-volume and metabolic-rate formulas, because
/// that is where the clinical literature distinguishes it. Carry weight is
/// deliberately the same for everyone — a fraction of body mass, nothing else.
/// That is a design decision, not an oversight.
library;

import 'dart:math' as math;

import 'tick.dart';

/// Needed by Nadler and Mifflin–St Jeor (§1.3), and by nothing else.
enum Sex {
  male('M'),
  female('F');

  const Sex(this.wire);

  final String wire;

  static Sex fromWire(String value) => values.firstWhere(
    (s) => s.wire == value.toUpperCase(),
    orElse: () => Sex.male,
  );
}

/// How death is handled. Chosen once at creation and never changed — being
/// able to switch would invalidate every Hardcore record (§9).
enum DeathMode {
  hardcore('hardcore'),
  softcore('softcore');

  const DeathMode(this.wire);

  final String wire;

  static DeathMode fromWire(String value) => values.firstWhere(
    (m) => m.wire == value,
    orElse: () => DeathMode.softcore,
  );
}

/// What the player entered. Validated by [BodyValidation] before it gets here.
class BodySpec {
  const BodySpec({
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
  });

  final Sex sex;
  final int ageYears;
  final int heightCm;
  final double weightKg;

  double get heightM => heightCm / 100.0;

  /// Used by the cross-validation of §1.2: a 200 cm / 35 kg character would
  /// otherwise drive every formula into nonsense.
  double get bmi => weightKg / (heightM * heightM);

  BodySpec copyWith({
    Sex? sex,
    int? ageYears,
    int? heightCm,
    double? weightKg,
  }) => BodySpec(
    sex: sex ?? this.sex,
    ageYears: ageYears ?? this.ageYears,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
  );
}

/// Everything derived from a [BodySpec].
class BodyProfile {
  const BodyProfile({
    required this.spec,
    required this.bloodVolumeMl,
    required this.basalMetabolicRateKcal,
    required this.dailyEnergyKcal,
    required this.baseWaterMlPerDay,
    required this.restingHeartRate,
    required this.maxHeartRate,
    required this.carryComfortKg,
    required this.carryMaxKg,
  });

  final BodySpec spec;

  /// Nadler. The number every wound in §2.6 is measured against.
  final double bloodVolumeMl;

  /// Mifflin–St Jeor. Energy at complete rest.
  final double basalMetabolicRateKcal;

  /// Daily requirement shown in the creator and used as the starting reserve
  /// (§2.3). BMR times the light-activity factor.
  final double dailyEnergyKcal;

  /// 35 ml per kilogram (§1.3). Sweat is added dynamically (§2.3).
  final double baseWaterMlPerDay;

  final double restingHeartRate;

  /// Tanaka, which is more accurate than 220 − age.
  final double maxHeartRate;

  /// 30% of body mass. Past this the metabolic cost scales; movement is never
  /// blocked, because the game cannot slow a real person down (§1.3).
  final double carryComfortKg;

  /// 45% of body mass. A hard limit.
  final double carryMaxKg;

  /// Constants the tick engine needs.
  SimConstants toSimConstants() => SimConstants(
    bloodMaxMl: bloodVolumeMl,
    waterDailyMl: baseWaterMlPerDay,
    caloriesDailyKcal: dailyEnergyKcal,
    restingHeartRate: restingHeartRate,
    maxHeartRate: maxHeartRate,
  );

  /// Derives the profile from a validated spec.
  factory BodyProfile.from(BodySpec spec) {
    final h = spec.heightM;
    final w = spec.weightKg;
    final a = spec.ageYears;

    // Nadler, result in litres.
    final bloodL = switch (spec.sex) {
      Sex.male => 0.3669 * h * h * h + 0.03219 * w + 0.6041,
      Sex.female => 0.3561 * h * h * h + 0.03308 * w + 0.1833,
    };

    // Mifflin–St Jeor, height in centimetres.
    final bmr = switch (spec.sex) {
      Sex.male => 10 * w + 6.25 * spec.heightCm - 5 * a + 5,
      Sex.female => 10 * w + 6.25 * spec.heightCm - 5 * a - 161,
    };

    // Resting heart rate is estimated rather than measured: reading it from a
    // sensor would mean collecting health data, and §2.5 rules that out.
    final restingHr = (70 + 0.15 * (spec.bmi - 22) + 0.1 * (a - 30)).clamp(
      50.0,
      95.0,
    );

    return BodyProfile(
      spec: spec,
      bloodVolumeMl: bloodL * 1000,
      basalMetabolicRateKcal: bmr,
      dailyEnergyKcal: bmr * kLightActivityFactor,
      baseWaterMlPerDay: 35.0 * w,
      restingHeartRate: restingHr,
      maxHeartRate: 208 - 0.7 * a,
      carryComfortKg: 0.30 * w,
      carryMaxKg: 0.45 * w,
    );
  }

  /// Multiplier from basal rate to daily requirement.
  ///
  /// 1.375 is the standard light-activity factor. It reproduces the worked
  /// example of §15.4: a 30-year-old male at 180 cm and 80 kg has a BMR of
  /// 1780 kcal and a daily requirement of ~2450 kcal.
  static const double kLightActivityFactor = 1.375;
}

/// Why a spec was rejected. Each maps to a message the creator shows.
enum BodyValidationIssue {
  nameTooShort,
  nameTooLong,
  nameHasInvalidCharacters,
  nameHasEdgeSpaces,
  nameHasDoubleSpaces,
  ageOutOfRange,
  heightOutOfRange,
  weightOutOfRange,
  bmiTooLow,
  bmiTooHigh,
}

/// Limits from §1.2.
abstract final class BodyLimits {
  static const int nameMin = 4;
  static const int nameMax = 16;

  static const int ageMin = 16;
  static const int ageMax = 80;

  static const int heightMinCm = 120;
  static const int heightMaxCm = 220;

  static const double weightMinKg = 35;
  static const double weightMaxKg = 200;

  /// Cross-validation. Outside this band the clinical formulas stop describing
  /// a human being and start producing numbers the game would have to special
  /// case (§1.2).
  static const double bmiMin = 12;
  static const double bmiMax = 60;
}

class BodyValidation {
  const BodyValidation(this.issues);

  final List<BodyValidationIssue> issues;

  bool get isValid => issues.isEmpty;

  bool has(BodyValidationIssue issue) => issues.contains(issue);

  /// Validates the physiological fields.
  static BodyValidation ofSpec(BodySpec spec) {
    final issues = <BodyValidationIssue>[];

    if (spec.ageYears < BodyLimits.ageMin ||
        spec.ageYears > BodyLimits.ageMax) {
      issues.add(BodyValidationIssue.ageOutOfRange);
    }
    if (spec.heightCm < BodyLimits.heightMinCm ||
        spec.heightCm > BodyLimits.heightMaxCm) {
      issues.add(BodyValidationIssue.heightOutOfRange);
    }
    if (spec.weightKg < BodyLimits.weightMinKg ||
        spec.weightKg > BodyLimits.weightMaxKg) {
      issues.add(BodyValidationIssue.weightOutOfRange);
    }

    // Only meaningful once height and weight are themselves sane.
    if (!issues.contains(BodyValidationIssue.heightOutOfRange) &&
        !issues.contains(BodyValidationIssue.weightOutOfRange)) {
      if (spec.bmi < BodyLimits.bmiMin) {
        issues.add(BodyValidationIssue.bmiTooLow);
      } else if (spec.bmi > BodyLimits.bmiMax) {
        issues.add(BodyValidationIssue.bmiTooHigh);
      }
    }

    return BodyValidation(issues);
  }

  /// Validates the character name (§1.2).
  static BodyValidation ofName(String name) {
    final issues = <BodyValidationIssue>[];

    if (name != name.trim()) {
      issues.add(BodyValidationIssue.nameHasEdgeSpaces);
    }
    if (name.contains('  ')) {
      issues.add(BodyValidationIssue.nameHasDoubleSpaces);
    }

    final trimmed = name.trim();
    if (trimmed.length < BodyLimits.nameMin) {
      issues.add(BodyValidationIssue.nameTooShort);
    }
    if (trimmed.length > BodyLimits.nameMax) {
      issues.add(BodyValidationIssue.nameTooLong);
    }

    // Letters include diacritics: the game ships in Polish, and refusing
    // "Zośka" would be a bug rather than a rule.
    if (trimmed.isNotEmpty &&
        !RegExp(r'^[\p{L}\p{N} ]+$', unicode: true).hasMatch(trimmed)) {
      issues.add(BodyValidationIssue.nameHasInvalidCharacters);
    }

    return BodyValidation(issues);
  }
}

/// Sweat loss in millilitres per hour (§2.3).
///
/// `pot = 400 + 200 × (MET − 1) + 50 × max(0, T − 20) + odzież`
///
/// The clothing term is the summed insulation of what is worn, at 100 ml/h per
/// clo above 22 °C. That is what makes a winter jacket in thirty degrees a
/// measurable mistake rather than a piece of flavour text.
double sweatMlPerHour({
  required double met,
  required double ambientTempC,
  double clothingClo = 0,
}) {
  final base = 400 + 200 * (met - 1) + 50 * math.max(0, ambientTempC - 20);
  final clothing = ambientTempC > 22 ? clothingClo * 100 : 0.0;
  return math.max(0, base + clothing);
}
