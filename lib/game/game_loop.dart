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
import '../safety/player_safety.dart';
import '../sim/daylight.dart';
import '../map/geometry.dart';
import '../shelter/shelter.dart';
import '../sim/body.dart';
import '../combat/pursuit.dart';
import '../sim/death.dart';
import '../sim/occupation.dart';
import '../sim/physiology.dart';
import '../sim/tick.dart';

/// The longest gap the loop is willing to treat as observed (§2.1.1, §3.3).
///
/// The tick runs every second while anything is watching, so a step longer than
/// this means the process was asleep, throttled or dead. Five minutes is far
/// beyond any scheduling jitter and far short of a journey.
const Duration kUnmeasuredGap = Duration(minutes: 5);

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
    this.displayFix,
    this.integrity = IntegrityState.ok,
    this.integrityReason = IntegrityReason.none,
    this.economy = false,
    this.batteryPercent = 100,
    this.combatBlocked = CombatBlock.none,
    this.clockRolledBack = false,
    this.lastFlushAt,
    this.down = DownState.none,
    this.downUntil,
    this.deathCause,
  });

  /// §9: on their feet, on the ground, still being ignored, or gone.
  final DownState down;

  /// §9.2: when the hour is up, or when the grace window closes.
  final DateTime? downUntil;

  /// §9.1: what did it, for the Chronicle and for the screen that says so.
  final DeathCause? deathCause;

  final SimState state;
  final SimStatus status;
  final PositionSignal signal;
  final double speedKmh;
  final bool isNight;
  final Occupation? occupation;

  /// The smoothed position the simulation trusts, or null while nothing has
  /// passed the accuracy gate (§3.2).
  final PositionFix? fix;

  /// The best position the phone has, gate or no gate.
  ///
  /// Deliberately separate. §3.2's 25 m gate decides what counts as *movement*
  /// — indoors every fix is 30 to 60 metres wide and none of it is walking. But
  /// it says nothing about where the player is standing, and refusing to draw
  /// them until the sky clears is how the map ended up pointing at nowhere in
  /// particular. Every other navigation app shows the wide fix with a wide
  /// circle round it, and so should this one.
  final PositionFix? displayFix;

  /// Whether the movement still looks like a person walking (§3.4). While
  /// suspended nothing is credited, and the HUD has to say why.
  final IntegrityState integrity;
  final IntegrityReason integrityReason;

  /// Reduced map, no animations (§3.3). True once the battery is low enough
  /// that the session is at risk of ending before the walk does.
  final bool economy;

  final int batteryPercent;

  /// Whether a fight may start (§3.5). Not a balance rule: somebody fighting a
  /// zombie at 20 km/h is on a bicycle, in a car, or crossing a road without
  /// looking.
  final CombatBlock combatBlocked;

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
    BleedTier initialBleeding = BleedTier.none,
    this.deathMode = DeathMode.softcore,
    DateTime? downUntil,
    DateTime? graceUntil,
    Pursuit? pursuit,
    // ignore: avoid_positional_boolean_parameters
    bool dead = false,
    GameClock? clock,
    PowerSource? power,
    this.cadence = const Duration(seconds: 1),
    this.powerInterval = const Duration(seconds: 60),
  }) : _state = initialState,
       _bleeding = initialBleeding,
       // ignore: prefer_initializing_formals
       _downUntil = downUntil,
       // ignore: prefer_initializing_formals
       _graceUntil = graceUntil,
       // ignore: prefer_initializing_formals
       _pursuit = pursuit,
       // ignore: prefer_initializing_formals
       _dead = dead,
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

  /// §8: what the player has built. Handed in from outside rather than read
  /// here, because the loop must not depend on the save layer — the tick
  /// engine runs in an isolate and the migration tests run without Flutter.
  List<Shelter> _shelters = const [];

  /// §8.1: the place the player is standing in, or null for the open street.
  Shelter? _inside;

  /// §2.5.1: when the player last settled under a roof with nothing on.
  ///
  /// Null the moment they step outside or start anything. Not persisted: after
  /// a restart the ten minutes begin again, which is the harmless direction to
  /// be wrong in — the overnight case is covered by night itself, and nobody
  /// loses sleep they had already banked.
  DateTime? _settledAt;

  /// §2.1a.2: whether a short action is running — eating, drinking, dressing a
  /// wound, turning a place over (§4.7).
  ///
  /// Owned by the interface rather than by the loop, so it has to be handed in.
  /// It matters here for one reason: somebody halfway through a bandage is not
  /// somebody who has been sitting still doing nothing.
  bool _acting = false;

  /// Tells the loop that the player has started or finished one.
  void setActing({required bool acting}) {
    if (_acting == acting) return;

    _acting = acting;
    _applyShelter();
    _publish();
  }

  PositionFix? _lastFix;
  double _speedKmh = 0;

  /// Raw fixes are never used directly: everything the simulation sees has been
  /// through the accuracy gate, the Kalman filter and the stationary test
  /// (§3.2).
  final FixFilter _filter = FixFilter();

  /// The last reading of any width, for the map. See [GameSnapshot.displayFix].
  PositionFix? _displayFix;

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

  /// True while the app is away *and* the source is still delivering fixes
  /// (§3.3). The simulation keeps running in that state; without it the time
  /// away is offline.
  bool _tracking = false;

  Timer? _timer;
  StreamSubscription<PositionFix>? _fixSub;
  StreamSubscription<PositionSignal>? _signalSub;
  final _snapshots = StreamController<GameSnapshot>.broadcast();

  Stream<GameSnapshot> get snapshots => _snapshots.stream;

  SimState get state => _state;

  Occupation? get occupation => _occupation;

  /// §8.1: which of them the player is inside, or null out in the open.
  Shelter? get insideShelter => _inside;

  /// §8: what the player has built. Setting it re-reads which one they are in,
  /// so walking through the door does not wait for the next fix.
  void setShelters(List<Shelter> shelters) {
    _shelters = shelters;
    _applyShelter();
    _publish();
  }

  /// §2.1, §2.5.1: the zone follows the walls, and sleep follows the zone.
  ///
  /// Sleep is a state rather than an action (§2.5.1): night, under a roof, and
  /// nothing else being done. Nobody presses anything — a character who is in
  /// their shelter at two in the morning is asleep, which is exactly what a
  /// player with the phone on a bedside table has actually done.
  void _applyShelter() {
    final fix = _lastFix ?? _displayFix;
    final now = _state.lastUpdate;

    _inside = fix == null
        ? null
        : shelterAt(
            GeoPoint(fix.latitude, fix.longitude),
            _shelters,
            now: now,
          );

    final inside = _inside;
    final night =
        fix != null &&
        isNightAt(
          momentUtc: now,
          latitude: fix.latitude,
          longitude: fix.longitude,
        );

    // §2.1a.1, §2.1a.2: anything the player deliberately started outranks
    // sleep. A character who chose to read at midnight is reading, and paying
    // for it — and so is one halfway through a bandage.
    //
    // Both kinds count. An *occupation* is the long one the loop owns; an
    // *action* is the short one the interface owns (§4.7: eating, drinking,
    // dressing a wound, turning a place over). The loop cannot see the second
    // kind on its own, which is why it is told.
    final busy =
        _acting || (_occupation != null && !_occupation!.kind.isDefault);

    // How long they have been under this roof with nothing on. Reset by
    // leaving and by starting anything — those are the two ways a person stops
    // settling down.
    if (inside == null || busy) {
      _settledAt = null;
    } else {
      _settledAt ??= now;
    }

    final settled =
        _settledAt != null &&
        now.difference(_settledAt!) >= kSettleToSleep;

    // Night is the immediate case §2.5.1 describes. The ten minutes are the
    // other half of the same idea: somebody who has been sitting in their own
    // shelter doing nothing at all since before the news started is not
    // "awake and idle", they are asleep in a chair. It costs them nothing they
    // were using — the moment they start anything, or step outside, they are
    // back on their feet.
    final asleep = inside != null && !busy && (night || settled);

    _state = _state.copyWith(
      zone: switch ((inside?.kind, asleep)) {
        (null, _) => MetabolicZone.open,
        (_, true) => MetabolicZone.sleep,
        (ShelterKind.main, _) => MetabolicZone.shelter,
        (ShelterKind.camp, _) => MetabolicZone.camp,
      },
    );
  }

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

    // Anything not from a mock provider is worth drawing, however wide. A
    // player standing in their kitchen should see themselves in their street.
    if (!raw.isMocked) {
      _displayFix = raw;
      _publish();
    }

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

    // A single step covering more than a few minutes means nobody was
    // measuring, whatever the flags say. A foreground service can be killed
    // without telling us, and Doze stops delivering fixes while leaving the
    // process alive — in both cases the loop wakes up holding a gap it did not
    // observe. Charging a fortnight of that as if it had been walked is
    // exactly what the offline valve of §2.1.1 exists to prevent.
    final unmeasured = elapsed > kUnmeasuredGap;
    final input = _buildInput(offline: offline || unmeasured);

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

    // Again, now that the clock has moved. The pass in [_buildInput] decided
    // what this step was, and this one decides what the *next* one is — which
    // is the difference between a character who settled down ten minutes ago
    // and one the HUD still shows sitting up.
    _applyShelter();
    await _applySampling(advanceResult.now);

    _checkDown();
    _checkWake();
    _checkGrace();

    writer.stageHot(_toCompanion());
    await writer.flushIfDue(advanceResult.now);
    await _maybeSnapshot(advanceResult.now);

    _publish();
  }

  TickInput _buildInput({required bool offline}) {
    _applyShelter();
    final sheltered = _state.zone.isSheltered;

    // §2.5.1: sleep is the default state under a roof at night, not a button.
    // The zone already carries that decision, so reading it back keeps the two
    // from ever disagreeing.
    final asleep = _state.zone == MetabolicZone.sleep;

    return TickInput(
      // A lost signal means the position cannot be trusted, so movement is not
      // counted at all — the alternative is charging the player for GPS drift
      // (§3.2).
      speedKmh:
          source.currentSignal == PositionSignal.good && !_integrity.isSuspended
          ? _speedKmh
          : 0,
      loadKg: 0, // inventory arrives in stage 4
      bleedTier: _bleeding,
      sleeping: asleep && sheltered,
      // Away from the screen but still being tracked is not offline: the walk
      // is real and measured (§3.3). Away with nothing measuring is.
      offline: offline || (!_appForeground && !_tracking),
    );
  }

  /// §9: whether the body has given out, and what that means for this mode.
  ///
  /// Called after every tick. The two refusals in §9.1 are checked here rather
  /// than in the rules, because only the loop knows whether the phone is
  /// asleep in a pocket or has lost the sky — and both of those are reasons a
  /// character must never die.
  void _checkDown() {
    if (_dead || _downUntil != null) return;

    final cause = fatalCause(statusOf(state: _state, constants: constants));
    if (cause == null) return;

    if (!mayDie(
      asleep: _state.zone == MetabolicZone.sleep,
      positionKnown: source.currentSignal != PositionSignal.lost,
    )) {
      return;
    }

    _cause = cause;
    _wentDown = true;

    if (deathMode == DeathMode.hardcore) {
      _dead = true;
    } else {
      // §9.2: an hour on the ground, wall-clock, and it runs with the app
      // closed — being unconscious cannot require watching a screen.
      _downUntil = _state.lastUpdate.add(kUnconsciousFor);
      _bleeding = BleedTier.none;
    }

    writer.stageHot(_toCompanion());
  }

  /// §9.2.1: comes round where the player physically is, once that is a place
  /// somebody can be standing.
  ///
  /// A deferral rather than a punishment: waking on a bus would put the
  /// character somewhere the player is not, and §0 makes that the one thing
  /// this game may never do.
  void _checkWake() {
    final until = _downUntil;
    if (until == null || _dead) return;

    final now = _state.lastUpdate;
    if (now.isBefore(until)) return;

    if (!mayWake(
      speedKmh: _speedKmh,
      positionKnown: source.currentSignal != PositionSignal.lost,
    )) {
      _downUntil = now.add(const Duration(minutes: 1));
      return;
    }

    // Up, and the hour is over for good: the deadline is cleared in the same
    // breath as the state is restored, so nothing can run this twice.
    _downUntil = null;
    _graceUntil = now.add(kGraceAfterWaking);
    _justWoke = true;
    _state = wokenFrom(_state, constants);

    writer.stageHot(_toCompanion());
    _publish();
  }

  /// §9.2: the ten minutes are over and the street has noticed them again.
  void _checkGrace() {
    final grace = _graceUntil;
    if (grace == null || _state.lastUpdate.isBefore(grace)) return;

    _graceUntil = null;
    writer.stageHot(_toCompanion());
  }

  /// Whether this snapshot is the one the character woke on.
  bool _justWoke = false;
  bool takeJustWoke() {
    final was = _justWoke;
    _justWoke = false;
    return was;
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
      at: now,
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
      appOpen: _appForeground || _tracking,
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
    pendingKcal: Value(_state.pendingKcal),
    pendingWaterMl: Value(_state.pendingWaterMl),
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
    bleedTier: Value(_bleeding.name),
    downUntil: Value(_downUntil),
    graceUntil: Value(_graceUntil),
    huntUntil: Value(_pursuit?.until),
    huntLatitude: Value(_pursuit?.at.latitude),
    huntLongitude: Value(_pursuit?.at.longitude),
    huntCount: Value(_pursuit?.count ?? 0),
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
        // The smoothed one when there is one: it is the same position with
        // the scatter taken out, and a pin that twitches while the player
        // stands still undermines every reading beside it. The raw fix is the
        // fallback for indoors, where nothing passes the gate at all.
        displayFix: fix ?? _displayFix,
        integrity: _integrity.state,
        integrityReason: _integrity.reason,
        economy: _economy,
        batteryPercent: _power.percent,
        combatBlocked: combatBlock(
          // The filtered speed of §3.2, not the raw one: a bad fix must not be
          // able to cancel a fight.
          speedKmh: _speedKmh,
          runSuspended: _integrity.isSuspended,
        ),
        clockRolledBack: _rolledBack,
        lastFlushAt: writer.lastHotFlush,
        down: down,
        downUntil: _downUntil,
        deathCause: _cause,
      ),
    );
  }

  /// Starts an occupation, cancelling whatever was running (§2.1a.1).
  OccupationEndReason? beginOccupation(Occupation next) {
    final result = startOccupation(next: next, current: _occupation);
    _occupation = result.started;

    // §2.1a.1: picking up a hammer is how somebody stops being asleep, and it
    // has to take effect now rather than at the next tick — otherwise the
    // screen shows a character building in their sleep.
    _applyShelter();
    _publish();
    return result.previousEnded;
  }

  void setZone(MetabolicZone zone) {
    _state = _state.copyWith(zone: zone);
    _publish();
  }

  /// Applies what using something did (§4.7).
  ///
  /// A game action rather than a developer override, so it has its own door:
  /// eating tops the reserve up towards the day's requirement and never past
  /// it (§2.2 — a full stomach is full), and first aid takes the bleeding down
  /// a grade rather than clearing it by fiat.
  /// ⚠️ No bleeding argument, on purpose. Nothing in the loop carries a wound
  /// yet — line 305 pins the tier at none until combat lands in stage 5 — so a
  /// dressing has nothing to treat, and accepting a parameter that silently
  /// did nothing would be worse than not offering it. The caller refuses to
  /// spend a bandage on an uninjured character instead.
  void applyUse({double kcal = 0, double waterMl = 0}) {
    // Into the stomach, not into the bloodstream. The tick moves it across at
    // the rates of §2.2 and §2.3, which is what makes a meal something taken
    // before it is needed.
    _state = _state.copyWith(
      pendingKcal: _state.pendingKcal + kcal,
      pendingWaterMl: _state.pendingWaterMl + waterMl,
    );
    writer.stageHot(_toCompanion());
    _publish();
  }

  /// §2.6: what is still open, and going on costing.
  BleedTier _bleeding;

  /// §9: how this character ends when the body gives out.
  final DeathMode deathMode;

  /// §5.6.2: the fight the player last walked out of, or null for a quiet
  /// street. Written with the vitals so that closing the app is not an escape.
  Pursuit? _pursuit;

  Pursuit? get pursuit => _pursuit;

  /// Records that the street is stirred up, or that it has gone quiet.
  void setPursuit(Pursuit? hunt) {
    _pursuit = hunt;
    writer.stageHot(_toCompanion());
  }

  /// §9.2: when the hour on the ground runs out. Null once they are up.
  DateTime? _downUntil;

  /// §9.2: when they stop being taken for dead. Null once that has passed.
  ///
  /// ⚠️ Persisted, and not a flag in memory. Held in memory, "already woken"
  /// was forgotten every time the process died — so reopening the app ran the
  /// waking again, put the character back to a quarter of their blood and
  /// announced the caches a second time. A character cannot wake up twice from
  /// the same blackout.
  DateTime? _graceUntil;

  /// §9.1: set once, and then nothing else happens to this character.
  bool _dead = false;
  DeathCause? _cause;

  /// §9: what the UI has to draw, and what every action has to check.
  DownState get down {
    if (_dead) return DownState.dead;

    final now = _state.lastUpdate;

    final until = _downUntil;
    if (until != null && now.isBefore(until)) return DownState.unconscious;

    final grace = _graceUntil;
    if (grace != null && now.isBefore(grace)) return DownState.grace;

    return DownState.none;
  }

  /// §9: whether the player may act at all. False on the ground and after the
  /// end; true during the grace window, which only stops the shooting.
  bool get canAct => down == DownState.none || down == DownState.grace;

  /// What the screen counts down to: the hour on the ground, then the ten
  /// minutes of being ignored.
  DateTime? get downUntil => _downUntil ?? _graceUntil;

  DeathCause? get deathCause => _cause;

  /// Raised for one snapshot when the character goes down, so the UI can say
  /// so once rather than every frame.
  bool _wentDown = false;
  bool takeWentDown() {
    final was = _wentDown;
    _wentDown = false;
    return was;
  }

  BleedTier get bleeding => _bleeding;

  /// §2.6: a dressing, in the grade it can handle.
  ///
  /// Down to the grade rather than to nothing: a pressure dressing on an
  /// arterial bleed is not a tourniquet, and §2.6's table is explicit that
  /// only a tourniquet answers that one.
  void treatBleeding(BleedTier down) {
    if (_bleeding.index <= down.index) return;

    _bleeding = down;
    writer.stageHot(_toCompanion());
    _publish();
  }

  /// A wound, in millilitres of blood (§2.6, §6.2).
  ///
  /// Straight out of the reserve rather than into a queue: §2.2's absorption
  /// is about a stomach, and nothing about being hit is gradual. Never below
  /// zero — §9's death arrives with the shelter in stage 8, and until then a
  /// character at nothing left is a character the game simply stops hurting.
  void applyWound(double bloodLossMl, {BleedTier bleeding = BleedTier.none}) {
    if (bloodLossMl <= 0) return;

    // The worse of the two: a bite on top of an open wound does not make the
    // open one better, and §2.6 has no notion of two bleeds at once.
    if (bleeding.index > _bleeding.index) _bleeding = bleeding;

    final left = _state.bloodMl - bloodLossMl;
    _state = _state.copyWith(bloodMl: left < 0 ? 0 : left);
    writer.stageHot(_toCompanion());
    _publish();
  }

  /// Applies a developer-mode override (§11.2).
  void applyOverride(SimState forced) {
    _state = forced.copyWith(lastUpdate: _state.lastUpdate);
    writer.stageHot(_toCompanion());
    _publish();
  }

  /// The app went to the background.
  ///
  /// Two things happen here and they are independent. Everything is flushed and
  /// the WAL checkpointed, because this is the moment the process is most
  /// likely to be killed (§11.1.5) — that is unconditional.
  ///
  /// Whether the simulation keeps running depends on the source. With the
  /// foreground service alive the fixes keep coming, so a walk with the phone
  /// in a pocket goes on being counted, which is the entire reason §3.3 pays
  /// for that service. Without it Android stops delivering fixes, and a tick
  /// that kept running would credit the player with standing still — so the
  /// loop stops and the time away is replayed under the offline valve of
  /// §2.1.1 instead.
  Future<void> onPaused(DateTime now) async {
    _appForeground = false;
    _tracking = source.tracksInBackground;

    if (!_tracking) {
      _timer?.cancel();
      _timer = null;
    }

    await _tick();
    await writer.quiesce(now);
    await persistClockMark(session.db, clock);

    if (!_tracking) {
      _cadence = PositionCadence.resting;
      await source.setCadence(PositionCadence.resting);
    }
  }

  /// The app came back.
  Future<void> onResumed() async {
    final wasTracking = _tracking;
    _appForeground = true;
    _tracking = false;

    if (!wasTracking) {
      // A fix from before the pause must not be smoothed against one from
      // after it: the estimate in between is meaningless, and the jump would
      // read as a sprint (§3.2). When the source never stopped there is no
      // gap, and resetting would throw away a path that was measured properly.
      _filter.reset();
      _cadence = PositionCadence.moving;
      await source.setCadence(PositionCadence.moving);
    }

    // Only a session that stopped needs an offline catch-up. One that kept
    // ticking has nothing to catch up on, and replaying it under the offline
    // valve would quietly refund the walk it just charged for.
    await _tick(offline: !wasTracking);
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
