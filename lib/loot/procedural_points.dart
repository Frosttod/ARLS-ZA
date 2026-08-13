/// Places invented where the map has none (§10.1).
///
/// §10.1 exists because the game otherwise only works in large cities. In a
/// town under about fifteen thousand people the shops and pharmacies §10 keys
/// off simply are not there, and that is most of the country: measured over the
/// same twelve kilometres, central Poznań carries 74 455 places and a stretch
/// of rural Wielkopolska carries 263.
///
/// The doc's substitute points are abandoned houses, barns, garages and hunting
/// stands. Three of those cannot be found: the OpenMapTiles building layer has
/// no type on it at all, so `building=house` and `building=barn` match nothing
/// however the selector is written (see `omt_schema.dart`). They have to be
/// invented instead, which is what this does — and the ground it invents them
/// on is real:
///
/// - `landuse.class=residential` → an abandoned house
/// - `landcover.class=farmland` → a barn
/// - `landcover.class=wood` → a hunting stand
/// - anything else → §10.1's last layer, points spaced along the road
///
/// **Points sit beside roads, never on them.** Every candidate is offset
/// perpendicular from the carriageway, because a generated point is still a
/// place the game asks a person to walk to (§3.5). The spawner checks the
/// exclusions again afterwards; this is about not proposing nonsense in the
/// first place.
///
/// **Deterministic.** The same seed and the same map give the same points, so a
/// village does not rearrange itself between sessions.
library;

import 'dart:math';

import '../map/geometry.dart';
import '../map/poi_source.dart';
import '../safety/spawn_exclusion.dart';

/// How far apart candidates are placed along a road.
///
/// Two hundred and fifty metres is roughly three minutes' walk: close enough
/// that a village road produces several, far enough that they do not read as a
/// row of identical markers.
const double kRoadStepM = 250;

/// How close two invented places may be to each other.
///
/// Without it the nearest-first choice puts the whole village on one lane, a
/// row of markers two hundred metres long.
const double kMinSeparationM = 300;

/// How far off the carriageway a point sits. §3.5 keeps spawns 15 m from a
/// road; twenty gives that rule room and puts the point where a building would
/// actually be.
const double kRoadOffsetM = 20;

/// An area the generator can recognise, reduced to what it needs.
class GeneratedArea {
  const GeneratedArea({required this.selector, required this.ring});

  /// The OpenMapTiles selector this area came from.
  final String selector;

  final List<GeoPoint> ring;
}

/// What §10.1 calls a substitute point, in the form the spawner already reads.
///
/// The selectors are the ones the generated tables carry, so nothing downstream
/// needs to know whether a place was found or invented — except the table
/// itself, which is procedural and therefore pays 55%.
const Map<String, String> kGeneratedSelectors = {
  'landuse.class=residential': 'generated.house',
  'landcover.class=farmland': 'generated.barn',
  'landcover.class=wood': 'generated.hunting_stand',
};

/// The fallback when a point falls on none of the above.
const String kRoadsideSelector = 'generated.roadside';

