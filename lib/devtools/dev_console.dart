/// Developer console state (design doc §11.2).
///
/// Holds everything the panels manipulate: the simulated GPS, the time scale,
/// the physiology overrides and the recorder. Kept apart from the widgets so
/// the behaviour is testable without pumping a UI, and so the whole thing sits
/// behind one `if (kDevTools)` at the composition root.
///
/// ⚠️ Every physiological override is recorded (§11.2, replays). A balance
/// figure taken from a session where someone quietly set blood to 100% is a
/// lie, and the recording is what exposes it.
library;

import 'package:flutter/foundation.dart';

import '../core/scaled_wall_clock.dart';
import '../sim/tick.dart';
import 'dev_mode.dart';
import 'gpx.dart';
import 'session_recorder.dart';
import 'simulated_position_source.dart';

/// One-tap fixtures from §11.2 ("zestawy testowe").
enum DevPreset {
  fullKit('pełne wyposażenie'),
  critical('stan krytyczny'),
  exhausted('wyczerpany'),
  wellRested('wypoczęty');

  const DevPreset(this.label);

  final String label;
}

class DevConsole extends ChangeNotifier {
  DevConsole({
    required this.clock,
    required this.source,
    required this.constants,
    SessionRecorder? recorder,
  }) {
    _recorder = recorder;
    assertDevTools('DevConsole');
  }

  final ScaledWallClock clock;
  final SimulatedPositionSource source;

  /// Character constants the panels write against (§1.3).
  final SimConstants constants;

  SessionRecorder? _recorder;

  SessionRecorder? get recorder => _recorder;
  bool get isRecording => _recorder != null;

  /// Pending physiological override, applied by the host on the next tick.
  SimState? _pendingOverride;

  SimState? takePendingOverride() {
    final value = _pendingOverride;
    _pendingOverride = null;
    return value;
  }

  // ------------------------------------------------------------- time ---

  TimeScale get timeScale => clock.scale;

  void setTimeScale(TimeScale scale) {
    if (scale == clock.scale) return;
    clock.setScale(scale);
    _record(RecordedEventKind.timeScale, {'factor': scale.factor});
    notifyListeners();
  }

  /// Jumps virtual time forward. Never backwards — that would defeat the
  /// rollback guard of §2.1.1 that the rest of the code depends on.
  void skipForward(Duration amount) {
    clock.skipForward(amount);
    _record(RecordedEventKind.timeScale, {'skipSeconds': amount.inSeconds});
    notifyListeners();
  }

  // --------------------------------------------------------- position ---

  void setMovementMode(SimMovementMode mode) {
    source.mode = mode;
    notifyListeners();
  }

  void setSpeed(SimSpeedPreset preset) {
    source.setSpeed(preset);
    notifyListeners();
  }

  void steer(double degrees) {
    source.steer(degrees);
    notifyListeners();
  }

  void setSignalQuality(SimSignalQuality quality) {
    source.setQuality(quality);
    _record(RecordedEventKind.signal, {'quality': quality.name});
    notifyListeners();
  }

  void setNoiseEnabled(bool value) {
    source.noiseEnabled = value;
    notifyListeners();
  }

  void jumpTo(double latitude, double longitude) {
    source.jumpTo(latitude, longitude);
    notifyListeners();
  }

  void loadTrack(GpxTrack track) {
    source.loadTrack(track);
    notifyListeners();
  }

  /// Parses and loads a GPX document. Returns the error message on failure so
  /// the panel can show it rather than swallowing it.
  String? loadGpx(String source) {
    try {
      loadTrack(parseGpx(source));
      return null;
    } on GpxParseException catch (e) {
      return e.message;
    }
  }

  // -------------------------------------------------------- physiology ---

  /// Forces physiological values. Anything left null keeps its current value.
  void forceVitals(
    SimState current, {
    double? bloodMl,
    double? waterMl,
    double? caloriesKcal,
    double? heartRateBpm,
    int? sleepDebtSeconds,
    MetabolicZone? zone,
  }) {
    _pendingOverride = current.copyWith(
      bloodMl: bloodMl,
      waterMl: waterMl,
      caloriesKcal: caloriesKcal,
      heartRateBpm: heartRateBpm,
      sleepDebtSeconds: sleepDebtSeconds,
      zone: zone,
    );

    _record(RecordedEventKind.forceVitals, {
      'bloodMl': ?bloodMl,
      'waterMl': ?waterMl,
      'caloriesKcal': ?caloriesKcal,
      'heartRateBpm': ?heartRateBpm,
      'sleepDebtSeconds': ?sleepDebtSeconds,
      'zone': ?zone?.wire,
    });
    notifyListeners();
  }

  /// Applies a one-tap fixture.
  void applyPreset(DevPreset preset, SimState current) {
    switch (preset) {
      case DevPreset.fullKit:
      case DevPreset.wellRested:
        forceVitals(
          current,
          bloodMl: constants.bloodMaxMl,
          waterMl: constants.waterDailyMl,
          caloriesKcal: constants.caloriesDailyKcal,
          heartRateBpm: constants.restingHeartRate,
          sleepDebtSeconds: 0,
        );

      case DevPreset.critical:
        // Class III haemorrhagic shock, 5% of water and calories left (§2.6).
        forceVitals(
          current,
          bloodMl: constants.bloodMaxMl * 0.65,
          waterMl: constants.waterDailyMl * 0.05,
          caloriesKcal: constants.caloriesDailyKcal * 0.05,
          heartRateBpm: constants.maxHeartRate * 0.9,
        );

      case DevPreset.exhausted:
        // 26 hours of sleep debt: past the microsleep threshold of §2.5.4.
        forceVitals(current, sleepDebtSeconds: 26 * 3600);
    }
  }

  void setZone(MetabolicZone zone) {
    _record(RecordedEventKind.zone, {'zone': zone.wire});
    notifyListeners();
  }

  // ---------------------------------------------------------- recording ---

  void startRecording(RecordingHeader header) {
    _recorder = SessionRecorder(header: header);
    notifyListeners();
  }

  /// Stops recording and hands back the JSON Lines document.
  String? stopRecording() {
    final encoded = _recorder?.encode();
    _recorder = null;
    notifyListeners();
    return encoded;
  }

  void mark(String label) {
    _recorder?.addMarker(label, clock.nowUtc());
    notifyListeners();
  }

  void _record(RecordedEventKind kind, Map<String, Object?> payload) {
    _recorder?.add(
      RecordedEvent(kind: kind, at: clock.nowUtc(), payload: payload),
    );
  }
}
