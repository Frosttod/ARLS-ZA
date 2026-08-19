/// Where loot appears, and when it comes back (§10).
///
/// One lootbox per place, at most fifteen active within two kilometres, and
/// four to eight hours before a looted one refills. Those are §10's numbers and
/// they are a ceiling, not a target — the ceiling exists so a city does not
/// become a carpet of markers and the save does not fill with rows.
///
/// **Distance decides which candidates win, not chance alone.** Fifteen points
/// scattered evenly over a two-kilometre disc puts the nearest one four hundred
/// to nine hundred metres away, which is a walk across town for a tin of beans.
/// So the spawner fills a near ring first — [kNearRing] points inside
/// [kNearRingM] — and weights everything after that by 1/(1 + d/[kFalloffM]).
/// The cap is untouched; what changes is where the fifteen land.
///
/// Measured in Poznań: 5834 places within 2 km match a table and 997 of them
/// are inside 600 m, so in a city the ring is easy to fill and the cap is what
/// binds. In the country the opposite holds, which is what §10.1 is for.
///
/// **Deterministic.** The same player, place and hour produce the same loot:
/// §11 wants a session replayable from its seed, and a spawner that rolled
/// freshly on every app start would hand out a different world each time the
/// player reopened the game.
library;

import 'dart:math';

import '../map/geometry.dart';
import '../map/poi_source.dart';
import '../notes/note.dart';
import '../safety/spawn_exclusion.dart';
import 'procedural_points.dart' show kCarSelector, kWasteSelector;
import 'loot_table.dart';

/// §10: at most this many live at once within [kSpawnRadiusM].
const int kMaxActiveBoxes = 15;

/// §10. Also the radius the POI query runs over.
///
/// ⚠️ **Beta figure, deliberately below §10's two kilometres.** Measured on a
/// walk through Poznań: fourteen places on the map and the furthest of them
/// nearly two kilometres out — twenty-five minutes' walk each way, for one
/// shop. They were not errands, they were noise on the map, and a marker
/// nobody will ever walk to teaches a player to stop reading markers.
///
/// Twelve hundred metres is about fifteen minutes: far enough to be a
/// decision, near enough to be a decision somebody actually makes. §10's
/// figure comes back when hotspots (§6.5) give the far ones a reason to exist.
const double kSpawnRadiusM = 1200;

/// §10.1 widens the search where the map is thin.
///
/// A village has to reach further for anything at all, so the backup keeps
/// half again on top — the same ratio §10.1 had at the wider figure.
const double kSpawnRadiusBackupM = 1800;

/// How many are guaranteed close enough to be worth a detour rather than a
/// journey. Six hundred metres is seven minutes' walk.
const int kNearRing = 5;
const double kNearRingM = 600;

/// §10.1: how many invented cars and bins a street keeps, whatever else is
/// on it.
///
/// ⚠️ These are not the car parks §10.1 keeps out of a city. That rule counts
/// *tagged* places — 4165 car parks against 427 grocers within 2 km of the
/// middle of Poznań — and it is right to keep them from drowning the map. But
/// a generated car and a generated bin are neither tagged nor numerous: there
/// are a handful of them, they are the most ordinary things on any street, and
/// they carry exactly what §18.2 is short of.
///
/// Measured on a walk through dense Poznań: the near ring filled with real
/// shops on the first pass, the fallback pool was never reached, and a city
/// produced no cars and no bins at all. So they get a small reservation
/// instead of a place in the queue — out of §10's fifteen, not on top of them.
const int kFurnitureNearby = 3;

/// How fast the odds fall off with distance beyond the ring. At 400 m a place
/// is half as likely as one underfoot, at 1200 m a quarter.
const double kFalloffM = 400;

