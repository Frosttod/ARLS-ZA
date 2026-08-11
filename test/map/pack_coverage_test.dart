import 'package:arls_za/map/pack_coverage.dart';
import 'package:arls_za/map/region_pack.dart';
import 'package:test/test.dart';

/// §16.6. Leaving the pack is not a failure — people travel — but the edge is
/// where this gets hard. A player walking along a boundary crosses it several
/// times a minute, and a message that appears and disappears with every step is
/// worse than no message at all.
void main() {
  const bounds = GeoBounds(south: 52.0, west: 20.8, north: 52.4, east: 21.3);
  final t0 = DateTime.utc(2026, 8, 11, 12);

  PackCoverage coverage() => PackCoverage(bounds: bounds);

  /// Degrees of latitude for a given number of metres.
  double lat(double metres) => metres / 110540.0;

  test('no pack installed is its own state, not "outside"', () {
    final none = PackCoverage();

    expect(none.state, Coverage.missing);
    expect(none.update(52.2, 21.0, t0), Coverage.missing);
  });

  test('well inside the pack is inside', () {
    expect(coverage().update(52.2, 21.0, t0), Coverage.inside);
  });

  test('a step past the edge is not yet leaving', () {
    final tracker = coverage();

    // Two hundred metres out: past the boundary, well inside the margin.
    expect(
      tracker.update(52.4 + lat(200), 21.0, t0),
      Coverage.inside,
      reason: 'the tiles are still there, and so is the game',
    );
  });

  test('leaving has to hold for half a minute before it counts', () {
    final tracker = coverage();
    final far = 52.4 + lat(2000);

    expect(tracker.update(far, 21.0, t0), Coverage.inside);
    expect(
      tracker.update(far, 21.0, t0.add(const Duration(seconds: 20))),
      Coverage.inside,
      reason: 'a single fix 2 km away is an artefact, not a car journey',
    );
    expect(
      tracker.update(far, 21.0, t0.add(const Duration(seconds: 30))),
      Coverage.outside,
    );
  });

  test('one wild fix does not end a session', () {
    final tracker = coverage();

    tracker.update(52.2, 21.0, t0);
    tracker.update(52.4 + lat(5000), 21.0, t0.add(const Duration(seconds: 5)));
    final after = tracker.update(
      52.2,
      21.0,
      t0.add(const Duration(seconds: 10)),
    );

    expect(after, Coverage.inside);
  });

  group('walking the boundary', () {
    test('never flaps between the two states', () {
      final tracker = coverage();
      var flips = 0;
      var previous = Coverage.inside;

      // Ten minutes of stepping back and forth across the northern edge, a
      // fix every five seconds.
      for (var step = 0; step < 120; step++) {
        final offset = step.isEven ? lat(50) : lat(-50);
        final state = tracker.update(
          52.4 + offset,
          21.0,
          t0.add(Duration(seconds: step * 5)),
        );
        if (state != previous) flips++;
        previous = state;
      }

      expect(
        flips,
        0,
        reason: 'crossing the line is not the same as leaving the region',
      );
    });

    test('coming back needs a margin inside, not merely inside', () {
      final tracker = coverage();

      // Leave properly.
      final far = 52.4 + lat(2000);
      tracker.update(far, 21.0, t0);
      tracker.update(far, 21.0, t0.add(const Duration(seconds: 40)));
      expect(tracker.state, Coverage.outside);

      // Step back over the line, but only just.
      final justInside = 52.4 - lat(50);
      tracker.update(justInside, 21.0, t0.add(const Duration(minutes: 2)));
      expect(
        tracker.update(justInside, 21.0, t0.add(const Duration(minutes: 3))),
        Coverage.outside,
        reason: 'hysteresis: the same line cannot decide both directions',
      );

      // Properly back in.
      final wellInside = 52.4 - lat(1000);
      tracker.update(wellInside, 21.0, t0.add(const Duration(minutes: 4)));
      expect(
        tracker.update(
          wellInside,
          21.0,
          t0.add(const Duration(minutes: 4, seconds: 40)),
        ),
        Coverage.inside,
      );
    });
  });
}
