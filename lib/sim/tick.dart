/// Simulation state and the tick function (design doc §11, §2.1).
///
/// Two properties are load-bearing and are what the tests here defend:
///
/// * **Idempotent.** A tick is derived from `last_update`, never from an
///   incrementing counter. Replaying the same tick after a crash recovery
///   produces the same state, so a crash can rewind the player but never
///   double-charge them (§11.1.2).
/// * **Pure.** No I/O, no clock reads, no globals. That is what lets it run in
///   an isolate and be replayed deterministically from a seed plus an event
///   stream (§11.2).
///
/// Stage 0 ships the plumbing with a deliberately trivial physiology model —
/// resting metabolism only. The real MET curves, sleep and bleeding arrive in
/// stage 2; the shape of [SimState] and [advance] is what stage 0 has to get
/// right.
library;

import 'dart:convert';
import 'dart:math' as math;

/// Metabolic zone the character is in (§2.1). Consumption scales by zone,
/// which is what makes closing the app under a roof cheaper than in the open.
enum MetabolicZone {
  open('open', calorieFactor: 1.00, waterFactor: 1.00),
  camp('camp', calorieFactor: 0.50, waterFactor: 0.55),
  shelter('shelter', calorieFactor: 0.35, waterFactor: 0.40),
  sleep('sleep', calorieFactor: 0.20, waterFactor: 0.30);

  const MetabolicZone(
    this.wire, {
    required this.calorieFactor,
    required this.waterFactor,
  });

  final String wire;
  final double calorieFactor;
  final double waterFactor;

  static MetabolicZone fromWire(String value) => values.firstWhere(
    (z) => z.wire == value,
    orElse: () => MetabolicZone.open,
  );
}

/// Constants a tick needs that do not change during a session. Derived once
/// from the character sheet (§1.3).
class SimConstants {
  const SimConstants({
    required this.bloodMaxMl,
    required this.waterDailyMl,
    required this.caloriesDailyKcal,
    required this.restingHeartRate,
    required this.maxHeartRate,
  });

  final double bloodMaxMl;
  final double waterDailyMl;
  final double caloriesDailyKcal;
  final double restingHeartRate;
  final double maxHeartRate;

  /// Floor enforced while the app is closed: offline consumption never drives
  /// a resource below 10% and never kills (§2.1.1).
  static const offlineFloor = 0.10;

  Map<String, Object?> toJson() => {
    'bloodMaxMl': bloodMaxMl,
    'waterDailyMl': waterDailyMl,
    'caloriesDailyKcal': caloriesDailyKcal,
    'restingHeartRate': restingHeartRate,
    'maxHeartRate': maxHeartRate,
  };

  factory SimConstants.fromJson(Map<String, Object?> json) => SimConstants(
    bloodMaxMl: (json['bloodMaxMl'] as num).toDouble(),
    waterDailyMl: (json['waterDailyMl'] as num).toDouble(),
    caloriesDailyKcal: (json['caloriesDailyKcal'] as num).toDouble(),
    restingHeartRate: (json['restingHeartRate'] as num).toDouble(),
    maxHeartRate: (json['maxHeartRate'] as num).toDouble(),
  );
}

/// The mutable simulation state. Immutable value object; [advance] returns a
/// new one rather than mutating, which is what makes replay comparisons cheap.
class SimState {
  const SimState({
    required this.lastUpdate,
    required this.bloodMl,
    required this.waterMl,
    required this.caloriesKcal,
    required this.heartRateBpm,
    required this.sleepDebtSeconds,
    required this.zone,
    required this.rngCursor,
  });

  /// The instant the simulation has been advanced to. Everything is derived
  /// from this, which is the whole idempotency story.
  final DateTime lastUpdate;

  final double bloodMl;
  final double waterMl;
  final double caloriesKcal;
  final double heartRateBpm;
  final int sleepDebtSeconds;
  final MetabolicZone zone;

  /// Draw position of the world RNG stream, carried so a resumed session
  /// continues the sequence instead of restarting it (§11).
  final int rngCursor;

  SimState copyWith({
    DateTime? lastUpdate,
    double? bloodMl,
    double? waterMl,
    double? caloriesKcal,
    double? heartRateBpm,
    int? sleepDebtSeconds,
    MetabolicZone? zone,
    int? rngCursor,
  }) => SimState(
    lastUpdate: lastUpdate ?? this.lastUpdate,
    bloodMl: bloodMl ?? this.bloodMl,
    waterMl: waterMl ?? this.waterMl,
    caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    sleepDebtSeconds: sleepDebtSeconds ?? this.sleepDebtSeconds,
    zone: zone ?? this.zone,
    rngCursor: rngCursor ?? this.rngCursor,
  );

  Map<String, Object?> toJson() => {
    'lastUpdate': lastUpdate.toUtc().toIso8601String(),
    'bloodMl': bloodMl,
    'waterMl': waterMl,
    'caloriesKcal': caloriesKcal,
    'heartRateBpm': heartRateBpm,
    'sleepDebtSeconds': sleepDebtSeconds,
    'zone': zone.wire,
    'rngCursor': rngCursor,
  };

