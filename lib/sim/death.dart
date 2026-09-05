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

import '../map/geometry.dart';
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

/// §9.2.1: how far from the body the grace still reaches.
///
/// ⚠️ **The whole balance of §9.2.1 hangs on this one figure, and it was not
/// implemented.** The caches stay where the character fell, so the penalty for
/// having moved grows by itself — but the ten minutes of being taken for dead
/// were granted to everyone, including a player who woke fifteen kilometres
/// away on a bus. That is the wrong way round: the grace is what makes going
/// back for the kit a *decision*, and there is nothing to decide when the kit
/// is an hour's walk away.
///
/// Inside 300 m the fiction is "you crawled" — the body is still where the
/// street last saw it. Beyond it the fiction is delirium, and delirium does
/// not come with anybody being fooled.
const double kGraceWithinM = 300;

/// §9.2.1: how long before a wake that had to be deferred is tried again.
///
/// A minute, because the reasons to defer — a bus, a lost sky — end without
/// warning, and a character lying on the ground for an extra quarter of an
/// hour after the player got off the bus is the deferral turning into the
/// punishment it is explicitly not.
const Duration kWakeRetry = Duration(minutes: 1);

/// §9.2.1: whether waking here still counts as having crawled.
///
/// A null [fellAt] or [wokeAt] reads as yes. Not generosity for its own sake:
/// a save written before the fall position was recorded, or a wake with no fix
/// yet, is a case where the game does not *know* the player moved — and taking
/// the grace away on a guess would punish somebody for a missing row.
bool grantsGrace({required GeoPoint? fellAt, required GeoPoint? wokeAt}) {
  if (fellAt == null || wokeAt == null) return true;
  return fellAt.distanceTo(wokeAt) <= kGraceWithinM;
}

/// §9.2: what is left in the tank on waking. Class III shock, and hungry.
///
/// ⚠️ §9.2's own row reads "25% of maximum (class III shock)", and those two
/// halves contradict each other: §2.6 puts class III at 30–40% *lost*, which
/// is 60–70% remaining. A quarter remaining is 75% lost — class IV, which
/// §2.6 defines as unconsciousness leading to death.
///
/// Taken literally it is unplayable, and it was: a character woke at 25%,
/// the next tick found them in class IV, and the game put them straight back
/// on the ground for another hour. On a phone that read as a timer that would
/// not run out and a save that kept reverting to the moment of death.
///
/// So the class wins over the figure — it is the half of the row that says
/// what the state is *for*. Sixty-five per cent is the middle of class III:
/// badly hurt, everything harder, and alive.
const double kWakeBloodFraction = 0.65;
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
  // ⚠️ **§2.3's calorie reserve is not what kills anybody, and it used to be.**
  //
  // §2.3 says "0% przez > 24 h → postępująca utrata przytomności", and the
  // game read that as a death. The reserve is a *day's* worth of food, so a
  // character with nothing to eat sits at nought from the second day of a
  // famine until the end of it — which made hunger fatal in forty-eight hours,
  // faster than thirst, in a game whose own §2.3 insists water must be the
  // harsher of the two.
  //
  // Blacking out is what that line describes and [HungerState] still says it.
  // Dying of hunger is a different event, and it is about the body rather than
  // about the larder: a third of the starting weight gone, which is six to ten
  // weeks of a complete fast.
  if (status.wasting.fatal) return DeathCause.starvation;
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
