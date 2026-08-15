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

  MapMarker copyWith({GeoPoint? at, String? label}) => MapMarker(
    id: id,
    kind: kind,
    at: at ?? this.at,
    label: label ?? this.label,
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
