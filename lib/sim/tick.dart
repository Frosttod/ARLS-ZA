/// Simulation state and the tick function (design doc §2, §11).
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
/// A third property falls out of the first two and matters just as much:
/// **linearity in elapsed time**. Advancing two weeks in one step and second by
/// second must land on the same numbers, because a catch-up after an absence
/// does the former while a live session does the latter.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'metabolism.dart';
import 'physiology.dart';

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

  /// True for the two zones that count as being under a roof, where shelter
  /// occupations may run and sleep is possible (§2.5.1).
  bool get isSheltered =>
      this == MetabolicZone.shelter ||
      this == MetabolicZone.camp ||
      this == MetabolicZone.sleep;

  static MetabolicZone fromWire(String value) => values.firstWhere(
    (z) => z.wire == value,
    orElse: () => MetabolicZone.open,
  );
}

/// §2.6: how fast blood comes back with nothing open and a full stomach.
///
/// Sixty millilitres an hour puts a two-litre loss — the far side of class III
/// — back in about a day and a half, and a survivable class II back overnight.
/// Slower than a real plasma refill on purpose: it has to be worth carrying
/// food home for, not something that happens while the phone is in a pocket.
const double kBloodRegenMlPerHour = 60;

/// Constants a tick needs that do not change during a session. Derived once
/// from the character sheet (§1.3) by `BodyProfile.toSimConstants`.
class SimConstants {
  const SimConstants({
    required this.bloodMaxMl,
    required this.waterDailyMl,
    required this.caloriesDailyKcal,
    required this.restingHeartRate,
    required this.maxHeartRate,
    this.bodyMassKg = 80,
  });

  final double bloodMaxMl;
  final double waterDailyMl;
  final double caloriesDailyKcal;
  final double restingHeartRate;
  final double maxHeartRate;

  /// Needed by the MET formulas of §2.2 and by the dehydration thresholds,
  /// which are expressed against body mass.
  final double bodyMassKg;

  /// Floor enforced while the app is closed: offline consumption never drives
  /// a resource below 10% and never kills (§2.1.1).
  static const offlineFloor = 0.10;

  Map<String, Object?> toJson() => {
    'bloodMaxMl': bloodMaxMl,
    'waterDailyMl': waterDailyMl,
    'caloriesDailyKcal': caloriesDailyKcal,
    'restingHeartRate': restingHeartRate,
    'maxHeartRate': maxHeartRate,
    'bodyMassKg': bodyMassKg,
  };

  factory SimConstants.fromJson(Map<String, Object?> json) => SimConstants(
    bloodMaxMl: (json['bloodMaxMl'] as num).toDouble(),
    waterDailyMl: (json['waterDailyMl'] as num).toDouble(),
    caloriesDailyKcal: (json['caloriesDailyKcal'] as num).toDouble(),
    restingHeartRate: (json['restingHeartRate'] as num).toDouble(),
    maxHeartRate: (json['maxHeartRate'] as num).toDouble(),
    bodyMassKg: (json['bodyMassKg'] as num?)?.toDouble() ?? 80,
  );
}

/// What the character is doing right now, as far as the tick is concerned.
///
/// Everything here comes from outside the simulation — GPS speed, carried
/// load, the wound state — and is held constant across a single [advance].
class TickInput {
  const TickInput({
    this.speedKmh = 0,
    this.loadKg = 0,
    this.ambientTempC = 15,
    this.clothingClo = 0,
    this.bleedTier = BleedTier.none,
    this.sleeping = false,
    this.offline = false,
  });

  /// Ground speed from the position layer. Already filtered — the dead zone of
  /// §3.2 decides what counts as movement before it reaches here.
  final double speedKmh;

  final double loadKg;

  /// Neutral default of 15 °C until the weather layer arrives (§17.3).
  final double ambientTempC;

  final double clothingClo;

  final BleedTier bleedTier;

  /// True while the character is asleep, which pays down the sleep debt
  /// instead of accruing it (§2.5).
  final bool sleeping;

  /// True for a catch-up over time the app was closed. Turns on the §2.1.1
  /// safety valve.
  final bool offline;

  static const resting = TickInput();
}

/// How fast what has been eaten becomes usable (§2.2).
///
/// A 520 kcal tin over roughly an hour. Not a digestion model — it is one
/// number standing in for one — but it is the number that makes the difference
/// a player feels: food is something you take before you need it, not a button
/// you press when the bar turns red.
const double kCalorieAbsorptionKcalPerMin = 8;

