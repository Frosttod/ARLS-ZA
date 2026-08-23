/// Hunger, thirst, sleep and bleeding (design doc §2.3, §2.5, §2.6).
///
/// Pure functions, all of them. The tick engine composes them; nothing here
/// reads a clock, touches disk or holds state, which is what keeps `advance()`
/// idempotent and replayable (§11.1.2).
library;

import 'dart:math' as math;

/// Penalties from calorie depletion (§2.3).
///
/// Hunger is the gentler of the two: it costs precision and time, and only
/// becomes lethal after a day at zero.
class HungerState {
  const HungerState({
    required this.fraction,
    required this.precisionPenalty,
    required this.actionTimeMultiplier,
    required this.losingConsciousness,
  });

  /// Calories remaining as a fraction of the daily requirement.
  final double fraction;

  /// Multiplier on aim quality: 0.9 means shaking hands cost 10 per cent.
  final double precisionPenalty;

  final double actionTimeMultiplier;

  /// True once the character has been at zero for more than a day.
  final bool losingConsciousness;

  static const healthy = HungerState(
    fraction: 1,
    precisionPenalty: 1.0,
    actionTimeMultiplier: 1.0,
    losingConsciousness: false,
  );
}

HungerState hungerState({
  required double caloriesKcal,
  required double dailyKcal,
  Duration timeAtZero = Duration.zero,
}) {
  if (dailyKcal <= 0) return HungerState.healthy;
  final fraction = (caloriesKcal / dailyKcal).clamp(0.0, double.infinity);

  return HungerState(
    fraction: fraction,
    // Below 50%: −10% precision, the hands start to shake.
    precisionPenalty: fraction < 0.50 ? 0.90 : 1.0,
    // Below 20%: everything takes a fifth longer.
    actionTimeMultiplier: fraction < 0.20 ? 1.20 : 1.0,
    losingConsciousness:
        fraction <= 0 && timeAtZero > const Duration(hours: 24),
  );
}

/// Penalties from dehydration (§2.3).
///
/// ⚠️ Deliberately harsher than hunger. Water is where the realism bites: two
/// per cent of body mass lost is already a measurable hit to accuracy, and
/// forty-eight hours without any under exertion is fatal.
class ThirstState {
  const ThirstState({
    required this.fraction,
    required this.deficitFractionOfBodyMass,
    required this.accuracyPenalty,
    required this.severelyWeakened,
    required this.critical,
    required this.lethal,
    this.actionTimeMultiplier = 1.0,
  });

  /// Water remaining as a fraction of the daily requirement.
  final double fraction;

  /// Deficit expressed as a fraction of body mass, which is the scale the
  /// clinical thresholds use.
  final double deficitFractionOfBodyMass;

  /// Multiplier on accuracy and reaction time.
  final double accuracyPenalty;

  final bool severelyWeakened;
  final bool critical;
  final bool lethal;

  /// §2.3: what "severe weakness" costs, in the only currency §2 measures
  /// anything in.
  ///
  /// ⚠️ Added because five and ten per cent had no consequence at all. §2.3
  /// names three thresholds and only the first — two per cent, the accuracy
  /// penalty — was attached to anything; a character at "stan krytyczny" shot
  /// exactly as well as one merely thirsty and did everything at full speed.
  /// Hunger, which the same paragraph insists must be the *gentler* of the
  /// two, was the only one of the pair that slowed anybody down.
  final double actionTimeMultiplier;

  static const healthy = ThirstState(
    fraction: 1,
    deficitFractionOfBodyMass: 0,
    accuracyPenalty: 1.0,
    severelyWeakened: false,
    critical: false,
    lethal: false,
  );
}