/// How long an emptied place takes to be worth returning to.
///
/// ⚠️ Eighteen to thirty-six hours, against §10's four to eight — and this is
/// a departure the walking made obvious. Four hours means a shop stripped on
/// the way to work is full again at lunchtime, which is not a city anybody has
/// been looting: it is a respawning arcade, and it removes the only reason to
/// walk somewhere new.
///
/// A day or so instead. The place is there tomorrow, not this afternoon — so
/// the loop of the game becomes covering ground rather than circling three
/// shops, and §10.2.1's grey dots are worth reading because they stay true for
/// a walk rather than for an hour.
///
/// Not a flat day, because a player who learns one interval times the whole
/// city by it. The spread is rolled per place, at the moment it is emptied.
const Duration kRespawnMin = Duration(hours: 18);
const Duration kRespawnMax = Duration(hours: 36);

/// §10.1: faster where the map is thin, for the same reason the radius is
/// wider there — a village has fewer places, so each has to come back sooner
/// or there is no game in it at all.
const Duration kRespawnBackupMin = Duration(hours: 10);
const Duration kRespawnBackupMax = Duration(hours: 20);

/// §10.2.1: how long a place the player emptied stays on their map.
///
/// ⚠️ Memory, not state. The place itself refills in four to eight hours and
/// the dot goes back to colour then — this is only the outer bound on
/// remembering having been somewhere, for the case where the player does not
/// come back and it never refills under their eye.
///
/// A week, because that is roughly how long "I did that street on Tuesday" is
/// worth anything. Longer and the map fills with a fortnight of grey nobody
/// reads; shorter and it forgets faster than a player does.
const Duration kSearchedMemory = Duration(days: 7);

/// Beyond this a box is forgotten rather than kept. Without it a player who
/// walks across a country accumulates every box they ever passed.
const double kForgetRadiusM = 4000;

/// One place with something in it.
class LootBox {
  const LootBox({
    required this.poiId,
    required this.position,
    required this.tableId,
    required this.spawnedAt,
    this.name,
    this.lootedAt,
    this.respawnAt,
    this.openedAt,
    this.searchUnits = 0,
  });

  /// The place it sits on, from [Poi.id]. What makes "one box per place" hold
  /// across restarts.
  final String poiId;

  final GeoPoint position;
  final String tableId;
  final String? name;

  final DateTime spawnedAt;

  /// Null while it still has something in it.
  final DateTime? lootedAt;

  /// When it refills. Rolled at the moment it is emptied, so a player cannot
  /// learn one interval and time the whole city by it.
  final DateTime? respawnAt;

  /// When §19.3's barrier was got through. Null while the place is still shut.
  final DateTime? openedAt;

  /// How much of [kSearchBudget] has been spent turning this place over.
  ///
  /// Three quick passes, two thorough ones or one deep one, in any mix that
  /// fits. A place is not a vending machine that gives one handful and shuts:
  /// a player who looked quickly and walked on can come back and look properly
  /// — until there is genuinely nothing left, which is what empties it.
  final int searchUnits;

  bool get isOpen => openedAt != null;

  int get searchUnitsLeft => kSearchBudget - searchUnits;

  /// Whether there is enough left of the place for one pass at this depth.
  bool canSearchAt(SearchDepth depth) => depth.cost <= searchUnitsLeft;

  /// The place after one pass at [depth].
  ///
  /// It empties when what is left cannot pay for the cheapest look there is —
  /// the shelves are bare rather than the timer being up.
  LootBox searchedAt(
    SearchDepth depth,
    DateTime now,
    Random random, {
    bool backup = false,
  }) {
    final spent = searchUnits + depth.cost;
    final exhausted = kSearchBudget - spent < SearchDepth.shallow.cost;

    final next = LootBox(
      poiId: poiId,
      position: position,
      tableId: tableId,
      name: name,
      spawnedAt: spawnedAt,
      lootedAt: lootedAt,
      respawnAt: respawnAt,
      openedAt: openedAt,
      searchUnits: spent,
    );

    return exhausted ? next.lootedAtTime(now, random, backup: backup) : next;
  }

  /// The same box, with the way in made.
  LootBox openedAtTime(DateTime now) => LootBox(
    poiId: poiId,
    position: position,
    tableId: tableId,
    name: name,
    spawnedAt: spawnedAt,
    lootedAt: lootedAt,
    respawnAt: respawnAt,
    openedAt: now,
    searchUnits: searchUnits,
  );

