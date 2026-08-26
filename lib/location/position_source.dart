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

  /// Standing still, or in the shelter. 0.1 Hz.
  ///
  /// §3.3 asks for 0.05 Hz here, and twenty seconds is what that means. It was
  /// too slow in both directions: one dropped reading put the player past the
  /// dropout threshold, and since walking is recognised *from* fixes, leaving
  /// stillness took up to twenty seconds to notice. Ten costs little — the
  /// receiver is already warm — and removes both.
  resting(Duration(seconds: 10), 'resting'),

  /// In the shelter zone. One reading every fifteen seconds.
  ///
  /// ⚠️ **Slow, never off — and that distinction is a deadlock.** §2.1a.4 asks
  /// for the receiver to stop while a character stands still under their own
  /// roof, and it was taken literally: [PositionCadence.off]. But the *zone* is
  /// decided from the position, and with the receiver off no position ever
  /// arrives — so nothing could ever observe the player leaving, the cadence
  /// stayed off, and the pin sat on the shelter for the rest of the session.
  /// Walking out of the door did not bring it back, because walking out is a
  /// thing only a fix can tell anybody about.
  ///
  /// Fifteen seconds is a third of what standing in a street costs and keeps
  /// the receiver warm, so the moment a reading lands outside the safe radius
  /// the zone flips and §3.3's full rate comes straight back.
  sheltered(Duration(seconds: 15), 'sheltered'),

  /// In the shelter zone, and settled there. One reading every thirty
  /// seconds.
  ///
  /// ⚠️ **The second half of [sheltered], and it exists for the battery.**
  /// The first two minutes under a roof are somebody who may be about to walk
  /// out again — a search finished, a bag dropped, straight back to the
  /// street. Past that they are staying: sleeping, reading, building. Half the
  /// cost of [sheltered] and a quarter of standing outdoors, and leaving is
  /// still noticed inside half a minute.
  ///
  /// ⚠️ Not slower than this, and never off. §8.1 keeps enemies out of the
  /// zone, so nothing here is dangerous — but the zone is decided *from* the
  /// position, and a receiver that stops is a door nobody can walk out of.
  settled(Duration(seconds: 30), 'settled'),

  /// Asleep in a shelter. One reading a minute.
  ///
  /// ⚠️ **The cheapest thing a running game asks for, and it runs all night.**
  /// Eight hours is the longest single state in the game (§2.5.3) and the one
  /// where the position is least likely to have changed — a character cannot
  /// leave a shelter without leaving the zone, and leaving is a walk, which a
  /// minute is quick enough to catch.
  ///
  /// Reported from a night: at thirty seconds the receiver scattered enough to
  /// be charged as walking. The cadence is half the answer; the other half is
  /// that §8.1's zone is not a place anybody walks (see `GameLoop._buildInput`).
  asleep(Duration(minutes: 1), 'asleep'),

  /// Not running at all. What a stopped source reports, never a policy's
  /// answer — see [sheltered] for why nothing may ask for this while a game is
  /// being played.
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
  BasePositionSource({
    this.signalTimeout = const Duration(seconds: 60),
    this.degradeAfter = const Duration(seconds: 45),
    this.acquireGrace = const Duration(seconds: 40),
  });

  /// How long without a fix before the position stops being trusted (§3.2).
  final Duration signalTimeout;

  /// How long wide fixes have to keep arriving before the player is told the
  /// signal is weak. A cold start is wide for a few seconds and then is not.
  ///
  /// Forty-five rather than thirty, and never shorter than three sampling
  /// intervals (see [degradeWindow]): at one fix every ten seconds, thirty
  /// seconds is three readings, and losing three readings in a city is a
  /// Tuesday, not a fault worth a warning.
  final Duration degradeAfter;

  /// How long after starting the game says "acquiring" rather than "weak".
  ///
  /// Nothing has gone wrong in the first half-minute outdoors — the receiver
  /// is doing what a receiver does.
  final Duration acquireGrace;

  /// Set by the source when the cadence changes, so the degrade threshold
  /// tracks how often fixes were even asked for.
  Duration _interval = const Duration(seconds: 5);

  /// The window that has to pass without an accurate fix before the player is
  /// warned.
  Duration get degradeWindow {
    final threeSamples = _interval * 3;
    return threeSamples > degradeAfter ? threeSamples : degradeAfter;
  }

  /// Called by subclasses whenever the sampling rate changes.
  void noteCadence(PositionCadence cadence) {
    if (cadence.interval > Duration.zero) _interval = cadence.interval;
  }

  final _fixes = StreamController<PositionFix>.broadcast();
  final _signal = StreamController<PositionSignal>.broadcast();

  PositionFix? _lastFix;

  /// When a fix inside the accuracy gate last arrived.
  DateTime? _lastAccurate;

  PositionSignal _currentSignal = PositionSignal.unavailable;
  Timer? _watchdog;

  /// When this source started producing. The grace period is measured from
  /// here rather than from the first fix, because before the first fix there
  /// is nothing to measure from.
  DateTime? _startedAt;

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
  /// the fix cannot be trusted for movement (§3.2).
  ///
  /// But a *warning* is not the same as a rejection. The first fixes after a
  /// cold start are routinely 40 or 60 metres wide and tighten within seconds,
  /// and announcing a weak signal each time teaches the player that the HUD is
  /// wrong. So the signal only degrades once nothing accurate has arrived for
  /// [degradeAfter]; the simulation still ignores every wide fix immediately,
  /// which is the part that matters.
  void emitFix(PositionFix fix, {double accuracyGateM = 25.0}) {
    if (_fixes.isClosed) return;
    _lastFix = fix;
    _fixes.add(fix);

    final now = fix.timestamp;
    _startedAt ??= now;

    if (fix.accuracyM <= accuracyGateM) {
      _lastAccurate = now;
      _setSignal(PositionSignal.good);
      _armWatchdog();
      return;
    }

    final since = _lastAccurate;
    if (since == null) {
      // Nothing accurate has ever arrived. Until the grace period is up this
      // is a receiver warming up, not a signal worth complaining about.
      final waited = now.difference(_startedAt!);
      _setSignal(
        waited >= acquireGrace
            ? PositionSignal.degraded
            : PositionSignal.acquiring,
      );
    } else if (now.difference(since) >= degradeWindow) {
      _setSignal(PositionSignal.degraded);
    }
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
