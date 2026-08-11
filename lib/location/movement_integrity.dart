/// Deciding whether the movement is a person walking (design doc §3.4).
///
/// The game measures a real body moving through a real city. Two things break
/// that premise: a mock provider feeding invented coordinates, and a player in
/// a car. Neither is treated as a moral failing — the run is suspended, not
/// deleted, and it resumes as soon as the movement looks human again.
///
/// The car rule is deliberately generous. 40 km/h is far above a sprint, and it
/// has to be held for half a minute, so a bad fix, a tram window or a bicycle
/// downhill will not trip it.
library;

/// What the integrity monitor currently believes.
enum IntegrityState {
  /// Movement looks like a person.
  ok,

  /// Speed is over the threshold but has not been held long enough to act on.
  suspect,

  /// Gameplay is suspended: no calories, no loot, no spawns (§3.4).
  suspended,
}

/// Why gameplay was suspended, so the player can be told something specific.
enum IntegrityReason { none, mockProvider, vehicleSpeed }

/// Tracks sustained speed and mock reports across a session.
///
/// Pure and Flutter-free. One instance per session; it carries the timer.
class MovementIntegrity {
  MovementIntegrity({
    this.vehicleSpeedMps = 40 * 1000 / 3600,
    this.sustainedFor = const Duration(seconds: 30),
  });

  /// §3.4: 40 km/h. Above a sprint by a wide margin.
  final double vehicleSpeedMps;

  /// How long the threshold must be held before the run is suspended.
  final Duration sustainedFor;

  IntegrityState _state = IntegrityState.ok;
  IntegrityReason _reason = IntegrityReason.none;

  /// When the current run of over-threshold speed began, or null if the last
  /// sample was below it.
  DateTime? _overSince;

  IntegrityState get state => _state;
  IntegrityReason get reason => _reason;

  /// True when the simulation should stop crediting anything (§3.4).
  bool get isSuspended => _state == IntegrityState.suspended;

  /// Reports one speed sample. Returns the state after it.
  ///
  /// [at] is simulation time, not wall time, so a session replayed at ×3600
  /// trips the rule at the same point it did in the field.
  IntegrityState observeSpeed(double speedMps, DateTime at) {
    if (speedMps < vehicleSpeedMps) {
      _overSince = null;
      // A mock provider is not forgiven by slowing down — only by the provider
      // going away, which arrives as its own report.
      if (_reason != IntegrityReason.mockProvider) {
        _state = IntegrityState.ok;
        _reason = IntegrityReason.none;
      }
      return _state;
    }

    final since = _overSince ??= at;
    if (at.difference(since) >= sustainedFor) {
      _state = IntegrityState.suspended;
      _reason = IntegrityReason.vehicleSpeed;
    } else if (_state != IntegrityState.suspended) {
      _state = IntegrityState.suspect;
    }
    return _state;
  }

  /// Reports whether the provider is currently claiming mocked positions.
  ///
  /// Unlike speed, this suspends immediately: there is no reading of a mocked
  /// coordinate that is worth half a minute of doubt.
  IntegrityState observeMocked({required bool mocked}) {
    if (mocked) {
      _state = IntegrityState.suspended;
      _reason = IntegrityReason.mockProvider;
      return _state;
    }
    if (_reason == IntegrityReason.mockProvider) {
      _state = _overSince == null ? IntegrityState.ok : IntegrityState.suspect;
      _reason = _overSince == null
          ? IntegrityReason.none
          : IntegrityReason.vehicleSpeed;
    }
    return _state;
  }

  /// Clears everything. Used when a session starts, so a suspension does not
  /// survive into a run that has not earned it.
  void reset() {
    _state = IntegrityState.ok;
    _reason = IntegrityReason.none;
    _overSince = null;
  }
}
