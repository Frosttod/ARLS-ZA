import 'package:arls_za/core/game_clock.dart';
import 'package:arls_za/core/scaled_wall_clock.dart';
import 'package:test/test.dart';

/// Time acceleration must be invisible to everything downstream: the tick
/// engine is handed a duration and never learns it was multiplied (§11.2).
void main() {
  final t0 = DateTime.utc(2026, 8, 10, 12);

  group('ScaledWallClock', () {
    test('×1 tracks the base clock exactly', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base);

      base.advance(const Duration(minutes: 7));

      expect(clock.nowUtc(), t0.add(const Duration(minutes: 7)));
      expect(clock.isAccelerated, isFalse);
    });

    test('×60 turns a minute of real time into an hour', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base, scale: TimeScale.fast);

      base.advance(const Duration(minutes: 1));

      expect(clock.nowUtc(), t0.add(const Duration(hours: 1)));
    });

    test('×3600 puts a game day inside 24 seconds', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base, scale: TimeScale.furious);

      base.advance(const Duration(seconds: 24));

      expect(
        clock.nowUtc().difference(t0),
        const Duration(hours: 24),
        reason: 'this is the stage 1 exit criterion',
      );
      expect(TimeScale.furious.dayDuration, const Duration(seconds: 24));
    });

    test('changing the scale keeps virtual time continuous', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base);

      base.advance(const Duration(seconds: 10));
      final beforeSwitch = clock.nowUtc();

      clock.setScale(TimeScale.furious);
      final afterSwitch = clock.nowUtc();

      expect(
        afterSwitch,
        beforeSwitch,
        reason: 'switching scale must not move the clock',
      );

      base.advance(const Duration(seconds: 1));
      expect(clock.nowUtc(), beforeSwitch.add(const Duration(hours: 1)));
    });

    test('flipping up and back down never moves time backwards', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base);
      var previous = clock.nowUtc();

      for (final scale in [
        TimeScale.furious,
        TimeScale.realtime,
        TimeScale.fast,
        TimeScale.realtime,
      ]) {
        clock.setScale(scale);
        final now = clock.nowUtc();
        expect(
          now.isBefore(previous),
          isFalse,
          reason: 'a backwards jump would trip the rollback guard of §2.1.1',
        );
        previous = now;
        base.advance(const Duration(seconds: 5));
        previous = clock.nowUtc();
      }
    });

    test('skipForward jumps, and only forwards', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base);

      clock.skipForward(const Duration(hours: 8));
      expect(clock.nowUtc(), t0.add(const Duration(hours: 8)));

      clock.skipForward(const Duration(hours: -3));
      expect(
        clock.nowUtc(),
        t0.add(const Duration(hours: 8)),
        reason: 'backwards skips are refused, not applied',
      );
    });

    test('reset returns to real time', () {
      final base = ManualWallClock(t0);
      final clock = ScaledWallClock(base: base, scale: TimeScale.furious);

      base.advance(const Duration(seconds: 10));
      clock.reset();

      expect(clock.scale, TimeScale.realtime);
      expect(clock.nowUtc(), base.nowUtc());
    });
  });

  group('with GameClock', () {
    test('the game clock sees accelerated time as ordinary elapsed time', () {
      final base = ManualWallClock(t0);
      final scaled = ScaledWallClock(base: base, scale: TimeScale.furious);
      final game = GameClock(wallClock: scaled);

      game.advance(null); // anchor
      final anchored = scaled.nowUtc();

      base.advance(const Duration(seconds: 24));
      final result = game.advance(anchored);

      expect(result.elapsed, const Duration(hours: 24));
      expect(result.rolledBack, isFalse);
      expect(result.clamped, isFalse);
    });

    test('acceleration cannot manufacture a rollback', () {
      final base = ManualWallClock(t0);
      final scaled = ScaledWallClock(base: base, scale: TimeScale.furious);
      final game = GameClock(wallClock: scaled);

      game.advance(null);
      base.advance(const Duration(seconds: 30));
      final fast = game.advance(t0);
      expect(fast.elapsed, const Duration(hours: 30));

      // Drop back to real time and keep going.
      scaled.setScale(TimeScale.realtime);
      base.advance(const Duration(seconds: 30));
      final slow = game.advance(fast.now);

      expect(slow.rolledBack, isFalse);
      expect(slow.elapsed, const Duration(seconds: 30));
    });

    test('the 30-day clamp still applies under acceleration', () {
      final base = ManualWallClock(t0);
      final scaled = ScaledWallClock(base: base, scale: TimeScale.furious);
      final game = GameClock(
        wallClock: scaled,
        maxAdvance: const Duration(days: 30),
      );

      game.advance(null);
      base.advance(const Duration(hours: 1)); // 3600 h of virtual time
      final result = game.advance(t0);

      expect(result.elapsed, const Duration(days: 30));
      expect(result.clamped, isTrue);
    });
  });
}
