/// Reading and writing what is on the shelves (§18.2, §11.1).
///
/// ⚠️ Nothing here deletes a stash when a camp falls down. §8.5.2 says a camp
/// nobody has visited for three weeks is gone "with whatever was in the chest",
/// and [ShelterStore.load] already removes the row — the foreign key does the
/// rest, in the schema, where it cannot be forgotten.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../inventory/inventory.dart';
import '../items/item_catalogue.dart';
import 'shelter.dart';
import 'stash.dart';

class StashStore {
  const StashStore(this._db);

  final SaveDatabase _db;

  /// What is in [shelter], with the capacity that shelter currently has.
  ///
  /// ⚠️ Rows naming an item nothing defines are dropped rather than guessed
  /// at, exactly as the pack does it (§4.1): that happens when a content pack
  /// is uninstalled, and the pack going away is what took the item with it.
  Future<Stash> load(
    int profileId,
    Shelter shelter,
    ItemCatalogue catalogue,
  ) async {
    final rows = await _db.stashFor(profileId, shelter.id);

    return Stash(
      capacityKg: shelter.storageKg,
      lines: [
        for (final row in rows)
          if (catalogue[row.itemId] != null)
            CarriedItem(
              itemId: row.itemId,
              count: row.count,
              condition: row.condition,
              pagesTotal: row.pagesTotal,
              pagesRead: row.pagesRead,
              noteId: row.noteId,
              portion: row.portion,
              attachments: row.attachments.isEmpty
                  ? const []
                  : row.attachments.split(','),
              rounds: row.rounds,
              salvageSeconds: row.salvageSeconds,
              uid: row.uid ?? newLineId(),
            ),
      ],
    );
  }

  Future<void> save(int profileId, int shelterId, Stash stash) =>
      _db.writeStash(profileId, shelterId, [
        for (final line in stash.lines)
          ShelterItemsCompanion.insert(
            profileId: profileId,
            shelterId: shelterId,
            itemId: line.itemId,
            count: Value(line.count),
            condition: Value(line.condition),
            pagesTotal: Value(line.pagesTotal),
            pagesRead: Value(line.pagesRead),
            noteId: Value(line.noteId),
            portion: Value(line.portion),
            attachments: Value(line.attachments.join(',')),
            rounds: Value(line.rounds),
            salvageSeconds: Value(line.salvageSeconds),
            uid: Value(line.uid ?? newLineId()),
          ),
      ]);
}
