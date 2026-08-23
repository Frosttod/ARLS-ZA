/// What is out there to be found, and what is lying about (§10, §4.8, §10.3).
///
/// Three lists that the map draws and the panel reads:
///
///   - the **places** worth turning over (§10.1, §10.2), which the world plans
///     around wherever the player has walked;
///   - what is on the **ground** (§4.8) — dropped, or shaken out of a place by
///     a search, and gone after a day;
///   - the **bodies** this character has left (§10.3), gone after twelve hours.
///
/// ⚠️ **Two of these used to be plain fields.** The pack and the shelves were
/// already notifiers, so moving them changed nothing; `_boxes` and `_remains`
/// were visible only through a `setState` on a six-thousand-line widget, which
/// is why nothing outside that widget could ever ask about them. They are
/// notifiers now, and the screen listens to them exactly as it listened to the
/// pack — one listener, one `setState`, the same frame as before. Narrowing
/// that down to the widgets that actually care is a later, separate change.
///
/// ⚠️ **One radius per place, and it lives here.** §10.2 gives a shop fifty
/// metres because its door is not where the map puts its dot; a bin gets
/// thirty because you reach it from the pavement. The same figure has to
/// decide whether a place can be searched, whether the player has walked off
/// mid-search, how far the find can be picked up from, and what ring the map
/// draws. They disagreed once, in three different ways, over one school.
library;

import 'package:flutter/foundation.dart';

import '../../combat/remains.dart';
import '../../combat/remains_store.dart';
import '../../data/db/database.dart';
import '../../loot/dropped_items.dart';
import '../../loot/dropped_store.dart';
import '../../loot/loot_spawner.dart';
import '../../loot/loot_store.dart';
import '../../loot/loot_table.dart';
import '../../loot/search.dart';
import '../../map/geometry.dart';
import '../../notes/note.dart';

class LootController extends ChangeNotifier {
  LootController(this._db);

  final SaveDatabase _db;

  /// §10.1, §10.2: the places on the map, whether or not they still hold
  /// anything — an emptied one stays as a grey dot for a week.
  final ValueNotifier<List<LootBox>> boxes = ValueNotifier(const []);

  /// §4.8: what is on the pavement, and gone in a day.
  final ValueNotifier<List<DroppedItem>> dropped = ValueNotifier(const []);

  /// §10.3: what this character has left lying, and gone in twelve hours.
  final ValueNotifier<List<Remains>> remains = ValueNotifier(const []);

  /// §10.2.1: places found by looking around rather than by being visible.
  ///
  /// A house that might or might not be abandoned is exactly what
  /// reconnaissance is for; a car in the street is visible from the pavement
  /// and is never in here.
  final Set<String> revealed = {};

  /// §19.1: the names the last plan gave the places it invented.
  PlaceNames placeNames = PlaceNames.none;

  /// §10.2.3: when reconnaissance last happened, and from where.
  DateTime? scoutedAt;
  GeoPoint? scoutedFrom;

  int? _profileId;
  LootTableSet? _tables;

  void bind({required int profileId}) => _profileId = profileId;

  /// §10.2, §10.2.1: the tables, which say how big a place is and whether it
  /// can be seen without going and looking.
  ///
  /// ⚠️ Separate from [bind] because the two arrive at different moments: the
  /// world is opened while the intro film plays, and the character some way
  /// after that. Null until then, and null behaves exactly as it did before —
  /// every place normal-sized and every place visible.
  set tables(LootTableSet? next) => _tables = next;

  // ------------------------------------------------------------- reading ---

  /// §10.2: how far this place is searched — and reached — from.
  double reachOf(LootBox box) =>
      searchReachFor(_tables?[box.tableId]?.size ?? PlaceSize.normal);

  /// §10.2.1: whether this place can be seen without going and looking.
  ///
  /// ⚠️ Not "was it invented". A car standing in the street is invented by
  /// §10.1 and is perfectly visible from the pavement; hiding everything
  /// invented meant a walk through a city showed no cars at all.
  bool isVisible(LootBox box) {
    final table = _tables?[box.tableId];
    if (table == null || !table.hidden) return true;
    return revealed.contains(box.poiId);
  }

  LootBox? byPoi(String poiId) =>
      boxes.value.where((box) => box.poiId == poiId).firstOrNull;

