/// Time acceleration for developer mode (design doc §11.2).
///
/// A game day has to be reachable in 24 seconds, otherwise nobody balances the
/// metabolic model. The acceleration lives here, in the clock, and **not** in
/// the tick engine: the engine is handed an elapsed duration and never learns
/// that time was multiplied. That keeps `advance()` pure and keeps accelerated
/// runs comparable with real ones.
library;

import 'game_clock.dart';

/// Multipliers offered by the developer panel.
enum TimeScale {
  realtime(1, '×1'),
  fast(60, '×60'),
  furious(3600, '×3600');

  const TimeScale(this.factor, this.label);

  /// How many simulated seconds pass per real second.
  final int factor;

  final String label;

  /// How long a game day takes at this scale.
  Duration get dayDuration => Duration(seconds: 86400 ~/ factor);

  static TimeScale fromFactor(int factor) => values.firstWhere(
    (s) => s.factor == factor,
    orElse: () => TimeScale.realtime,
  );
}

/// A [WallClock] that runs faster than the one underneath it.
///
/// Changing the scale re-anchors rather than recomputing history, so virtual
/// time is continuous across a switch — flipping ×1 → ×3600 → ×1 never makes
/// the clock jump backwards, which would trip the rollback guard of §2.1.1.
class ScaledWallClock implements WallClock {
  ScaledWallClock({
    this.base = const SystemWallClock(),
    TimeScale scale = TimeScale.realtime,
  }) {
    _scale = scale;
    _baseAnchor = base.nowUtc();
    _virtualAnchor = _baseAnchor;
  }

  /// The clock underneath. Real time in the app, a [ManualWallClock] in tests.
  final WallClock base;

  late TimeScale _scale;
  late DateTime _baseAnchor;
  late DateTime _virtualAnchor;

  TimeScale get scale => _scale;

  bool get isAccelerated => _scale != TimeScale.realtime;

  @override
  DateTime nowUtc() {
    final realElapsed = base.nowUtc().difference(_baseAnchor);
    return _virtualAnchor.add(realElapsed * _scale.factor);
  }

  /// Switches the multiplier, keeping virtual time continuous.
  void setScale(TimeScale value) {
    if (value == _scale) return;
    // Freeze where we are, then start counting at the new rate from here.
    _virtualAnchor = nowUtc();
    _baseAnchor = base.nowUtc();
    _scale = value;
  }

  /// Jumps virtual time forward by [amount] in one step.
  ///
  /// Used by the "skip to nightfall" style shortcuts. Only ever forward:
  /// jumping back would defeat the anti-cheat the rest of the code relies on.
  void skipForward(Duration amount) {
    if (amount <= Duration.zero) return;
    _virtualAnchor = nowUtc().add(amount);
    _baseAnchor = base.nowUtc();
  }

  /// Re-anchors virtual time to the real clock and drops back to ×1.
  void reset() {
    _scale = TimeScale.realtime;
    _baseAnchor = base.nowUtc();
    _virtualAnchor = _baseAnchor;
  }

  @override
  String toString() => 'ScaledWallClock(${_scale.label}, now: ${nowUtc()})';
}
