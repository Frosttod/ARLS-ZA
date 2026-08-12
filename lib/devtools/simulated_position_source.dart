/// GPS simulator for developer mode (design doc §11.2).
///
/// ⚠️ **Injects through the same layer as the real GPS.** It implements
/// [PositionSource] and nothing downstream can tell the difference — which is
/// the point. A simulator that fed the game clean coordinates through a side
/// door would hide every problem that shows up outdoors.
///
/// Consequently it reproduces what the real chip does to us (§3.2):
///
/// * accuracy that wanders between 3 and 30 m
/// * positions scattered inside that accuracy circle, so a standing player
///   still produces drift
/// * signal loss on demand, for walking into a building
///
/// Randomness comes from [DeterministicRng], so a recorded session replays
/// with identical noise (§11.2, replays).
library;

import 'dart:async';
import 'dart:math' as math;

import '../core/deterministic_rng.dart';
import '../core/game_clock.dart';
import '../location/position_fix.dart';
import '../location/position_source.dart';
import 'dev_mode.dart';
import 'gpx.dart';

/// How the simulated character moves.
enum SimMovementMode {
  /// Standing still. Only GPS drift moves the reported position.
  stationary,

  /// Walking a loaded GPX track at [SimulatedPositionSource.speedMps].
  route,

  /// Driven by hand: heading from the arrow keys, speed from the slider.
  manual,
}

/// Preset ground speeds, matching the MET table of §2.2 so the metabolic model
/// can be exercised at each band without arithmetic in the operator's head.
enum SimSpeedPreset {
  still(0.0, 'postój'),
  slowWalk(0.8, 'powolny marsz'),
  walk(1.3, 'marsz'),
  briskWalk(1.6, 'szybki marsz'),
  jog(2.0, 'trucht'),
  run(2.6, 'bieg'),
  sprint(3.6, 'sprint');

  const SimSpeedPreset(this.mps, this.label);

  final double mps;
  final String label;

  double get kmh => mps * 3.6;
}

/// Quality of the simulated signal, which the operator sets to reproduce a
/// street canyon or the inside of a building.
enum SimSignalQuality {
  /// Open sky. 3–6 m, what the game is balanced around.
  open(3, 6, 'otwarte niebo'),

  /// Between buildings. 8–18 m — still usable, but the dead-zone filter of
  /// §3.2 starts to matter.
  urban(8, 18, 'zabudowa'),

  /// Deep canyon. 20–35 m, mostly above the 25 m gate: fixes arrive and get
  /// thrown away.
  canyon(20, 35, 'wąwóz miejski'),

  /// Indoors. Nothing arrives at all.
  none(0, 0, 'brak sygnału');

  const SimSignalQuality(this.minAccuracyM, this.maxAccuracyM, this.label);

  final double minAccuracyM;
  final double maxAccuracyM;
  final String label;

  bool get emitsFixes => this != SimSignalQuality.none;
}

class SimulatedPositionSource extends BasePositionSource {
  SimulatedPositionSource({
    required this.clock,
    GpxTrack? track,
    PositionFix? origin,
    DeterministicRng? rng,
    super.signalTimeout,
  }) : _track = track ?? defaultTestLoop(),
       _rng = rng ?? DeterministicRng(seed: 20260810) {
    assertDevTools('SimulatedPositionSource');
    final start = origin ?? _fixFromTrack(0);
    _truthLat = start.latitude;
    _truthLon = start.longitude;
  }

  /// The clock the simulator reads. Passing a [ScaledWallClock] makes the
  /// simulated walk speed up along with everything else.
  final WallClock clock;

  GpxTrack _track;
  final DeterministicRng _rng;

  Timer? _timer;
  PositionCadence _cadence = PositionCadence.moving;

  /// True position, before the error model. The game never sees this — which
  /// is exactly the situation in the field.
  late double _truthLat;
  late double _truthLon;

  double _distanceAlongM = 0;
  DateTime? _lastStep;

  SimMovementMode mode = SimMovementMode.route;
  double speedMps = SimSpeedPreset.walk.mps;
  double headingDeg = 0;
  SimSignalQuality quality = SimSignalQuality.open;

  /// When true, the reported position is the true one. Useful for isolating a
  /// bug: turn the noise off, see whether it survives.
  bool noiseEnabled = true;

  /// Marks every fix as coming from a mock provider (§3.4).
  ///
  /// §11.2 is the reason this exists: anything the real provider can do to us,
  /// the simulator has to be able to do too. Without it the anti-cheat could
  /// only ever be tested by installing a location spoofer on a real phone.
  bool reportMocked = false;

  GpxTrack get track => _track;

  /// Where the character really is, for the diagnostic overlay.
  ({double latitude, double longitude}) get truth =>
      (latitude: _truthLat, longitude: _truthLon);

  @override
  bool get isSimulated => true;

  @override
  PositionCadence get currentCadence => _cadence;

