/// Day length, sunrise and sunset, computed offline (design doc §17.2).
///
/// Sleep is not an action the player picks — the character sleeps when it is
/// night and they are under a roof (§2.5.1). So "is it night" has to be
/// answerable at any moment, on a phone with no signal, anywhere on Earth.
///
/// Solar declination and the hour angle give that for free:
///
/// ```
/// δ = 23.45° × sin(360/365 × (284 + N))     N = day of year
/// cos(ω) = −tan(φ) × tan(δ)                 φ = latitude
/// daylight = 2ω / 15
/// ```
///
/// No API, no network, correct on both hemispheres. Seasonality then emerges
/// on its own rather than being written into a calendar — which is what lets
/// §17 work in Cape Town and vanish in Nairobi.
library;

import 'dart:math' as math;

/// Sun geometry for one day at one latitude.
class DaylightInfo {
  const DaylightInfo({
    required this.date,
    required this.latitude,
    required this.declinationDeg,
    required this.daylightHours,
    required this.sunriseUtc,
    required this.sunsetUtc,
    required this.isPolarDay,
    required this.isPolarNight,
  });

  final DateTime date;
  final double latitude;
  final double declinationDeg;

  /// Hours of daylight, 0 to 24.
  final double daylightHours;

  /// Null during polar day or polar night, when the sun does not cross the
  /// horizon at all.
  final DateTime? sunriseUtc;
  final DateTime? sunsetUtc;

  final bool isPolarDay;
  final bool isPolarNight;

  double get nightHours => 24 - daylightHours;

  /// Darkness index of §17.4, 0 for a twelve-hour day and 1 at six hours or
  /// less. Feeds enemy detection range and loot respawn.
  double get darknessIndex => ((12 - daylightHours) / 6).clamp(0.0, 1.0);
}

/// Longitude is needed to place sunrise and sunset on the clock; day *length*
/// depends only on latitude and date.
DaylightInfo daylightAt({
  required DateTime dateUtc,
  required double latitude,
  double longitude = 0,
}) {
  final date = DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
  final n = _dayOfYear(date);

  final declination = 23.45 * math.sin(_radians(360 / 365 * (284 + n)));

  final latRad = _radians(latitude);
  final decRad = _radians(declination);

  // cos(ω) outside [−1, 1] means the sun never sets or never rises.
  final cosOmega = -math.tan(latRad) * math.tan(decRad);

  if (cosOmega <= -1) {
    return DaylightInfo(
      date: date,
      latitude: latitude,
      declinationDeg: declination,
      daylightHours: 24,
      sunriseUtc: null,
      sunsetUtc: null,
      isPolarDay: true,
      isPolarNight: false,
    );
  }
  if (cosOmega >= 1) {
    return DaylightInfo(
      date: date,
      latitude: latitude,
      declinationDeg: declination,
      daylightHours: 0,
      sunriseUtc: null,
      sunsetUtc: null,
      isPolarDay: false,
      isPolarNight: true,
    );
  }

  final omegaDeg = _degrees(math.acos(cosOmega));
  final daylightHours = 2 * omegaDeg / 15;

  // Solar noon in UTC, corrected for longitude and the equation of time.
  final solarNoonUtc = 12 - longitude / 15 - _equationOfTimeHours(n);
  final half = daylightHours / 2;

  return DaylightInfo(
    date: date,
    latitude: latitude,
    declinationDeg: declination,
    daylightHours: daylightHours,
    sunriseUtc: _atHour(date, solarNoonUtc - half),
    sunsetUtc: _atHour(date, solarNoonUtc + half),
    isPolarDay: false,
    isPolarNight: false,
  );
}

/// Whether it is night at [momentUtc].
///
/// Night is what unlocks sleep (§2.5.1) and what widens the noise radius
/// (§5.6.1) and enemy detection (§17.4).
bool isNightAt({
  required DateTime momentUtc,
  required double latitude,
  double longitude = 0,
}) {
  final info = daylightAt(
    dateUtc: momentUtc,
    latitude: latitude,
    longitude: longitude,
  );

  if (info.isPolarDay) return false;
  if (info.isPolarNight) return true;

  final sunrise = info.sunriseUtc!;
  final sunset = info.sunsetUtc!;
  final moment = momentUtc.toUtc();

  return moment.isBefore(sunrise) || moment.isAfter(sunset);
}

/// Night hours falling inside `[from, to)`.
///
/// Used by the sleep model: the character accumulates sleep only during the
/// dark part of a catch-up, which is what makes a summer night short enough to
/// build a debt (§2.5.3).
Duration nightHoursBetween({
  required DateTime fromUtc,
  required DateTime toUtc,
  required double latitude,
  double longitude = 0,
  Duration resolution = const Duration(minutes: 15),
}) {
  if (!toUtc.isAfter(fromUtc)) return Duration.zero;

  // Sampling rather than interval arithmetic: the boundary moves every day, a
  // catch-up can span months, and a quarter-hour error over a fortnight is far
  // below anything the sleep model reacts to.
  var night = Duration.zero;
  var cursor = fromUtc.toUtc();
  final end = toUtc.toUtc();

  while (cursor.isBefore(end)) {
    final step = cursor.add(resolution).isAfter(end)
        ? end.difference(cursor)
        : resolution;
    final midpoint = cursor.add(step * 0.5);

    if (isNightAt(
      momentUtc: midpoint,
      latitude: latitude,
      longitude: longitude,
    )) {
      night += step;
    }
    cursor = cursor.add(step);
  }

  return night;
}

int _dayOfYear(DateTime date) =>
    date.difference(DateTime.utc(date.year)).inDays + 1;

/// Equation of time in hours — the offset between clock noon and solar noon.
///
/// Worth up to about a quarter of an hour. Included because sunset drives the
/// night-time noise multiplier of §5.6.1, and being fifteen minutes early with
/// that is a balance error rather than a rounding one.
double _equationOfTimeHours(int dayOfYear) {
  final b = _radians(360 * (dayOfYear - 81) / 364);
  final minutes =
      9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
  return minutes / 60;
}

DateTime _atHour(DateTime date, double hour) {
  final wrapped = hour % 24;
  final micros = (wrapped * Duration.microsecondsPerHour).round();
  return date.add(Duration(microseconds: micros));
}

double _radians(double degrees) => degrees * math.pi / 180;

double _degrees(double radians) => radians * 180 / math.pi;
