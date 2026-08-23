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

/// §2.5, §2.6: what a night under a roof is worth on top of that.
///
/// A body rebuilds plasma fastest lying still, warm and doing nothing — which
/// is precisely the state §2.5.1 already models as sleep, and precisely the
/// state a player gives up a night of walking to reach.
///
/// Two and a half times, so a hundred and fifty millilitres an hour. Eight
/// hours is 1,2 litres, and the figure that matters is §9.2's: somebody who
/// wakes from unconsciousness is 35% down, in class III shock, and one full
/// night here puts them back on their feet. That is the whole intent — a bad
/// night rather than a dead end — and it is still not enough to make a
/// bandage optional.
///
/// ⚠️ Multiplied by nourishment like the base rate. Blood is made out of what
/// was eaten and drunk (§2.2, §2.3): sleeping through a famine rebuilds
/// nothing, which makes "why is my blood not coming back" a question the other
/// two bars answer rather than a mystery.
const double kSleepBloodRegenFactor = 2.5;

/// §7: how much faster a skilled medic's body puts blood back.
///
/// §7 gives Medicine "+30% skuteczności opatrunków". A dressing either stops a
/// bleed or does not, so the honest reading of *effectiveness* is what the
/// body does once it is closed — §2.6's regeneration, which is the whole of
/// getting better in this game.
const double kMedicineHealing = 0.30;

/// Constants a tick needs that do not change during a session. Derived once
/// from the character sheet (§1.3) by `BodyProfile.toSimConstants`.
class SimConstants {
  const SimConstants({
    required this.bloodMaxMl,
    required this.waterDailyMl,
    required this.caloriesDailyKcal,
    required this.restingHeartRate,
    required this.maxHeartRate,
    required this.startingMassKg,
  });

  final double bloodMaxMl;
  final double waterDailyMl;
  final double caloriesDailyKcal;
  final double restingHeartRate;
  final double maxHeartRate;

  // ⚠️ **Body mass is not here, and used to be.**
  //
  // It sat in this class with a default of eighty and `toSimConstants` never
  // filled it in, so §2.3's thresholds — two, five and ten per cent of *body
  // mass* — measured every character in the game against an eighty-kilogram
  // person. Filling it in was the obvious fix and the wrong one: mass is not a
  // constant. §2.3's calorie deficit has to come out of the body somewhere,
  // and a figure that changes belongs with the ones that change.
  //
  // So it lives on [SimState] now, and there is exactly one of it. Everything
  // that needs it — the load surcharge of §2.2, the burn rate, the thirst
  // thresholds, §1.3's derived figures — reads that one.

  /// §2.3: what the character weighed when they were made.
  ///
  /// ⚠️ **This one really is constant, and it is a different question.** The
  /// live mass answers "how heavy am I"; this answers "how much of me is
  /// gone", which is the only way to read a wasting body — a fifty-five
  /// kilogram character at fifty is in trouble and a ninety-five kilogram one
  /// at fifty is dead.
  ///
  /// Survives a rebuild: [BodyProfile.at] carries it through, so a profile
  /// re-derived at a lighter weight still remembers where it started.
  final double startingMassKg;

  /// Floor enforced while the app is closed: offline consumption never drives
  /// a resource below 10% and never kills (§2.1.1).
  static const offlineFloor = 0.10;

  Map<String, Object?> toJson() => {
    'bloodMaxMl': bloodMaxMl,
    'waterDailyMl': waterDailyMl,
    'caloriesDailyKcal': caloriesDailyKcal,
    'restingHeartRate': restingHeartRate,
    'maxHeartRate': maxHeartRate,
    'startingMassKg': startingMassKg,
  };

