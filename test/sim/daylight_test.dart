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
}
