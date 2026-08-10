/// A single position reading (design doc §3.2).
///
/// Every position in the game passes through this type, whether it came from
/// the GPS chip or from the developer-mode simulator. That is the whole point
/// of §11.2: the simulator must not be a shortcut around the code that runs in
/// the field, or testing proves nothing.
library;

import 'dart:math' as math;

/// Metres per degree of latitude. Constant enough for game distances.
const double _metresPerDegreeLat = 110540.0;

/// Metres per degree of longitude at the equator.
const double _metresPerDegreeLonEquator = 111320.0;

class PositionFix {
  const PositionFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.timestamp,
    this.speedMps,
    this.headingDeg,
    this.altitudeM,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in metres, as reported by the provider. Readings worse
  /// than 25 m are discarded downstream (§3.2).
  final double accuracyM;

  final DateTime timestamp;

  /// Speed over ground, when the provider supplies one. The simulator computes
  /// it from consecutive points.
  final double? speedMps;

  /// Course over ground in degrees, 0 = north.
  final double? headingDeg;

  final double? altitudeM;

  /// True when Android reports the fix came from a mock provider (§3.4).
  final bool isMocked;

  /// Great-circle distance to [other] in metres, flat-earth approximation.
  ///
  /// Good to a few centimetres over the distances this game cares about, and
  /// far cheaper than haversine at 1 Hz.
  double distanceTo(PositionFix other) {
    final dLat = (other.latitude - latitude) * _metresPerDegreeLat;
    final dLon =
        (other.longitude - longitude) *
        _metresPerDegreeLonEquator *
        math.cos(_radians((latitude + other.latitude) / 2));
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  /// Bearing to [other] in degrees, 0 = north, clockwise.
  double bearingTo(PositionFix other) {
    final dLat = (other.latitude - latitude) * _metresPerDegreeLat;
    final dLon =
        (other.longitude - longitude) *
        _metresPerDegreeLonEquator *
        math.cos(_radians((latitude + other.latitude) / 2));
    final deg = math.atan2(dLon, dLat) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  /// Moves [metres] along [bearingDeg] and returns the new coordinates.
  ///
  /// Used by the simulator to walk a route and by the error model to scatter a
  /// fix within its accuracy circle.
  PositionFix offset({
    required double metres,
    required double bearingDeg,
    DateTime? timestamp,
    double? accuracyM,
    double? speedMps,
  }) {
    final rad = _radians(bearingDeg);
    final dNorth = metres * math.cos(rad);
    final dEast = metres * math.sin(rad);

    final newLat = latitude + dNorth / _metresPerDegreeLat;
    final lonScale =
        _metresPerDegreeLonEquator *
        math.cos(_radians((latitude + newLat) / 2));
    final newLon = longitude + (lonScale == 0 ? 0 : dEast / lonScale);

    return PositionFix(
      latitude: newLat,
      longitude: newLon,
      accuracyM: accuracyM ?? this.accuracyM,
      timestamp: timestamp ?? this.timestamp,
      speedMps: speedMps ?? this.speedMps,
      headingDeg: bearingDeg,
      altitudeM: altitudeM,
      isMocked: isMocked,
    );
  }

  PositionFix copyWith({
    double? latitude,
    double? longitude,
    double? accuracyM,
    DateTime? timestamp,
    double? speedMps,
    double? headingDeg,
    double? altitudeM,
    bool? isMocked,
  }) => PositionFix(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracyM: accuracyM ?? this.accuracyM,
    timestamp: timestamp ?? this.timestamp,
    speedMps: speedMps ?? this.speedMps,
    headingDeg: headingDeg ?? this.headingDeg,
    altitudeM: altitudeM ?? this.altitudeM,
    isMocked: isMocked ?? this.isMocked,
  );

  Map<String, Object?> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'acc': accuracyM,
    'ts': timestamp.toUtc().toIso8601String(),
    if (speedMps != null) 'spd': speedMps,
    if (headingDeg != null) 'hdg': headingDeg,
    if (altitudeM != null) 'alt': altitudeM,
    if (isMocked) 'mock': true,
  };

  factory PositionFix.fromJson(Map<String, Object?> json) => PositionFix(
    latitude: (json['lat']! as num).toDouble(),
    longitude: (json['lon']! as num).toDouble(),
    accuracyM: (json['acc']! as num).toDouble(),
    timestamp: DateTime.parse(json['ts']! as String).toUtc(),
    speedMps: (json['spd'] as num?)?.toDouble(),
    headingDeg: (json['hdg'] as num?)?.toDouble(),
    altitudeM: (json['alt'] as num?)?.toDouble(),
    isMocked: json['mock'] == true,
  );

  @override
  String toString() =>
      'PositionFix(${latitude.toStringAsFixed(6)}, '
      '${longitude.toStringAsFixed(6)}, ±${accuracyM.toStringAsFixed(1)} m)';
}

double _radians(double degrees) => degrees * math.pi / 180;

/// What the position layer is currently able to tell the simulation.
enum PositionSignal {
  /// Fixes are arriving and pass the accuracy gate.
  good,

  /// Fixes are arriving but are too imprecise to act on (§3.2).
  degraded,

  /// Nothing has arrived for long enough to stop trusting the last position.
  /// Movement simulation pauses here (§3.2).
  lost,

  /// The provider is off, or permission was refused.
  unavailable,
}
