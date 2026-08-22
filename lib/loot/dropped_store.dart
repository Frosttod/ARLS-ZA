/// Reading and writing what is on the ground (§4.8, §11.1).
library;

import '../inventory/inventory.dart';
import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../map/geometry.dart';
import 'dropped_items.dart';

class DroppedStore {
  const DroppedStore(this._db);

  final SaveDatabase _db;

  /// Everything on the ground, with §4.8's rules already applied.
  ///
  /// The sweep runs on read rather than on a timer: nothing about an expired
  /// pile matters until somebody looks, and a timer that fires while the app
  /// is closed is a timer that does not fire.
  Future<List<DroppedItem>> load(int profileId, DateTime now) async {
    final rows = await _db.groundItemsFor(profileId);

    final sweep = sweepDropped([
      for (final row in rows)
        DroppedItem(
          id: row.id,
          itemId: row.itemId,
          count: row.count,
          condition: row.condition,
          pagesTotal: row.pagesTotal,
          pagesRead: row.pagesRead,
          attachments: row.attachments.isEmpty
              ? const []
              : row.attachments.split(','),
          rounds: row.rounds,
          salvageSeconds: row.salvageSeconds,
          uid: row.uid ?? newLineId(),
          position: GeoPoint(row.latitude, row.longitude),
          droppedAt: row.droppedAt,
        ),
    ], now);

    await _db.removeGroundItems([for (final gone in sweep.removed) gone.id]);
    return sweep.kept;
  }

  /// Puts something on the ground where the player is standing.
  Future<void> drop(int profileId, DroppedItem item) => _db.addGroundItem(
    GroundItemsCompanion.insert(
      profileId: profileId,
      itemId: item.itemId,
      latitude: item.position.latitude,
      longitude: item.position.longitude,
      droppedAt: item.droppedAt,
    ).copyWith(
      count: Value(item.count),
      condition: Value(item.condition),
      pagesTotal: Value(item.pagesTotal),
      pagesRead: Value(item.pagesRead),
      attachments: Value(item.attachments.join(',')),
      rounds: Value(item.rounds),
      salvageSeconds: Value(item.salvageSeconds),
      uid: Value(item.uid ?? newLineId()),
    ),
  );

  /// Takes it back off the ground. Called once it is in the pack, never before:
  /// an item deleted here and refused by the inventory would be an item the
  /// game destroyed on the player's behalf.
  Future<void> take(int id) => _db.removeGroundItems([id]);

  /// Takes part of a pile, leaving the rest where it lies.
  ///
  /// A pack with room for two of the five pieces of wood at somebody's feet
  /// takes two. Deleting the row for a partial pick-up would be the game
  /// destroying three of them on the player's behalf.
  Future<void> takeSome(int id, {required int left}) =>
      left <= 0 ? take(id) : _db.setGroundItemCount(id, left);
}
