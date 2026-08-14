/// Everything the loot layer needs off the map, read in one pass (§10).
///
/// ⚠️ **This runs in a background isolate.** Reading two kilometres of a city
/// means decompressing and decoding up to twenty-five vector tiles; on a
/// desktop that measured about 900 ms, and a phone is slower. Done on the UI
/// isolate it froze the frame and — worse — the platform channel carrying
/// position updates, so the game decided the GPS signal had gone weak while the
/// receiver was perfectly happy.
///
/// So the whole read is one function with no state: it takes a path and a
/// point, opens the archive itself, and hands back plain values. Nothing here
/// may touch a file handle owned by anybody else, because a handle does not
/// travel between isolates.
library;

import 'dart:io';

import '../map/geometry.dart';
import '../map/mvt.dart';
import '../map/omt_schema.dart';
import '../map/pmtiles_archive.dart';
import '../map/poi_source.dart';
import '../safety/spawn_exclusion.dart';
import 'procedural_points.dart';

/// One pass of the map, as three lists.
class Ground {
  const Ground({
    required this.places,
    required this.obstacles,
    required this.areas,
  });

  /// Places a loot table might want (§10.3).
  final List<Poi> places;

  /// Roads, rails and water — what §3.5 refuses to spawn on, and what §10.1
  /// walks along when it has to invent a village.
  final List<MapFeature> obstacles;

  /// Ground the generator reads to decide what an invented place would be.
  final List<GeneratedArea> areas;
}

/// Reads it all. Call inside `Isolate.run`.
Future<Ground> readGround({
  required String packPath,
  required double latitude,
  required double longitude,
  required double radiusM,
}) async {
  final archive = await PmtilesArchive.open(File(packPath));
  final centre = GeoPoint(latitude, longitude);

  try {
    return Ground(
      places: await PoiSource(archive).near(centre, radiusM: radiusM),
      obstacles: await _obstaclesNear(archive, centre),
      areas: await _areasNear(archive, centre),
    );
  } finally {
    await archive.close();
  }
}

/// The roads, rails and water that §3.5 refuses to spawn on.
///
/// Read from the same tiles as the places, in the same pass, so a road that
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
            geometry: _toGround(feature.points, tile.x + dx, tile.y + dy, decoded.extent),
          ),
        );
      }
    }
  }

  return features;
}

/// Houses in residential land, barns in farmland, hunting stands at the wood.
///
/// Measured in rural Wielkopolska: 368 farmland areas and 200 of woodland
/// across 25 tiles that hold 263 places in total. The ground is described where
/// the buildings are not (§10.1).
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

      final decoded = decodeMvt(bytes, layers: const {'landuse', 'landcover'});
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
            ring: _toGround(feature.points, tile.x + dx, tile.y + dy, decoded.extent),
          ),
        );
      }
    }
  }

  return areas;
}

List<GeoPoint> _toGround(
  List<({int x, int y})> points,
  int tileX,
  int tileY,
  int extent,
) => [
  for (final point in points)
    tileLocalToLatLon(
      tileX,
      tileY,
      kPoiZoom,
      (x: point.x.toDouble(), y: point.y.toDouble()),
      extent,
    ),
];
