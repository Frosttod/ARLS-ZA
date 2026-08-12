import 'package:arls_za/game/relocation.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:test/test.dart';

/// §16.6. A player finishes in Poznań, takes a night train, and opens the game
/// in Kraków. Nothing about the simulation is wrong — the journey happened
/// without a single fix, so nothing was credited — but the place changed, and
/// the map, the POI of §10 and the shelter of §8 all stand on the place.
void main() {
  const poznan = GeoPoint(52.4064, 16.9252);
  const krakow = GeoPoint(50.0647, 19.9450);

  /// A point [metres] north of [from].
  GeoPoint north(GeoPoint from, double metres) =>
      GeoPoint(from.latitude + metres / metresPerDegreeLat, from.longitude);

  Relocation check(GeoPoint? last, GeoPoint? now, {bool covered = true}) =>
      detectRelocation(lastKnown: last, trusted: now, mapCoversHere: covered);

  group('what does not count as a journey', () {
    test('a first run has nowhere to have moved from', () {
      expect(check(null, poznan).happened, isFalse);
    });

    test('no fix yet is not a verdict', () {
      // The screen opens before the first lock. Guessing in that window would
      // put a blackout note in front of a player who has not moved.
      expect(check(poznan, null).happened, isFalse);
    });

    test('the same place is the same place', () {
      expect(check(poznan, north(poznan, 30)).happened, isFalse);
    });

    test('a walk across town is still the same town', () {
      // Twelve kilometres is a long walk and an ordinary one. The threshold
      // has to sit above anything somebody might do on foot between two
      // sessions.
      expect(check(poznan, north(poznan, 12000)).happened, isFalse);
    });
  });

  group('a night train', () {
    test('is noticed, with the distance the game can honestly state', () {
      final result = check(poznan, krakow);

      expect(result.happened, isTrue);
      // Poznań to Kraków is about 350 km in a straight line. The game says a
      // distance because it is the one concrete thing it knows without asking
      // a network what the place is called.
      expect(result.kilometres, inInclusiveRange(330, 370));
    });

    test('with a map for where they woke, the game carries on', () {
      expect(check(poznan, krakow).verdict, RelocationVerdict.covered);
    });

    test('without one, there is nothing to draw and it says so', () {
      expect(
        check(poznan, krakow, covered: false).verdict,
        RelocationVerdict.uncovered,
      );
    });
  });

  test('the threshold is the one §16.6 settled on', () {
    // Just under and just over, so the number cannot drift without a failure.
    expect(
      check(poznan, north(poznan, kRelocationThresholdM - 500)).happened,
      isFalse,
    );
    expect(
      check(poznan, north(poznan, kRelocationThresholdM + 500)).happened,
      isTrue,
    );
  });
}