  bool isActiveAt(DateTime now) {
    if (lootedAt == null) return true;
    final at = respawnAt;
    return at != null && !now.isBefore(at);
  }

  /// §10.2.1: whether this is still worth a grey dot.
  ///
  /// A place the player emptied stays on the map, in grey, saying "you have
  /// been here" rather than "there is something here". It goes back to colour
  /// the moment it refills — the memory and the contents are two different
  /// facts, and the dot carries both.
  bool isRememberedAt(DateTime now) {
    final at = lootedAt;
    if (at == null) return false;
    return now.difference(at) < kSearchedMemory;
  }

  /// Worth drawing at all: either it holds something, or the player emptied it
  /// recently enough to be worth remembering.
  bool isKnownAt(DateTime now) => isActiveAt(now) || isRememberedAt(now);

  LootBox lootedAtTime(DateTime now, Random random, {bool backup = false}) {
    final min = backup ? kRespawnBackupMin : kRespawnMin;
    final max = backup ? kRespawnBackupMax : kRespawnMax;
    final spread = max.inMinutes - min.inMinutes;

    return LootBox(
      poiId: poiId,
      position: position,
      tableId: tableId,
      name: name,
      spawnedAt: spawnedAt,
      lootedAt: now,
      respawnAt: now.add(
        Duration(minutes: min.inMinutes + random.nextInt(spread)),
      ),
      openedAt: openedAt,
      searchUnits: searchUnits,
    );
  }

  /// After a respawn the box is simply full again — same place, same table,
  /// and the door somebody already forced is still open.
  LootBox refilledAt(DateTime now) => LootBox(
    poiId: poiId,
    position: position,
    tableId: tableId,
    name: name,
    spawnedAt: now,
    openedAt: openedAt,
  );
}

/// What one pass of the spawner decided.
class SpawnPlan {
  const SpawnPlan({
    required this.boxes,
    required this.added,
    required this.forgotten,
    this.names = PlaceNames.none,
  });

  /// Everything that should exist after this pass.
  final List<LootBox> boxes;

  final List<LootBox> added;

  /// Boxes dropped for being too far away to matter.
  final List<LootBox> forgotten;

  /// What the map calls this place (§19.1.1). Carried on the plan because it
  /// comes from the same pass over the tiles the candidates did, and reading
  /// them twice would be reading a city twice.
  final PlaceNames names;
}

class LootSpawner {
  const LootSpawner({required this.tables, this.backupMode = false});

  final LootTableSet tables;

  /// §10.1's mode for a thin map: procedural points count, respawn is faster
  /// and the radius is wider.
  final bool backupMode;

  double get radiusM => backupMode ? kSpawnRadiusBackupM : kSpawnRadiusM;