  /// §19.3: the place the player is standing at, if any.
  ///
  /// The nearest one whose own reach covers them. A bin is reached by hand and
  /// a supermarket has its door round the back; one radius made the second
  /// unreachable rather than awkward.
  LootBox? boxInReach(GeoPoint? at, DateTime now) {
    if (at == null) return null;

    LootBox? best;
    var bestDistance = double.infinity;

    for (final box in boxes.value) {
      // §10.2.1: a remembered place is a grey dot, not something to open.
      if (!box.isActiveAt(now) || !isVisible(box)) continue;

      final distance = box.position.distanceTo(at);
      if (distance > reachOf(box) || distance > bestDistance) continue;

      best = box;
      bestDistance = distance;
    }
    return best;
  }

  /// §4.8, §10.2: the widest reach any place near [at] grants.
  ///
  /// ⚠️ A pile is picked up from as far as its *place* is searched from. §10.2
  /// gives a shop fifty metres because its door is not where the dot is, and a
  /// search drops what it found at the dot — so with one fifteen-metre rule a
  /// player could turn a shop over from the pavement and then be unable to
  /// reach what they had just found. What they dropped themselves, and what a
  /// body left, keep §4.8's arm's length.
  double reachForPilesAt(GeoPoint at) {
    var reach = kStillnessM;

    for (final box in boxes.value) {
      final placeReach = reachOf(box);
      if (box.position.distanceTo(at) > placeReach) continue;
      if (placeReach > reach) reach = placeReach;
    }
    return reach;
  }

  /// §4.8: the heaps within reach of [at], nearest first.
  List<GroundPile> pilesInReach(GeoPoint? at) {
    if (at == null) return const [];
    return pilesWithin(dropped.value, at, reachM: reachForPilesAt(at));
  }

  // ------------------------------------------------------------- writing ---

  /// What was on the map when the app last closed.
  ///
  /// Read before anything is spawned, so a player who walked towards a marker
  /// and closed the app finds the same marker in the same place.
  Future<void> loadBoxes() async {
    final profileId = _profileId;
    if (profileId == null) return;

    boxes.value = await LootStore(_db).load(profileId);
    notifyListeners();
  }

  Future<void> reloadDropped(DateTime now) async {
    final profileId = _profileId;
    if (profileId == null) return;

    dropped.value = await DroppedStore(_db).load(profileId, now);
    notifyListeners();
  }

  Future<void> reloadRemains(DateTime now) async {
    final profileId = _profileId;
    if (profileId == null) return;

    remains.value = await RemainsStore(_db).load(profileId, now);
    notifyListeners();
  }

  /// Takes on what the world planned, names and all.
  void adopt(SpawnPlan plan) {
    boxes.value = plan.boxes;
    placeNames = plan.names;
    notifyListeners();
  }

  /// Puts [box] back in the list in place of the one with its poi id.
  ///
  /// ⚠️ By poi id rather than by position in the list: a plan can arrive
  /// between a search starting and finishing, and an index would then name
  /// somebody else's shop.
  void replace(LootBox box) {
    boxes.value = [
      for (final entry in boxes.value)
        if (entry.poiId == box.poiId) box else entry,
    ];
    notifyListeners();
  }

  /// §10.2.3: a place reconnaissance turned up, which is by definition one the
  /// player could not see.
  void reveal(LootBox box) {
    boxes.value = [...boxes.value, box];
    revealed.add(box.poiId);
    notifyListeners();
  }

  /// §10.2.3: remembers a look around, so the next one has to be worth it.
  void scouted(GeoPoint at, DateTime now) {
    scoutedAt = now;
    scoutedFrom = at;
  }

  /// §10.3: one more body on the pavement.
  void addBody(Remains body) {
    final before = remains.value;
    final next = addRemains(before, body);
    if (identical(next, before)) return;

    remains.value = next;
    notifyListeners();
  }

  void replaceBody(Remains body) {
    remains.value = [
      for (final other in remains.value)
        if (other.id == body.id) body else other,
    ];
    notifyListeners();
  }

  /// §10.3: forgets what is no longer worth walking back to.
  void sweep(DateTime now) {
    final before = remains.value;
    final next = sweepRemains(before, now);
    if (next.length == before.length) return;

    remains.value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    boxes.dispose();
    dropped.dispose();
    remains.dispose();
    super.dispose();
  }
}
