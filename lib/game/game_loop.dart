/// Connects the position layer, the tick engine and the save layer.
///
/// This is the piece stages 0 and 1 deliberately left out: the persistence
/// machinery and the GPS simulator existed but nothing joined them. The chain
/// it closes is short and is the whole game underneath the UI:
///
/// ```
/// PositionSource → speed → MET → TickEngine → SaveWriter → database
/// ```
///
/// Responsibilities kept out of here on purpose: the tick function stays pure
/// (§11.1.2), the position source stays ignorant of the simulation (§11.2), and
/// the writer keeps owning the 60-second cadence (§11.1.1). This class only
/// wires them and decides *when*.
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/game_clock.dart';
import '../data/db/database.dart';
import '../data/persistence/save_bootstrap.dart';
import '../data/persistence/save_writer.dart';
import '../location/fix_filter.dart';
import '../location/movement_integrity.dart';
import '../location/position_fix.dart';
import '../location/position_source.dart';
import '../location/power_source.dart';
import '../location/sampling_policy.dart';
import '../sim/daylight.dart';
import '../sim/occupation.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';

/// Everything the UI needs to draw a frame.
class GameSnapshot {
  const GameSnapshot({
    required this.state,
    required this.status,
    required this.signal,
    required this.speedKmh,
    required this.isNight,
    required this.occupation,
    this.fix,
    this.integrity = IntegrityState.ok,
    this.integrityReason = IntegrityReason.none,
    this.economy = false,
    this.batteryPercent = 100,
    this.clockRolledBack = false,
    this.lastFlushAt,
  });

  final SimState state;
  final SimStatus status;
  final PositionSignal signal;
  final double speedKmh;
  final bool isNight;
  final Occupation? occupation;

  /// The smoothed position, not the raw reading (§3.2).
  final PositionFix? fix;

  /// Whether the movement still looks like a person walking (§3.4). While
  /// suspended nothing is credited, and the HUD has to say why.
  final IntegrityState integrity;
  final IntegrityReason integrityReason;

  /// Reduced map, no animations (§3.3). True once the battery is low enough
  /// that the session is at risk of ending before the walk does.
  final bool economy;

  final int batteryPercent;

  /// True once the anti-cheat of §2.1.1 has rejected a tick, so the HUD can
  /// say so rather than appearing frozen.
  final bool clockRolledBack;

  final DateTime? lastFlushAt;
}

/// Drives one character's simulation for as long as the app is running.
class GameLoop {
  GameLoop({
    required this.session,
    required this.source,
    required this.profileId,
    required this.constants,
    required SimState initialState,
    GameClock? clock,
    PowerSource? power,
    this.cadence = const Duration(seconds: 1),
    this.powerInterval = const Duration(seconds: 60),
  }) : _state = initialState,
       power = power ?? const ConstantPowerSource(),
       clock = clock ?? session.clock {
    this.clock.restore(initialState.lastUpdate);
  }

  final SaveSession session;
  final PositionSource source;
  final int profileId;
  final SimConstants constants;
  final GameClock clock;
  final Duration cadence;

  /// Where the battery level comes from (§3.3).
  final PowerSource power;

  /// How often to ask. The level moves by a per cent every few minutes, and
  /// every read crosses a platform channel, so asking each tick would cost more
  /// than it saves.
  final Duration powerInterval;

  SaveWriter get writer => session.writer;

  SimState _state;
  Occupation? _occupation;
  PositionFix? _lastFix;
  double _speedKmh = 0;

  /// Raw fixes are never used directly: everything the simulation sees has been
  /// through the accuracy gate, the Kalman filter and the stationary test
  /// (§3.2).
  final FixFilter _filter = FixFilter();

  /// §3.4. Kept alongside the filter because both answer the same question from
  /// different ends: is this movement real, and is it human.
  final MovementIntegrity _integrity = MovementIntegrity();

  /// §3.3. Decides how often to ask the chip where we are.
  final SamplingPolicy _sampling = SamplingPolicy();

  PowerState _power = PowerState.unknown;
  DateTime? _powerReadAt;
  bool _economy = false;
  PositionCadence _cadence = PositionCadence.moving;

  /// Raised for one snapshot when the battery first drops below the threshold,
  /// so the UI can suggest heading back to the shelter (§3.3).
  bool _lowBatteryWarning = false;
  bool get lowBatteryWarning => _lowBatteryWarning;

