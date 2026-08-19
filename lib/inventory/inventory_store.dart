/// Reading and writing an inventory (§4.1, §11.1).
///
/// Rows hold item ids and per-piece state, never the item's parameters. Mass,
/// volume and everything else come from the catalogue when the rows are read,
/// so a content pack that corrects a weight corrects it for what is already in
/// a player's pack — and a save stays readable when a pack is uninstalled.
///
/// **A row naming an item nothing defines is dropped, not guessed.** It is
/// reported instead, because a player who removed a content pack should be
/// told what went with it rather than handed a nameless object of unknown mass.
library;

import 'package:drift/drift.dart' show Value;

import '../data/db/database.dart';
import '../items/item_catalogue.dart';
import 'inventory.dart';

/// The result of reading rows back: what survived, and what did not.
class LoadedInventory {
  const LoadedInventory(this.inventory, this.droppedItemIds);

  final Inventory inventory;

  /// Ids the catalogue no longer knows. Empty in every ordinary case.
  final List<String> droppedItemIds;
}

const String _slotPack = 'pack';
const String _slotWorn = 'worn';

/// The id used for the pack itself, which is neither carried nor worn.
const String _slotBackpack = 'backpack';

class InventoryStore {
  const InventoryStore(this.db);

  final SaveDatabase db;

  Future<LoadedInventory> load(int profileId, ItemCatalogue catalogue) async {
    final rows = await db.inventoryFor(profileId);

    final carried = <CarriedItem>[];
    final worn = <CarriedItem>[];
    final dropped = <String>[];
    String? packId;

    for (final row in rows) {
      if (catalogue[row.itemId] == null) {
        dropped.add(row.itemId);
        continue;
      }

      if (row.slot == _slotBackpack) {
        packId = row.itemId;
        continue;
      }

      final line = CarriedItem(
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
      );
      (row.slot == _slotWorn ? worn : carried).add(line);
    }

    return LoadedInventory(
      Inventory(carried: carried, worn: worn, packId: packId),
      dropped,
    );
  }

  Future<void> save(int profileId, Inventory inventory) =>
      db.writeInventory(profileId, [
        for (final line in inventory.carried)
          _companion(profileId, line, _slotPack),
        for (final line in inventory.worn)
          _companion(profileId, line, _slotWorn),
        if (inventory.packId != null)
          InventoryLinesCompanion.insert(
            profileId: profileId,
            itemId: inventory.packId!,
          ).copyWith(slot: Value(_slotBackpack)),
      ]);

  InventoryLinesCompanion _companion(
    int profileId,
    CarriedItem line,
    String slot,
  ) => InventoryLinesCompanion.insert(profileId: profileId, itemId: line.itemId)
      .copyWith(
        count: Value(line.count),
        slot: Value(slot),
        condition: Value(line.condition),
        pagesTotal: Value(line.pagesTotal),
        pagesRead: Value(line.pagesRead),
        noteId: Value(line.noteId),
        portion: Value(line.portion),
        attachments: Value(line.attachments.join(',')),
        rounds: Value(line.rounds),
      );
}
