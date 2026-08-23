/// What has been left in a shelter, and who owns the answer (§18.2, §8.5.1).
///
/// ⚠️ **Deliberately not the pack, and deliberately not a neighbour of it.**
///
/// A shelf holds what it holds and refuses the rest. A pack has a body behind
/// it — comfort, a maximum, a surcharge for being over (§18.1a) — and the two
/// stay simpler by not sharing a class. That was already true of [Stash] and
/// [Inventory]; this keeps it true of who owns them.
///
/// Where something genuinely needs both — a bench spends materials off the
/// shelves first and the pack second (§18.2) — the thing that needs both asks
/// both. Neither controller reaches for the other, because the moment one
/// does, moving either of them means moving both.
library;

import 'package:flutter/foundation.dart';

import '../../data/db/database.dart';
import '../../inventory/inventory.dart';
import '../../items/item_catalogue.dart';
import '../../shelter/shelter.dart';
import '../../shelter/stash.dart';
import '../../shelter/stash_store.dart';

class StashController extends ChangeNotifier {
  StashController(this._db);

  final SaveDatabase _db;

  /// ⚠️ Created here and never replaced, so a screen that took a reference to
  /// it at boot still has the right one an hour later.
  final ValueNotifier<Stash> stash = ValueNotifier(const Stash(capacityKg: 0));

  /// Which shelter these shelves belong to, so a save goes to the right place.
  ///
  /// Null when the player is nowhere near one — and then nothing here writes,
  /// which is the point: shelves that saved themselves against no shelter
  /// would put one shelter's things into another's.
  Shelter? get openAt => _openAt;
  Shelter? _openAt;

  int? _profileId;

  void bind({required int profileId}) => _profileId = profileId;

  Stash get shelves => stash.value;

  set shelves(Stash next) {
    stash.value = next;
    notifyListeners();
  }

  // ------------------------------------------------------------- reading ---

  /// §18.2: what is on these shelves, by item id.
  Map<String, int> counts() {
    final counts = <String, int>{};
    for (final line in stash.value.lines) {
      counts[line.itemId] = (counts[line.itemId] ?? 0) + line.count;
    }
    return counts;
  }

  // ------------------------------------------------------------- writing ---

  /// Reads one shelter's shelves in, and remembers which shelter they are.
  Future<void> open(Shelter place, ItemCatalogue catalogue) async {
    final profileId = _profileId;
    if (profileId == null) return;

    _openAt = place;
    shelves = await StashStore(_db).load(profileId, place, catalogue);
  }

  /// Forgets which shelves are open, leaving nothing to write to.
  void close() {
    _openAt = null;
    shelves = const Stash(capacityKg: 0);
  }

  Future<void> save() async {
    final place = _openAt;
    if (place == null) return;

    await saveTo(place);
  }

  /// Writes these shelves against a named shelter.
  ///
  /// ⚠️ For the paths that reach the shelves without ever opening the shelves
  /// screen — putting something away from the pack, a bench job finishing —
  /// where [openAt] is null and the destination is known anyway.
  Future<void> saveTo(Shelter place) async {
    final profileId = _profileId;
    if (profileId == null) return;

    await StashStore(_db).save(profileId, place.id, stash.value);
  }

  /// §18.1a: puts what would not fit in a pack onto [place]'s shelves.
  ///
  /// ⚠️ **One at a time, and that is not fussiness.** The shelves refuse a
  /// line that will not fit, so a stack of five offered whole and refused
  /// loses five rather than one. An overflow is a state, not a reason to
  /// destroy something — a forty-five minute pack that vanishes because the
  /// bag was full is the worst possible reading of a carry limit.
  ///
  /// ⚠️ **Opens [place]'s own shelves first, and that is a fix.**
  ///
  /// This is reached when a job finishes, and the shelves screen may never
  /// have been opened — or, worse, may have been opened on a *different*
  /// shelter. The version this replaces took whatever was held and wrote it
  /// under the main shelter's id, so a player who had just looked in a camp's
  /// cupboard and then finished a build at home would have moved the camp's
  /// contents into the house.
  ///
  /// Never observed in the field. Found by moving the code, which is most of
  /// what moving code is for.
  Future<void> spill(
    Map<String, int> overflow,
    Shelter place,
    ItemCatalogue catalogue,
  ) async {
    final profileId = _profileId;
    if (profileId == null || overflow.isEmpty) return;

    if (_openAt?.id != place.id) await open(place, catalogue);

    var shelf = stash.value;
    for (final entry in overflow.entries) {
      for (var i = 0; i < entry.value; i++) {
        final put = shelf.put(CarriedItem(itemId: entry.key), catalogue);
        if (!put.moved) break;
        shelf = put.stash;
      }
    }

    shelves = shelf;
    await StashStore(_db).save(profileId, place.id, shelf);
  }

  @override
  void dispose() {
    stash.dispose();
    super.dispose();
  }
}