/// §2.3: how long the critical state may be held before it is the end.
///
/// ⚠️ **An extension, and named as one.** §2.3 gives thirst one lethal rule —
/// forty-eight hours without water *under exertion* — and nothing at all for
/// somebody who sits still. The reserve floors at ten per cent of body mass,
/// so without this a character who stops walking survives complete dehydration
/// for ever, which is the one outcome §2.3's own warning ("tu realizm jest
/// bezlitosny") rules out.
///
/// Twelve hours because ten per cent of body mass in water is the point at
/// which the clinical literature stops talking about performance and starts
/// talking about organ failure, and half a day is the generous end of it.
const Duration kCriticalThirstGrace = Duration(hours: 12);

ThirstState thirstState({
  required double waterMl,
  required double dailyMl,
  required double bodyMassKg,
  Duration timeWithoutWater = Duration.zero,
  bool underExertion = false,
}) {
  if (dailyMl <= 0 || bodyMassKg <= 0) return ThirstState.healthy;

  final fraction = (waterMl / dailyMl).clamp(0.0, double.infinity);
  final deficitMl = math.max(0.0, dailyMl - waterMl);

  // 1 ml of water weighs 1 g, so the deficit converts directly to body mass.
  final deficitFraction = (deficitMl / 1000) / bodyMassKg;

  final critical = deficitFraction >= 0.10;

  return ThirstState(
    fraction: fraction,
    deficitFractionOfBodyMass: deficitFraction,
    accuracyPenalty: deficitFraction >= 0.02 ? 0.85 : 1.0,
    severelyWeakened: deficitFraction >= 0.05,
    critical: critical,
    // §2.3: harsher than hunger, in both directions. A fifth longer is what
    // twenty per cent of the day's calories costs; five per cent of body mass
    // in water costs more than that, and ten per cent more again.
    actionTimeMultiplier: critical
        ? 1.60
        : (deficitFraction >= 0.05 ? 1.30 : 1.0),
    // Two ways to die of thirst, and the second is an extension — see
    // [kCriticalThirstGrace].
    lethal:
        (underExertion && timeWithoutWater > const Duration(hours: 48)) ||
        (critical && timeWithoutWater > kCriticalThirstGrace),
  );
}

/// Effects of sleep debt (§2.5.4).
class SleepState {
  const SleepState({
    required this.debt,
    this.readingTimeMultiplier = 1.0,
    this.actionTimeMultiplier = 1.0,
    this.extraMoa = 0,
    this.learningRateMultiplier = 1.0,
    this.microsleeps = false,
  });

  final Duration debt;

  final double readingTimeMultiplier;
  final double actionTimeMultiplier;

  /// Added to `MOA_total` (§5.1).
  final double extraMoa;

  final double learningRateMultiplier;

  /// Above 24 hours: the interface locks for 5–15 s at random.
  final bool microsleeps;

  static const rested = SleepState(debt: Duration.zero);
}

SleepState sleepState(Duration debt) {
  final hours = debt.inMinutes / 60.0;

  if (hours < 4) return SleepState(debt: debt);
  if (hours < 12) {
    return SleepState(debt: debt, readingTimeMultiplier: 1.20, extraMoa: 1.0);
  }
  if (hours < 24) {
    return SleepState(
      debt: debt,
      readingTimeMultiplier: 1.50,
      actionTimeMultiplier: 1.50,
      extraMoa: 3.0,
      learningRateMultiplier: 0.80,
    );
  }
  return SleepState(
    debt: debt,
    readingTimeMultiplier: 1.50,
    actionTimeMultiplier: 1.50,
    extraMoa: 3.0,
    learningRateMultiplier: 0.80,
    microsleeps: true,
  );
}

/// Haemorrhagic shock class, following ATLS (§2.6).
///
/// Blood is the health bar this game does not have. Everything that wounds the
/// character is expressed as millilitres, and the consequences come from the
/// clinical thresholds rather than from a designed curve.
enum ShockClass {
  none(0.0, 'brak objawów'),
  compensated(0.15, 'tachykardia'),
  decompensated(0.30, 'przyciemniony obraz'),
  critical(0.40, 'utrata przytomności');

  const ShockClass(this.lossThreshold, this.label);

  /// Fraction of blood volume lost at which this class begins.
  final double lossThreshold;

  final String label;
}

