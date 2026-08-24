/// A fight the player walked out of (§5.6.2, §6.1a).
///
/// ⚠️ The enemies themselves are never written down. §6.4 makes the population
/// from hotspots and the ambient trickle every time the game runs, and a
/// Walker written to disk would be yesterday's Walker on a street the player
/// has already left.
///
/// But that left a hole big enough to drive a strategy through: closing the
/// app was a perfect escape from anything. Fire into a crowd, kill the
/// process, come back to an empty street. Nothing in §5 costs anything if the
/// way out is free.
///
/// So the *fight* is written down, without the fighters: when the street was
/// stirred up, where, and by how many. On the way back in, if it is still
/// warm and the player is still near it, that many are put back — looking for
/// them, not on top of them. What the player gets is a warning and a chance to
/// leave, which is more than they had when they pulled the trigger.
library;

import '../map/geometry.dart';
import 'enemy.dart';

/// How long a street stays stirred up after the player stops feeding it.
///
/// Longer than §5.6.2's noise window, because this is not the sound itself but
/// what the sound started: bodies that came looking, spread out, and have not
/// gone home yet. Short enough that a walk round the block genuinely loses
/// them — the escape is a walk, not a task manager.
const Duration kHuntLasts = Duration(minutes: 15);

/// How far from where it happened the player has to be for it to still be
/// their problem.
///
/// Beyond this they are simply somewhere else, and §6.4's ordinary population
/// is what they meet. It is deliberately wider than the active radius: walking
/// three streets away and back should not be a clean slate.
const double kHuntReachM = 500;

/// What was left behind, or nothing at all.
class Pursuit {
  const Pursuit({required this.at, required this.until, required this.count});

  /// Where the player was when they last made themselves the centre of it.
  final GeoPoint at;

  /// When the street gives up, if nothing else happens.
  final DateTime until;

  /// How many were on them. Capped where it is written, not here.
  final int count;

  bool isWarmAt(DateTime now) => count > 0 && now.isBefore(until);

  /// Whether this is still the player's problem, standing here.
  bool followsTo(GeoPoint here, DateTime now) =>
      isWarmAt(now) && at.distanceTo(here) <= kHuntReachM;

  /// How many come looking on the way back in.
  ///
  /// Fewer than were on them, and never more than a handful: some wandered
  /// off, and the point is a fight the player can still choose to leave rather
  /// than an ambush at the loading screen.
  int resumedAt(GeoPoint here, DateTime now) {
    if (!followsTo(here, now)) return 0;

    final left = (count * 0.6).round();
    return left.clamp(1, 4);
  }
}

/// §5.6.2: how warm the street is after one more second of it.
///
/// ⚠️ **Fed by who is *onto* the player, never by who is merely stirred up.**
///
/// This lived in the interface and counted anything that was not idle and not
/// going home — which includes a body walking towards a noise three streets
/// away. So the hunt was refreshed on every tick, [Pursuit.until] was pushed
/// fifteen minutes into the future for ever, and the street never went cold.
/// Coming back into the game then put hunters back, every time.
///
/// Reported from a walk as exactly that: shoot from a distance, close the app,
/// reopen it, and they are still looking.
Pursuit? pursuitAfter({
  required Pursuit? current,
  required List<Enemy> near,
  required GeoPoint at,
  required DateTime now,
  double scouting = 0,
  double darkness = 0,
}) {
  final engaged = [
    for (final enemy in near)
      if (!enemy.isDead &&
          enemy.isOnto(at, scouting: scouting, darkness: darkness))
        enemy,
  ].length;

  if (engaged > 0) return stirredUp(at: at, now: now, engaged: engaged);

  // Gone cold on its own: a walk round the block genuinely loses them.
  return current == null || current.isWarmAt(now) ? current : null;
}

/// The fight as it stands after the player has been seen or heard again.
Pursuit stirredUp({
  required GeoPoint at,
  required DateTime now,
  required int engaged,
}) => Pursuit(
  at: at,
  until: now.add(kHuntLasts),
  // Capped: §5.5.6 allows eight active, and putting eight back on somebody
  // opening the app is not a warning, it is a sentence.
  count: engaged > 6 ? 6 : engaged,
);