  /// The simulator runs on an ordinary timer, which the screen going off does
  /// not stop.
  @override
  bool get tracksInBackground => true;

  @override
  Future<void> start({PositionCadence cadence = PositionCadence.moving}) async {
    _cadence = cadence;
    _lastStep = clock.nowUtc();
    _schedule();
  }

  @override
  Future<void> setCadence(PositionCadence cadence) async {
    if (_cadence == cadence) return;
    _cadence = cadence;
    _schedule();
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    markUnavailable();
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await super.dispose();
  }

  /// Loads a different route and restarts from its beginning.
  void loadTrack(GpxTrack value) {
    _track = value;
    _distanceAlongM = 0;
    final start = _fixFromTrack(0);
    _truthLat = start.latitude;
    _truthLon = start.longitude;
  }

  /// Teleports to a coordinate. The one thing the real GPS cannot do, and the
  /// reason the developer panel exists — testing a hotspot 2 km away should
  /// not require a walk.
  void jumpTo(double latitude, double longitude) {
    _truthLat = latitude;
    _truthLon = longitude;
    mode = SimMovementMode.manual;
    _emitNow();
  }

  /// Arrow-key steering: turn by [degrees] and keep walking.
  void steer(double degrees) {
    mode = SimMovementMode.manual;
    headingDeg = (headingDeg + degrees) % 360;
    if (headingDeg < 0) headingDeg += 360;
  }

  void setSpeed(SimSpeedPreset preset) {
    speedMps = preset.mps;
    if (preset == SimSpeedPreset.still) return;
    if (mode == SimMovementMode.stationary) mode = SimMovementMode.manual;
  }

  /// Reproduces walking into a building: fixes stop arriving and the watchdog
  /// of §3.2 eventually declares the signal lost.
  void setQuality(SimSignalQuality value) {
    quality = value;
    if (!value.emitsFixes) emitSignalLoss();
  }

  /// Emits one fix immediately, regardless of the cadence.
  void step() => _emitNow();

  void _schedule() {
    _timer?.cancel();
    final interval = _cadence.interval;
    if (interval <= Duration.zero) {
      markUnavailable();
      return;
    }
    _timer = Timer.periodic(interval, (_) => _emitNow());
  }

  void _emitNow() {
    final now = clock.nowUtc();
    final elapsed = _lastStep == null
        ? Duration.zero
        : now.difference(_lastStep!);
    _lastStep = now;

    _advanceTruth(elapsed);

    if (!quality.emitsFixes) {
      // Nothing to publish. The watchdog in the base class handles the rest.
      return;
    }

    emitFix(_observedFix(now));
  }

  /// Moves the true position. Elapsed time comes from [clock], so under a
  /// [ScaledWallClock] the character covers ×60 or ×3600 the ground.
  void _advanceTruth(Duration elapsed) {
    if (elapsed <= Duration.zero) return;
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

    switch (mode) {
      case SimMovementMode.stationary:
        return;

      case SimMovementMode.route:
        _distanceAlongM += speedMps * seconds;
        final point = _track.pointAt(_distanceAlongM);
        _truthLat = point.latitude;
        _truthLon = point.longitude;
        headingDeg = point.bearingDeg;

      case SimMovementMode.manual:
        if (speedMps <= 0) return;
        final moved = _truthFix(
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ).offset(metres: speedMps * seconds, bearingDeg: headingDeg);
        _truthLat = moved.latitude;
        _truthLon = moved.longitude;
    }
  }

  /// Applies the error model: an accuracy figure drawn from the quality band,
  /// and a position scattered somewhere inside that circle.
  PositionFix _observedFix(DateTime now) {
    final truth = _truthFix(now);
    if (!noiseEnabled) {
      return truth.copyWith(
        accuracyM: quality.minAccuracyM,
        speedMps: speedMps,
        isMocked: reportMocked,
      );
    }

    final accuracy = _rng.nextDoubleRange(
      quality.minAccuracyM,
      quality.maxAccuracyM,
    );

    // Scatter within the accuracy circle. sqrt keeps the distribution uniform
    // over the area rather than clustering at the centre — real drift does not
    // politely stay near the truth.
    final radius = accuracy * math.sqrt(_rng.nextDouble());
    final bearing = _rng.nextDoubleRange(0, 360);

    return truth
        .offset(metres: radius, bearingDeg: bearing, accuracyM: accuracy)
        .copyWith(
          headingDeg: headingDeg,
          speedMps: speedMps,
          isMocked: reportMocked,
        );
  }

  PositionFix _truthFix(DateTime now) => PositionFix(
    latitude: _truthLat,
    longitude: _truthLon,
    accuracyM: quality.minAccuracyM,
    timestamp: now,
    headingDeg: headingDeg,
    speedMps: speedMps,
  );

  PositionFix _fixFromTrack(double metres) {
    final point = _track.pointAt(metres);
    return PositionFix(
      latitude: point.latitude,
      longitude: point.longitude,
      accuracyM: 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
