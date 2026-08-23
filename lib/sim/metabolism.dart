/// Energy expenditure and heart rate (design doc §2.2, §2.4).
///
/// The chain is short and entirely mechanical: GPS speed picks a MET band,
/// carried load scales it, and the result drives both calorie burn and the
/// heart rate the body is heading towards. Nothing here is tuned for
/// game feel — the numbers are the published ones, and the difficulty comes
/// from the situation rather than from the constants.
library;

import 'dart:math' as math;

/// Activity bands from §2.2, keyed by ground speed in km/h.
enum ActivityBand {
  standing(0.0, 1.0, 'postój'),
  slowWalk(0.0, 2.0, 'powolny marsz'),
  walk(3.2, 3.5, 'marsz'),
  briskWalk(4.8, 5.0, 'szybki marsz'),
  jog(6.4, 8.3, 'trucht'),
  run(8.0, 9.8, 'bieg'),
  fastRun(9.7, 11.0, 'bieg szybki'),
  sprint(11.3, 14.0, 'sprint');

  const ActivityBand(this.minKmh, this.met, this.label);

  /// Lower bound of the band, inclusive.
  final double minKmh;

  final double met;
  final String label;
}

/// Highest MET the model recognises. Used as the ceiling when converting
/// intensity to heart rate (§2.4).
const double kMetMax = 14.0;

/// MET at complete rest.
const double kMetResting = 1.0;

/// Picks the activity band for a ground speed.
///
/// Standing is a special case: any movement at all, however slow, is at least
/// a slow walk. The 8 m / 10 s dead zone of §3.2 is what decides whether the
/// player is moving; by the time speed reaches here it is already trusted.
ActivityBand bandForSpeed(double kmh) {
  if (kmh <= 0) return ActivityBand.standing;
  if (kmh > 11.3) return ActivityBand.sprint;
  if (kmh > 9.7) return ActivityBand.fastRun;
  if (kmh > 8.0) return ActivityBand.run;
  if (kmh > 6.4) return ActivityBand.jog;
  if (kmh > 4.8) return ActivityBand.briskWalk;
  if (kmh > 3.2) return ActivityBand.walk;
  return ActivityBand.slowWalk;
}

/// Raw MET for a ground speed.
double metForSpeed(double kmh) => bandForSpeed(kmh).met;

/// MET adjusted for what the character is carrying (§2.2).
///
/// `MET_efektywne = MET × (1 + 0.8 × (obciążenie / masa_ciała))`
///
/// A simplification of the Pandolf equation: 20 kg on an 80 kg character is a
/// 20% surcharge. Note that load never slows anyone down — the game cannot
/// slow a real person — it only makes the same distance cost more (§1.3).
double effectiveMet({
  required double met,
  required double loadKg,
  required double bodyMassKg,
}) {
  if (bodyMassKg <= 0 || loadKg <= 0) return met;
  return met * (1 + 0.8 * (loadKg / bodyMassKg));
}

/// Energy burn in kcal per minute (§2.2).
///
/// `kcal/min = MET × 3.5 × masa [kg] / 200`
double kcalPerMinute({required double met, required double bodyMassKg}) =>
    met * 3.5 * bodyMassKg / 200;

/// Energy burn over a duration.
double kcalOver({
  required double met,
  required double bodyMassKg,
  required Duration elapsed,
}) =>
    kcalPerMinute(met: met, bodyMassKg: bodyMassKg) *
    (elapsed.inMicroseconds / Duration.microsecondsPerMinute);

/// Fraction of maximum effort, 0 at rest and 1 at a full sprint (§2.4).
double intensityFraction(double met) =>
    ((met - kMetResting) / (kMetMax - kMetResting)).clamp(0.0, 1.0);

/// Heart rate the body is heading towards at this intensity (§2.4).
///
/// `HR = HR_spoczynkowe + %intensywności × (HR_max − HR_spoczynkowe)`
double targetHeartRate({
  required double met,
  required double restingHr,
  required double maxHr,
}) => restingHr + intensityFraction(met) * (maxHr - restingHr);

