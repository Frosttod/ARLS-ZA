/// The ground around a shelter, where the fight does not happen (§8.1).
///
/// ⚠️ **One radius, used for both halves of the rule.** Enemies do not come
/// inside it and the player does not shoot out of it — and §8.1 puts that in
/// bold, because two different numbers would leave a ring in which something
/// can reach the player and the player cannot answer. That is not a balance
/// tweak, it is a ring that punishes standing near your own front door.
///
/// What it produces is the behaviour §8.1 describes in one line: they wait at
/// the edge. Nobody camps a doorway picking off a queue, and nobody is caught
/// defenceless on their own step. To fight, you go outside.
library;

import '../map/geometry.dart';

/// A circle of ground somebody built (§8.1, §8.5.1).
class Sanctuary {
  const Sanctuary({required this.at, required this.radiusM});

  final GeoPoint at;
  final double radiusM;

  bool contains(GeoPoint point) => at.distanceTo(point) <= radiusM;
}

/// Whether this point is inside any of them.
bool inSanctuary(GeoPoint point, List<Sanctuary> sanctuaries) {
  for (final sanctuary in sanctuaries) {
    if (sanctuary.contains(point)) return true;
  }
  return false;
}

/// Pushes a point out to the edge of whatever it has walked into (§8.1).
///
/// Out along the line it came in on, so something that walked at the shelter
/// ends up standing at the boundary facing it — which is exactly the picture
/// §8.1 asks for. Returns the point unchanged when it is not inside anything.
GeoPoint keepOut(GeoPoint point, List<Sanctuary> sanctuaries) {
  var moved = point;

  for (final sanctuary in sanctuaries) {
    if (!sanctuary.contains(moved)) continue;

    final away = sanctuary.at.bearingTo(moved);
    // Dead centre has no bearing worth trusting; north is as good as anything
    // and it only ever happens the moment a shelter goes up on top of one.
    moved = sanctuary.at.offsetBy(
      metres: sanctuary.radiusM,
      bearingDeg: sanctuary.at.distanceTo(moved) < 0.5 ? 0 : away,
    );
  }
  return moved;
}