  factory SimState.fromJson(Map<String, Object?> json) => SimState(
    lastUpdate: DateTime.parse(json['lastUpdate']! as String).toUtc(),
    bloodMl: (json['bloodMl'] as num).toDouble(),
    waterMl: (json['waterMl'] as num).toDouble(),
    caloriesKcal: (json['caloriesKcal'] as num).toDouble(),
    heartRateBpm: (json['heartRateBpm'] as num).toDouble(),
    sleepDebtSeconds: (json['sleepDebtSeconds'] as num).toInt(),
    zone: MetabolicZone.fromWire(json['zone']! as String),
    rngCursor: (json['rngCursor'] as num?)?.toInt() ?? 0,
  );

  /// Compares everything except [lastUpdate]. Used by the idempotency test:
  /// replaying a tick must land on the same numbers.
  bool sameValues(SimState other) =>
      _close(bloodMl, other.bloodMl) &&
      _close(waterMl, other.waterMl) &&
      _close(caloriesKcal, other.caloriesKcal) &&
      _close(heartRateBpm, other.heartRateBpm) &&
      sleepDebtSeconds == other.sleepDebtSeconds &&
      zone == other.zone &&
      rngCursor == other.rngCursor;

  static bool _close(double a, double b) => (a - b).abs() < 1e-9;

  @override
  String toString() => jsonEncode(toJson());
}

/// Result of advancing the simulation.
class TickOutcome {
  const TickOutcome({
    required this.state,
    required this.secondsApplied,
    required this.floored,
  });

  final SimState state;

  /// How many simulated seconds were actually applied.
  final int secondsApplied;

  /// True when the offline floor of §2.1.1 caught a resource. Surfaced in the
  /// return-after-a-break summary so the player understands why nothing hit
  /// zero.
  final bool floored;
}

/// Advances [state] by [elapsed], in whole seconds.
///
/// Pure and total: same inputs, same output, no I/O. `elapsed` must already
/// have been vetted by `GameClock` — this function trusts it and will happily
/// apply whatever it is handed.
///
/// `offline` selects the §2.1.1 safety valve: while the app was closed no
/// resource may fall below 10% and nothing may be fatal.
TickOutcome advance({
  required SimState state,
  required SimConstants constants,
  required Duration elapsed,
  bool offline = false,
}) {
  final seconds = elapsed.inSeconds;
  if (seconds <= 0) {
    return TickOutcome(state: state, secondsApplied: 0, floored: false);
  }

  final hours = seconds / 3600.0;

  // Stage 0 model: resting metabolism scaled by zone. MET from GPS speed,
  // sweat, sleep and bleeding land in stage 2 (§2.2–2.6).
  final calorieBurn =
      constants.caloriesDailyKcal / 24.0 * hours * state.zone.calorieFactor;
  final waterLoss =
      constants.waterDailyMl / 24.0 * hours * state.zone.waterFactor;

  // Heart rate relaxes towards resting with a ~90 s time constant (§2.4).
  const tauSeconds = 90.0;
  final relax = math.exp(-seconds / tauSeconds);
  final heartRate =
      constants.restingHeartRate +
      (state.heartRateBpm - constants.restingHeartRate) * relax;

  var calories = state.caloriesKcal - calorieBurn;
  var water = state.waterMl - waterLoss;
  var blood = state.bloodMl;

  var floored = false;
  if (offline) {
    final calorieFloor =
        constants.caloriesDailyKcal * SimConstants.offlineFloor;
    final waterFloor = constants.waterDailyMl * SimConstants.offlineFloor;
    final bloodFloor = constants.bloodMaxMl * SimConstants.offlineFloor;

    if (calories < calorieFloor) {
      calories = math.min(state.caloriesKcal, calorieFloor);
      floored = true;
    }
    if (water < waterFloor) {
      water = math.min(state.waterMl, waterFloor);
      floored = true;
    }
    if (blood < bloodFloor) {
      blood = math.min(state.bloodMl, bloodFloor);
      floored = true;
    }
  } else {
    calories = math.max(0, calories);
    water = math.max(0, water);
  }

  return TickOutcome(
    state: state.copyWith(
      lastUpdate: state.lastUpdate.add(Duration(seconds: seconds)),
      caloriesKcal: calories,
      waterMl: water,
      bloodMl: blood,
      heartRateBpm: heartRate,
    ),
    secondsApplied: seconds,
    floored: floored,
  );
}

/// Replays [elapsed] as a sequence of at most [chunk]-long steps.
///
/// Catching up on two weeks in one arithmetic step and catching up second by
/// second must land on the same state; chunking is how the tests prove the
/// model has no hidden per-tick accumulation.
TickOutcome advanceInChunks({
  required SimState state,
  required SimConstants constants,
  required Duration elapsed,
  Duration chunk = const Duration(hours: 1),
  bool offline = false,
}) {
  var current = state;
  var remaining = elapsed;
  var applied = 0;
  var floored = false;

  while (remaining > Duration.zero) {
    final step = remaining < chunk ? remaining : chunk;
    final outcome = advance(
      state: current,
      constants: constants,
      elapsed: step,
      offline: offline,
    );
    current = outcome.state;
    applied += outcome.secondsApplied;
    floored = floored || outcome.floored;
    remaining -= step;
  }

  return TickOutcome(state: current, secondsApplied: applied, floored: floored);
}