  bool _samplingBusy = false;
  bool _rolledBack = false;
  bool _appForeground = true;

  Timer? _timer;
  StreamSubscription<PositionFix>? _fixSub;
  StreamSubscription<PositionSignal>? _signalSub;
  final _snapshots = StreamController<GameSnapshot>.broadcast();

  Stream<GameSnapshot> get snapshots => _snapshots.stream;

  SimState get state => _state;

  Occupation? get occupation => _occupation;

  /// Starts the position source and the tick cadence, replaying whatever time
  /// passed since the save was last written.
  Future<void> start() async {
    _fixSub = source.fixes.listen(_onFix);
    _signalSub = source.signal.listen((_) => _publish());

    await source.start();

    // Catch up before the first live tick, so the player never sees a stale
    // body for a frame (§2.1.1).
    await _tick(offline: true);

    _timer = Timer.periodic(cadence, (_) => unawaited(_tick()));
  }

  void _onFix(PositionFix raw) {
    final outcome = _filter.accept(raw);

    if (outcome is FixDropped) {
      // A mocked fix is the one rejection the player has to hear about; the
      // other two are ordinary weather.
      _integrity.observeMocked(mocked: outcome.reason == FixRejection.mocked);
      if (outcome.reason == FixRejection.mocked) _publish();
      return;
    }

    final accepted = outcome as FixAccepted;
    _integrity.observeMocked(mocked: false);

    // Speed comes from consecutive fixes rather than from the provider's own
    // field: the simulator supplies one and the real chip sometimes does not,
    // and the simulation must not behave differently depending on which is
    // running.
    _speedKmh = accepted.speedMps * 3.6;
    _lastFix = accepted.fix;
    _integrity.observeSpeed(accepted.speedMps, accepted.fix.timestamp);

    // The sampling rate reacts to movement, and movement arrives here rather
    // than on the tick. Waiting for the next tick would leave someone who has
    // just started walking being sampled at 0.05 Hz (§3.3).
    unawaited(_applySampling(accepted.fix.timestamp));
  }

  /// Advances the simulation to now and stages the result for writing.
  Future<void> _tick({bool offline = false}) async {
    final advanceResult = clock.advance(_state.lastUpdate);
    _rolledBack = advanceResult.rolledBack;

    if (advanceResult.isZero) {
      _publish();
      return;
    }

    final elapsed = advanceResult.elapsed;
    final input = _buildInput(offline: offline);

    // A long gap is replayed in chunks so the model has no chance to
    // accumulate error, and so a fortnight does not become one arithmetic step.
    final outcome = elapsed > const Duration(hours: 1)
        ? advanceInChunks(
            state: _state,
            constants: constants,
            elapsed: elapsed,
            input: input,
          )
        : advance(
            state: _state,
            constants: constants,
            elapsed: elapsed,
            input: input,
          );

    _state = outcome.state;
    _advanceOccupation(elapsed);
    await _applySampling(advanceResult.now);

    writer.stageHot(_toCompanion());
    await writer.flushIfDue(advanceResult.now);
    await _maybeSnapshot(advanceResult.now);

    _publish();
  }

  TickInput _buildInput({required bool offline}) {
    final sheltered = _state.zone.isSheltered;
    final asleep = _occupation?.kind == OccupationKind.sleep;

    return TickInput(
      // A lost signal means the position cannot be trusted, so movement is not
      // counted at all — the alternative is charging the player for GPS drift
      // (§3.2).
      speedKmh:
          source.currentSignal == PositionSignal.good && !_integrity.isSuspended
          ? _speedKmh
          : 0,
      loadKg: 0, // inventory arrives in stage 4
      bleedTier: BleedTier.none, // combat arrives in stage 5
      sleeping: asleep && sheltered,
      offline: offline || !_appForeground,
    );
  }

  /// Re-reads the battery when it is due, then sets the sampling rate the
  /// character's current activity deserves (§3.3).
  Future<void> _applySampling(DateTime now) async {
    // Fixes and ticks both ask for this, and both can be in flight at once.
    // Two concurrent runs would fight over the cadence.
    if (_samplingBusy) return;
    _samplingBusy = true;
    try {
      await _decideSampling(now);
    } finally {
      _samplingBusy = false;
    }
  }