  factory SimConstants.fromJson(Map<String, Object?> json) => SimConstants(
    bloodMaxMl: (json['bloodMaxMl'] as num).toDouble(),
    waterDailyMl: (json['waterDailyMl'] as num).toDouble(),
    caloriesDailyKcal: (json['caloriesDailyKcal'] as num).toDouble(),
    restingHeartRate: (json['restingHeartRate'] as num).toDouble(),
    maxHeartRate: (json['maxHeartRate'] as num).toDouble(),
    startingMassKg: (json['startingMassKg'] as num?)?.toDouble() ?? 0,
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
    this.medicine = 0,
    this.sleepRate = 1,
    this.nutritionRate = 1,
  });

  /// §7: how well this character looks after a wound, 0–1.
  ///
  /// ⚠️ **The one place a skill reaches the tick, and it comes in from
  /// outside.** Everything else in `advance()` is physiology; skills are not,
  /// and `lib/sim` must not learn what a skill is. So it arrives as a number
  /// on the input, exactly as the bleed tier and the ground speed do — the
  /// tick sees a rate, not a character sheet.
  ///
  /// §7 gives Medicine "+30% skuteczności opatrunków". A dressing that stops a
  /// bleed either stops it or does not, so the honest reading of *effectiveness*
  /// is what the body does afterwards: §2.6's regeneration, which is the whole
  /// of getting better in this game.
  final double medicine;

  /// §8.4, §8.5.1, §2.5.3: what an hour of sleep here is worth.
  ///
  /// ⚠️ **Neither this nor [nutritionRate] reached anything until now.**
  /// `Shelter.sleepRate` and `Shelter.nutritionRate` were computed, one of
  /// them was drawn on the shelter screen as a percentage, and no clock ever
  /// read either — so the Lounge and the Laboratory did nothing at all, and
  /// neither did §8.5.1's rule that a camp is worth seven tenths of a night.
  /// Three rules, three decorations.
  ///
  /// One rather than a level, for the same reason [medicine] is a number:
  /// `lib/sim` must not learn what a shelter module is.
  final double sleepRate;

  /// §8.4: how much of what is eaten and drunk actually arrives.
  final double nutritionRate;

  /// What an hour of sleep here is worth, never negative and never absurd.
  ///
  /// Clamped rather than trusted: a rate arriving from a module table is a
  /// number somebody could get wrong, and a negative one would make sleeping
  /// *add* debt — a bug that reads exactly like the game being broken.
  double get nightWorth => sleepRate.clamp(0.0, 3.0);

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

  /// The same inputs, asleep.
  ///
  /// §2.5.1's ten minutes can fall inside a span that is replayed in one go,
  /// and the half after them has to be applied with this rather than with the
  /// input the span started under.
  TickInput get asleep => TickInput(
    speedKmh: speedKmh,
    loadKg: loadKg,
    ambientTempC: ambientTempC,
    clothingClo: clothingClo,
    bleedTier: bleedTier,
    sleeping: true,
    offline: offline,
  );
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
    required this.bodyMassKg,
    required this.sleepDebtSeconds,
    this.sleepStrain = 0,
    required this.zone,
    required this.rngCursor,
    this.pendingKcal = 0,
    this.pendingWaterMl = 0,
    this.dryStreakSeconds = 0,
    this.starvedStreakSeconds = 0,
  });

  /// The instant the simulation has been advanced to. Everything is derived
  /// from this, which is the whole idempotency story.
  final DateTime lastUpdate;

  final double bloodMl;
  final double waterMl;
  final double caloriesKcal;
  final double heartRateBpm;

  /// §2.3, §1.3: what the character weighs **now**.
  ///
  /// ⚠️ **A body is where a calorie deficit is paid from.** §2.3 gives hunger
  /// one tier past an empty reserve — a day at nought and the lights go out —
  /// and nothing whatever for the week before or the month after, so a
  /// starving character was in exactly the same state on day three as on day
  /// thirty. That is the wrong shape for the one axis in §2 that a person
  /// really does survive for weeks on.
  ///
  /// The long axis is this number. A deficit takes mass off it at
  /// [kKcalPerKgOfBody], a surplus puts it back, and everything §1.3 derives
  /// from mass follows: the carry limits of §18.1a, the burn rate of §2.2,
  /// the daily water of §1.3, and §2.3's own thresholds, which are fractions
  /// of it.
  ///
  /// Which also means there is only one of it. It used to be a field on
  /// [SimConstants] as well, unfilled — see the note there.
  final double bodyMassKg;

  final int sleepDebtSeconds;

  /// §2.5.5: accumulated shortfall in whole nights — see [SleepStrainState].
  ///
  /// ⚠️ A second clock rather than a bigger first one. [sleepDebtSeconds] is
  /// about last night, is capped at a day and clears in a day; this is about
  /// the last month and takes a month to clear. One short night reads the same
  /// on the debt whether it is the first in a fortnight or the fourteenth in a
  /// row, and that is the right answer to the question the debt asks.
  final double sleepStrain;

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

  /// §2.3: how long since any water at all reached the body.
  ///
  /// ⚠️ **The clock §2.3's lethal rule needs, and it did not exist.**
  /// `thirstState` has taken a `timeWithoutWater` since it was written and
  /// every call site left it at the default of zero, so `lethal` was always
  /// false and `DeathCause.thirst` was an enumerator nothing could reach. The
  /// game let a character go for ever without drinking.
  ///
  /// Reset by a swallow rather than by a full reserve, which is what "brak
  /// wody" says and is also the honest physiology: a mouthful resets the
  /// clock on dying of thirst and does nothing at all to the deficit, so the
  /// two thresholds go on climbing while the countdown restarts.
  final int dryStreakSeconds;

  /// §2.3: how long the calorie reserve has been at nought.
  ///
  /// The same defect as [dryStreakSeconds], one paragraph up: "0% przez > 24 h
  /// → postępująca utrata przytomności" was a rule whose clock nobody wound.
  ///
  /// ⚠️ Measured on the *reserve*, not on the last meal — that is what §2.3
  /// says here, and it is the difference between the two halves of §2.3. A
  /// person with an empty stomach is not a person with nothing left.
  final int starvedStreakSeconds;

  Duration get sleepDebt => Duration(seconds: sleepDebtSeconds);

  /// §2.3: how long since the last swallow of water.
  Duration get dryFor => Duration(seconds: dryStreakSeconds);

  /// §2.3: how long the reserve has been empty.
  Duration get starvedFor => Duration(seconds: starvedStreakSeconds);

  SimState copyWith({
    DateTime? lastUpdate,
    double? bloodMl,
    double? waterMl,
    double? caloriesKcal,
    double? heartRateBpm,
    double? bodyMassKg,
    int? sleepDebtSeconds,
    double? sleepStrain,
    MetabolicZone? zone,
    int? rngCursor,
    double? pendingKcal,
    double? pendingWaterMl,
    int? dryStreakSeconds,
    int? starvedStreakSeconds,
  }) => SimState(
    lastUpdate: lastUpdate ?? this.lastUpdate,
    bloodMl: bloodMl ?? this.bloodMl,
    waterMl: waterMl ?? this.waterMl,
    caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    bodyMassKg: bodyMassKg ?? this.bodyMassKg,
    sleepDebtSeconds: sleepDebtSeconds ?? this.sleepDebtSeconds,
    sleepStrain: sleepStrain ?? this.sleepStrain,
    zone: zone ?? this.zone,
    rngCursor: rngCursor ?? this.rngCursor,
    pendingKcal: pendingKcal ?? this.pendingKcal,
    pendingWaterMl: pendingWaterMl ?? this.pendingWaterMl,
    dryStreakSeconds: dryStreakSeconds ?? this.dryStreakSeconds,
    starvedStreakSeconds: starvedStreakSeconds ?? this.starvedStreakSeconds,
  );

  Map<String, Object?> toJson() => {
    'lastUpdate': lastUpdate.toUtc().toIso8601String(),
    'bloodMl': bloodMl,
    'waterMl': waterMl,
    'caloriesKcal': caloriesKcal,
    'heartRateBpm': heartRateBpm,
    'bodyMassKg': bodyMassKg,
    'sleepDebtSeconds': sleepDebtSeconds,
    'sleepStrain': sleepStrain,
    'zone': zone.wire,
    'rngCursor': rngCursor,
    'pendingKcal': pendingKcal,
    'pendingWaterMl': pendingWaterMl,
    'dryStreakSeconds': dryStreakSeconds,
    'starvedStreakSeconds': starvedStreakSeconds,
  };

  factory SimState.fromJson(Map<String, Object?> json) => SimState(
    lastUpdate: DateTime.parse(json['lastUpdate']! as String).toUtc(),
    bloodMl: (json['bloodMl'] as num).toDouble(),
    waterMl: (json['waterMl'] as num).toDouble(),
    caloriesKcal: (json['caloriesKcal'] as num).toDouble(),
    heartRateBpm: (json['heartRateBpm'] as num).toDouble(),
    // ⚠️ Nought is not a body. A row written before mass moved has none, and
    // the caller is the only one that knows what the character weighed at
    // creation — so it is read back as nought and filled in there rather than
    // guessed at here (§11.1.4).
    bodyMassKg: (json['bodyMassKg'] as num?)?.toDouble() ?? 0,
    sleepDebtSeconds: (json['sleepDebtSeconds'] as num).toInt(),
    sleepStrain: (json['sleepStrain'] as num?)?.toDouble() ?? 0,
    zone: MetabolicZone.fromWire(json['zone']! as String),
    rngCursor: (json['rngCursor'] as num?)?.toInt() ?? 0,
    pendingKcal: (json['pendingKcal'] as num?)?.toDouble() ?? 0,
    pendingWaterMl: (json['pendingWaterMl'] as num?)?.toDouble() ?? 0,
    dryStreakSeconds: (json['dryStreakSeconds'] as num?)?.toInt() ?? 0,
    starvedStreakSeconds: (json['starvedStreakSeconds'] as num?)?.toInt() ?? 0,
  );

  /// Starting state for a freshly created character.
  factory SimState.fresh({
    required DateTime at,
    required SimConstants constants,
    required double massKg,
  }) => SimState(
    lastUpdate: at.toUtc(),
    bloodMl: constants.bloodMaxMl,
    waterMl: constants.waterDailyMl,
    caloriesKcal: constants.caloriesDailyKcal,
    heartRateBpm: constants.restingHeartRate,
    bodyMassKg: massKg,
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
      _close(bodyMassKg, other.bodyMassKg) &&
      sleepDebtSeconds == other.sleepDebtSeconds &&
      _close(sleepStrain, other.sleepStrain) &&
      dryStreakSeconds == other.dryStreakSeconds &&
      starvedStreakSeconds == other.starvedStreakSeconds &&
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
    this.wasting = StarvationState.healthy,
    this.chronicSleep = SleepStrainState.rested,
  });

  final BloodState blood;
  final HungerState hunger;
  final ThirstState thirst;

  /// §2.3: the long axis of going without food — see [StarvationState].
  final StarvationState wasting;

  final SleepState sleep;

  /// §2.5.5: the weeks-long axis of not sleeping enough.
  final SleepStrainState chronicSleep;

  final HeartRatePenalty heartRate;

  /// Everything that currently adds to `MOA_total` (§5.1.1).
  double get totalExtraMoa =>
      blood.extraMoa +
      sleep.extraMoa +
      heartRate.extraMoa +
      wasting.extraMoa +
      chronicSleep.extraMoa;

  /// Multiplier on how long an action takes (§2.3, §2.5.4).
  double get actionTimeMultiplier =>
      hunger.actionTimeMultiplier *
      thirst.actionTimeMultiplier *
      wasting.actionTimeMultiplier *
      sleep.actionTimeMultiplier;

  /// The same figure the way a clock wants it: how much of a second of work a
  /// second of wall time is worth (§2.3, §2.5.4).
  ///
  /// ⚠️ **This is what [actionTimeMultiplier] was missing.** §2.3's "+20% to
  /// the time of every action" and §2.5.4's "+50%" were computed, written on
  /// the status notes, and read by nothing that measures anything — hunger and
  /// sleep debt lengthened precisely nothing. A multiplier on a duration has
  /// to meet a duration somewhere, and the only place every duration in this
  /// game passes through is the rate its clock credits at.
  double get workRate =>
      actionTimeMultiplier <= 0 ? 1 : 1 / actionTimeMultiplier;

  /// §2.3, §2.6: on the ground, one way or another.
  ///
  /// ⚠️ [HungerState.losingConsciousness] is here and deliberately not in
  /// [fatalCause]. §2.3 calls it "postępująca utrata przytomności" — which is
  /// what this is for — and reading it as a death made a famine lethal in
  /// forty-eight hours. See the note there.
  bool get isIncapacitated =>
      blood.isFatal ||
      hunger.losingConsciousness ||
      thirst.lethal ||
      wasting.fatal;
}