  /// Decides what should exist around [centre] now.
  ///
  /// [existing] is what is already saved. Boxes are kept wherever possible —
  /// a player who walked to a marker must find it still there, so this only
  /// ever adds, refills and forgets.
  SpawnPlan plan({
    required GeoPoint centre,
    required List<Poi> candidates,
    required List<LootBox> existing,
    required DateTime now,
    required int seed,
    PlaceNames names = PlaceNames.none,

    /// §3.5. A place on the map is not automatically a place a person can
    /// stand: the middle of a carriageway, a level crossing and a private yard
    /// are all somewhere the game must never send anybody. Passed in because
    /// the same tiles that produced the candidates produced these.
    List<MapFeature> obstacles = const [],
  }) {
    final filter = SpawnFilter(obstacles);
    final kept = <LootBox>[];
    final forgotten = <LootBox>[];

    for (final box in existing) {
      if (box.position.distanceTo(centre) > kForgetRadiusM) {
        forgotten.add(box);
        continue;
      }
      // A respawn is not a new box: same place, same table, full again.
      kept.add(
        box.lootedAt != null && box.isActiveAt(now) ? box.refilledAt(now) : box,
      );
    }

    final taken = {for (final box in kept) box.poiId};
    final activeNearby = kept
        .where(
          (box) =>
              box.isActiveAt(now) && box.position.distanceTo(centre) <= radiusM,
        )
        .length;

    var room = kMaxActiveBoxes - activeNearby;
    if (room <= 0) {
      return SpawnPlan(
        boxes: kept,
        added: const [],
        forgotten: forgotten,
        names: names,
      );
    }

    // A place is only a candidate if a table wants it, nothing already sits on
    // it, and §3.5 will let a person stand there.
    final available = <({Poi poi, LootTable table, double distance})>[];

    // ⚠️ Car parks, recycling points, bus shelters and lock-ups, near enough to
    // be worth walking to.
    //
    // §10.1 keeps these out of a city, on the reasoning that a city has real
    // shops — and measured over 2 km of Poznań it does: 4165 car parks against
    // 427 grocers, which is why the rule exists. But a player standing on a
    // residential estate has none of those 427 within six hundred metres, and
    // got a game with nothing in it. Found on a walk, not in a test.
    //
    // These are real places, not invented ones, and §10.1 already prices them
    // at 55%. They fill the near ring only when nothing better can.
    final nearFallback = <({Poi poi, LootTable table, double distance})>[];

    for (final poi in candidates) {
      if (taken.contains(poi.id)) continue;

      // Outside the radius the cap is counted over. A candidate further out
      // would let the spawner keep placing boxes for ever: each one lands
      // beyond 2 km, so none of them counts against the fifteen.
      final distance = poi.position.distanceTo(centre);
      if (distance > radiusM) continue;

      // ⚠️ Which table wants it first, §3.5 second, and in that order.
      //
      // Refusing by geometry means walking every road and river near the
      // player for each candidate. Doing that before the table lookup ran it
      // over all 31 195 features around central Poznań instead of the 5834 a
      // table actually wants, and one plan went from 0.9 s to 16 s.
      final table = _tableFor(poi);
      final fallback = table == null && !backupMode && distance <= kNearRingM
          ? _fallbackTableFor(poi)
          : null;
      if (table == null && fallback == null) continue;

      final refusal = filter.refuse(poi.position);
      if (refusal != null) continue;

      if (table != null) {
        available.add((poi: poi, table: table, distance: distance));
      } else {
        nearFallback.add((poi: poi, table: fallback!, distance: distance));
      }
    }
    if (available.isEmpty && nearFallback.isEmpty) {
      return SpawnPlan(
        boxes: kept,
        added: const [],
        forgotten: forgotten,
        names: names,
      );
    }

    final random = Random(seed ^ _hourStamp(now));
    final added = <LootBox>[];

    // The near ring first, and only as much of it as is missing: a player who
    // already has four boxes under their nose does not need five more.
    final nearActive = kept
        .where(
          (box) =>
              box.isActiveAt(now) &&
              box.position.distanceTo(centre) <= kNearRingM,
        )
        .length;

    // §10.1: the reservation, taken before the ring is filled with shops.
    //
    // Nearest first and no weighting: three of them is not enough for a
    // weighted draw to mean anything, and the nearest bin is the one worth
    // fifteen seconds on the way past.
    final furnitureIds = _furnitureTables;
    final standing = kept
        .where(
          (box) =>
              box.isActiveAt(now) &&
              furnitureIds.contains(box.tableId) &&
              box.position.distanceTo(centre) <= kNearRingM,
        )
        .length;

    // ⚠️ Chosen by the selector, counted by the table.
    //
    // The two tables also match a real, tagged car park, and the reservation
    // must never hand one of §10.1's 4165 of those a place a shop could have
    // had — so only invented points are picked. Counting is the other way
    // round on purpose: a real car park already standing nearby is a car to
    // search, and inventing another one beside it would be the map repeating
    // itself.
    final furniture =
        nearFallback
            .where(
              (c) =>
                  c.poi.selectors.contains(kCarSelector) ||
                  c.poi.selectors.contains(kWasteSelector),
            )
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));

    for (var i = standing; i < kFurnitureNearby && room > 0; i++) {
      if (furniture.isEmpty) break;
      final pick = furniture.removeAt(0);
      nearFallback.remove(pick);
      added.add(_boxAt(pick, now, seed));
      room--;
    }

    final near = available.where((c) => c.distance <= kNearRingM).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    for (var i = 0; i < kNearRing - nearActive && room > 0; i++) {
      // Real shops first, always. The fallback is what an estate has, not what
      // a high street has, and it should never displace the high street.
      final pool = near.isNotEmpty ? near : nearFallback;
      if (pool.isEmpty) break;

      // Not simply the closest five: that would put every box on the same
      // street corner. One of the nearest handful, chosen by weight.
      final pick = _weightedPick(pool, random);
      if (pick == null) break;
      pool.remove(pick);
      available.remove(pick);
      added.add(_boxAt(pick, now, seed));
      room--;
    }

    while (room > 0 && available.isNotEmpty) {
      final pick = _weightedPick(available, random);
      if (pick == null) break;
      available.remove(pick);
      added.add(_boxAt(pick, now, seed));
      room--;
    }

    return SpawnPlan(
      boxes: [...kept, ...added],
      added: added,
      forgotten: forgotten,
      names: names,
    );
  }

  LootBox _boxAt(
    ({Poi poi, LootTable table, double distance}) pick,
    DateTime now,
    int seed,
  ) {
    // §19.3: somebody got here first, sometimes.
    //
    // Seeded from the place and the character rather than from the clock, so
    // a shop that stood open yesterday stands open today. A world where every
    // door is shut is a world nobody else lived in.
    final barrier = pick.table.barrier;
    final open =
        barrier == null ||
        Random(seed ^ pick.poi.id.hashCode).nextDouble() <
            barrier.alreadyOpenShare;

    return LootBox(
      poiId: pick.poi.id,
      position: pick.poi.position,
      tableId: pick.table.id,
      name: pick.poi.name,
      spawnedAt: now,
      openedAt: barrier != null && open ? now : null,
    );
  }

  /// The tables a generated car and a generated bin belong to.
  ///
  /// Read out of the data rather than named here: the ids live in
  /// `loot_tables.json` beside everything else, and a second copy of them in
  /// code is a second thing to keep in step.
  Set<String> get _furnitureTables => {
    for (final selector in const [kCarSelector, kWasteSelector])
      for (final table in tables.forTags([selector])) table.id,
  };

  /// Which table this place belongs to, or null where none wants it.
  ///
  /// Procedural tables are ignored unless §10.1's backup mode is on. Without
  /// that rule a city would spawn nothing but car parks: there are 4165 of
  /// them within 2 km of the middle of Poznań and 427 grocery shops.
  LootTable? _tableFor(Poi poi) {
    for (final table in tables.forTags(poi.selectors)) {
      if (table.source == LootSource.procedural && !backupMode) continue;
      return table;
    }
    return null;
  }

  /// The procedural table for a place, used only to keep the near ring from
  /// being empty in a city (see [plan]).
  ///
  /// Generated places count here as well as tagged ones. A district can be
  /// dense enough for §10.1's test and still have nothing at all within six
  /// hundred metres of where somebody happens to be standing; refusing the
  /// invented points there left the ring empty for the sake of a rule about
  /// two-kilometre averages.
  LootTable? _fallbackTableFor(Poi poi) {
    for (final table in tables.forTags(poi.selectors)) {
      if (table.source == LootSource.procedural) return table;
    }
    return null;
  }

  /// Picks by 1/(1 + d/falloff), so near places win more often without near
  /// being the only thing that can happen.
  ({Poi poi, LootTable table, double distance})? _weightedPick(
    List<({Poi poi, LootTable table, double distance})> from,
    Random random,
  ) {
    if (from.isEmpty) return null;

    var total = 0.0;
    for (final candidate in from) {
      total += 1 / (1 + candidate.distance / kFalloffM);
    }

    var roll = random.nextDouble() * total;
    for (final candidate in from) {
      roll -= 1 / (1 + candidate.distance / kFalloffM);
      if (roll <= 0) return candidate;
    }
    return from.last;
  }

  /// Rounds to the hour so a pass repeated within the same hour decides the
  /// same thing — the game re-plans on every resume, and a player who reopens
  /// the app twice in a minute should not see the map rearrange itself.
  static int _hourStamp(DateTime now) =>
      now.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerHour;
}
