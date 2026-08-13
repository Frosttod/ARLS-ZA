/// Small-area geometry, in metres (design doc §3.5, §10).
///
/// Everything here uses an equirectangular approximation anchored at the point
/// being asked about. Over the distances the game cares about — a spawn is
/// never judged against something kilometres away — it is accurate to
/// centimetres and costs a fraction of the trigonometry a proper projection
/// would.
library;

import 'dart:math' as math;

/// Metres per degree of latitude. Constant enough at this scale.
const double metresPerDegreeLat = 110540.0;

double metresPerDegreeLon(double latitude) =>
    111320.0 * math.cos(latitude * math.pi / 180).abs();

/// A coordinate. Deliberately not a [PositionFix]: a corner of a building has
/// no accuracy, speed or timestamp.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  double distanceTo(GeoPoint other) {
    final dLat = (other.latitude - latitude) * metresPerDegreeLat;
    final dLon =
        (other.longitude - longitude) *
        metresPerDegreeLon((latitude + other.latitude) / 2);
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  @override
  String toString() =>
      'GeoPoint(${latitude.toStringAsFixed(6)}, '
      '${longitude.toStringAsFixed(6)})';
}

/// Distance in metres from [point] to the segment [a]–[b].
double distanceToSegment(GeoPoint point, GeoPoint a, GeoPoint b) {
  // Work in metres relative to the point, so the projection is anchored where
  // the answer matters.
  final scaleLon = metresPerDegreeLon(point.latitude);

  final ax = (a.longitude - point.longitude) * scaleLon;
  final ay = (a.latitude - point.latitude) * metresPerDegreeLat;
  final bx = (b.longitude - point.longitude) * scaleLon;
  final by = (b.latitude - point.latitude) * metresPerDegreeLat;

  final dx = bx - ax;
  final dy = by - ay;
  final lengthSquared = dx * dx + dy * dy;

  if (lengthSquared == 0) return math.sqrt(ax * ax + ay * ay);

  // Projection of the origin onto the segment, clamped to its ends.
  final t = (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
  final cx = ax + t * dx;
  final cy = ay + t * dy;

  return math.sqrt(cx * cx + cy * cy);
}

/// Distance in metres from [point] to the nearest part of the polyline
/// [vertices]. Returns infinity for an empty list.
double distanceToPolyline(GeoPoint point, List<GeoPoint> vertices) {
  if (vertices.isEmpty) return double.infinity;
  if (vertices.length == 1) return point.distanceTo(vertices.first);

  var best = double.infinity;
  for (var i = 1; i < vertices.length; i++) {
    final d = distanceToSegment(point, vertices[i - 1], vertices[i]);
    if (d < best) best = d;
  }
  return best;
}

/// Whether [point] falls inside the ring [vertices].
///
/// Ray casting, counting crossings to the east. The ring is treated as closed
/// whether or not the last vertex repeats the first, because OSM ways do both.
bool isInsideRing(GeoPoint point, List<GeoPoint> vertices) {
  if (vertices.length < 3) return false;

  var inside = false;
  for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
    final vi = vertices[i];
    final vj = vertices[j];

    final straddles =
        (vi.latitude > point.latitude) != (vj.latitude > point.latitude);
    if (!straddles) continue;

    final crossingLon =
        vi.longitude +
        (point.latitude - vi.latitude) *
            (vj.longitude - vi.longitude) /
            (vj.latitude - vi.latitude);
    if (point.longitude < crossingLon) inside = !inside;
  }
  return inside;
}

/// Distance in metres from [point] to a closed area: zero inside it, otherwise
/// the distance to its edge.
double distanceToArea(GeoPoint point, List<GeoPoint> ring) {
  if (isInsideRing(point, ring)) return 0;

  // Close the ring for the edge walk, so the segment from the last vertex back
  // to the first is not silently missing.
  final closed =
      ring.isNotEmpty &&
          ring.first.latitude == ring.last.latitude &&
          ring.first.longitude == ring.last.longitude
      ? ring
      : [...ring, if (ring.isNotEmpty) ring.first];

  return distanceToPolyline(point, closed);
}

/// Web-mercator resolution at the equator, in metres per pixel at zoom 0.
const double _equatorMetresPerPixel = 156543.03392;

/// The zoom level at which [metresAcross] fills a viewport [pixelWidth] wide.
///
/// The game clamps how far out a player may zoom (§3.6): you know the street
/// you are on and the next junction, not what is over the hill. Expressing that
/// as a distance rather than a zoom number is the only way it means the same
/// thing on a small phone and a large one, and at the top of the country and
/// the bottom.
double zoomForWidth({
  required double metresAcross,
  required double pixelWidth,
  required double latitude,
}) {
  if (metresAcross <= 0 || pixelWidth <= 0) return 0;

  final metresPerPixel = metresAcross / pixelWidth;
  final atThisLatitude =
      _equatorMetresPerPixel * math.cos(latitude * math.pi / 180).abs();

  return math.log(atThisLatitude / metresPerPixel) / math.ln2;
}
