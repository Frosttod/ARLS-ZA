/// What the character is carrying, and who owns the answer (§18.1a, §11.1).
///
/// ⚠️ **The first thing to leave `main.dart`, and deliberately the easiest.**
///
/// The pack was already a `ValueNotifier` that the screens listened to, so
/// moving who *owns* it changes no subscription and no rebuild. That is the
/// whole reason it goes first: the pattern gets established on a change that
/// cannot alter a frame.
///
/// What it owns:
///
///   - the pack and what is worn, as one [Inventory];
///   - the order the rows are shown in — one order for the pack screen and
///     the shelves screen, because they are one decision seen twice;
///   - what is left of §18.1a's two limits, cached;
///   - putting all of that on disk.
///
/// What it deliberately does **not** own: saying anything to the player,
/// refusing out loud, opening a screen, or knowing what a shelter is. Those
/// need a `BuildContext` or a neighbour, and a controller that has either is
/// the God class again with a smaller file name.
library;

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../sim/body.dart';
import '../../inventory/inventory.dart';
import '../../inventory/inventory_store.dart';
import '../../items/item_catalogue.dart';
import '../../ui/inventory_screen.dart' show PackOrder;

class InventoryController extends ChangeNotifier {
  InventoryController(this._db);

  final SaveDatabase _db;

  /// ⚠️ The notifier is created here and never replaced, so a screen that took
  /// a reference to it at boot still has the right one an hour later. The
  /// character arrives later — see [bind] — and that is the only thing that is
  /// allowed to be late.
  final ValueNotifier<Inventory> inventory = ValueNotifier(const Inventory());

  /// §18.2: one order for the pack and the shelves. A choice held inside a
  /// pushed route is a choice forgotten every time the player closes it, which
  /// is a bug class this codebase has now found six times.
  final ValueNotifier<PackOrder> order = ValueNotifier(PackOrder.kind);

  int? _profileId;
  ItemCatalogue? _catalogue;
  BodyProfile? _body;

  /// Says whose pack this is. Called once the character is on screen.
  void bind({
    required int profileId,
    required ItemCatalogue catalogue,
    required BodyProfile body,
  }) {
    _profileId = profileId;
    _catalogue = catalogue;
    _body = body;
    _roomCache = null;
  }

  bool get isBound => _profileId != null;

  Inventory get pack => inventory.value;

  set pack(Inventory next) {
    inventory.value = next;
    notifyListeners();
  }

  // ------------------------------------------------------------- reading ---

  /// §18.1a: what is still free, worked out once per change.
  ///
  /// ⚠️ Cached on the identity of the pack, not on its contents. Every edit
  /// replaces the whole [Inventory], so a reference comparison is exact and
  /// costs nothing — and this is asked once per row of a list somebody is
  /// scrolling.
  PackRoom room() {
    final catalogue = _catalogue;
    final body = _body;
    if (catalogue == null || body == null) {
      return const PackRoom(massKg: 0, volumeL: 0);
    }

    final current = inventory.value;
    final cached = _roomCache;
    if (cached != null && identical(cached.pack, current)) return cached.room;

    final room = current.roomLeft(body, catalogue);
    _roomCache = (pack: current, room: room);
    return room;
  }

  ({Inventory pack, PackRoom room})? _roomCache;

  /// How many of each item is in the pack, by id.
  Map<String, int> counts() {
    final counts = <String, int>{};
    for (final line in inventory.value.carried) {
      counts[line.itemId] = (counts[line.itemId] ?? 0) + line.count;
    }
    return counts;
  }

  /// Item ids carried **or worn**. What decides the ways in (§19.3).
  Set<String> ids() => {
    for (final line in inventory.value.carried) line.itemId,
    for (final line in inventory.value.worn) line.itemId,
  };

  bool carries(String itemId) => ids().contains(itemId);

  // ------------------------------------------------------------- writing ---

  Future<void> save() async {
    final profileId = _profileId;
    if (profileId == null) return;

    await InventoryStore(_db).save(profileId, inventory.value);
  }

  /// §4.7: how much of one piece is left, and nothing else.
  ///
  /// ⚠️ **Not [save].** A meal moves this figure once a second, and the
  /// wholesale write deletes every row a profile owns and inserts them all
  /// back inside a transaction. Doing that every second of every meal put a
  /// pack's worth of rows through the write queue per second, ahead of the
  /// position writes and the hot state the loop was trying to save — reported
  /// from the field as the game freezing on food.
  Future<void> savePortion(String uid, double portion) async {
    final profileId = _profileId;
    if (profileId == null) return;

    await InventoryStore(_db).savePortion(profileId, uid, portion);
  }

  /// Reads the pack off disk, replacing whatever is held.
  Future<LoadedInventory?> load(ItemCatalogue catalogue) async {
    final profileId = _profileId;
    if (profileId == null) return null;

    final loaded = await InventoryStore(_db).load(profileId, catalogue);
    pack = loaded.inventory;
    return loaded;
  }

  @override
  void dispose() {
    inventory.dispose();
    order.dispose();
    super.dispose();
  }
}