/// And how fast water does (§2.3). Half a litre in twenty minutes, which is
/// roughly what a stomach passes on.
const double kWaterAbsorptionMlPerMin = 25;

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
    this.pendingKcal = 0,
    this.pendingWaterMl = 0,
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

  /// Eaten and drunk, not yet absorbed.
  ///
  /// A tin of beans is not blood sugar the moment it is swallowed, and half a
  /// litre of water is not hydration until the stomach has passed it on. The
  /// reserves fill from here at [kCalorieAbsorptionKcalPerMin] and
  /// [kWaterAbsorptionMlPerMin], which is what makes eating something a player
  /// does *before* they need it rather than at the moment the bar turns red.
  final double pendingKcal;
  final double pendingWaterMl;

  Duration get sleepDebt => Duration(seconds: sleepDebtSeconds);

  SimState copyWith({
    DateTime? lastUpdate,
    double? bloodMl,
    double? waterMl,
    double? caloriesKcal,
    double? heartRateBpm,
    int? sleepDebtSeconds,
    MetabolicZone? zone,
    int? rngCursor,
    double? pendingKcal,
    double? pendingWaterMl,
  }) => SimState(
    lastUpdate: lastUpdate ?? this.lastUpdate,
    bloodMl: bloodMl ?? this.bloodMl,
    waterMl: waterMl ?? this.waterMl,
    caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    sleepDebtSeconds: sleepDebtSeconds ?? this.sleepDebtSeconds,
    zone: zone ?? this.zone,
    rngCursor: rngCursor ?? this.rngCursor,
    pendingKcal: pendingKcal ?? this.pendingKcal,
    pendingWaterMl: pendingWaterMl ?? this.pendingWaterMl,
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
    'pendingKcal': pendingKcal,
    'pendingWaterMl': pendingWaterMl,
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
    pendingKcal: (json['pendingKcal'] as num?)?.toDouble() ?? 0,
    pendingWaterMl: (json['pendingWaterMl'] as num?)?.toDouble() ?? 0,
  );

  /// Starting state for a freshly created character.
  factory SimState.fresh({
    required DateTime at,
    required SimConstants constants,
  }) => SimState(
    lastUpdate: at.toUtc(),
    bloodMl: constants.bloodMaxMl,
    waterMl: constants.waterDailyMl,
    caloriesKcal: constants.caloriesDailyKcal,
    heartRateBpm: constants.restingHeartRate,
    sleepDebtSeconds: 0,
    zone: MetabolicZone.open,
    rngCursor: 0,
  );

  /// Compares everything except [lastUpdate]. Used by the idempotency test:
  /// replaying a tick must land on the same numbers.
  bool sameValues(SimState other) =>
      _close(bloodMl, other.bloodMl) &&
      _close(waterMl, other.waterMl) &&
      _close(caloriesKcal, other.caloriesKcal) &&
      _close(pendingKcal, other.pendingKcal) &&
      _close(pendingWaterMl, other.pendingWaterMl) &&
      _close(heartRateBpm, other.heartRateBpm) &&
      sleepDebtSeconds == other.sleepDebtSeconds &&
      zone == other.zone &&
      rngCursor == other.rngCursor;

  static bool _close(double a, double b) => (a - b).abs() < 1e-9;

  @override
  String toString() => jsonEncode(toJson());
}

/// A read-only view of what the state means, for the HUD and the combat model.
class SimStatus {
  const SimStatus({
    required this.blood,
    required this.hunger,
    required this.thirst,
    required this.sleep,
    required this.heartRate,
  });

  final BloodState blood;
  final HungerState hunger;
  final ThirstState thirst;
  final SleepState sleep;
  final HeartRatePenalty heartRate;

  /// Everything that currently adds to `MOA_total` (§5.1.1).
  double get totalExtraMoa =>
      blood.extraMoa + sleep.extraMoa + heartRate.extraMoa;

  /// Multiplier on how long an action takes (§2.3, §2.5.4).
  double get actionTimeMultiplier =>
      hunger.actionTimeMultiplier * sleep.actionTimeMultiplier;

  bool get isIncapacitated =>
      blood.isFatal || hunger.losingConsciousness || thirst.lethal;
}

