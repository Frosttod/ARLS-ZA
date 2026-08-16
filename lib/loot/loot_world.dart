/// The loot layer as the game uses it (§10).
///
/// Ties together the four pieces that already exist on their own: the pack the
/// player installed, the places inside it, the tables that say what a place
/// holds, and the spawner that decides which of them get a box. Everything
/// here is a consequence of one rule — loot appears where things really are —
/// so all of it depends on having a local pack to read.
///
/// **Only an installed pack works.** A streamed one is read over the network by
/// the renderer alone, and running a POI query across it would mean hundreds of
/// range requests on mobile data every time the player moves. Where the map is
/// streamed there is no loot layer yet, and the map view says so rather than
/// leaving the player wondering why nothing spawns.
library;

import 'dart:io';
import 'dart:isolate';

import '../map/geometry.dart';
import '../map/map_source.dart';
import '../map/poi_source.dart';
import '../safety/spawn_exclusion.dart';
import 'ground_reader.dart';
import 'loot_spawner.dart';
import 'loot_table.dart';
import 'procedural_points.dart';

/// §10.1: below this many places within the radius the map counts as thin, and
/// the procedural layer takes over.
const int kThinMapPoiCount = 8;

/// §10.1: what the layer tops the count up to. Substitute points number
/// `12 − density`, so a village with six real places gets six invented ones.
const int kThinMapTarget = 12;

/// How far the player must move before the spawner is worth running again.
///
/// Re-planning on every fix would read tiles once a second while somebody
/// walks. Three hundred metres is far enough that the near ring is worth
/// refilling and short enough that it happens during the walk, not after it.
const double kReplanAfterM = 300;

class LootWorld {
  LootWorld({required this.tables});

  final LootTableSet tables;

  /// The pack on disk. A path rather than an open archive, because the reading
  /// happens in another isolate and a file handle does not travel.
  String? _packPath;

  GeoPoint? _plannedAt;

  /// True while a plan is being read.
  ///
  /// ⚠️ Without this the spawner piles up. Snapshots arrive every second, the
  /// plan takes far longer than that on a phone, and [shouldReplan] keeps
  /// saying yes until one finishes — so a single walk past the 300 m mark
  /// started a new tile read every second, each decoding up to 25 gzipped
  /// tiles. That is what starved the position stream and brought back the weak
  /// signal warning: the GPS was fine, the isolate was busy.
  bool _planning = false;

  /// The §3.5 features from the last read, for anything else that needs them.
  List<MapFeature> _obstacles = const [];

  /// What the last pass over the tiles found in the way (§3.5).
  List<MapFeature> get obstacles => _obstacles;

  /// Points at the pack, or at nothing.
  Future<void> useSource(MapSource? source) async {
    final path = source is InstalledPack ? source.path : null;
    if (path == _packPath) return;

    _packPath = path != null && File(path).existsSync() ? path : null;
    _plannedAt = null;
  }

  Future<void> dispose() async {
    _packPath = null;
  }

  /// True when there is a pack to read places out of.
  bool get isReady => _packPath != null;

  /// Whether the spawner should run for a player standing here.
  bool shouldReplan(GeoPoint at) {
    if (_planning) return false;
    final last = _plannedAt;
    return last == null || last.distanceTo(at) >= kReplanAfterM;
  }

  /// Reads the places around [centre] and decides what should be there.
  ///
  /// Returns null where there is no pack, which is not a failure: the game runs
  /// without a map, it simply has nothing to spawn on.
  Future<SpawnPlan?> plan({
    required GeoPoint centre,
    required List<LootBox> existing,
    required DateTime now,
    required int seed,
  }) async {
    final path = _packPath;
    if (path == null || _planning) return null;

    // Claimed before the read, not after. The read is the slow part, and
    // leaving the claim until it finished is what let the next second's
    // snapshot start another one.
    _planning = true;
    _plannedAt = centre;

    final Ground ground;
    try {
      // ⚠️ Off the UI isolate. Reading two kilometres of a city means
      // decompressing and decoding up to 25 vector tiles; measured on a
      // desktop that is ~900 ms, and a phone is slower. Done here it froze the
      // frame *and* the platform channel carrying position updates.
      ground = await Isolate.run(
        () => readGround(
          packPath: path,
          latitude: centre.latitude,
          longitude: centre.longitude,
          radiusM: kSpawnRadiusBackupM,
        ),
      );
    } finally {
      _planning = false;
    }

    final places = ground.places;
    final withinNormal = places
        .where((poi) => poi.position.distanceTo(centre) <= kSpawnRadiusM)
        .toList();

    final found = _countMatching(withinNormal);
    final spawner = LootSpawner(
      tables: tables,
      backupMode: found < kThinMapPoiCount,
    );

    final obstacles = ground.obstacles;
    // Kept for whoever else has to obey §3.5. Reading two kilometres of city
    // costs the better part of a second, and the answer to "may a person be
    // sent here" is the same one whether the thing being placed is a lootbox
    // or a Walker.
    _obstacles = obstacles;
    final roads = obstacles.where(_isRoad).toList();
    var candidates = spawner.backupMode ? places : withinNormal;

    if (spawner.backupMode) {
      // §10.1: twelve minus what the map already gives. A village with six
      // real places gets six invented ones, not twelve — the layer fills a
      // gap rather than replacing what is there.
      candidates = [
        ...candidates,
        ...generateProceduralPoints(
          centre: centre,
          radiusM: spawner.radiusM,
          wanted: kThinMapTarget - found,
          seed: seed,
          roads: roads,
          areas: ground.areas,
        ),
      ];
    } else {
      // ⚠️ §10.1's density test is answered over two kilometres, and a city
      // passes it comfortably — but the player is standing in one spot, not
      // in an average. Measured on the southern edge of Poznań: fifteen boxes
      // placed, the nearest 653 m away and nothing at all inside the ring, in
      // a district the test calls dense.
      //
      // So the ring gets topped up locally, from the same generator §10.1
      // already uses, and only by as much as it is short.
      final nearReal = _countNear(candidates, centre);
      if (nearReal < kNearRing) {
        candidates = [
          ...candidates,
          ...generateProceduralPoints(
            centre: centre,
            radiusM: kNearRingM,
            wanted: kNearRing - nearReal,
            seed: seed,
            roads: roads,
            areas: ground.areas,
          ),
        ];
      }
    }

    return spawner.plan(
      centre: centre,
      candidates: candidates,
      existing: existing,
      now: now,
      seed: seed,
      names: ground.names,
      obstacles: obstacles,
    );
  }

  /// Roads only. The generator walks along them; rails and rivers are things
  /// to stay away from, not things to put a house beside.
  static bool _isRoad(MapFeature feature) =>
      feature.tags.containsKey('highway');

  /// How many candidates inside the near ring any table would take.
  int _countNear(List<Poi> places, GeoPoint centre) => places
      .where(
        (poi) =>
            poi.position.distanceTo(centre) <= kNearRingM &&
            tables.forTags(poi.selectors).isNotEmpty,
      )
      .length;

  /// How many places a real table wants. §10.1 counts lootable POI, not
  /// features: a district of car parks and bus shelters is a thin map.
  int _countMatching(List<Poi> places) => places
      .where(
        (poi) => tables
            .forTags(poi.selectors)
            .any((table) => table.source == LootSource.osm),
      )
      .length;
}
