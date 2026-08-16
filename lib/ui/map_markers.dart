/// What sits on the map, and what it looks like (design doc §3.6).
///
/// §3.6 fixes the colour code: green is the player, red an enemy, yellow a
/// loot box, grey an item somebody dropped, blue the shelter. Colour alone is
/// never enough (§12), so every marker carries a label for the screen reader
/// and the shapes differ as well as the hues.
///
/// Pure data: no widget, no map plugin. The renderer reads this, and so will
/// the tests that check a marker is not being drawn somewhere §3.5 forbids.
library;

import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../map/geometry.dart';

/// The kinds of thing §3.6 puts on the map.
enum MarkerKind {
  /// §3.6: red. Visible within a radius that depends on the Reconnaissance
  /// skill (§7), which is why the renderer is told what to draw rather than
  /// working it out.
  enemy,

  /// §3.6: yellow.
  loot,

  /// §3.6: grey. Dropped by the player, gone after 24 hours (§4.8).
  dropped,

  /// §3.6: blue. There is only ever one (§8).
  shelter,
}

/// One thing on the map.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.kind,
    required this.at,
    this.label,
    this.reachM,
    this.count = 1,
  });

  /// Stable across frames, so the renderer can move a marker instead of
  /// deleting and recreating it — a marker that blinks every second is a
  /// marker nobody can tap.
  final String id;

  final MarkerKind kind;
  final GeoPoint at;

  /// Read out by the screen reader, and shown on tap. §12 requires that
  /// nothing on this map is knowable by colour alone.
  final String? label;

  /// How many things this one dot stands for (§4.8).
  ///
  /// A player who emptied their pack on a corner left fourteen rows in one
  /// place, and fourteen overlapping circles is not a map — it is a smear. One
  /// dot with a number on it is the same information in a form somebody can
  /// use.
  final int count;

  /// How close a player has to be for this to be worth anything (§10.2,
  /// §4.8), drawn as a ring around it.
  ///
  /// Twenty-five metres for a place and fifteen for a pile at somebody's feet
  /// are numbers nobody can judge by eye on a map that zooms. A ring turns
  /// "am I close enough yet" from a guess into something to walk into.
  final double? reachM;

  MapMarker copyWith({
    GeoPoint? at,
    String? label,
    double? reachM,
    int? count,
  }) => MapMarker(
    id: id,
    kind: kind,
    at: at ?? this.at,
    label: label ?? this.label,
    reachM: reachM ?? this.reachM,
    count: count ?? this.count,
  );
}

/// The colour code of §3.6, as ARGB values.
///
/// Kept out of the widget so a test can assert the code rather than a shade of
/// paint chosen in a layout file.
const Map<MarkerKind, int> kMarkerColours = {
  MarkerKind.enemy: 0xFFD93A2B,
  MarkerKind.loot: 0xFFE8B33A,
  MarkerKind.dropped: 0xFF8C8F92,
  MarkerKind.shelter: 0xFF3A7BD9,
};

/// The player's own colour. Green, and not one of [kMarkerColours] — the player
/// is not a marker, it is the thing everything else is measured from.
const int kPlayerColour = 0xFF4CD964;

/// How large each kind is drawn, in logical pixels of radius.
///
/// The shelter is the largest: it is the one point on the map a player
/// navigates *to* from a distance (§8).
const Map<MarkerKind, double> kMarkerRadius = {
  MarkerKind.enemy: 7,
  MarkerKind.loot: 6,
  MarkerKind.dropped: 5,
  MarkerKind.shelter: 9,
};

/// How many metres one logical pixel covers at this zoom and latitude.
///
/// ⚠️ Logical pixels, not device ones. MapLibre's zoom is defined against CSS
/// pixels, which is the same trap that once made "one kilometre across the
/// screen" mean 330 m on a phone with a device pixel ratio of three.
double metresPerPixel(double zoom, double latitude) =>
    156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);

/// Where a point sits on screen, in logical pixels from the middle.
///
/// The inverse of [markerAtOffset], and the reason both live here: a badge
/// drawn a few pixels off the dot it counts is worse than no badge.
Offset offsetOf(
  GeoPoint point, {
  required GeoPoint centre,
  required double zoom,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);

  return Offset(
    (point.longitude - centre.longitude) *
        metresPerDegreeLon(centre.latitude) /
        scale,
    // Screen y grows downwards, latitude grows upwards.
    -(point.latitude - centre.latitude) * metresPerDegreeLat / scale,
  );
}

/// Which marker the player meant, tapping [offset] logical pixels from the
/// centre of a map centred on [centre].
///
/// A finger is not a pixel: [slopPx] is what makes a marker tappable at all,
/// and the nearest one inside it wins so that two markers on one street corner
/// do not become one unreachable marker.
MapMarker? markerAtOffset(
  List<MapMarker> markers,
  Offset offset, {
  required GeoPoint centre,
  required double zoom,
  double slopPx = 26,
}) {
  final scale = metresPerPixel(zoom, centre.latitude);
  final slopM = slopPx * scale;

  // Screen y grows downwards, latitude grows upwards.
  final at = GeoPoint(
    centre.latitude - offset.dy * scale / metresPerDegreeLat,
    centre.longitude +
        offset.dx * scale / metresPerDegreeLon(centre.latitude),
  );

  MapMarker? best;
  var bestDistance = slopM;
  for (final marker in markers) {
    final distance = marker.at.distanceTo(at);
    if (distance > bestDistance) continue;
    best = marker;
    bestDistance = distance;
  }
  return best;
}

/// Folds markers that sit on top of each other into one (§4.8).
///
/// Only within [withinM] and only among the same kind: a pile of dropped kit
/// and a shop are two different answers to "what is that", and merging them
/// would say neither. The dot lands on the first of the group rather than on
/// the average of it, so a marker never drifts off the thing it stands for
/// into the middle of a road.
List<MapMarker> clusterMarkers(
  List<MapMarker> markers, {
  double withinM = 25,
}) {
  final clustered = <MapMarker>[];
  final taken = List<bool>.filled(markers.length, false);

  for (var i = 0; i < markers.length; i++) {
    if (taken[i]) continue;
    final first = markers[i];

    var count = first.count;
    for (var j = i + 1; j < markers.length; j++) {
      if (taken[j] || markers[j].kind != first.kind) continue;
      if (first.at.distanceTo(markers[j].at) > withinM) continue;

      taken[j] = true;
      count += markers[j].count;
    }

    clustered.add(count == first.count ? first : first.copyWith(count: count));
  }

  return clustered;
}
