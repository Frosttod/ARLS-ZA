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
import '../../inventory/item_use.dart';
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
    assert(_namesAreUnique(next), 'two pieces answering to one name (§11.1)');

    inventory.value = next;
    notifyListeners();
  }

  /// §11.1: no two pieces share a name.
  ///
  /// ⚠️ **An assert, in the one place every edit passes through.**
  ///
  /// This was found the hard way, twice. [CarriedItem.isSame] compares uids,
  /// and everything that acts on one piece — the progress bar, the dismantling
  /// lock, the portion of a meal, the rounds in a magazine — asks it. Two rows
  /// with one name means an act on either finds both, which reached the field
  /// as two progress bars under two different bottles.
  ///
  /// Debug only, and deliberately: in a debug build this fires the moment the
  /// rule breaks and the crash strip shows it, which is a walk's worth of
  /// diagnosis for nothing. In release it costs nothing at all — the model
  /// having been fixed is what makes the game right; this is what stops the
  /// next mutator from quietly un-fixing it.
  static bool _namesAreUnique(Inventory next) {
    final seen = <String>{};
    for (final line in [...next.carried, ...next.worn]) {
      final uid = line.uid;
      if (uid == null) continue;
      if (!seen.add(uid)) return false;
    }
    return true;
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

  /// §4.1: whether anything carried goes through the lid of a tin.
  ///
  /// ⚠️ Read off the catalogue rather than from a pair of ids: two things say
  /// `opens_cans` today and a content pack may ship a third.
  bool get opensTins => opensCans([for (final id in ids()) ?_catalogue?[id]]);

  /// §10.2.2: binoculars in the pack or round the neck — one question rather
  /// than the same two-line check in each of the places that asks it.
  bool get hasBinoculars => carries('tool_binoculars');

  // ------------------------------------------------------------- writing ---

  /// §19.3: pierwsze z [candidates], które gracz ma, schodzi o swoje zużycie.
  ///
  /// Ta sama kolejność, którą sprawdza `BarrierBreach.isAvailableWith` — czym
  /// panel pozwolił otworzyć, to się zużyło.
  Future<void> useTool(Iterable<String> candidates) async {
    final catalogue = _catalogue;
    final used = candidates.where(carries).firstOrNull;
    if (catalogue == null || used == null) return;

    inventory.value = inventory.value.usedTool(used, catalogue);
    notifyListeners();

    await save();
  }

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
