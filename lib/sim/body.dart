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
/// What a self-reported resting heart rate may be.
///
/// Wide on purpose: an endurance athlete at rest can sit in the high thirties
/// and somebody unwell can sit near a hundred. The range exists to catch a
/// typo, not to tell anybody what their heart should be doing.
const int kRestingHrMin = 35;
const int kRestingHrMax = 110;

class BodySpec {
  const BodySpec({
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    this.measuredRestingHr,
  });

  final Sex sex;
  final int ageYears;
  final int heightCm;
  final double weightKg;

  /// The player's own resting heart rate, in beats per minute, or null to let
  /// §1.3's estimate stand.
  ///
  /// §1.3 estimates it precisely because the game has no data and will not
  /// read a sensor: that would be collecting health data (§2.5), and it does
  /// not. But a player who *knows* their own is not a sensor — a figure typed
  /// in once is the same kind of self-reported number as height and weight,
  /// and it stays on the device with them.
  ///
  /// It matters more than it looks. Everything the heart rate does — the
  /// recovery curve of §2.4, the accuracy penalties, the bleeding rate of
  /// §2.6 — is measured from this floor. A bradycardic player at 58 given an
  /// estimated 72 is told their heart never settles, because in the model it
  /// never does.
  final int? measuredRestingHr;

  double get heightM => heightCm / 100.0;

  /// Used by the cross-validation of §1.2: a 200 cm / 35 kg character would
  /// otherwise drive every formula into nonsense.
  double get bmi => weightKg / (heightM * heightM);

  BodySpec copyWith({
    Sex? sex,
    int? ageYears,
    int? heightCm,
    double? weightKg,
    int? measuredRestingHr,
    bool clearMeasuredRestingHr = false,
  }) => BodySpec(
    sex: sex ?? this.sex,
    ageYears: ageYears ?? this.ageYears,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    measuredRestingHr: clearMeasuredRestingHr
        ? null
        : measuredRestingHr ?? this.measuredRestingHr,
  );

  /// A character sheet is a value: two sheets with the same four figures are
  /// the same character, whether one came from the creator and the other from
  /// a row read back off disk.
  @override
  bool operator ==(Object other) =>
      other is BodySpec &&
      other.sex == sex &&
      other.ageYears == ageYears &&
      other.heightCm == heightCm &&
      other.weightKg == weightKg &&
      other.measuredRestingHr == measuredRestingHr;

  @override
  int get hashCode =>
      Object.hash(sex, ageYears, heightCm, weightKg, measuredRestingHr);
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
  ///
  /// ⚠️ [SimConstants.bodyMassKg] used to be left out, and it has a default of
  /// eighty. §2.3's dehydration thresholds are fractions of *body mass* — two
  /// per cent for the accuracy penalty, ten for the critical state — so every
  /// character in the game was being measured against an eighty-kilogram
  /// person regardless of what the player typed on the character sheet. A
  /// fifty-five kilogram character was given the thresholds of somebody
  /// twenty-five kilos heavier, which is most of a day of extra grace.
  SimConstants toSimConstants() => SimConstants(
    bloodMaxMl: bloodVolumeMl,
    waterDailyMl: baseWaterMlPerDay,
    caloriesDailyKcal: dailyEnergyKcal,
    restingHeartRate: restingHeartRate,
    maxHeartRate: maxHeartRate,
    bodyMassKg: spec.weightKg,
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

    // Estimated only when the player has not told us better. Reading it from a
    // sensor would be collecting health data and §2.5 rules that out; a number
    // somebody types in themselves is a different thing entirely.
    final restingHr =
        spec.measuredRestingHr?.toDouble() ??
        (70 + 0.15 * (spec.bmi - 22) + 0.1 * (a - 30)).clamp(50.0, 95.0);

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
