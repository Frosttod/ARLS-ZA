/// Which one is being aimed at, and what that costs (§5.5.1, §5.3).
///
/// **One active target for a firearm.** Everything else in the fight carries
/// on: the unaimed ones run, close and swing, so aiming is a choice about
/// where attention goes rather than a pause button. That is the whole of
/// §5.5.5's tactical loop — every second spent on one of them is ground given
/// to the rest.
///
/// Changing target costs time and the sights open up while it happens, and
/// §5.5.1 refuses to switch automatically when a target dies for exactly that
/// reason: automation would remove the decision and leave tapping.
library;

import 'engagement.dart';
import 'magazine.dart' show kWeaponsSpeed;

/// §5.3: how long the group takes to settle once the shooter is still.
///
/// Two seconds at rest, four when the heart is at its worst. §5.3 calls the
/// narrowing circle the main decision loop of a firefight, and this is what
/// makes standing still worth something.
const Duration kSettleFast = Duration(seconds: 2);
const Duration kSettleSlow = Duration(seconds: 4);

/// What the player is shooting at, and how settled the sights are.
class Aim {
  const Aim({this.targetId, this.since, this.settle = kSettleFast});

  /// §5.5.1: null after a target dies. Nothing picks the next one — the
  /// "nearest threat" button costs the same time as any other switch.
  final String? targetId;

  /// When this target was taken. Null means the sights are already settled.
  final DateTime? since;

  /// How long settling takes for this shooter right now (§5.3).
  final Duration settle;

  /// Takes a new target, paying §5.5.1's price for the change.
  ///
  /// Re-taking the one already aimed at is free: a player tapping the same
  /// marker twice has not changed their mind about anything.
  Aim at(
    String id, {
    required DateTime now,
    double weaponSkill = 0,
    Duration settle = kSettleFast,
  }) {
    if (id == targetId) return this;

    return Aim(
      targetId: id,
      since: now.add(targetSwitchTime(weaponSkill)),
      settle: settle,
    );
  }

  /// The target died, or the player let it go.
  Aim get released => Aim(settle: settle);

  /// §5.5.1: while the sight picture is being recovered, the group is at its
  /// widest — two and a half times the settled figure — and it narrows from
  /// there over §5.3's two to four seconds.
  double spreadMultiplierAt(DateTime now) {
    final ready = since;
    if (ready == null) return 1;

    // Still recovering the picture: nothing has begun to narrow yet.
    if (now.isBefore(ready)) return kSwitchingSpreadMultiplier;

    final settled = now.difference(ready);
    if (settled >= settle) return 1;

    final left = 1 - settled.inMilliseconds / settle.inMilliseconds;
    return 1 + (kSwitchingSpreadMultiplier - 1) * left;
  }

  /// Whether a shot now would be at anything at all.
  bool get hasTarget => targetId != null;
}

/// §5.3: how long the sights take to settle, given the pulse.
///
/// Two seconds rested, four at the ceiling — the same fraction §5.1.1 squares
/// for the aim itself, because both are the same shaking hand.
Duration settleTime({
  required double heartRate,
  required double rest,
  required double max,
  double weapons = 0,
}) {
  final span = max - rest;
  final over = span <= 0 ? 0.0 : ((heartRate - rest) / span).clamp(0.0, 1.0);

  final ms =
      kSettleFast.inMilliseconds +
      (kSettleSlow.inMilliseconds - kSettleFast.inMilliseconds) * over;

  // §7: −30% on the narrowing circle at full mastery. §5.3 calls that circle
  // the main decision loop of a firefight, so this is the one skill effect a
  // player watches happen rather than reads about.
  return Duration(
    milliseconds: (ms * (1 - kWeaponsSpeed * weapons.clamp(0.0, 1.0))).round(),
  );
}
