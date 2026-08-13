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
import '../safety/spawn_exclusion.dart';
import 'loot_table.dart';

/// §10: at most this many live at once within [kSpawnRadiusM].
const int kMaxActiveBoxes = 15;

/// §10. Also the radius the POI query runs over.
const double kSpawnRadiusM = 2000;

/// §10.1 widens the search where the map is thin.
const double kSpawnRadiusBackupM = 3000;

/// How many are guaranteed close enough to be worth a detour rather than a
/// journey. Six hundred metres is seven minutes' walk.
const int kNearRing = 5;
const double kNearRingM = 600;

/// How fast the odds fall off with distance beyond the ring. At 400 m a place
/// is half as likely as one underfoot, at 1200 m a quarter.
const double kFalloffM = 400;

/// §10: four to eight hours, and §10.1's three to five where the map is thin.
const Duration kRespawnMin = Duration(hours: 4);
const Duration kRespawnMax = Duration(hours: 8);
const Duration kRespawnBackupMin = Duration(hours: 3);
const Duration kRespawnBackupMax = Duration(hours: 5);

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

  bool isActiveAt(DateTime now) {
    if (lootedAt == null) return true;
    final at = respawnAt;
    return at != null && !now.isBefore(at);
  }

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
      respawnAt: now.add(Duration(minutes: min.inMinutes + random.nextInt(spread))),
    );
  }

  /// After a respawn the box is simply full again — same place, same table.
  LootBox refilledAt(DateTime now) => LootBox(
    poiId: poiId,
    position: position,
    tableId: tableId,
    name: name,
    spawnedAt: now,
  );
}

/// What one pass of the spawner decided.
class SpawnPlan {
  const SpawnPlan({
    required this.boxes,
    required this.added,
    required this.forgotten,
  });

  /// Everything that should exist after this pass.
  final List<LootBox> boxes;

  final List<LootBox> added;

  /// Boxes dropped for being too far away to matter.
  final List<LootBox> forgotten;
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
      return SpawnPlan(boxes: kept, added: const [], forgotten: forgotten);
    }

    // A place is only a candidate if a table wants it, nothing already sits on
    // it, and §3.5 will let a person stand there.
    final available = <({Poi poi, LootTable table, double distance})>[];
    for (final poi in candidates) {
      if (taken.contains(poi.id)) continue;

      // Outside the radius the cap is counted over. A candidate further out
      // would let the spawner keep placing boxes for ever: each one lands
      // beyond 2 km, so none of them counts against the fifteen.
      final distance = poi.position.distanceTo(centre);
      if (distance > radiusM) continue;

      final table = _tableFor(poi);
      if (table == null) continue;

      final refusal = filter.refuse(poi.position);
      if (refusal != null) continue;

      available.add((poi: poi, table: table, distance: distance));
    }
    if (available.isEmpty) {
      return SpawnPlan(boxes: kept, added: const [], forgotten: forgotten);
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

    final near = available.where((c) => c.distance <= kNearRingM).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    for (var i = 0; i < kNearRing - nearActive && room > 0; i++) {
      if (near.isEmpty) break;
      // Not simply the closest five: that would put every box on the same
      // street corner. One of the nearest handful, chosen by weight.
      final pick = _weightedPick(near, random);
      if (pick == null) break;
      near.remove(pick);
      available.remove(pick);
      added.add(_boxAt(pick, now));
      room--;
    }

    while (room > 0 && available.isNotEmpty) {
      final pick = _weightedPick(available, random);
      if (pick == null) break;
      available.remove(pick);
      added.add(_boxAt(pick, now));
      room--;
    }

    return SpawnPlan(
      boxes: [...kept, ...added],
      added: added,
      forgotten: forgotten,
    );
  }

  LootBox _boxAt(({Poi poi, LootTable table, double distance}) pick, DateTime now) =>
      LootBox(
        poiId: pick.poi.id,
        position: pick.poi.position,
        tableId: pick.table.id,
        name: pick.poi.name,
        spawnedAt: now,
      );

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
