/// Where the game refuses to put anything (design doc §3.5).
///
/// §3.5 is marked mandatory, and it is the one section whose failure hurts
/// somebody rather than the simulation. The game asks people to walk around a
/// city, often after dark, looking at a phone. A loot marker on a dual
/// carriageway, on a railway, in a river, in somebody's garden or in a hospital
/// car park is not a bug in a game — it is an injury, a trespass or a
/// distressed stranger.
///
/// So the rule is refusal, not preference: a candidate point that matches
/// anything here is discarded, and if that leaves the area empty then the area
/// is empty. §10.1 has a procedural fallback for genuinely sparse places, and
/// it is bound by these same rules.
///
/// **Buffers are only where §3.5 states them** — 15 m from a major road, 30 m
/// from a railway. For water, private land and sensitive places the geometry is
/// the zone. That is a deliberate reading rather than an omission: the pavement
/// outside a school is a public street, and pushing a blanket buffer around
/// every hospital and cemetery would empty large parts of a city centre. If
/// field testing says otherwise, these numbers are the place to change.
library;

import '../map/geometry.dart';

/// Why a place is out of bounds. Kept distinct so the developer overlay can say
/// *which* rule refused a point, which is the only way to tell an over-eager
/// filter from an empty neighbourhood.
enum ExclusionKind {
  /// Carriageways and their verges. The buffer is what keeps a marker off the
  /// hard shoulder.
  road,

  /// Any railway. The widest buffer in §3.5, and the one worth being generous
  /// about.
  railway,

  /// Rivers, lakes, canals.
  water,

  /// Somebody's home or land. Trespass, not danger.
  private,

  /// Hospitals, schools, nurseries, cemeteries, places of worship, police
  /// stations, military sites. Places where a stranger looking at a phone is
  /// unwelcome, frightening, or both.
  sensitive,
}

/// A reason to refuse, and how far it reaches.
class ExclusionRule {
  const ExclusionRule(this.kind, this.bufferM);

  final ExclusionKind kind;

  /// Metres from the geometry. Zero means the geometry itself.
  final double bufferM;
}

/// Major roads. §3.5 lists these four; the `_link` slip roads that join them
/// carry the same traffic and are included for the same reason.
const Set<String> _majorRoads = {
  'motorway',
  'trunk',
  'primary',
  'secondary',
  'motorway_link',
  'trunk_link',
  'primary_link',
  'secondary_link',
};

/// Railway values that describe a line no train has used for years. A spawn on
/// a dismantled embankment is a walk in the woods, not a level crossing.
const Set<String> _deadRailways = {
  'abandoned',
  'disused',
  'razed',
  'dismantled',
  'proposed',
  'construction',
};

const Set<String> _sensitiveAmenities = {
  'hospital',
  'clinic',
  'doctors',
  'school',
  'kindergarten',
  'childcare',
  'college',
  'university',
  'place_of_worship',
  'police',
  'prison',
  'grave_yard',
  'funeral_hall',
  'crematorium',
};

const Set<String> _sensitiveLanduse = {'cemetery', 'military', 'religious'};

/// The rule a feature falls under, or null if it is ordinary ground.
///
/// Order matters where tags overlap: a railway inside a military area is still
/// a railway, and the wider buffer wins.
ExclusionRule? exclusionFor(Map<String, String> tags) {
  final railway = tags['railway'];
  if (railway != null && !_deadRailways.contains(railway)) {
    return const ExclusionRule(ExclusionKind.railway, 30);
  }

  final highway = tags['highway'];
  if (highway != null && _majorRoads.contains(highway)) {
    return const ExclusionRule(ExclusionKind.road, 15);
  }

  if (tags['natural'] == 'water' ||
      tags.containsKey('waterway') ||
      tags['landuse'] == 'reservoir') {
    return const ExclusionRule(ExclusionKind.water, 0);
  }

  final amenity = tags['amenity'];
  if (amenity != null && _sensitiveAmenities.contains(amenity)) {
    return const ExclusionRule(ExclusionKind.sensitive, 0);
  }
  if (tags.containsKey('healthcare') || tags.containsKey('military')) {
    return const ExclusionRule(ExclusionKind.sensitive, 0);
  }

  final landuse = tags['landuse'];
  if (landuse != null && _sensitiveLanduse.contains(landuse)) {
    return const ExclusionRule(ExclusionKind.sensitive, 0);
  }

  // Private land is checked last: `access=private` also appears on service
  // roads and gated railways, and those are better described by their own rule.
  if (tags['access'] == 'private' || tags['access'] == 'no') {
    return const ExclusionRule(ExclusionKind.private, 0);
  }
  if (landuse == 'residential') {
    return const ExclusionRule(ExclusionKind.private, 0);
  }

  return null;
}

/// How a feature is shaped on the ground.
enum FeatureShape { point, line, area }

/// One thing from the map, reduced to what §3.5 needs to know about it.
class MapFeature {
  const MapFeature({
    required this.tags,
    required this.geometry,
    required this.shape,
  });

  MapFeature.at(GeoPoint point, {required this.tags})
    : geometry = [point],
      shape = FeatureShape.point;

  final Map<String, String> tags;
  final List<GeoPoint> geometry;
  final FeatureShape shape;

  /// Distance in metres from [point] to this feature.
  double distanceFrom(GeoPoint point) => switch (shape) {
    FeatureShape.point =>
      geometry.isEmpty ? double.infinity : point.distanceTo(geometry.first),
    FeatureShape.line => distanceToPolyline(point, geometry),
    FeatureShape.area => distanceToArea(point, geometry),
  };
}

/// Why a candidate spawn was refused.
class Exclusion {
  const Exclusion({
    required this.kind,
    required this.distanceM,
    required this.tags,
  });

