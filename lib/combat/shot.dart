/// One shot, from trigger to consequence (§5.1, §5.1.5, §5.6).
///
/// A shot costs three things and the game has to charge all three: a round,
/// which is the scarcest thing in the world (§5.1.5's ammunition economy); the
/// wound it does or does not make; and the noise, which is what walks towards
/// the sound afterwards (§5.6). Charging only the first two would make a rifle
/// strictly better than a knife, and §5.6.3 is built on it not being.
///
/// The roll is the last thing that happens and the only random part. Everything
/// before it — the error budget, the chance, the wound — is arithmetic the
/// player can see in the HUD before they decide (§5.1.4), because a model this
/// unforgiving is only fair while it is legible.
library;

import 'dart:math';

import '../items/item.dart';
import 'ballistics.dart';
import 'enemy.dart';
import 'noise.dart';

/// What a shot did.
class ShotOutcome {
  const ShotOutcome({
    required this.chance,
    required this.hit,
    required this.bloodLossMl,
    required this.noiseM,
    required this.dominant,
  });

  /// §5.1.4: the number that was on screen before the trigger was pressed.
  final double chance;

  final bool hit;

  /// §5.1.5. Zero on a miss — and a miss is still paid for in noise.
  final double bloodLossMl;

  /// §5.6.1, after the environment has had its say.
  final double noiseM;

  /// §5.1.4: the largest source of error, for the words beside the percentage.
  final ErrorSource dominant;
}

/// The error budget for a shot with this weapon, in this body, at this target.
///
/// §5.1.1's components, assembled in one place so the HUD and the trigger
/// cannot disagree about what the odds are.
ShotError aimError({
  required ItemDefinition weapon,
  required double skill,
  required double heartRate,
  required double restingHr,
  required double maxHr,
  required double playerSpeedKmh,
  required double targetSpeedKmh,
  double conditionMoa = 0,
  double spreadMultiplier = 1,
}) {
  final mechanical = (weapon.props['moa'] as num?)?.toDouble() ?? 4;

  // §5.5.1: an unsettled sight picture opens every source at once rather than
  // adding one of its own — the shooter is not making a new mistake, they are
  // making all the old ones larger.
  return ShotError(
    weapon: mechanical * spreadMultiplier,
    skill: skillMoa(skill) * spreadMultiplier,
    heart: heartMoa(heartRate, rest: restingHr, max: maxHr) * spreadMultiplier,
    movement: movementMoa(playerSpeedKmh) * spreadMultiplier,
    target: targetMoa(targetSpeedKmh) * spreadMultiplier,
    condition: conditionMoa * spreadMultiplier,
  );
}

/// Fires at [target] and says what happened (§5.1, §5.1.5, §5.6).
///
/// [protection] is §4.4's armour at the location hit, already resolved by the
/// caller — this does not know where anybody was standing.
ShotOutcome fireAt({
  required ItemDefinition weapon,
  required Enemy target,
  ItemDefinition? ammo,
  required double distanceM,
  required ShotError error,
  required Random random,
  bool suppressed = false,
  bool night = false,
  bool denseUrban = false,
  bool openGround = false,
  bool badWeather = false,
  double protection = 0,
  double locationMultiplier = 1,
}) {
  final chance = hitChance(moa: error.total, distanceM: distanceM);
  final hit = random.nextDouble() < chance;

  final energy = (weapon.props['muzzle_energy_j'] as num?)?.toDouble() ?? 0;

  // §5.1.5: the wound channel belongs to the round, not to the rifle. The
  // same 7.62 out of the same barrel does what the round it came from does.
  final wound =
      (ammo?.props['wound_factor'] as num?)?.toDouble() ??
      (weapon.props['wound_factor'] as num?)?.toDouble() ??
      1;

  // §5.6.1: the item carries what it is heard from; a suppressor is the one
  // item in the game that changes how it is played rather than adding a
  // percentage (§5.6.3).
  final base =
      (weapon.props['noise_range_m'] as num?)?.toDouble() ??
      NoiseKind.rifle.baseM;

  return ShotOutcome(
    chance: chance,
    hit: hit,
    bloodLossMl: hit
        ? bloodLossMl(
            energyJ: energy,
            woundFactor: wound,
            locationMultiplier: locationMultiplier,
            protection: protection,
          )
        : 0,
    // A miss is heard exactly as well as a hit. That is the whole cost of
    // firing at a poor chance.
    noiseM: noiseRadiusM(
      suppressed ? base / 3.5 : base,
      night: night,
      denseUrban: denseUrban,
      openGround: openGround,
      badWeather: badWeather,
    ),
    dominant: error.dominant,
  );
}
