import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/daylight.dart';
import 'package:test/test.dart';

/// OD ZMIERZCHU DO ŚWITU (§17.2, §17.4, §10.2.2, §5.6.1).
///
/// ⚠️ **Night existed as a boolean and almost nothing read it.**
///
/// `isNightAt` has been right since stage 2, and three rules that depend on
/// darkness were not wired to anything:
///
///   - `searchRadiusM` took a `darkness` and no call site passed it, so
///     reconnaissance at midnight covered exactly as much ground as at noon;
///   - `fireAt` took a `night` and the game passed the literal `false`, so a
///     shot fired in the dark pulled enemies from a *daytime* radius while the
///     ring drawn on the map used the real one — the picture and the
///     consequence disagreeing, which is worse than either being wrong alone;
///   - §17.4's "przeciwnicy wykrywają lepiej (+20%)" did not exist at all,
///     which made a night raid strictly safer than a daytime one and turned
///     §2.5.2's whole argument on its head.
///
/// The mode itself runs on **civil twilight**, which is what "od zmierzchu do
/// świtu" means and is not the same boundary sleep uses. Sunset is the sun's
/// centre crossing the horizon and there is still plenty of light after it;
/// nobody switches a lamp on at sunset.
void main() {
  // Poznań, and the two dates §2.5.3's table is built on.
  const lat = 52.41;
  const lon = 16.93;

  double darkAt(DateTime moment) =>
      darknessAt(momentUtc: moment, latitude: lat, longitude: lon);

  group('§17.2: the sun, at an instant', () {
    test('noon in June is high and midnight is well under', () {
      expect(
        sunAltitudeDeg(
          momentUtc: DateTime.utc(2026, 6, 21, 11),
          latitude: lat,
          longitude: lon,
        ),
        greaterThan(50),
      );
      expect(
        sunAltitudeDeg(
          momentUtc: DateTime.utc(2026, 6, 21, 22),
          latitude: lat,
          longitude: lon,
        ),
        lessThan(kCivilTwilightDeg),
      );
    });

    test('and the two hemispheres disagree about the season', () {
      final north = sunAltitudeDeg(
        momentUtc: DateTime.utc(2026, 12, 21, 11),
        latitude: 52.41,
      );
      final south = sunAltitudeDeg(
        momentUtc: DateTime.utc(2026, 12, 21, 11),
        latitude: -33.9,
      );

      expect(north, lessThan(south));
    });
  });

  group('§17.4: darkness is continuous, not a second boolean', () {
    test('full day is nought and civil night is one', () {
      expect(darkAt(DateTime.utc(2026, 6, 21, 11)), 0);
      expect(darkAt(DateTime.utc(2026, 6, 21, 22)), 1);
    });

    test('and dusk is somewhere in between', () {
      // ⚠️ The point of having a figure rather than a flag. The half hour
      // after sunset is darker than noon and lighter than midnight, and a rule
      // that flipped would halve a search radius between one fix and the next.
      final dusk = darkAt(DateTime.utc(2026, 6, 21, 20));

      expect(dusk, greaterThan(0));
      expect(dusk, lessThan(1));
    });

    test('§2.5.3: dusk-to-dawn is shorter than sunset-to-sunrise', () {
      // ⚠️ Two boundaries, an hour and a half apart in June — which is why
      // sleep keeps its own. §2.5.1 puts a character to bed at nightfall, and
      // nobody waits for pitch black to go to sleep.
      var fullDark = Duration.zero;
      final start = DateTime.utc(2026, 6, 21);

      for (var minute = 0; minute < 24 * 60; minute += 5) {
        if (darkAt(start.add(Duration(minutes: minute))) >= 1) {
          fullDark += const Duration(minutes: 5);
        }
      }

      final info = daylightAt(dateUtc: start, latitude: lat, longitude: lon);

      expect(fullDark.inMinutes / 60, closeTo(5.5, 0.4));
      expect(info.nightHours, closeTo(7.4, 0.3));
      expect(fullDark.inMinutes / 60, lessThan(info.nightHours));
    });

    test('a polar winter is dim at noon and black at midnight', () {
      // ⚠️ Tromsø on the solstice, and the model is more right than I was.
      // The sun peaks about three degrees under the horizon — civil twilight,
      // not pitch black — which is exactly the few hours of blue light the
      // place actually gets. A flag would have called it night and drawn the
      // map as midnight while somebody could still read a street sign.
      const tromso = 69.6;

      expect(
        darknessAt(
          momentUtc: DateTime.utc(2026, 12, 21, 11),
          latitude: tromso,
          longitude: 18.9,
        ),
        allOf(greaterThan(0.3), lessThan(1)),
      );
      expect(
        darknessAt(
          momentUtc: DateTime.utc(2026, 12, 21, 23),
          latitude: tromso,
          longitude: 18.9,
        ),
        1,
      );

      // §2.5.1 still calls the whole day night, and should: the sun never
      // rises, so the character sleeps whenever they are under a roof.
      expect(
        isNightAt(
          momentUtc: DateTime.utc(2026, 12, 21, 11),
          latitude: tromso,
          longitude: 18.9,
        ),
        isTrue,
      );
    });
  });

  group('what darkness costs, and what it buys', () {
    test('§10.2.2: half the reconnaissance radius in the dark', () {
      expect(searchRadiusM(darkness: 1), searchRadiusM() * 0.5);
      expect(searchRadiusM(darkness: 0.5), searchRadiusM() * 0.75);
    });

    test('§17.4: and a fifth more detection', () {
      final walker = Enemy.spawn(
        id: 'w',
        kind: EnemyKind.walker,
        at: const GeoPoint(52.4, 16.9),
        home: const GeoPoint(52.4, 16.9),
        random: _seed,
      );

      expect(walker.sightAgainst(0), walker.sightM);
      expect(
        walker.sightAgainst(0, darkness: 1),
        closeTo(walker.sightM * (1 + kNightDetection), 0.001),
      );
    });

    test('§7: and Scouting still helps, on top of it', () {
      final walker = Enemy.spawn(
        id: 'w',
        kind: EnemyKind.walker,
        at: const GeoPoint(52.4, 16.9),
        home: const GeoPoint(52.4, 16.9),
        random: _seed,
      );

      // A master at night is still noticed later than a novice at night —
      // otherwise the skill would simply stop existing after sunset.
      expect(
        walker.sightAgainst(1, darkness: 1),
        lessThan(walker.sightAgainst(0, darkness: 1)),
      );
    });
  });

  test('§12, §17.2: nothing may take the night back out again', () {
    // ⚠️ Source-level, and every one of these was a parameter with a harmless
    // default that nobody filled in — the defect no test of the function
    // itself can catch, because the function was always right.
    final main = File('lib/main.dart').readAsStringSync();

    for (final wiring in [
      'darkness: _snapshot?.darkness', // §10.2.2's radius
      'darkness: snapshot.darkness', // §17.4's detection
      'night: _snapshot?.isNight', // §5.6.1's noise, once a literal false
      'setDarkOutside(', // §12's palette
    ]) {
      expect(
        main.contains(wiring),
        isTrue,
        reason: '$wiring is gone — the dark stopped meaning anything',
      );
    }

    expect(
      main.contains('night: false'),
      isFalse,
      reason: 'a shot at midnight is carrying a daytime radius again',
    );
  });
}

final _seed = Random(1);