/// Interprets a state through the tables of §2.
SimStatus statusOf({
  required SimState state,
  required SimConstants constants,
}) => SimStatus(
  blood: bloodState(volumeMl: state.bloodMl, maxMl: constants.bloodMaxMl),
  hunger: hungerState(
    caloriesKcal: state.caloriesKcal,
    dailyKcal: constants.caloriesDailyKcal,
  ),
  thirst: thirstState(
    waterMl: state.waterMl,
    dailyMl: constants.waterDailyMl,
    bodyMassKg: constants.bodyMassKg,
  ),
  sleep: sleepState(state.sleepDebt),
  heartRate: heartRatePenalty(
    currentHr: state.heartRateBpm,
    maxHr: constants.maxHeartRate,
  ),
);

/// Result of advancing the simulation.
class TickOutcome {
  const TickOutcome({
    required this.state,
    required this.secondsApplied,
    required this.floored,
    this.caloriesBurned = 0,
    this.waterLostMl = 0,
    this.bloodLostMl = 0,
    this.met = 1.0,
  });

  final SimState state;

  /// How many simulated seconds were actually applied.
  final int secondsApplied;

  /// True when the offline floor of §2.1.1 caught a resource. Surfaced in the
  /// return-after-a-break summary so the player understands why nothing hit
  /// zero.
  final bool floored;

  final double caloriesBurned;
  final double waterLostMl;
  final double bloodLostMl;

  /// Effective MET applied over the step, for the diagnostic overlay.
  final double met;
}

/// Sleep requirement per day (§2.5.3). Anything short of this accrues debt.
const Duration kDailySleepNeed = Duration(hours: 8);

/// §2.5.1: how long under a roof with nothing on before the character sleeps.
///
/// §2.5.1 makes sleep a state rather than an action, and names night as the
/// condition. This is the same idea by day: somebody who has been sitting in
/// their own shelter doing nothing at all for ten minutes is not "awake and
/// idle", they are asleep in a chair. Ten minutes because it has to be longer
/// than putting a kettle on and shorter than an afternoon.
///
/// ⚠️ A deliberate step past §2.5.3, which counts only hours of *night* in a
/// shelter. A daytime nap pays the debt down here. It cannot be farmed — the
/// debt stops at zero — and the cost is the same one every shelter hour has:
/// the player is standing in one place instead of out finding anything.
const Duration kSettleToSleep = Duration(minutes: 10);

/// How far below the daily reserve water may fall before the model stops.
///
/// The floor is the 10% of body mass §2.3 calls critical, expressed relative
/// to the reserve. Past this the character is dying of thirst and the outcome
/// no longer depends on the exact figure.
double _lethalWaterDeficitMl(SimConstants constants) =>
    math.max(0, 0.10 * constants.bodyMassKg * 1000 - constants.waterDailyMl);

