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

import '../map/geometry.dart';
import '../map/map_source.dart';
import '../map/mvt.dart';
import '../map/omt_schema.dart';
import '../map/pmtiles_archive.dart';
import '../map/poi_source.dart';
import '../safety/spawn_exclusion.dart';
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

  PmtilesArchive? _archive;
  String? _openedPath;

  GeoPoint? _plannedAt;

  /// Opens the pack, or does nothing where there is nothing to open.
  Future<void> useSource(MapSource? source) async {
    final path = source is InstalledPack ? source.path : null;
    if (path == _openedPath) return;

    await _archive?.close();
    _archive = null;
    _openedPath = path;
    _plannedAt = null;

    if (path == null) return;
    final file = File(path);
    if (!file.existsSync()) return;

    _archive = await PmtilesArchive.open(file);
  }

  Future<void> dispose() async {
    await _archive?.close();
    _archive = null;
  }

  /// True when there is a pack to read places out of.
  bool get isReady => _archive != null;

  /// Whether the spawner should run for a player standing here.
  bool shouldReplan(GeoPoint at) {
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
    final archive = _archive;
    if (archive == null) return null;

    final source = PoiSource(archive);

    // Read once at the wider radius, then decide whether the map is thin.
    // Doing it the other way round would mean reading the tiles twice.
    final places = await source.near(centre, radiusM: kSpawnRadiusBackupM);

    final withinNormal = places
        .where((poi) => poi.position.distanceTo(centre) <= kSpawnRadiusM)
        .toList();

    final found = _countMatching(withinNormal);
    final spawner = LootSpawner(
      tables: tables,
      backupMode: found < kThinMapPoiCount,
    );

    _plannedAt = centre;

    final obstacles = await _obstaclesNear(archive, centre);
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
          roads: obstacles.where(_isRoad).toList(),
          areas: await _areasNear(archive, centre),
        ),
      ];
    }

    return spawner.plan(
      centre: centre,
      candidates: candidates,
      existing: existing,
      now: now,
      seed: seed,
      obstacles: obstacles,
    );
  }

  /// Roads only. The generator walks along them; rails and rivers are things
  /// to stay away from, not things to put a house beside.
  static bool _isRoad(MapFeature feature) =>
      feature.tags.containsKey('highway');

  /// The ground the generator reads to decide what a place would be: houses in
  /// residential land, barns in farmland, hunting stands at the wood.
  ///
  /// Measured in rural Wielkopolska: 368 farmland areas, 200 of woodland and 23
  /// of residential land across 25 tiles that hold 263 places in total. The
  /// ground is described where the buildings are not.
  Future<List<GeneratedArea>> _areasNear(
    PmtilesArchive archive,
    GeoPoint centre,
  ) async {
    final areas = <GeneratedArea>[];
    final tile = tileOf(centre.latitude, centre.longitude, kPoiZoom);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final bytes = await archive.tile(kPoiZoom, tile.x + dx, tile.y + dy);
        if (bytes == null) continue;

        final decoded = decodeMvt(
          bytes,
          layers: const {'landuse', 'landcover'},
        );
        for (final feature in decoded.features) {
          if (feature.geometry != MvtGeometry.polygon) continue;

          final selector = selectorsFor(feature).firstWhere(
            kGeneratedSelectors.containsKey,
            orElse: () => '',
          );
          if (selector.isEmpty) continue;

          areas.add(
            GeneratedArea(
              selector: selector,
              ring: [
                for (final point in feature.points)
                  tileLocalToLatLon(
                    tile.x + dx,
                    tile.y + dy,
                    kPoiZoom,
                    (x: point.x.toDouble(), y: point.y.toDouble()),
                    decoded.extent,
                  ),
              ],
            ),
          );
        }
      }
    }

    return areas;
  }

  /// How many places a real table wants. §10.1 counts lootable POI, not
  /// features: a district of car parks and bus shelters is a thin map.
  int _countMatching(List<Poi> places) => places
      .where(
        (poi) => tables
            .forTags(poi.selectors)
            .any((table) => table.source == LootSource.osm),
      )
      .length;

  /// The roads, rails and water that §3.5 refuses to spawn on.
  ///
  /// Read from the same tiles as the places, at the same moment, so a road that
  /// exists on the map cannot be missing from the check.
  Future<List<MapFeature>> _obstaclesNear(
    PmtilesArchive archive,
    GeoPoint centre,
  ) async {
    final features = <MapFeature>[];

    final tile = tileOf(centre.latitude, centre.longitude, kPoiZoom);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final bytes = await archive.tile(kPoiZoom, tile.x + dx, tile.y + dy);
        if (bytes == null) continue;

        final decoded = decodeMvt(
          bytes,
          layers: const {'transportation', 'water', 'waterway'},
        );
        for (final feature in decoded.features) {
          final tags = osmTagsFor(feature);
          if (tags.isEmpty || feature.points.isEmpty) continue;

          features.add(
            MapFeature(
              tags: tags,
              shape: feature.geometry == MvtGeometry.polygon
                  ? FeatureShape.area
                  : FeatureShape.line,
              geometry: [
                for (final point in feature.points)
                  tileLocalToLatLon(
                    tile.x + dx,
                    tile.y + dy,
                    kPoiZoom,
                    (x: point.x.toDouble(), y: point.y.toDouble()),
                    decoded.extent,
                  ),
              ],
            ),
          );
        }
      }
    }

    return features;
  }
}
