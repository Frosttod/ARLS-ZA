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

/// Decides whether the game may put something at a point.
class SpawnFilter {
  const SpawnFilter(this.features);

  /// The features near the area being populated. The caller is expected to have
  /// narrowed these down — this class walks the whole list.
  final List<MapFeature> features;

  /// The rule that refuses [point], or null if it is allowed.
  ///
  /// The nearest offending feature wins, so the overlay names the thing the
  /// player can actually see.
  Exclusion? refuse(GeoPoint point) {
    Exclusion? worst;

    for (final feature in features) {
      final rule = exclusionFor(feature.tags);
      if (rule == null) continue;

      final distance = feature.distanceFrom(point);
      final excluded = rule.bufferM > 0
          ? distance <= rule.bufferM
          // A zero buffer means the geometry itself: inside an area, or on a
          // line. Lines are given a metre of width, because a point exactly on
          // an infinitely thin river is not a case that survives floating
          // point.
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
    return worst;
  }

  bool allows(GeoPoint point) => refuse(point) == null;
}
