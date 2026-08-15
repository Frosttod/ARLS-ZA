/// Whether the shot lands, and what it does (§5.1, §5.1.5).
///
/// The whole of §5.1 rests on one sentence: **a calm, still shooter hits
/// reliably**, and the game is hard because it almost never gives anybody calm
/// and stillness. Nothing here fudges the odds downwards to make combat
/// interesting — the difficulty is the player's own pulse and the thing
/// running at them, which is a fight against a body rather than against a
/// random number generator.
///
/// ⚠️ **MOA is the diameter of the group, never the radius.** §5.1 says so in
/// bold because confusing the two moves the hit chance by about a factor of
/// three, and every number in §5.1.2's calibration table assumes diameter.
///
/// Errors compose as the root of the sum of squares: five sources of one
/// minute of angle are not five minutes of angle, and treating them as though
/// they were would make a walking novice unable to hit a wall.
library;

import 'dart:math' as math;

/// What is being shot at, in metres (§5.1).
enum TargetSize {
  /// The default of §5.1.2's table.
  torso(width: 0.50, height: 0.65),

  /// A whole person, for anything that is not a deliberate aimed shot.
  silhouette(width: 0.55, height: 1.75);

  const TargetSize({required this.width, required this.height});

  final double width;
  final double height;
}

/// Where the error in a shot comes from (§5.1.1).
///
/// Kept apart rather than summed on the way in, because §5.1.4 makes showing
/// the *largest* source a hard requirement: a player who misses five times at
/// 26% must be able to see that it was their pulse, not the game.
enum ErrorSource { weapon, skill, heart, movement, target, condition }

/// The error budget of one shot, in minutes of angle.
class ShotError {
  const ShotError({
    required this.weapon,
    required this.skill,
    required this.heart,
    required this.movement,
    required this.target,
    this.condition = 0,
  });

  /// §5.1.1: what the rifle itself does, from the item's `moa` prop.
  final double weapon;

  /// §5.1.1: 25 MOA at no skill, 4 at complete mastery. Even a practised
  /// shooter standing unsupported does not do better than about four.
  final double skill;

  /// §5.1.1, squared in the heart rate: nothing below about 60% of the way to
  /// maximum, and everything above 85%.
  final double heart;

  /// §5.1.1: the player's own speed, which is the largest number in the table
  /// by a distance.
  final double movement;

  /// §5.1.1: the target's, and small — the thing is running *at* the shooter,
  /// so most of its speed is closing rather than crossing.
  final double target;

  /// §2.5 and §2.6: sleep debt and blood loss.
  final double condition;

  double get(ErrorSource source) => switch (source) {
    ErrorSource.weapon => weapon,
    ErrorSource.skill => skill,
    ErrorSource.heart => heart,
    ErrorSource.movement => movement,
    ErrorSource.target => target,
    ErrorSource.condition => condition,
  };

  /// §5.1: the root of the sum of squares.
  double get total {
    var sum = 0.0;
    for (final source in ErrorSource.values) {
      final value = get(source);
      sum += value * value;
    }
    return math.sqrt(sum);
  }

  /// §5.1.4: what the HUD names beside the percentage.
  ///
  /// The largest single contributor, which is what the player can actually do
  /// something about — standing still, waiting, or not taking the shot.
  ErrorSource get dominant {
    var worst = ErrorSource.weapon;
    for (final source in ErrorSource.values) {
      if (get(source) > get(worst)) worst = source;
    }
    return worst;
  }
}

/// §5.1.1: 25 MOA at no skill, 4 at full, straight between.
double skillMoa(double skill) => 25 - 21 * skill.clamp(0.0, 1.0);

/// §5.1.1: `60 × ((HR − HR_rest) / (HR_max − HR_rest))²`.
///
/// Squared, which is the whole point of §5.1.3: a walk up to a shot costs
/// almost nothing, and a sprint away from something costs everything. There is
/// no waiting it out either — §2.4 puts the recovery constant at ninety
/// seconds and §6.1 puts a Walker sixteen kilometres an hour away.
double heartMoa(double heartRate, {required double rest, required double max}) {
  final span = max - rest;
  if (span <= 0) return 0;

  final over = ((heartRate - rest) / span).clamp(0.0, 1.0);
  return 60 * over * over;
}

/// §5.1.1: `8 × v^1.2`, with v in km/h. A walk is 55 MOA and a run is 165.
double movementMoa(double speedKmh) =>
    speedKmh <= 0 ? 0 : 8 * math.pow(speedKmh, 1.2).toDouble();

/// §5.1.1: `2 × v × 0.3`. Small, because it is coming towards you.
double targetMoa(double speedKmh) => speedKmh <= 0 ? 0 : 0.6 * speedKmh;

/// The diameter of the group at this range, in metres (§5.1).
double spreadDiameterM(double moa, double distanceM) =>
    moa * distanceM * 2.9089e-4;

/// §5.1: `P = [2Φ(W/2σ) − 1] × [2Φ(H/2σ) − 1]`, with `σ = D/4`.
///
/// Extreme spread is about four standard deviations, which is where the four
/// comes from. Width and height are taken separately because a torso is not a
/// circle and a silhouette is nothing like one.
double hitChance({
  required double moa,
  required double distanceM,
  TargetSize target = TargetSize.torso,
}) {
  if (distanceM <= 0) return 1;

  final sigma = spreadDiameterM(moa, distanceM) / 4;
  if (sigma <= 0) return 1;

  final across = 2 * _phi(target.width / 2 / sigma) - 1;
  final down = 2 * _phi(target.height / 2 / sigma) - 1;
  return (across * down).clamp(0.0, 1.0);
}

/// §5.1.5: `5.1 × J^0.6 × wound_factor × location × (1 − protection)`.
///
/// ⚠️ The exponent is the point. A linear model would always punish small
/// calibres and flatter large ones, and the whole weapon hierarchy of §5.1.5 —
/// a pistol that works but eats ammunition, a carbine as the standard, a
/// hunting rifle for Brutes — comes out of that six-tenths.
double bloodLossMl({
  required double energyJ,
  required double woundFactor,
  double locationMultiplier = 1,
  double protection = 0,
}) {
  if (energyJ <= 0) return 0;

  return 5.1 *
      math.pow(energyJ, 0.6) *
      woundFactor *
      locationMultiplier *
      (1 - protection.clamp(0.0, 1.0));
}

/// The standard normal distribution function.
///
/// Abramowitz and Stegun 7.1.26 through an error function: good to about
/// 1.5e-7, which is several digits more than a hit chance shown as a whole
/// percentage can use.
double _phi(double x) => 0.5 * (1 + _erf(x / math.sqrt2));

double _erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final value = x.abs();

  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  final t = 1 / (1 + p * value);
  final y =
      1 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
          t *
          math.exp(-value * value);

  return sign * y;
}