/// Advances [state] by [elapsed], in whole seconds.
///
/// Pure and total: same inputs, same output, no I/O. `elapsed` must already
/// have been vetted by `GameClock` — this function trusts it and will happily
/// apply whatever it is handed.
TickOutcome advance({
  required SimState state,
  required SimConstants constants,
  required Duration elapsed,
  TickInput input = TickInput.resting,
  @Deprecated('pass TickInput(offline: true) instead') bool offline = false,
}) {
  final seconds = elapsed.inSeconds;
  if (seconds <= 0) {
    return TickOutcome(state: state, secondsApplied: 0, floored: false);
  }

  final isOffline = input.offline || offline;
  final step = Duration(seconds: seconds);
  final hours = seconds / 3600.0;

  // ---- energy (§2.2) -----------------------------------------------------
  //
  // Two contributions, and keeping them apart matters: the basal requirement
  // is what the zone factor of §2.1 scales, while movement is paid at full
  // price wherever it happens.
  final rawMet = metForSpeed(input.speedKmh);
  final met = effectiveMet(
    met: rawMet,
    loadKg: input.loadKg,
    bodyMassKg: constants.bodyMassKg,
  );

  final basalKcal =
      constants.caloriesDailyKcal / 24.0 * hours * state.zone.calorieFactor;
  final movementKcal = rawMet <= 1.0
      ? 0.0
      : kcalOver(met: met, bodyMassKg: constants.bodyMassKg, elapsed: step) -
            kcalOver(met: 1.0, bodyMassKg: constants.bodyMassKg, elapsed: step);

  final calorieBurn = basalKcal + math.max(0, movementKcal);

  // ---- water (§2.3) ------------------------------------------------------
  // The baseline requirement of §1.3 covers being alive; sweat is added on top
  // (§2.3: "Woda_całkowita = Woda_bazowa + straty_z_potem"). The sweat formula
  // is split because its halves apply at different times — heat and clothing
  // cost water at any activity level, while the 400 ml/h constant is a rate
  // for a body that is actually working and would be absurd applied to someone
  // asleep in a shelter.
  final basalWater =
      constants.waterDailyMl / 24.0 * hours * state.zone.waterFactor;

  final environmentalWater =
      environmentalSweatMlPerHour(
        ambientTempC: input.ambientTempC,
        clothingClo: input.clothingClo,
      ) *
      hours;

  final activityWater = rawMet <= 1.0
      ? 0.0
      : sweatMlPerHour(
                  met: met,
                  ambientTempC: input.ambientTempC,
                  clothingClo: input.clothingClo,
                ) *
                hours -
            environmentalWater;

  final waterLoss =
      basalWater + environmentalWater + math.max(0, activityWater);

  // ---- heart rate (§2.4) -------------------------------------------------
  // Asleep the heart goes below waking resting, so that is the target it
  // relaxes towards. Awake, §2.4's formula stands.
  final heartRate = relaxHeartRate(
    current: state.heartRateBpm,
    target: input.sleeping && met <= kMetResting
        ? sleepingHeartRate(constants.restingHeartRate)
        : targetHeartRate(
            met: met,
            restingHr: constants.restingHeartRate,
            maxHr: constants.maxHeartRate,
          ),
    elapsed: step,
  );

  // ---- bleeding (§2.6) ---------------------------------------------------
  //
  // Uses the heart rate at the start of the step. Taking the average would be
  // marginally more accurate and would break linearity, which the catch-up
  // depends on far more than it depends on that margin.
  final bloodLoss = bleedOver(
    tier: input.bleedTier,
    currentHr: state.heartRateBpm,
    restingHr: constants.restingHeartRate,
    elapsed: step,
  );

  // ---- sleep (§2.5) ------------------------------------------------------
  //
  // Sleeping pays the debt down at the rate it was accrued; being awake builds
  // it at the daily requirement spread over the day.
  final debtChange = input.sleeping
      ? -seconds
      : (kDailySleepNeed.inSeconds * seconds / Duration.secondsPerDay).round();
  final sleepDebt = math.max(0, state.sleepDebtSeconds + debtChange);

  // ---- absorption (§2.2, §2.3) -------------------------------------------
  //
  // What was eaten arrives over the following minutes rather than at the
  // moment of swallowing. Half a litre of water is through the stomach in
  // about twenty minutes and a tin of beans takes over an hour, which is why
  // eating is something a player does before they need it.
  //
  // Linear, and capped by what is left waiting, so the whole thing composes
  // for catch-up exactly as the losses do.
  final minutes = seconds / Duration.secondsPerMinute;
  final kcalAbsorbed = math.min(
    state.pendingKcal,
    kCalorieAbsorptionKcalPerMin * minutes,
  );
  final waterAbsorbed = math.min(
    state.pendingWaterMl,
    kWaterAbsorptionMlPerMin * minutes,
  );

  // ⚠️ Neither reserve holds more than a day's worth, and the surplus is
  // simply lost. A stomach is not a warehouse: eating four tins on a full
  // stomach banks nothing, and without this the bar sits at a hundred per cent
  // for hours afterwards while the surplus quietly drains — which reads, from
  // the player's side, as calories that have stopped working.
  var calories = math.min(
    constants.caloriesDailyKcal,
    state.caloriesKcal - calorieBurn + kcalAbsorbed,
  );
  var water = math.min(
    constants.waterDailyMl,
    state.waterMl - waterLoss + waterAbsorbed,
  );
  // §2.6: blood comes back, slowly, and only out of what is eaten and drunk.
  //
  // Not in the document as a number, and it has to be one: without it a
  // character who survives a bad fight is in class IV shock for the rest of
  // their life, with every bandage in the world refusing to help because
  // nothing is bleeding any more. Plasma volume is restored in a day or two
  // when fed and watered, which is what this is — the red cells §2.6 does not
  // model would take weeks.
  //
  // Nothing at all while something is open: the body cannot refill a bucket
  // with a hole in it, and that is what makes stopping a bleed the first job
  // rather than an optional one.
  //
  // ⚠️ The *rate* depends on the state at the start of the step, so this term
  // is not linear in elapsed time the way consumption is — a single forty-hour
  // step credits more than forty one-hour steps, because the one-hour steps
  // watch the stomach empty. The same shape as absorption, and bounded the
  // same way: [advanceInChunks] is what every gap over an hour goes through,
  // so the drift is at most one hour of regeneration.
  final regenerated = input.bleedTier == BleedTier.none && bloodLoss <= 0
      ? kBloodRegenMlPerHour *
            (seconds / Duration.secondsPerHour) *
            nourishment(state, constants)
      : 0.0;

  var blood = math.min(
    constants.bloodMaxMl,
    state.bloodMl - bloodLoss + regenerated,
  );

  var floored = false;
  if (isOffline) {
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
    blood = math.max(0, blood);

    // Water is allowed past zero, and that is deliberate.
    //
    // §2.3 mixes two scales: the reserve is the *daily* requirement
    // (35 ml/kg), while the severity thresholds are fractions of *body mass*
    // (2%, 5%, 10%). For an 80 kg character the reserve is 2800 ml but severe
    // weakness needs a 4000 ml deficit — so clamping at zero would make two of
    // the three published thresholds unreachable. Letting the value go
    // negative lets the deficit accumulate across days, which is what a
    // multi-day dehydration actually is.
    water = math.max(-_lethalWaterDeficitMl(constants), water);
  }

  return TickOutcome(
    state: state.copyWith(
      lastUpdate: state.lastUpdate.add(step),
      caloriesKcal: calories,
      waterMl: water,
      bloodMl: blood,
      heartRateBpm: heartRate,
      sleepDebtSeconds: sleepDebt,
      pendingKcal: state.pendingKcal - kcalAbsorbed,
      pendingWaterMl: state.pendingWaterMl - waterAbsorbed,
    ),
    secondsApplied: seconds,
    floored: floored,
    caloriesBurned: state.caloriesKcal - calories,
    waterLostMl: state.waterMl - water,
    bloodLostMl: state.bloodMl - blood,
    met: met,
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
  TickInput input = TickInput.resting,
  @Deprecated('pass TickInput(offline: true) instead') bool offline = false,
}) {
  var current = state;
  var remaining = elapsed;
  var applied = 0;
  var floored = false;
  var calories = 0.0;
  var water = 0.0;
  var blood = 0.0;

  final effectiveInput = offline && !input.offline
      ? TickInput(
          speedKmh: input.speedKmh,
          loadKg: input.loadKg,
          ambientTempC: input.ambientTempC,
          clothingClo: input.clothingClo,
          bleedTier: input.bleedTier,
          sleeping: input.sleeping,
          offline: true,
        )
      : input;

  while (remaining > Duration.zero) {
    final step = remaining < chunk ? remaining : chunk;
    final outcome = advance(
      state: current,
      constants: constants,
      elapsed: step,
      input: effectiveInput,
    );
    current = outcome.state;
    applied += outcome.secondsApplied;
    floored = floored || outcome.floored;
    calories += outcome.caloriesBurned;
    water += outcome.waterLostMl;
    blood += outcome.bloodLostMl;
    remaining -= step;
  }

  return TickOutcome(
    state: current,
    secondsApplied: applied,
    floored: floored,
    caloriesBurned: calories,
    waterLostMl: water,
    bloodLostMl: blood,
  );
}

/// §2.2, §2.3: how much of that regeneration the body can actually pay for.
///
/// Blood is made out of what is eaten and drunk. An empty character does not
/// rebuild anything, and a half-fed one rebuilds at half speed — which is the
/// whole reason a fight is followed by a meal rather than by a nap.
double nourishment(SimState state, SimConstants constants) {
  final fed = constants.caloriesDailyKcal <= 0
      ? 0.0
      : (state.caloriesKcal / constants.caloriesDailyKcal).clamp(0.0, 1.0);
  final watered = constants.waterDailyMl <= 0
      ? 0.0
      : (state.waterMl / constants.waterDailyMl).clamp(0.0, 1.0);

  // The worse of the two, not the average: being well fed does not make up
  // for having nothing to drink.
  return fed < watered ? fed : watered;
}