class BloodState {
  const BloodState({
    required this.volumeMl,
    required this.lossFraction,
    required this.shockClass,
    required this.extraMoa,
    required this.carryPenalty,
    required this.canRunWithoutDizziness,
  });

  final double volumeMl;
  final double lossFraction;
  final ShockClass shockClass;

  final double extraMoa;

  /// Multiplier on carry capacity. Class II costs a tenth of it.
  final double carryPenalty;

  final bool canRunWithoutDizziness;

  /// Class IV: without help, death follows in two to five minutes.
  bool get isFatal => shockClass == ShockClass.critical;
}

BloodState bloodState({required double volumeMl, required double maxMl}) {
  if (maxMl <= 0) {
    return const BloodState(
      volumeMl: 0,
      lossFraction: 1,
      shockClass: ShockClass.critical,
      extraMoa: 0,
      carryPenalty: 1,
      canRunWithoutDizziness: false,
    );
  }

  final loss = (1 - volumeMl / maxMl).clamp(0.0, 1.0);

  final (shock, moa, carry, canRun) = switch (loss) {
    < 0.15 => (ShockClass.none, 0.0, 1.0, true),
    < 0.30 => (ShockClass.compensated, 2.0, 0.90, true),
    < 0.40 => (ShockClass.decompensated, 5.0, 0.90, false),
    _ => (ShockClass.critical, 5.0, 0.90, false),
  };

  return BloodState(
    volumeMl: volumeMl,
    lossFraction: loss,
    shockClass: shock,
    extraMoa: moa,
    carryPenalty: carry,
    canRunWithoutDizziness: canRun,
  );
}

/// Bleeding severity (§2.6). Each tier has its own rate and its own answer.
enum BleedTier {
  none(0, 'brak'),
  superficial(3, 'powierzchowne'),
  moderate(25, 'umiarkowane'),
  severe(90, 'silne'),
  arterial(350, 'tętnicze');

  const BleedTier(this.mlPerMinute, this.label);

  /// Base loss rate before the exertion modifier.
  final double mlPerMinute;

  final String label;

  /// Superficial wounds close on their own; everything else needs treatment,
  /// and an arterial bleed needs a tourniquet specifically.
  bool get stopsOnItsOwn =>
      this == BleedTier.superficial || this == BleedTier.none;

  static BleedTier fromWire(String value) =>
      values.firstWhere((t) => t.name == value, orElse: () => BleedTier.none);
}

/// Effective blood loss rate (§2.6).
///
/// `ubytek_efektywny = ubytek_bazowy × (HR_aktualne / HR_spoczynkowe)`
///
/// Running with an open wound is not a flavour detail: at 160 bpm against a
/// resting 70, the bleed is 2.3 times faster.
double bleedMlPerMinute({
  required BleedTier tier,
  required double currentHr,
  required double restingHr,
}) {
  if (tier == BleedTier.none) return 0;
  if (restingHr <= 0) return tier.mlPerMinute;
  return tier.mlPerMinute * math.max(1.0, currentHr / restingHr);
}

/// Blood lost over a duration.
double bleedOver({
  required BleedTier tier,
  required double currentHr,
  required double restingHr,
  required Duration elapsed,
}) =>
    bleedMlPerMinute(tier: tier, currentHr: currentHr, restingHr: restingHr) *
    (elapsed.inMicroseconds / Duration.microsecondsPerMinute);

/// Sweat driven by the environment alone — heat and what is being worn.
///
/// Split out from [sweatMlPerHour] because the two halves apply at different
/// times. Heat and clothing cost water whether or not the character is moving;
/// the 400 ml/h constant in the full formula is a rate *while active* and
/// would be absurd applied to someone asleep in a shelter.
double environmentalSweatMlPerHour({
  required double ambientTempC,
  double clothingClo = 0,
}) {
  final heat = 50 * math.max(0, ambientTempC - 20);
  final clothing = ambientTempC > 22 ? clothingClo * 100 : 0.0;
  return heat + clothing;
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
