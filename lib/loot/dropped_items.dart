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
    this.attachments = const [],
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

  /// §5.6.3: what is bolted to it, by item id. Putting a rifle down is not a
  /// way to lose its sights.
  final List<String> attachments;

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

/// One kind of thing lying within reach, however many rows of it there are.
///
/// §4.8 stores a row per drop, so three bandages put down on three walks are
/// three rows in one spot. To the player standing over them that is one pile
/// of three bandages, and picking them up one at a time is a chore rather than
/// a decision. Two rows only merge where nothing distinguishes the pieces:
/// a rifle at 40% and the same rifle at 90% stay apart, because which one is
/// picked up is exactly the choice worth having (§4.2).
class GroundPile {
  const GroundPile({
    required this.itemId,
    required this.count,
    required this.parts,
    required this.distanceM,
    this.condition,
    this.pagesTotal,
    this.pagesRead = 0,
    this.attachments = const [],
  });

  final String itemId;

  /// Everything in this pile, added up.
  final int count;

  /// The rows behind it, nearest first. Picking the pile up takes them in that
  /// order, so a pack that fills part-way through leaves the far ones.
  final List<DroppedItem> parts;

  /// How far the nearest row of it is.
  final double distanceM;

  final double? condition;
  final int? pagesTotal;
  final int pagesRead;

  /// §5.6.3: what is on the pieces in this pile. They are only one pile
  /// because they carry the same things.
  final List<String> attachments;
}

/// Everything within [reachM] of [at], gathered into piles, nearest first.
List<GroundPile> pilesWithin(
  List<DroppedItem> items,
  GeoPoint at, {
  required double reachM,
}) {
  final near =
      items
          .map((item) => (item: item, distance: item.position.distanceTo(at)))
          .where((entry) => entry.distance <= reachM)
          .toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));

  final piles = <String, List<({DroppedItem item, double distance})>>{};
  for (final entry in near) {
    // Anything that tells one piece from another keeps them apart: condition,
    // and how far through a book somebody is.
    final key = [
      entry.item.itemId,
      entry.item.condition ?? '',
      entry.item.pagesTotal ?? '',
      entry.item.pagesRead,
      // §5.6.3: a suppressed rifle and a bare one are two piles, however alike
      // the rest of them is. Merging them would let a player pick up the wrong
      // one, which for the rarest things in the game is not a small mistake.
      entry.item.attachments.join(','),
    ].join('|');
    piles.putIfAbsent(key, () => []).add(entry);
  }

  return [
    for (final group in piles.values)
      GroundPile(
        itemId: group.first.item.itemId,
        count: group.fold(0, (sum, entry) => sum + entry.item.count),
        parts: [for (final entry in group) entry.item],
        distanceM: group.first.distance,
        condition: group.first.item.condition,
        pagesTotal: group.first.item.pagesTotal,
        pagesRead: group.first.item.pagesRead,
        attachments: group.first.item.attachments,
      ),
  ]..sort((a, b) => a.distanceM.compareTo(b.distanceM));
}
