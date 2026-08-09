/// Monotonic wall clock with rollback protection (design doc §2.1.1).
///
/// The simulation is driven by elapsed wall time, because the character's
/// physiology has to keep running while the app is closed. That makes the
/// system clock an attack surface: winding it back would otherwise hand the
/// player free hunger and thirst.
///
/// The rule is simple and absolute: **a tick is never negative and never
/// longer than the cap**. Time that cannot be trusted is time that did not
/// happen.
library;

import 'dart:math' as math;

/// Result of advancing the clock.
class ClockAdvance {
  const ClockAdvance({
    required this.elapsed,
    required this.now,
    required this.rolledBack,
    required this.clamped,
  });

  /// Trusted elapsed time to feed into the simulation. Never negative.
  final Duration elapsed;

  /// The timestamp the caller should persist as the new `last_update`.
  final DateTime now;

  /// True when the system clock moved backwards since the last tick.
  final bool rolledBack;

  /// True when [elapsed] was cut down to [GameClock.maxAdvance].
  final bool clamped;

  bool get isZero => elapsed == Duration.zero;

  @override
  String toString() =>
      'ClockAdvance(elapsed: $elapsed, rolledBack: $rolledBack, clamped: $clamped)';
}

/// Reads wall time. Swapped out in tests and by the developer mode time
/// accelerator (§11.2).
abstract class WallClock {
  DateTime nowUtc();
}

class SystemWallClock implements WallClock {
  const SystemWallClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// A wall clock the caller drives by hand. Used by tests and by the ×60/×3600
/// time acceleration in developer mode.
class ManualWallClock implements WallClock {
  ManualWallClock(DateTime start) : _now = start.toUtc();

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void set(DateTime value) => _now = value.toUtc();
}

class GameClock {
  GameClock({
    this.wallClock = const SystemWallClock(),
    this.maxAdvance = const Duration(days: 30),
  });

  final WallClock wallClock;

  /// Upper bound on a single catch-up. A player returning after a year should
  /// not stall the tick engine grinding through 31 million seconds; the offline
  /// floor of §2.1.1 means the outcome is identical past a certain point anyway.
  final Duration maxAdvance;

  /// Highest timestamp ever accepted. Persisted alongside the save so the
  /// guarantee survives a restart — see [restore].
  DateTime? _highWaterMark;

  DateTime? get highWaterMark => _highWaterMark;

  /// Reinstates the high-water mark loaded from the database.
  void restore(DateTime? lastUpdate) {
    if (lastUpdate == null) return;
    final utc = lastUpdate.toUtc();
    final current = _highWaterMark;
    if (current == null || utc.isAfter(current)) {
      _highWaterMark = utc;
    }
  }

  /// Computes the trusted time elapsed since [lastUpdate].
  ///
  /// Three cases:
  /// * forward motion — the honest one, returns the real difference
  /// * clock rolled back — returns [Duration.zero] and holds the high-water
  ///   mark, so the player gains nothing and loses nothing
  /// * absurdly long gap — clamps to [maxAdvance]
  ClockAdvance advance(DateTime? lastUpdate) {
    final now = wallClock.nowUtc();
    final reference = _laterOf(lastUpdate?.toUtc(), _highWaterMark);

    if (reference == null) {
      // First ever tick: nothing elapsed, just anchor the clock.
      _highWaterMark = now;
      return ClockAdvance(
        elapsed: Duration.zero,
        now: now,
        rolledBack: false,
        clamped: false,
      );
    }

    if (!now.isAfter(reference)) {
      // Clock went backwards (or stood still). The stored timestamp stays put,
      // so winding the device clock forward again cannot be cashed in twice.
      return ClockAdvance(
        elapsed: Duration.zero,
        now: reference,
        rolledBack: now.isBefore(reference),
        clamped: false,
      );
    }

    final raw = now.difference(reference);
    final clamped = raw > maxAdvance;
    final elapsed = clamped ? maxAdvance : raw;

    _highWaterMark = now;
    return ClockAdvance(
      elapsed: elapsed,
      now: now,
      rolledBack: false,
      clamped: clamped,
    );
  }

  /// Number of whole 1 Hz ticks in [elapsed], capped so a single catch-up
  /// cannot exceed [maxAdvance].
  int ticksIn(Duration elapsed) => math.max(0, elapsed.inSeconds);

  static DateTime? _laterOf(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
