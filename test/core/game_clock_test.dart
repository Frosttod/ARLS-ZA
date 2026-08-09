import 'package:arls_za/core/game_clock.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 9, 12, 0, 0);

  group('GameClock', () {
    test('first advance anchors without elapsing time', () {
      final wall = ManualWallClock(t0);
      final clock = GameClock(wallClock: wall);

      final result = clock.advance(null);

      expect(result.elapsed, Duration.zero);
      expect(result.rolledBack, isFalse);
      expect(clock.highWaterMark, t0);
    });

    test('forward motion returns the real difference', () {
      final wall = ManualWallClock(t0);
      final clock = GameClock(wallClock: wall);
      clock.advance(null);

      wall.advance(const Duration(seconds: 90));
      final result = clock.advance(t0);

      expect(result.elapsed, const Duration(seconds: 90));
      expect(result.now, t0.add(const Duration(seconds: 90)));
    });

    test('rolling the clock back yields a zero tick, never a negative one', () {
      final wall = ManualWallClock(t0);
      final clock = GameClock(wallClock: wall);
      clock.advance(null);

      wall.advance(const Duration(hours: 2));
      clock.advance(t0);

      // Player winds the device clock back a day.
      wall.advance(const Duration(days: -1));
      final result = clock.advance(t0.add(const Duration(hours: 2)));

      expect(result.elapsed, Duration.zero);
      expect(result.rolledBack, isTrue);
      expect(clock.highWaterMark, t0.add(const Duration(hours: 2)));
    });

    test('winding forward again cannot be cashed in twice', () {
      final wall = ManualWallClock(t0);
      final clock = GameClock(wallClock: wall);
      clock.advance(null);

      wall.advance(const Duration(hours: 5));
      final honest = clock.advance(t0);
      expect(honest.elapsed, const Duration(hours: 5));

      // Back three hours...
      wall.advance(const Duration(hours: -3));
      final back = clock.advance(honest.now);
      expect(back.elapsed, Duration.zero);

      // ...then forward one. Net position is still behind the high-water mark,
      // so nothing is owed.
      wall.advance(const Duration(hours: 1));
      final replay = clock.advance(honest.now);
      expect(replay.elapsed, Duration.zero);

      // Only genuinely new time counts.
      wall.advance(const Duration(hours: 3));
      final fresh = clock.advance(honest.now);
      expect(fresh.elapsed, const Duration(hours: 1));
    });

    test('an absurd gap is clamped', () {
      final wall = ManualWallClock(t0);
      final clock = GameClock(
        wallClock: wall,
        maxAdvance: const Duration(days: 30),
      );
      clock.advance(null);

      wall.advance(const Duration(days: 400));
      final result = clock.advance(t0);

      expect(result.elapsed, const Duration(days: 30));
      expect(result.clamped, isTrue);
    });

    test('restore reinstates the mark across a restart', () {
      final wall = ManualWallClock(t0.add(const Duration(hours: 1)));
      final clock = GameClock(wallClock: wall);

      // Persisted mark is two hours ahead of where the caller thinks it is.
      clock.restore(t0.add(const Duration(hours: 2)));

      final result = clock.advance(t0);

      expect(
        result.elapsed,
        Duration.zero,
        reason: 'wall clock is behind the restored mark',
      );
      expect(result.rolledBack, isTrue);
    });

    test('restore never moves the mark backwards', () {
      final clock = GameClock(wallClock: ManualWallClock(t0));
      clock.restore(t0.add(const Duration(hours: 3)));
      clock.restore(t0.add(const Duration(hours: 1)));

      expect(clock.highWaterMark, t0.add(const Duration(hours: 3)));
    });

    test('ticksIn counts whole seconds only', () {
      final clock = GameClock(wallClock: ManualWallClock(t0));

      expect(clock.ticksIn(const Duration(milliseconds: 999)), 0);
      expect(clock.ticksIn(const Duration(seconds: 1)), 1);
      expect(clock.ticksIn(const Duration(minutes: 2)), 120);
    });
  });
}
