/// The single entry point for positions (design doc §11.2).
///
/// ⚠️ **There is exactly one of these.** The real GPS (stage 3) and the
/// developer-mode simulator both implement [PositionSource], and everything
/// downstream — the metabolic engine, the map, spawn rules, the noise system —
/// only ever sees this interface.
///
/// The design document is blunt about why: a simulator that bypasses the field
/// code path masks every problem that will actually happen outdoors. Anything
/// the real provider can do to us — a bad fix, a dropout, a mocked location —
/// the simulator has to be able to do too.
library;

import 'dart:async';

import 'position_fix.dart';

/// How often positions are requested. Adaptive by activity to keep the battery
/// alive over a multi-hour session (§3.3).
enum PositionCadence {
  /// In combat. Everything depends on distance, so pay for it.
  combat(Duration(seconds: 1), 'combat'),

  /// Walking. 0.2 Hz is plenty to track a person on foot.
  moving(Duration(seconds: 5), 'moving'),

  /// Standing still, or in the shelter. 0.05 Hz.
  resting(Duration(seconds: 20), 'resting'),

  /// Shelter occupations run with GPS off entirely — the character is not
  /// moving, so the position is not needed (§2.1a.4).
  off(Duration.zero, 'off');

  const PositionCadence(this.interval, this.wire);

  final Duration interval;
  final String wire;
}

abstract class PositionSource {
  /// Fixes as they arrive. Never emits after [dispose].
  Stream<PositionFix> get fixes;

  /// Signal state, so the UI can say "no signal" rather than freezing (§3.2).
  Stream<PositionSignal> get signal;

  /// Last fix seen, or null before the first one.
  PositionFix? get lastFix;

  PositionSignal get currentSignal;

  /// The rate fixes are currently being asked for (§3.3). Reported rather than
  /// assumed, because the sampling policy and the source can disagree — a
  /// source that has been stopped is at [PositionCadence.off] whatever the
  /// policy last decided.
  PositionCadence get currentCadence;

  /// Whether this source is the developer simulator. The HUD says so, because
  /// a build that silently fakes movement is a build that produces meaningless
  /// balance data.
  bool get isSimulated;

  /// Whether fixes keep arriving once the app leaves the screen (§3.3).
  ///
  /// The simulation asks before deciding whether a walk with the phone in a
  /// pocket counts. A source that stops when the screen does cannot be
  /// distinguished from a player standing still, and charging them for a walk
  /// nobody measured would be worse than not counting it.
  bool get tracksInBackground;

  Future<void> start({PositionCadence cadence = PositionCadence.moving});

  /// Changes the sampling rate without tearing the source down.
  Future<void> setCadence(PositionCadence cadence);

  Future<void> stop();

  Future<void> dispose();
}

/// Shared plumbing: stream controllers, last-fix bookkeeping and the dropout
/// watchdog. Both the simulator and the real provider extend this, so the
/// "signal lost after 60 s" rule cannot be implemented twice and differently.
abstract class BasePositionSource implements PositionSource {
  BasePositionSource({this.signalTimeout = const Duration(seconds: 60)});

  /// How long without a fix before the position stops being trusted (§3.2).
  final Duration signalTimeout;

  final _fixes = StreamController<PositionFix>.broadcast();
  final _signal = StreamController<PositionSignal>.broadcast();

  PositionFix? _lastFix;
  PositionSignal _currentSignal = PositionSignal.unavailable;
  Timer? _watchdog;

  @override
  Stream<PositionFix> get fixes => _fixes.stream;

  @override
  Stream<PositionSignal> get signal => _signal.stream;

  @override
  PositionFix? get lastFix => _lastFix;

  @override
  PositionSignal get currentSignal => _currentSignal;

  /// Publishes a fix and restarts the dropout watchdog.
  ///
  /// Accuracy is judged here rather than by each caller: worse than 25 m and
  /// the fix is published but the signal is marked degraded, so the simulation
  /// can decide to ignore the movement (§3.2).
  void emitFix(PositionFix fix, {double accuracyGateM = 25.0}) {
    if (_fixes.isClosed) return;
    _lastFix = fix;
    _fixes.add(fix);
    _setSignal(
      fix.accuracyM > accuracyGateM
          ? PositionSignal.degraded
          : PositionSignal.good,
    );
    _armWatchdog();
  }

  /// Declares the signal gone without waiting for the watchdog. The simulator
  /// uses this to reproduce walking into a building.
  void emitSignalLoss() {
    _watchdog?.cancel();
    _watchdog = null;
    _setSignal(PositionSignal.lost);
  }

  void _setSignal(PositionSignal value) {
    if (_currentSignal == value) return;
    _currentSignal = value;
    if (!_signal.isClosed) _signal.add(value);
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    if (signalTimeout <= Duration.zero) return;
    _watchdog = Timer(signalTimeout, () => _setSignal(PositionSignal.lost));
  }

  /// Called by [stop] implementations.
  void markUnavailable() {
    _watchdog?.cancel();
    _watchdog = null;
    _setSignal(PositionSignal.unavailable);
  }

  @override
  Future<void> dispose() async {
    _watchdog?.cancel();
    _watchdog = null;
    await _fixes.close();
    await _signal.close();
  }
}
