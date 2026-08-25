import 'package:arls_za/sim/daylight.dart';
import 'package:test/test.dart';

/// Verification table from §17.2. The whole point of computing daylight from
/// declination is that seasonality then works on both hemispheres and vanishes
/// at the equator — without a line of region-specific code.
void main() {
  const poznan = 52.4;
  const szczecin = 53.4;
  const capeTown = -33.9;
  const sydney = -33.9;
  const nairobi = -1.3;
  const tromso = 69.6;

  double hours(double latitude, DateTime date) =>
      daylightAt(dateUtc: date, latitude: latitude).daylightHours;

  final marchEquinox = DateTime.utc(2026, 3, 21);
  final juneSolstice = DateTime.utc(2026, 6, 21);
  final septemberEquinox = DateTime.utc(2026, 9, 21);
  final decemberSolstice = DateTime.utc(2026, 12, 21);

  group('day length reproduces the §17.2 table', () {
    test('Poznań', () {
      expect(hours(poznan, marchEquinox), closeTo(11.9, 0.25));
      expect(hours(poznan, juneSolstice), closeTo(16.6, 0.25));
      expect(hours(poznan, septemberEquinox), closeTo(12.0, 0.25));
      expect(hours(poznan, decemberSolstice), closeTo(7.4, 0.25));
    });

    test('Szczecin sits slightly further north', () {
      expect(hours(szczecin, juneSolstice), closeTo(16.8, 0.25));
      expect(hours(szczecin, decemberSolstice), closeTo(7.2, 0.25));
      expect(
        hours(szczecin, juneSolstice),
        greaterThan(hours(poznan, juneSolstice)),
      );
    });

    test('Cape Town — the seasons are inverted', () {
      expect(hours(capeTown, juneSolstice), closeTo(9.7, 0.25));
      expect(hours(capeTown, decemberSolstice), closeTo(14.3, 0.25));
      expect(
        hours(capeTown, juneSolstice),
        lessThan(hours(capeTown, decemberSolstice)),
        reason: 'June is midwinter in the southern hemisphere',
      );
    });

    test('Sydney matches Cape Town at the same latitude', () {
      expect(
        hours(sydney, juneSolstice),
        closeTo(hours(capeTown, juneSolstice), 0.01),
      );
    });

    test('Nairobi — seasonality disappears', () {
      final spread = [
        marchEquinox,
        juneSolstice,
        septemberEquinox,
        decemberSolstice,
      ].map((d) => hours(nairobi, d)).toList();

      final amplitude =
          spread.reduce((a, b) => a > b ? a : b) -
          spread.reduce((a, b) => a < b ? a : b);

      expect(
        amplitude,
        lessThan(0.5),
        reason: 'at the equator §17 has to switch itself off',
      );
    });
  });

  group('polar cases', () {
    test('Tromsø has a polar day in June', () {
      final info = daylightAt(dateUtc: juneSolstice, latitude: tromso);

      expect(info.isPolarDay, isTrue);
      expect(info.daylightHours, 24);
      expect(info.sunriseUtc, isNull);
      expect(info.sunsetUtc, isNull);
    });

    test('Tromsø has a polar night in December', () {
      final info = daylightAt(dateUtc: decemberSolstice, latitude: tromso);

      expect(info.isPolarNight, isTrue);
      expect(info.daylightHours, 0);
    });

    test('polar night is night all day, polar day never is', () {
      expect(
        isNightAt(momentUtc: DateTime.utc(2026, 12, 21, 12), latitude: tromso),
        isTrue,
      );
      expect(
        isNightAt(momentUtc: DateTime.utc(2026, 6, 21, 2), latitude: tromso),
        isFalse,
      );
    });
  });

  group('sunrise and sunset', () {
    test('bracket a day of the stated length', () {
      final info = daylightAt(
        dateUtc: juneSolstice,
        latitude: poznan,
        longitude: 16.93,
      );

      final span = info.sunsetUtc!.difference(info.sunriseUtc!);
      expect(span.inMinutes / 60, closeTo(info.daylightHours, 0.01));
    });

    test('a June morning in Poznań is daylight, midnight is not', () {
      expect(
        isNightAt(
          momentUtc: DateTime.utc(2026, 6, 21, 10),
          latitude: poznan,
          longitude: 16.93,
        ),
        isFalse,
      );
      expect(
        isNightAt(
          momentUtc: DateTime.utc(2026, 6, 21, 0, 30),
          latitude: poznan,
          longitude: 16.93,
        ),
        isTrue,
      );
    });

    test('longitude shifts the clock without changing the length', () {
      final west = daylightAt(
        dateUtc: juneSolstice,
        latitude: poznan,
        longitude: 0,
      );
      final east = daylightAt(
        dateUtc: juneSolstice,
        latitude: poznan,
        longitude: 30,
      );

      expect(east.daylightHours, closeTo(west.daylightHours, 1e-9));
      expect(east.sunriseUtc!.isBefore(west.sunriseUtc!), isTrue);
    });
  });

  group('night accumulated over a span (§2.5.3)', () {
    test('a full December day in Poznań is mostly night', () {
      final night = nightHoursBetween(
        fromUtc: DateTime.utc(2026, 12, 21),
        toUtc: DateTime.utc(2026, 12, 22),
        latitude: poznan,
        longitude: 16.93,
      );

      expect(night.inMinutes / 60, closeTo(16.6, 0.5));
    });

    test(
      'a full June day in Poznań leaves too little night for eight hours',
      () {
        final night = nightHoursBetween(
          fromUtc: DateTime.utc(2026, 6, 21),
          toUtc: DateTime.utc(2026, 6, 22),
          latitude: poznan,
          longitude: 16.93,
        );

        expect(night.inMinutes / 60, closeTo(7.4, 0.5));
        expect(
          night,
          lessThan(const Duration(hours: 8)),
          reason: 'this is what makes summer build a sleep debt (§2.5.3)',
        );
      },
    );

    test('a fortnight accumulates roughly fourteen nights', () {
      final night = nightHoursBetween(
        fromUtc: DateTime.utc(2026, 6, 1),
        toUtc: DateTime.utc(2026, 6, 15),
        latitude: poznan,
        longitude: 16.93,
      );

      expect(night.inHours, inInclusiveRange(100, 118));
    });

    test('an empty or reversed span is zero', () {
      expect(
        nightHoursBetween(
          fromUtc: DateTime.utc(2026, 6, 21),
          toUtc: DateTime.utc(2026, 6, 21),
          latitude: poznan,
        ),
        Duration.zero,
      );
      expect(
        nightHoursBetween(
          fromUtc: DateTime.utc(2026, 6, 22),
          toUtc: DateTime.utc(2026, 6, 21),
          latitude: poznan,
        ),
        Duration.zero,
      );
    });
  });

  group('darkness index (§17.4)', () {
    test('is zero on a twelve-hour day and one at six hours or less', () {
      final equinox = daylightAt(dateUtc: marchEquinox, latitude: poznan);
      expect(equinox.darknessIndex, closeTo(0, 0.05));

      final polar = daylightAt(dateUtc: decemberSolstice, latitude: tromso);
      expect(polar.darknessIndex, 1);
    });

    test('Poznań in December sits near the top of the range', () {
      final winter = daylightAt(dateUtc: decemberSolstice, latitude: poznan);

      // §17.5 quotes D ≈ 0.8 for the November–February period.
      expect(winter.darknessIndex, closeTo(0.77, 0.06));
    });
  });

  group('§17.2: the moment the sky changes, not just how long', () {
    // Poznań, a clear August day. The exact minute is the model's business;
    // what these hold is that a moment comes back at all, that it is precise
    // enough for a second hand, and that the duration everything already used
    // still agrees with it.
    const poznan = (lat: 52.4064, lon: 16.9252);
    final afternoon = DateTime.utc(2026, 8, 10, 14);

    test('it comes back to the second, not to the five minutes', () {
      final change = skyChangeAfter(
        fromUtc: afternoon,
        latitude: poznan.lat,
        longitude: poznan.lon,
      );

      expect(change, isNotNull);
      expect(change!.untilDark, isTrue, reason: 'dusk is what comes next');

      // ⚠️ The reason for the halving. A countdown reading "Zmierzch za
      // 00:14:37" off a five-minute grid would be wrong by up to five minutes
      // and would jump in steps a player can see.
      final coarse = change.at.difference(afternoon).inSeconds % 300;
      expect(
        coarse,
        isNot(0),
        reason: 'landing exactly on the grid every time is the grid, not a sun',
      );
    });

    test('and the duration everything already draws agrees with it', () {
      final change = skyChangeAfter(
        fromUtc: afternoon,
        latitude: poznan.lat,
        longitude: poznan.lon,
      );
      final ahead = twilightAhead(
        fromUtc: afternoon,
        latitude: poznan.lat,
        longitude: poznan.lon,
      );

      expect(ahead!.untilDark, change!.untilDark);
      expect(
        (ahead.left - change.at.difference(afternoon)).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('both times come back, and in the right order', () {
      final sky = skyTimes(
        fromUtc: afternoon,
        latitude: poznan.lat,
        longitude: poznan.lon,
      );

      expect(sky.dusk, isNotNull);
      expect(sky.dawn, isNotNull);
      expect(
        sky.dusk!.isBefore(sky.dawn!),
        isTrue,
        reason: 'an afternoon reaches dusk before it reaches dawn',
      );
      expect(sky.dusk!.isAfter(afternoon), isTrue);
    });

    test('and at night it is dawn that comes first', () {
      final night = DateTime.utc(2026, 8, 10, 23, 30);
      final sky = skyTimes(
        fromUtc: night,
        latitude: poznan.lat,
        longitude: poznan.lon,
      );

      expect(sky.dawn!.isBefore(sky.dusk!), isTrue);
    });

    test('a polar summer has no dusk to count to (§17.2)', () {
      // ⚠️ Null rather than a guess. A time that never arrives is worse than
      // no time — and this is a real place a real player can be standing in.
      final sky = skyTimes(
        fromUtc: DateTime.utc(2026, 6, 21, 12),
        latitude: 78.22,
        longitude: 15.65,
      );

      expect(sky.dusk, isNull);
      expect(sky.dawn, isNull);
    });
  });
}