/// Interprets a state through the tables of §2.
///
/// ⚠️ [underExertion] is §2.3's own qualifier on the only lethal rule it gives
/// thirst — "brak wody > 48 h **w warunkach wysiłku**". Only the caller knows
/// whether anybody is walking, so it comes in from outside; the default is the
/// merciful one, because a status asked about with no context should not kill
/// anybody.
SimStatus statusOf({
  required SimState state,
  required SimConstants constants,
  bool underExertion = false,
}) => SimStatus(
  blood: bloodState(volumeMl: state.bloodMl, maxMl: constants.bloodMaxMl),
  hunger: hungerState(
    caloriesKcal: state.caloriesKcal,
    dailyKcal: constants.caloriesDailyKcal,
    timeAtZero: state.starvedFor,
  ),
  thirst: thirstState(
    waterMl: state.waterMl,
    dailyMl: constants.waterDailyMl,
    bodyMassKg: state.bodyMassKg,
    timeWithoutWater: state.dryFor,
    underExertion: underExertion,
  ),
  wasting: starvationState(
    massKg: state.bodyMassKg,
    startingMassKg: constants.startingMassKg,
  ),
  sleep: sleepState(state.sleepDebt),
  chronicSleep: sleepStrainState(state.sleepStrain),
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

/// §2.5.4: the deepest the hole gets.
///
/// The last tier of §2.5.4 is "twenty-four hours or more", and there is
/// nothing past it — microsleeps are the worst it does. So a debt beyond a day
/// costs nothing extra and only lengthens the climb out, which is a punishment
/// the document never asked for and one the interface cannot draw.
const Duration kMaxSleepDebt = Duration(hours: 24);

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
double _lethalWaterDeficitMl(SimState state, SimConstants constants) =>
    math.max(0, 0.10 * state.bodyMassKg * 1000 - constants.waterDailyMl);

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
    bodyMassKg: state.bodyMassKg,
  );

  final basalKcal =
      constants.caloriesDailyKcal / 24.0 * hours * state.zone.calorieFactor;
  final movementKcal = rawMet <= 1.0
      ? 0.0
      : kcalOver(met: met, bodyMassKg: state.bodyMassKg, elapsed: step) -
            kcalOver(met: 1.0, bodyMassKg: state.bodyMassKg, elapsed: step);

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
  // §2.5.5: weeks of short nights, read once and applied where they belong.
  final chronic = sleepStrainState(state.sleepStrain);

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
    tauMultiplier: chronic.heartRecoveryMultiplier,
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
  // §8.4, §8.5.1: an hour under a good roof covers more than an hour under a
  // tarpaulin. The Lounge gives fifteen per cent a level back; a camp takes
  // three tenths away.
  final debtChange = input.sleeping
      ? -(seconds * input.nightWorth).round()
      : (kDailySleepNeed.inSeconds * seconds / Duration.secondsPerDay).round();
  // ⚠️ Capped, and §2.5 gives no cap.
  //
  // The debt grows eight hours a day awake and nothing stops it, so a
  // character three days into a run owes a day of sleep and a week in owes
  // two. §2.5.4's own tiers stop at twenty-four hours — past that there is no
  // further penalty — so everything beyond the cap is a hole to climb out of
  // that models nothing and cannot be shown: the bar is a fraction of one
  // night and reads empty either way.
  //
  // Found from a walk reported as "sleep does not regenerate in the shelter".
  // It was regenerating perfectly; the debt was tens of hours deep, and a
  // night of it moved nothing anybody could see.
  final sleepDebt = math
      .max(0, state.sleepDebtSeconds + debtChange)
      .clamp(0, kMaxSleepDebt.inSeconds);

  // §2.5.5: the other clock, the one that counts weeks.
  //
  // ⚠️ **Different arithmetic from the debt above, on purpose.**
  //
  // The debt only accrues while the character is *awake*, so a night of eight
  // hours over-pays it — sixteen waking hours are worth five and a third, and
  // the night pays eight. The upshot is that six-hour nights break even and
  // the debt never moves, which is why three weeks of them read exactly like
  // one late evening. That is the defect this whole tier exists to answer.
  //
  // Here the requirement accrues against the *wall clock*, which is what
  // §2.5.3's own formula says: a day needs eight hours whatever you did with
  // it. Over twenty-four hours with S hours slept the strain moves by
  // `1 − S/8` — a quarter of a night for six hours, a whole one for none, and
  // downwards only for a night longer than the requirement.
  final strainChange =
      seconds / Duration.secondsPerDay -
      (input.sleeping
          ? seconds * input.nightWorth / kDailySleepNeed.inSeconds
          : 0);

  // ⚠️ Floored one night *below* nought rather than at it. A day is lived as
  // a night and then a day, so the night's payoff arrives before the waking
  // hours it cancels — and a hard floor at nought would throw that payoff away
  // every morning, leaving somebody who sleeps their full eight hours gaining
  // a third of a night of strain a day for ever. See [kSleepStrainFloor];
  // nothing below nought is ever readable as credit.
  final sleepStrain = (state.sleepStrain + strainChange).clamp(
    kSleepStrainFloor,
    kMaxSleepStrain,
  );

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
  // ⚠️ The Laboratory (§8.4) multiplies what *arrives*, not what is taken out
  // of the stomach. "Three per cent more out of every meal" is about the meal,
  // so the pending pool drains at its own rate and credits a little more than
  // it loses — which is also the only reading that works for something eaten
  // before the module was finished.
  final kcalTaken = math.min(
    state.pendingKcal,
    kCalorieAbsorptionKcalPerMin * minutes,
  );
  final waterTaken = math.min(
    state.pendingWaterMl,
    kWaterAbsorptionMlPerMin * minutes,
  );

  final kcalAbsorbed = kcalTaken * input.nutritionRate;
  final waterAbsorbed = waterTaken * input.nutritionRate;

  // ⚠️ Neither reserve holds more than a day's worth, and the surplus is
  // simply lost. A stomach is not a warehouse: eating four tins on a full
  // stomach banks nothing, and without this the bar sits at a hundred per cent
  // for hours afterwards while the surplus quietly drains — which reads, from
  // the player's side, as calories that have stopped working.
  // ---- the body itself (§2.3) --------------------------------------------
  //
  // ⚠️ **What overflows and what is short both used to vanish.**
  //
  // The reserve is a day's worth and no more, so eating four tins on a full
  // stomach banked nothing — there was never a reason to eat before a journey.
  // At the other end the reserve floors at nought, so the calories a starving
  // character went on burning were charged to nobody. §2.3 then had exactly
  // one thing left to say about hunger — a day at nought and the lights go out
  // — which puts a healthy adult in the ground in forty-eight hours and makes
  // day three of a famine identical to day thirty.
  //
  // Both ends are the same account, and it is the body. A deficit is paid from
  // it at [kKcalPerKgOfBody]; a surplus is put back at
  // [kSurplusStorageEfficiency], which is lossy because storing is — a week of
  // overeating does not undo a week of starving.
  final rawCalories = state.caloriesKcal - calorieBurn + kcalAbsorbed;

  final overflow = math.max(0.0, rawCalories - constants.caloriesDailyKcal);
  final shortfall = math.max(0.0, -rawCalories);

  // ⚠️ §2.1.1: nothing is taken off the body while the app is closed.
  //
  // The offline floor exists so that a phone in a drawer cannot kill anybody,
  // and a fortnight of unwatched wasting would walk straight through it — the
  // reserve would be held at ten per cent by the floor below while the mass it
  // is measured against quietly fell off. A surplus still counts: what was
  // actually eaten was actually eaten.
  final massKg = math.max(
    0.0,
    state.bodyMassKg +
        (overflow * kSurplusStorageEfficiency - (isOffline ? 0 : shortfall)) /
            kKcalPerKgOfBody,
  );

  var calories = math.min(constants.caloriesDailyKcal, rawCalories);
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
            (input.sleeping ? kSleepBloodRegenFactor : 1.0) *
            (seconds / Duration.secondsPerHour) *
            nourishment(state, constants) *
            // §2.5.5: a body that has not slept properly in weeks mends
            // slowly. The one penalty here a player is most likely to feel
            // and least likely to guess at, which is why it has a note of its
            // own on the status screen (§12).
            chronic.healingMultiplier *
            // §7: +30% at full mastery, and it stacks with §2.6's own
            // ×2.5 for being asleep — so a skilled medic who sleeps mends at
            // over three times the waking rate of a novice.
            (1 + kMedicineHealing * input.medicine.clamp(0.0, 1.0))
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
    water = math.max(-_lethalWaterDeficitMl(state, constants), water);
  }

  // ---- the two clocks §2.3's lethal rules need (§2.3) --------------------
  //
  // ⚠️ Both rules were written and neither could ever fire. `hungerState` and
  // `thirstState` have taken `timeAtZero` and `timeWithoutWater` since they
  // were written, `statusOf` passed neither, and `SimState` had nowhere to
  // keep them — so `losingConsciousness` and `lethal` were permanently false
  // and two of the three `DeathCause` values were unreachable. A character
  // could go without food or water for ever.
  //
  // Reset by a *swallow* for water and by the *reserve* for food, which is
  // exactly how §2.3 words its two halves: "brak wody > 48 h" is about
  // drinking, "0% przez > 24 h" is about what is left. A mouthful therefore
  // restarts the countdown to dying of thirst and does nothing whatever to the
  // deficit, which goes on climbing towards the thresholds underneath.
  final dryStreak = waterAbsorbed > 0 ? 0 : state.dryStreakSeconds + seconds;
  final starvedStreak = calories > 0 ? 0 : state.starvedStreakSeconds + seconds;

  return TickOutcome(
    state: state.copyWith(
      lastUpdate: state.lastUpdate.add(step),
      caloriesKcal: calories,
      waterMl: water,
      bloodMl: blood,
      heartRateBpm: heartRate,
      bodyMassKg: massKg,
      sleepDebtSeconds: sleepDebt,
      sleepStrain: sleepStrain,
      dryStreakSeconds: dryStreak,
      starvedStreakSeconds: starvedStreak,
      pendingKcal: state.pendingKcal - kcalTaken,
      pendingWaterMl: state.pendingWaterMl - waterTaken,
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