/// How far below the resting rate a sleeping heart settles.
///
/// Sleep is not rest with the eyes shut: the heart slows past waking resting
/// by roughly ten to twenty beats, and in a healthy adult can reach the
/// mid-thirties in deep sleep. Without this the game claims a sleeping
/// character's heart never drops below the figure it uses for somebody
/// standing in a kitchen.
const double kSleepHeartRateDrop = 14;

/// The floor, whatever the arithmetic says. Below this is not sleep, it is a
/// cardiology appointment.
const double kSleepHeartRateFloorBpm = 35;

/// Where the heart settles while asleep (§2.4, §2.5).
double sleepingHeartRate(double restingHr) {
  final target = restingHr - kSleepHeartRateDrop;
  return target < kSleepHeartRateFloorBpm ? kSleepHeartRateFloorBpm : target;
}

/// Time constant for heart-rate recovery, ~90 s for an average person (§2.4).
///
/// This one number is why "wait for your heart to slow down" is not a tactic:
/// against a Leaper covering 30 km/h, ninety seconds is nearly a kilometre
/// (§5.1.3).
const Duration kHeartRateTau = Duration(seconds: 90);

/// Relaxes the heart rate towards [target] over [elapsed].
///
/// Exponential, so the result composes: advancing 10 minutes in one step and
/// in six hundred one-second steps land on the same value. The tick engine
/// depends on that for catch-up after an absence.
double relaxHeartRate({
  required double current,
  required double target,
  required Duration elapsed,
  double tauMultiplier = 1,
}) {
  if (elapsed <= Duration.zero) return current;
  final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

  // §2.5.5: a body weeks short of sleep takes longer to settle, which in a
  // game with no stamina bar is a real cost — §2.4's whole point is that the
  // heart *is* the stamina, so a slower recovery is more time spent unable to
  // aim after a run.
  final tau =
      kHeartRateTau.inSeconds * (tauMultiplier <= 0 ? 1 : tauMultiplier);

  final decay = math.exp(-seconds / tau);
  return target + (current - target) * decay;
}

/// Penalties that follow from heart rate (§2.4).
///
/// The player has no stamina bar; the heart rate is what does that job, and it
/// does it by making the weapon harder to aim rather than by slowing anyone
/// down — the one thing the design cannot do (§0).
class HeartRatePenalty {
  const HeartRatePenalty({
    required this.extraMoa,
    required this.reloadTimeMultiplier,
    required this.canAimPrecisely,
    required this.faintRisk,
  });

  /// Added to `MOA_total` (§5.1).
  final double extraMoa;

  final double reloadTimeMultiplier;

  /// False above 85%: the shooter cannot hold a precise sight picture.
  final bool canAimPrecisely;

  /// True above 95%, where a low blood volume can put the character down.
  final bool faintRisk;

  static const none = HeartRatePenalty(
    extraMoa: 0,
    reloadTimeMultiplier: 1.0,
    canAimPrecisely: true,
    faintRisk: false,
  );
}

/// Penalty band for a heart rate, expressed as a fraction of maximum.
HeartRatePenalty heartRatePenalty({
  required double currentHr,
  required double maxHr,
}) {
  if (maxHr <= 0) return HeartRatePenalty.none;
  final ratio = currentHr / maxHr;

  if (ratio < 0.60) return HeartRatePenalty.none;
  if (ratio < 0.75) {
    return const HeartRatePenalty(
      extraMoa: 0.5,
      reloadTimeMultiplier: 1.0,
      canAimPrecisely: true,
      faintRisk: false,
    );
  }
  if (ratio < 0.85) {
    return const HeartRatePenalty(
      extraMoa: 1.5,
      reloadTimeMultiplier: 1.15,
      canAimPrecisely: true,
      faintRisk: false,
    );
  }
  if (ratio < 0.95) {
    return const HeartRatePenalty(
      extraMoa: 3.0,
      reloadTimeMultiplier: 1.30,
      canAimPrecisely: false,
      faintRisk: false,
    );
  }
  return const HeartRatePenalty(
    extraMoa: 5.0,
    reloadTimeMultiplier: 1.30,
    canAimPrecisely: false,
    faintRisk: true,
  );
}