/// Invents up to [wanted] places around [centre].
///
/// [roads] and [areas] come from the same tiles the real places did.
List<Poi> generateProceduralPoints({
  required GeoPoint centre,
  required double radiusM,
  required int wanted,
  required int seed,
  required List<MapFeature> roads,
  required List<GeneratedArea> areas,
}) {
  if (wanted <= 0 || roads.isEmpty) return const [];

  final candidates = <Poi>[];

  // Sorted so the walk is the same on every device and every run. Without it
  // the order depends on how the tiles happened to decode, and a village would
  // reshuffle itself between sessions.
  final ordered = [...roads]..sort(_byFirstVertex);

  for (final road in ordered) {
    for (final point in _alongRoad(road, stepM: kRoadStepM)) {
      if (point.at.distanceTo(centre) > radiusM) continue;

      // Both sides of the road are tried; which one is used is decided by the
      // seed, so the choice is stable but not always the same side.
      final side = _stableHash(seed, point.at).isEven ? 1.0 : -1.0;
      final offset = _offsetFrom(point, kRoadOffsetM * side);

      candidates.add(
        Poi(
          position: offset,
          selectors: [_selectorFor(offset, areas)],
          name: null,
          layer: 'generated',
        ),
      );
    }
  }

  if (candidates.length <= wanted) return candidates;

  // Nearest first, but never two within [kMinSeparationM] of each other.
  //
  // Spreading the picks evenly across the whole road network was the obvious
  // thing and the wrong one: measured in rural Wielkopolska it put every
  // invented place between 900 m and 2.9 km away, so the near ring the spawner
  // guarantees had nothing to draw on and the village was a two-kilometre walk
  // in any direction. Sorting by distance fixes that; the separation stops the
  // whole village from landing on one lane.
  candidates.sort(
    (a, b) => a.position
        .distanceTo(centre)
        .compareTo(b.position.distanceTo(centre)),
  );

  final chosen = <Poi>[];
  for (final candidate in candidates) {
    if (chosen.length >= wanted) break;
    final tooClose = chosen.any(
      (taken) =>
          taken.position.distanceTo(candidate.position) < kMinSeparationM,
    );
    if (!tooClose) chosen.add(candidate);
  }

  return chosen;
}

/// Which kind of place this ground suggests.
String _selectorFor(GeoPoint point, List<GeneratedArea> areas) {
  for (final area in areas) {
    if (!isInsideRing(point, area.ring)) continue;
    final selector = kGeneratedSelectors[area.selector];
    if (selector != null) return selector;
  }
  return kRoadsideSelector;
}

/// Points spaced along a road, with the direction at each one.
Iterable<({GeoPoint at, double bearingX, double bearingY})> _alongRoad(
  MapFeature road, {
  required double stepM,
}) sync* {
  final vertices = road.geometry;
  if (vertices.length < 2) return;

  var carried = 0.0;

  for (var i = 1; i < vertices.length; i++) {
    final a = vertices[i - 1];
    final b = vertices[i];
    final length = a.distanceTo(b);
    if (length <= 0) continue;

    // Metres per degree, so the direction is in the same units as the offset.
    final scaleLon = metresPerDegreeLon((a.latitude + b.latitude) / 2);
    final dx = (b.longitude - a.longitude) * scaleLon / length;
    final dy = (b.latitude - a.latitude) * metresPerDegreeLat / length;

    var travelled = stepM - carried;
    while (travelled <= length) {
      final fraction = travelled / length;
      yield (
        at: GeoPoint(
          a.latitude + (b.latitude - a.latitude) * fraction,
          a.longitude + (b.longitude - a.longitude) * fraction,
        ),
        bearingX: dx,
        bearingY: dy,
      );
      travelled += stepM;
    }

    carried = (carried + length) % stepM;
  }
}

/// Moves a point sideways from the road it sits on.
GeoPoint _offsetFrom(
  ({GeoPoint at, double bearingX, double bearingY}) point,
  double metres,
) {
  // Perpendicular in the plane: (x, y) becomes (-y, x).
  final dLat = point.bearingX * metres / metresPerDegreeLat;
  final dLon =
      -point.bearingY * metres / metresPerDegreeLon(point.at.latitude);

  return GeoPoint(point.at.latitude + dLat, point.at.longitude + dLon);
}

/// A stable number for a place, so decisions about it survive a restart.
int _stableHash(int seed, GeoPoint at) {
  final lat = (at.latitude * 100000).round();
  final lon = (at.longitude * 100000).round();
  return Random(seed ^ (lat * 31 + lon)).nextInt(1 << 30);
}

int _byFirstVertex(MapFeature a, MapFeature b) {
  if (a.geometry.isEmpty || b.geometry.isEmpty) {
    return a.geometry.length.compareTo(b.geometry.length);
  }
  final byLat = a.geometry.first.latitude.compareTo(b.geometry.first.latitude);
  return byLat != 0
      ? byLat
      : a.geometry.first.longitude.compareTo(b.geometry.first.longitude);
}
