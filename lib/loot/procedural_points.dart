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

/// A car somebody left, and a bin somebody filled.
///
/// Neither is in OpenStreetMap as a point — nobody maps the Passat outside
/// number 14 — but both are the most ordinary things on any street, and both
/// carry exactly what §18.2 is short of: wood, metal, plastic, cloth. Ammunition
/// and weapons stay where they were, in the places that had them.
const String kCarSelector = 'generated.car';
const String kWasteSelector = 'generated.waste';

/// The two vehicles worth a table of their own (§10.3.3).
///
/// Anchored to the building they belong to rather than scattered: an ambulance
/// is outside a hospital and a patrol car is outside a station, and finding
/// one anywhere else would say the world is random rather than abandoned.
const String kAmbulanceSelector = 'generated.ambulance';
const String kPoliceCarSelector = 'generated.police_car';

/// What a point on this kind of ground turns out to be.
///
/// ⚠️ These are shares of the *same* points, not extra ones. §10's density
/// caps are counted in places, so a street that grows cars and bins grows them
/// instead of something else — the map gets more varied without getting more
/// crowded, which is the only way to add anything to it at all.
const Map<String, List<({String selector, int share})>> kGeneratedMix = {
  'landuse.class=residential': [
    (selector: 'generated.house', share: 60),
    (selector: kWasteSelector, share: 25),
    (selector: kCarSelector, share: 15),
  ],
  'landcover.class=farmland': [
    (selector: 'generated.barn', share: 85),
    (selector: kCarSelector, share: 15),
  ],
  'landcover.class=wood': [(selector: 'generated.hunting_stand', share: 100)],
};

/// And for a point that fell on no recognised ground at all.
const List<({String selector, int share})> kRoadsideMix = [
  (selector: kRoadsideSelector, share: 55),
  (selector: kCarSelector, share: 30),
  (selector: kWasteSelector, share: 15),
];

/// How far an emergency vehicle stands from the building it belongs to.
const double kAnchoredVehicleM = 25;

/// Which anchor earns which vehicle (§10.3.3).
const Map<String, String> kAnchoredVehicles = {
  'poi.class=hospital': kAmbulanceSelector,
  'landuse.class=hospital': kAmbulanceSelector,
  'poi.class=police': kPoliceCarSelector,
  'poi.subclass=police': kPoliceCarSelector,
};

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
          selectors: [_selectorFor(offset, areas, seed)],
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
    (a, b) =>
        a.position.distanceTo(centre).compareTo(b.position.distanceTo(centre)),
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
String _selectorFor(GeoPoint point, List<GeneratedArea> areas, int seed) {
  for (final area in areas) {
    if (!isInsideRing(point, area.ring)) continue;

    final mix = kGeneratedMix[area.selector];
    if (mix != null) return _pickFrom(mix, seed, point);

    final selector = kGeneratedSelectors[area.selector];
    if (selector != null) return selector;
  }
  return _pickFrom(kRoadsideMix, seed, point);
}

/// One of [mix], chosen by the seed and the point itself.
///
/// Deterministic, like everything else here: the same street gives the same
/// car outside the same house every time, because a village that rearranges
/// itself between sessions is a village nobody can learn.
String _pickFrom(
  List<({String selector, int share})> mix,
  int seed,
  GeoPoint point,
) {
  var total = 0;
  for (final entry in mix) {
    total += entry.share;
  }
  if (total <= 0) return kRoadsideSelector;

  var roll = _stableHash(seed ^ 0x5eed, point) % total;
  for (final entry in mix) {
    if (roll < entry.share) return entry.selector;
    roll -= entry.share;
  }
  return mix.last.selector;
}

/// §10.3.3: an ambulance outside the hospital, a patrol car outside the
/// station.
///
/// One each, and only where the building is actually on the map. They are the
/// two richest things in the game per kilogram carried, so they are not
/// something a generator may sprinkle about — they are attached to a place
/// that earns them.
List<Poi> vehiclesBeside(List<Poi> anchors, {required int seed}) {
  final vehicles = <Poi>[];

  for (final anchor in anchors) {
    String? kind;
    for (final selector in anchor.selectors) {
      kind ??= kAnchoredVehicles[selector];
    }
    if (kind == null) continue;

    vehicles.add(
      Poi(
        position: anchor.position.offsetBy(
          metres: kAnchoredVehicleM,
          bearingDeg: (_stableHash(seed, anchor.position) % 360).toDouble(),
        ),
        selectors: [kind],
        name: null,
        layer: 'generated',
      ),
    );
  }
  return vehicles;
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
  final dLon = -point.bearingY * metres / metresPerDegreeLon(point.at.latitude);

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
