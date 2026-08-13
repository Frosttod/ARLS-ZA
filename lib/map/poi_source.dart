/// The places near the player, read straight from the map pack (§10).
///
/// Loot spawns where things are: a pharmacy is loot because there is a pharmacy
/// there, on the real map, in the real street. That is the strongest idea in
/// the design — a player learns their own city through survival — and it needs
/// the game to know what the map knows, which means reading the tiles.
///
/// Reads happen off the map view entirely. The spawner runs whether or not the
/// map is on screen, and the answers have to be the same either way.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'mvt.dart';
import 'omt_schema.dart';
import 'pmtiles_archive.dart';

/// A place on the map that the game can do something with.
class Poi {
  const Poi({
    required this.position,
    required this.selectors,
    required this.name,
    required this.layer,
  });

  final GeoPoint position;

  /// What this place is, in the vocabulary loot tables match on
  /// (`poi.subclass=pharmacy`). More than one, because a feature has both a
  /// class and a subclass and tables key off either.
  final List<String> selectors;

  /// The name from the tile, where it has one. Shown on the marker: a player
  /// who reads "Apteka Pod Orłem" is being told something about their own city.
  final String? name;

  final String layer;

  /// A stable identity for this place, so a lootbox spawned on it can be found
  /// again after a restart without storing the whole feature.
  ///
  /// Position to six decimals — about 11 cm — plus what it is. Two pharmacies
  /// in one building would collide; two pharmacies in one building would also
  /// be one pharmacy as far as a player walking to it is concerned.
  String get id =>
      '${position.latitude.toStringAsFixed(6)},'
      '${position.longitude.toStringAsFixed(6)}:'
      '${selectors.isEmpty ? layer : selectors.first}';
}

/// Reads places out of a pack.
class PoiSource {
  const PoiSource(this._archive);

  final PmtilesArchive _archive;

  /// Every place within [radiusM] of [centre] that carries a selector.
  ///
  /// Tiles are read at [kPoiZoom] because that is the only zoom that has POI in
  /// it — measured, not assumed: one z14 tile over central Poznań holds 7331
  /// of them and the z13 tile above it holds nine.
  Future<List<Poi>> near(
    GeoPoint centre, {
    required double radiusM,
    Set<String> layers = kGameplayLayers,
  }) async {
    final found = <Poi>[];

    for (final tile in _tilesCovering(centre, radiusM, kPoiZoom)) {
      final bytes = await _archive.tile(kPoiZoom, tile.x, tile.y);
      if (bytes == null) continue;

      final decoded = decodeMvt(bytes, layers: layers);
      for (final feature in decoded.features) {
        final selectors = selectorsFor(feature).toList();
        if (selectors.isEmpty) continue;

        final at = feature.centre;
        if (at == null) continue;

        final position = tileLocalToLatLon(
          tile.x,
          tile.y,
          kPoiZoom,
          at,
          decoded.extent,
        );
        if (position.distanceTo(centre) > radiusM) continue;

        found.add(
          Poi(
            position: position,
            selectors: selectors,
            name: feature.properties['name'] as String?,
            layer: feature.layer,
          ),
        );
      }
    }

    return found;
  }

  /// Which tiles a circle touches.
  static Iterable<({int x, int y})> _tilesCovering(
    GeoPoint centre,
    double radiusM,
    int zoom,
  ) sync* {
    final dLat = radiusM / metresPerDegreeLat;
    final dLon = radiusM / metresPerDegreeLon(centre.latitude);

    final topLeft = tileOf(
      centre.latitude + dLat,
      centre.longitude - dLon,
      zoom,
    );
    final bottomRight = tileOf(
      centre.latitude - dLat,
      centre.longitude + dLon,
      zoom,
    );

    for (var x = topLeft.x; x <= bottomRight.x; x++) {
      for (var y = topLeft.y; y <= bottomRight.y; y++) {
        yield (x: x, y: y);
      }
    }
  }
}

/// Web-Mercator tile containing a coordinate.
({int x, int y}) tileOf(double latitude, double longitude, int zoom) {
  final n = 1 << zoom;
  final latRad = latitude * math.pi / 180;

  return (
    x: ((longitude + 180) / 360 * n).floor().clamp(0, n - 1),
    y:
        ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
                2 *
                n)
            .floor()
            .clamp(0, n - 1),
  );
}

/// Tile-local coordinates back to the ground.
GeoPoint tileLocalToLatLon(
  int tileX,
  int tileY,
  int zoom,
  ({double x, double y}) local,
  int extent,
) {
  final n = 1 << zoom;
  final worldX = (tileX + local.x / extent) / n;
  final worldY = (tileY + local.y / extent) / n;

  final longitude = worldX * 360 - 180;
  final latitude =
      math.atan(_sinh(math.pi * (1 - 2 * worldY))) * 180 / math.pi;

  return GeoPoint(latitude, longitude);
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