  Future<void> _decideSampling(DateTime now) async {
    final due =
        _powerReadAt == null || now.difference(_powerReadAt!) >= powerInterval;
    if (due) {
      _powerReadAt = now;
      _power = await power.read();
    }

    final decision = _sampling.decide(
      activity: activityFrom(
        // Combat arrives in stage 5; until then nothing asks for 1 Hz.
        inCombat: false,
        sheltered: _state.zone.isSheltered,
        speedKmh: _speedKmh,
      ),
      batteryPercent: _power.percent,
      charging: _power.charging,
    );

    _economy = decision.economy;
    _lowBatteryWarning = decision.warnLowBattery;

    if (decision.cadence != _cadence) {
      _cadence = decision.cadence;
      await source.setCadence(decision.cadence);
    }
  }

  void _advanceOccupation(Duration elapsed) {
    final current = _occupation;
    if (current == null) return;

    final progress = advanceOccupation(
      occupation: current,
      elapsed: elapsed,
      appOpen: _appForeground,
      inShelterZone: _state.zone.isSheltered,
      gpsHealthy: source.currentSignal != PositionSignal.lost,
    );

    _occupation = progress.occupation;
  }

  Future<void> _maybeSnapshot(DateTime now) async {
    if (!await session.snapshots.isDue(session.db, now)) return;
    await session.snapshots.capture(session.db, now: now);
  }

  VitalsCompanion _toCompanion() => VitalsCompanion(
    profileId: Value(profileId),
    lastUpdate: Value(_state.lastUpdate),
    bloodMl: Value(_state.bloodMl),
    waterMl: Value(_state.waterMl),
    caloriesKcal: Value(_state.caloriesKcal),
    heartRateBpm: Value(_state.heartRateBpm),
    sleepDebtSeconds: Value(_state.sleepDebtSeconds),
    zone: Value(_state.zone.wire),
    latitude: Value(_lastFix?.latitude),
    longitude: Value(_lastFix?.longitude),
    accuracyM: Value(_lastFix?.accuracyM),
    speedKmh: Value(_speedKmh),
    occupationJson: Value(
      _occupation == null ? null : jsonEncode(_occupation!.toJson()),
    ),
  );

  void _publish() {
    if (_snapshots.isClosed) return;

    final fix = _lastFix;
    _snapshots.add(
      GameSnapshot(
        state: _state,
        status: statusOf(state: _state, constants: constants),
        signal: source.currentSignal,
        speedKmh: _speedKmh,
        isNight: fix == null
            ? false
            : isNightAt(
                momentUtc: _state.lastUpdate,
                latitude: fix.latitude,
                longitude: fix.longitude,
              ),
        occupation: _occupation,
        fix: fix,
        integrity: _integrity.state,
        integrityReason: _integrity.reason,
        economy: _economy,
        batteryPercent: _power.percent,
        clockRolledBack: _rolledBack,
        lastFlushAt: writer.lastHotFlush,
      ),
    );
  }

  /// Starts an occupation, cancelling whatever was running (§2.1a.1).
  OccupationEndReason? beginOccupation(Occupation next) {
    final result = startOccupation(next: next, current: _occupation);
    _occupation = result.started;
    _publish();
    return result.previousEnded;
  }

  void setZone(MetabolicZone zone) {
    _state = _state.copyWith(zone: zone);
    _publish();
  }

  /// Applies a developer-mode override (§11.2).
  void applyOverride(SimState forced) {
    _state = forced.copyWith(lastUpdate: _state.lastUpdate);
    writer.stageHot(_toCompanion());
    _publish();
  }

  /// The app went to the background: flush everything and checkpoint the WAL,
  /// because this is the moment the process is most likely to be killed
  /// (§11.1.5).
  Future<void> onPaused(DateTime now) async {
    _appForeground = false;
    _timer?.cancel();
    _timer = null;

    await _tick();
    await writer.quiesce(now);
    await persistClockMark(session.db, clock);
    _cadence = PositionCadence.resting;
    await source.setCadence(PositionCadence.resting);
  }

  /// The app came back. Catch up before resuming the cadence.
  Future<void> onResumed() async {
    _appForeground = true;

    // A fix from before the pause must not be smoothed against one from after
    // it: the estimate in between is meaningless, and the jump would read as a
    // sprint (§3.2).
    _filter.reset();
    _cadence = PositionCadence.moving;
    await source.setCadence(PositionCadence.moving);
    await _tick(offline: true);
    _timer ??= Timer.periodic(cadence, (_) => unawaited(_tick()));
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _fixSub?.cancel();
    await _signalSub?.cancel();
    await _snapshots.close();
  }
}
