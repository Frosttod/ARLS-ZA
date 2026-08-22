/// How fast a thing being done actually gets done (§2.1a, §4.7, §10.2).
///
/// ⚠️ **One rule instead of three special cases.**
///
/// The game had three unrelated pieces of code answering the same question.
/// A shelter build stopped when the character left the site. A search was
/// cancelled outright by a step. A reload was broken by a body within five
/// metres. Each was a hand-written `if` in a different file, and adding a
/// fourth — "eating should be slower on the move" — would have been a fourth.
///
/// They are all one thing: **an action accrues time at a rate, and the rate
/// depends on what the character is doing while it runs.**
///
///     credited += elapsed × rate(pace, context)
///
/// A build runs at 1.0 whatever happens. A dressing runs at 1.0 standing
/// still, slower walking, and 0.0 at a run. A search runs at 0.0 the moment
/// the character is not where they started. Nothing needs a branch anywhere
/// else, and a new action is a row in a table rather than a new `if`.
library;

/// §4.7: how much longer a thing takes while moving.
///
/// Not a penalty invented here — it is the difference between doing something
/// with both hands and doing it while watching where your feet go. The figures
/// are a starting point for the walks, not a measurement.
const double kPaceWalking = 1.6;
const double kPaceBrisk = 2.5;

/// Below this the character counts as standing still (§10.2's own threshold
/// for a search, reused so that one speed does not mean two things).
const double kStillKmh = 0.5;

/// §2.3's ordinary walking pace.
const double kWalkingKmh = 5;

/// Past this nobody is dressing a wound (§4.7).
const double kRunningKmh = 8;

/// What kind of thing this is, for the purpose of the clock.
enum ActionPace {
  /// §2.1a.3: runs whether or not anybody is watching, and whether or not the
  /// app is open. Building, crafting, taking things apart, sleeping.
  ///
  /// The character is not doing it with their hands every second — they set it
  /// going and come back.
  unattended,

  /// §4.7: their own two hands. Eating, drinking, dressing a wound.
  ///
  /// ⚠️ Slowed by movement rather than cancelled by it, which is the change
  /// this enum exists to allow. A step used to throw the whole meal away.
  handsOn,

  /// §10.2: has to happen where it started. Searching a place, forcing a door.
  ///
  /// Not slowed — stopped. Half a shop searched from across the road is not a
  /// slower search, it is not a search.
  onTheSpot,
}

/// What the world is doing to the action, sampled each tick.
///
/// Comes from a GPS fix, which arrives at 1, 0.2 or 0.05 Hz (§3.3) — so
/// sampling the rate costs nothing extra and happens at exactly the moments
/// the speed is known.
class PaceContext {
  const PaceContext({this.speedKmh = 0, this.atStartingPlace = true});

  /// Ground speed from the last accepted fix.
  final double speedKmh;

  /// Whether the character is still where the action began, within whatever
  /// radius that action calls close enough.
  final bool atStartingPlace;

  /// Standing still, for anything that cares.
  bool get isStill => speedKmh < kStillKmh;
}

/// How much of one second counts, for an action of this [pace].
///
/// Nought means the clock is stopped, not that the action failed: §18.6's
/// dismantling and §8.3's building both keep what they have earned and go on
/// when the condition comes back. Whether stopping should also *end* something
/// is a decision for the action, not for its clock.
double rateFor(ActionPace pace, PaceContext context) => switch (pace) {
  ActionPace.unattended => 1,

  ActionPace.onTheSpot => context.atStartingPlace ? 1 : 0,

  ActionPace.handsOn => switch (context.speedKmh) {
    < kStillKmh => 1,
    < kWalkingKmh => 1 / kPaceWalking,
    < kRunningKmh => 1 / kPaceBrisk,
    _ => 0,
  },
};

/// How long [work] will really take at this rate, or null when it never ends.
///
/// For the interface: a player who starts a fifteen-minute job while walking
/// deserves to see twenty-four rather than fifteen and a surprise.
Duration? atThisRate(Duration work, double rate) {
  if (rate <= 0) return null;

  return Duration(milliseconds: (work.inMilliseconds / rate).round());
}