  final ExclusionKind kind;
  final double distanceM;

  /// The tags of the feature that refused it. Carried for the developer
  /// overlay: "excluded" without "by what" is not diagnosable.
  final Map<String, String> tags;
}

/// How wide one cell of the lookup grid is, in degrees of latitude.
///
/// About 111 m north-south and 68 m east-west at Poland's latitude. A query
/// reads the cell the point is in plus its eight neighbours, so anything
/// within roughly 68 m is certain to be looked at — comfortably more than the
/// widest buffer any rule uses (30 m for a railway).
const double _kCellDeg = 0.001;

/// How finely a line or an edge is sampled into cells.
///
/// A segment is entered into every cell it passes through, sampled at this
/// spacing. Smaller than a cell, so no cell a segment crosses is missed, which
/// is the whole correctness argument for the index.
const double _kSampleM = 40;

/// Decides whether the game may put something at a point.
///
/// ⚠️ **Indexed, because the honest version was a hang.** The first version
/// walked every feature for every point, and every vertex of every feature —
/// which is the right answer written the obvious way. Then §6.5 started asking
/// it sixty times per empty hotspot slot, on a two-kilometre extract of a real
/// city, on the interface isolate: measured at 75 ms per sixty probes over
/// three thousand features on a desktop, so the better part of a second on a
/// phone, per slot. Reported from the field as the game hanging when a shelter
/// module is toggled — because building one reloads the shelters, and that
/// reloads the zones.
///
/// So the features are bucketed into a coarse grid once and each probe reads
/// nine cells. The answer is the same one: `spawn_exclusion_test.dart` checks
/// it against the brute-force version on random cities, because this decides
/// where the game sends a person and an index that quietly disagrees would be
/// worse than a slow one.
class SpawnFilter {
  SpawnFilter(this.features);

  /// The features near the area being populated. The caller is expected to have
  /// narrowed these down.
  final List<MapFeature> features;

  /// Built on first use: a caller that asks one question pays about what one
  /// brute-force question used to cost, and a caller that asks sixty pays it
  /// once.
  Map<(int, int), List<(MapFeature, ExclusionRule)>>? _grid;

  Map<(int, int), List<(MapFeature, ExclusionRule)>> get _cells {
    final built = _grid;
    if (built != null) return built;

    final grid = <(int, int), List<(MapFeature, ExclusionRule)>>{};
    for (final feature in features) {
      // Features with no rule are dropped here rather than skipped per probe:
      // most of a city is neither a railway nor a river.
      final rule = exclusionFor(feature.tags);
      if (rule == null) continue;

      for (final cell in _cellsOf(feature)) {
        (grid[cell] ??= []).add((feature, rule));
      }
    }

    return _grid = grid;
  }

  /// The rule that refuses [point], or null if it is allowed.
  ///
  /// The nearest offending feature wins, so the overlay names the thing the
  /// player can actually see.
  Exclusion? refuse(GeoPoint point) {
    Exclusion? worst;

    final home = _cellOf(point);
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final bucket = _cells[(home.$1 + dx, home.$2 + dy)];
        if (bucket == null) continue;

        for (final (feature, rule) in bucket) {
          final distance = feature.distanceFrom(point);
          final excluded = rule.bufferM > 0
              ? distance <= rule.bufferM
              // A zero buffer means the geometry itself: inside an area, or on
              // a line. Lines are given a metre of width, because a point
              // exactly on an infinitely thin river is not a case that
              // survives floating point.
              : distance <= (feature.shape == FeatureShape.area ? 0 : 1);
          if (!excluded) continue;

          if (worst == null || distance < worst.distanceM) {
            worst = Exclusion(
              kind: rule.kind,
              distanceM: distance,
              tags: feature.tags,
            );
          }
        }
      }
    }
    return worst;
  }

  bool allows(GeoPoint point) => refuse(point) == null;

  static (int, int) _cellOf(GeoPoint point) => (
    (point.longitude / _kCellDeg).floor(),
    (point.latitude / _kCellDeg).floor(),
  );

  /// Every cell this feature touches.
  ///
  /// ⚠️ Sampled along each segment, not only at the vertices. A road drawn
  /// with two points a kilometre apart has vertices in two cells and passes
  /// through fifteen — and the fifteen are exactly the places a player would
  /// have been sent to stand on it.
  static Set<(int, int)> _cellsOf(MapFeature feature) {
    final cells = <(int, int)>{};
    final points = feature.geometry;
    if (points.isEmpty) return cells;

    cells.add(_cellOf(points.first));
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      cells.add(_cellOf(to));

      final metres = from.distanceTo(to);
      final steps = (metres / _kSampleM).ceil();
      for (var step = 1; step < steps; step++) {
        final fraction = step / steps;
        cells.add(
          _cellOf(
            GeoPoint(
              from.latitude + (to.latitude - from.latitude) * fraction,
              from.longitude + (to.longitude - from.longitude) * fraction,
            ),
          ),
        );
      }
    }

    // ⚠️ **An area is its inside, not its edge.** A point in the middle of a
    // lake is nought metres from it and refused — but the middle of a lake
    // holds no boundary sample, so an index built from the outline alone
    // answers "allowed" there. Caught by the test that checks this class
    // against the brute-force version: a railway crossing a big residential
    // polygon disappeared. So every cell of the bounding box is filled.
    if (feature.shape == FeatureShape.area) {
      var minX = 1 << 30, maxX = -(1 << 30);
      var minY = 1 << 30, maxY = -(1 << 30);
      for (final point in points) {
        final (x, y) = _cellOf(point);
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
      for (var x = minX; x <= maxX; x++) {
        for (var y = minY; y <= maxY; y++) {
          cells.add((x, y));
        }
      }
    }

    return cells;
  }
}
