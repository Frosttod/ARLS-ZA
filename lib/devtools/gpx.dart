/// Minimal GPX reader for the route simulator (design doc §11.2).
///
/// Only `<trkpt>` is understood — track points with their optional elevation
/// and timestamp. Routes and waypoints are ignored, because what the simulator
/// needs is a polyline to walk along.
///
/// Hand-rolled rather than pulling in an XML package: this parses recorded
/// walks in developer builds and nothing else, and a dependency that only
/// devtools use would still sit in `pubspec.yaml` for the release build.
library;

import '../location/position_fix.dart';

class GpxTrackPoint {
  const GpxTrackPoint({
    required this.latitude,
    required this.longitude,
    this.elevationM,
    this.time,
  });

  final double latitude;
  final double longitude;
  final double? elevationM;
  final DateTime? time;
}

class GpxParseException implements Exception {
  GpxParseException(this.message);

  final String message;

  @override
  String toString() => 'GpxParseException: $message';
}

/// A parsed track, plus the geometry the simulator needs to walk it.
class GpxTrack {
  GpxTrack(this.name, this.points)
    : assert(points.length >= 2, 'a track needs at least two points') {
    var total = 0.0;
    _cumulative = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      total += _distance(points[i - 1], points[i]);
      _cumulative[i] = total;
    }
    _lengthM = total;
  }

  final String name;
  final List<GpxTrackPoint> points;

  late final List<double> _cumulative;
  late final double _lengthM;

  /// Total length of the track in metres.
  double get lengthM => _lengthM;

  /// How long walking the whole track takes at [speedMps].
  Duration durationAt(double speedMps) => speedMps <= 0
      ? Duration.zero
      : Duration(milliseconds: (_lengthM / speedMps * 1000).round());

  /// The position [metres] along the track, interpolated between points.
  ///
  /// Past the end the track wraps, so a simulated walk can run indefinitely
  /// without anyone having to record a longer route.
  ({double latitude, double longitude, double bearingDeg}) pointAt(
    double metres, {
    bool loop = true,
  }) {
    if (_lengthM <= 0) {
      return (
        latitude: points.first.latitude,
        longitude: points.first.longitude,
        bearingDeg: 0,
      );
    }

    var target = metres;
    if (loop) {
      target = target % _lengthM;
      if (target < 0) target += _lengthM;
    } else {
      target = target.clamp(0.0, _lengthM);
    }

    var index = 1;
    while (index < _cumulative.length - 1 && _cumulative[index] < target) {
      index++;
    }

    final from = points[index - 1];
    final to = points[index];
    final segmentStart = _cumulative[index - 1];
    final segmentLength = _cumulative[index] - segmentStart;
    final t = segmentLength <= 0
        ? 0.0
        : (target - segmentStart) / segmentLength;

    final fromFix = _asFix(from);
    final toFix = _asFix(to);

    return (
      latitude: from.latitude + (to.latitude - from.latitude) * t,
      longitude: from.longitude + (to.longitude - from.longitude) * t,
      bearingDeg: fromFix.bearingTo(toFix),
    );
  }

  static double _distance(GpxTrackPoint a, GpxTrackPoint b) =>
      _asFix(a).distanceTo(_asFix(b));

  static PositionFix _asFix(GpxTrackPoint p) => PositionFix(
    latitude: p.latitude,
    longitude: p.longitude,
    accuracyM: 0,
    timestamp: p.time ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

final _trkptPattern = RegExp(
  r'<trkpt\b[^>]*\blat\s*=\s*"([^"]+)"[^>]*\blon\s*=\s*"([^"]+)"[^>]*'
  r'(?:/>|>(.*?)</trkpt>)',
  dotAll: true,
  caseSensitive: false,
);
final _elePattern = RegExp(r'<ele>\s*([^<\s]+)\s*</ele>', caseSensitive: false);
final _timePattern = RegExp(
  r'<time>\s*([^<\s]+)\s*</time>',
  caseSensitive: false,
);
final _namePattern = RegExp(
  r'<name>\s*(.*?)\s*</name>',
  dotAll: true,
  caseSensitive: false,
);

/// Parses the first track in a GPX document.
GpxTrack parseGpx(String source, {String fallbackName = 'trasa'}) {
  final matches = _trkptPattern.allMatches(source).toList();
  if (matches.length < 2) {
    throw GpxParseException(
      'found ${matches.length} track points, need at least 2',
    );
  }

  final points = <GpxTrackPoint>[];
  for (final match in matches) {
    final lat = double.tryParse(match.group(1)!);
    final lon = double.tryParse(match.group(2)!);
    if (lat == null || lon == null) {
      throw GpxParseException('unparseable coordinates in "${match.group(0)}"');
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      throw GpxParseException('coordinates out of range: $lat, $lon');
    }

    final body = match.group(3) ?? '';
    points.add(
      GpxTrackPoint(
        latitude: lat,
        longitude: lon,
        elevationM: double.tryParse(
          _elePattern.firstMatch(body)?.group(1) ?? '',
        ),
        time: DateTime.tryParse(
          _timePattern.firstMatch(body)?.group(1) ?? '',
        )?.toUtc(),
      ),
    );
  }

  final name = _namePattern.firstMatch(source)?.group(1);
  return GpxTrack(name == null || name.isEmpty ? fallbackName : name, points);
}

/// A short loop used when no GPX file is loaded, so the simulator is usable
/// straight away. Roughly a 600 m block in Poznań — the reference city of the
/// design document's worked examples.
GpxTrack defaultTestLoop() => GpxTrack('pętla testowa', const [
  GpxTrackPoint(latitude: 52.40640, longitude: 16.92520),
  GpxTrackPoint(latitude: 52.40820, longitude: 16.92520),
  GpxTrackPoint(latitude: 52.40820, longitude: 16.92900),
  GpxTrackPoint(latitude: 52.40640, longitude: 16.92900),
  GpxTrackPoint(latitude: 52.40640, longitude: 16.92520),
]);
