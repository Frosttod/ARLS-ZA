/// What is left where something went down (§4.8, §10.3).
///
/// A body is not a pile of loot. Dropping what it carried onto the ground the
/// instant it falls tells the player, from two hundred metres away and through
/// a wall, exactly what is there — which answers the only question worth
/// walking over to answer. So the body is a body: a mark on the map, and
/// whatever it had stays in its pockets until somebody goes and puts a hand in
/// them.
///
/// ⚠️ Not persisted, for the same reason [CombatSession] is not: §6.4 makes
/// the population from hotspots and the ambient trickle every time the game
/// runs, so a body written down would be a body on a street the player left
/// yesterday. Within one session it lasts [kRemainsLifetime], which is long
/// enough to shoot something, back off, and come back when it is quiet.
library;

import '../map/geometry.dart';
import 'enemy.dart';

/// How long a body is worth walking back to.
///
/// §4.8 gives a dropped pile a day; a body gets rather less, because the
/// decision it creates — take the fight now or come back for the pockets
/// later — is only interesting while the street is still the same street.
const Duration kRemainsLifetime = Duration(hours: 6);

/// Something dead, where it fell.
class Remains {
  const Remains({
    required this.id,
    required this.kind,
    required this.position,
    required this.diedAt,
    this.searched = false,
  });

  /// The enemy's own id, so the same body cannot be added twice.
  final String id;

  final EnemyKind kind;
  final GeoPoint position;
  final DateTime diedAt;

  /// Pockets already turned out. Kept on the map rather than removed: a player
  /// who searched it should be able to see that they did, or they will walk
  /// back to it a second time.
  final bool searched;

  Remains get emptied => Remains(
    id: id,
    kind: kind,
    position: position,
    diedAt: diedAt,
    searched: true,
  );

  bool isGoneAt(DateTime now) => now.difference(diedAt) >= kRemainsLifetime;
}

/// Adds a body, or leaves the list alone if that one is already in it.
List<Remains> addRemains(List<Remains> remains, Remains body) =>
    remains.any((other) => other.id == body.id)
    ? remains
    : [...remains, body];

/// Drops the ones nobody is coming back for.
List<Remains> sweepRemains(List<Remains> remains, DateTime now) => [
  for (final body in remains)
    if (!body.isGoneAt(now)) body,
];
