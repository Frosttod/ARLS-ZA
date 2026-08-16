/// What happens when the body gives out (§9).
///
/// Two modes, chosen once at creation and never again. Hardcore ends the
/// character; Softcore puts them on the ground for an hour and takes most of
/// what they were carrying. Everything here is rules rather than storage — the
/// loop decides *when*, this decides *what*.
///
/// ⚠️ §9.1's safeguards are not optional and are not balance. Permadeath
/// caused by a phone in a pocket losing signal is a one-star review, and the
/// document says so in as many words. Nothing can die asleep, and nothing can
/// die while the simulation is not being fed real positions.
library;

import '../sim/body.dart';
import '../sim/tick.dart';

/// §9.2: how long a softcore character is on the ground. Wall-clock.
const Duration kUnconsciousFor = Duration(minutes: 60);

/// §9.2: how long afterwards the dead are still fooled.
///
/// "They took you for dead." Ten minutes in which nothing attacks and the
/// player cannot attack either — the valve against waking up inside a level 8
/// hotspot and going straight back down.
const Duration kGraceAfterWaking = Duration(minutes: 10);

/// §9.2: what is left in the tank on waking. Class III shock, and hungry.
const double kWakeBloodFraction = 0.25;
const double kWakeReservesFraction = 0.15;

/// §9.2: how much of what was carried is simply gone.
const double kWakeLossFraction = 0.50;

/// §9.2.1: above this the player is in a vehicle, and waking up is deferred.
const double kWakeSpeedLimitKmh = 15;

/// Where the character stands with respect to being alive (§9).
enum DownState {
  /// On their feet.
  none,

  /// §9.2: on the ground, and the hour has not run out.
  unconscious,

  /// §9.2: up again, and still being ignored by everything nearby.
  grace,

  /// §9.1: hardcore, and that is the end of the character.
  dead,
}

/// Why it happened, in the words the Chronicle keeps (§13.1).
enum DeathCause {
  bloodLoss('blood_loss'),
  thirst('thirst'),
  starvation('starvation');

  const DeathCause(this.wire);

  final String wire;
}

/// What put the character down, or null while they are fine (§2.2, §2.3, §2.6).
DeathCause? fatalCause(SimStatus status) {
  if (status.blood.isFatal) return DeathCause.bloodLoss;
  if (status.thirst.lethal) return DeathCause.thirst;
  if (status.hunger.losingConsciousness) return DeathCause.starvation;
  return null;
}

/// Whether the game is allowed to end a character right now (§9.1).
///
/// Both refusals are about the phone rather than the character. Asleep, §2.1
/// has already stopped the bleeding at five per cent of volume, so a death
/// there could only come from arithmetic nobody was watching. Without a
/// position the simulation is not being fed anything real, and killing
/// somebody on the strength of that is killing them for walking into a car
/// park.
bool mayDie({required bool asleep, required bool positionKnown}) =>
    !asleep && positionKnown;

/// §9.2: what the character has left on waking, from what they had at maximum.
SimState wokenFrom(SimState state, SimConstants constants) => state.copyWith(
  bloodMl: constants.bloodMaxMl * kWakeBloodFraction,
  waterMl: constants.waterDailyMl * kWakeReservesFraction,
  caloriesKcal: constants.caloriesDailyKcal * kWakeReservesFraction,
  // Whatever was in the stomach is not there any more.
  pendingKcal: 0,
  pendingWaterMl: 0,
);

/// §9.2.1: whether the character may come round yet.
///
/// Not a punishment and not extra loss — a deferral. Waking somebody up on a
/// bus would put the character somewhere the player is not, and §0 makes that
/// the one thing the game may never do.
bool mayWake({required double speedKmh, required bool positionKnown}) =>
    positionKnown && speedKmh <= kWakeSpeedLimitKmh;

/// §9: what happens to this character when the body gives out.
DownState outcomeFor(DeathMode mode) =>
    mode == DeathMode.hardcore ? DownState.dead : DownState.unconscious;
