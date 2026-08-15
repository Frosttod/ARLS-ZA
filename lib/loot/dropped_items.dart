/// Things a player put down, and how long the world keeps them (§4.8).
///
/// Dropping is the other half of the two carry limits (§18.1a). A pack that
/// fills is only a decision if what comes out of it goes somewhere — otherwise
/// the answer to "this is too heavy" is always "destroy it", and nobody
/// deliberates over that.
///
/// §4.8 gives the rule in one line: visible on the map, gone after 24 hours,
/// at most fifty markers, oldest first. The cap is not flavour. Fifty rows and
/// fifty circles is the difference between a map somebody reads and a map
/// carpeted in a fortnight of abandoned bandages.
library;

import '../map/geometry.dart';

/// §4.8: how long a dropped thing waits.
///
/// A day, so anything put down on a walk is still there the next evening and
/// nothing is kept for ever. The clock runs on world time, not on play time —
/// a player who does not open the game for a week comes back to an empty
/// street, which is what a week does to a bag left in one.
const Duration kDroppedItemLifetime = Duration(hours: 24);

/// §4.8: the most that may exist at once, oldest discarded first.
const int kMaxDroppedItems = 50;

/// One pile, at one place.
class DroppedItem {
  const DroppedItem({
    required this.id,
    required this.itemId,
    required this.position,
    required this.droppedAt,
    this.count = 1,
    this.condition,
    this.pagesTotal,
    this.pagesRead = 0,
  });

  /// Row id, or zero for one that has not been written yet.
  final int id;

  final String itemId;
  final int count;

  /// Carried through unchanged: a dropped rifle is as worn as it was and a
  /// part-read book keeps its place (§4.6.3). Dropping something is not a way
  /// to repair it.
  final double? condition;
  final int? pagesTotal;
  final int pagesRead;

  final GeoPoint position;
  final DateTime droppedAt;

  DateTime get expiresAt => droppedAt.add(kDroppedItemLifetime);

  bool isAliveAt(DateTime now) => now.isBefore(expiresAt);

  /// How long is left, for the marker's label. Zero once it has gone.
  Duration remainingAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// What a pass over the pile decided.
class DropSweep {
  const DropSweep({required this.kept, required this.removed});

  final List<DroppedItem> kept;

  /// Rows to delete: expired, or pushed out by the cap.
  final List<DroppedItem> removed;
}

/// Applies §4.8's two rules to everything on the ground.
///
/// Expiry first, then the cap — in that order, because a pile that has already
/// gone should never be the reason a fresh one is refused.
DropSweep sweepDropped(List<DroppedItem> items, DateTime now) {
  final alive = <DroppedItem>[];
  final removed = <DroppedItem>[];

  for (final item in items) {
    (item.isAliveAt(now) ? alive : removed).add(item);
  }

  if (alive.length <= kMaxDroppedItems) {
    return DropSweep(kept: alive, removed: removed);
  }

  // Newest survive. §4.8 says oldest go first, and the reason is a player's
  // memory: the thing they dropped a minute ago is the thing they are walking
  // back towards.
  alive.sort((a, b) => b.droppedAt.compareTo(a.droppedAt));

  return DropSweep(
    kept: alive.take(kMaxDroppedItems).toList(),
    removed: [...removed, ...alive.skip(kMaxDroppedItems)],
  );
}
