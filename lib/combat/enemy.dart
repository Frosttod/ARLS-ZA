/// What comes towards the player, and what stops it (§6.1, §6.1a, §6.2).
///
/// **The sprint budget is the whole design.** A player's speed is their real
/// speed, so anything faster than about nine kilometres an hour would be
/// impossible to escape and running away — the first tactic in any survival
/// game — would stop existing. §6.1 keeps the terrifying speeds and gives them
/// a stopwatch instead: a Leaper runs at thirty for twenty-five seconds, and a
/// human being outlasts it. That is also true of sprinters, who hold their top
/// speed for twenty or thirty seconds and no longer.
///
/// The one exception is deliberate: a Leaper covers about two hundred metres
/// on a full budget and notices the player at a hundred and twenty, so it
/// always reaches them. There is no outrunning a Leaper, only killing it in
/// the air or surviving the clinch (§6.1). Walkers and Brutes can be escaped.
///
/// Nothing here stands still. §6.1a is explicit that a chasing enemy closes
/// the distance in every state including exhaustion, so shooting one is always
/// paid for in ground lost to the others.
library;

import 'dart:math' as math;

import '../map/geometry.dart';

/// §6.1a: what an enemy is doing.
enum EnemyState {
  /// Wandering its hotspot at walking pace.
  idle,

  /// Has noticed something and is walking towards it. No budget is spent —
  /// which is what makes a slow approach survivable.
  alert,

  /// Sprinting, and paying for it.
  chase,

  /// The budget is gone. Still coming, at 40% of a run, getting it back.
  spent,

  /// Contact lost or the leash reached: walking home, recovering fully.
  returning,
}

/// §6.2, §6.1. One kind of thing, and everything that makes it that kind.
enum EnemyKind {
  /// §6.1: nothing outruns it. Single, fast, fragile.
  leaper(
    walkKmh: (5, 7),
    runKmh: (27, 32),
    sprintBudget: Duration(seconds: 25),
    sprintRecovery: Duration(seconds: 60),
    bloodMl: (2400, 2800),
    attackMultiplier: 0.9,
    baseDamageMl: 120,
    attackInterval: Duration(milliseconds: 1200),
    detectionM: 120,
    deathAtLoss: 0.45,
    packSize: (1, 1),
  ),

  /// §6.2: two to four of them, which makes a group fight the default state
  /// of the game rather than a special case (§5.5).
  walker(
    walkKmh: (3, 4),
    runKmh: (15, 18),
    sprintBudget: Duration(seconds: 90),
    sprintRecovery: Duration(seconds: 45),
    bloodMl: (3200, 3600),
    attackMultiplier: 1.05,
    baseDamageMl: 180,
    attackInterval: Duration(seconds: 2),
    detectionM: 80,
    deathAtLoss: 0.45,
    packSize: (2, 4),
  ),

  /// §6.2: slow, enormous, and what the hunting rifle exists for (§5.1.5).
  brute(
    walkKmh: (2, 4),
    runKmh: (12, 17),
    sprintBudget: Duration(seconds: 45),
    sprintRecovery: Duration(seconds: 120),
    bloodMl: (6000, 8000),
    attackMultiplier: 1.2,
    baseDamageMl: 400,
    attackInterval: Duration(seconds: 3),
    detectionM: 60,
    deathAtLoss: 0.50,
    packSize: (1, 1),
  );

  const EnemyKind({
    required this.walkKmh,
    required this.runKmh,
    required this.sprintBudget,
    required this.sprintRecovery,
    required this.bloodMl,
    required this.attackMultiplier,
    required this.baseDamageMl,
    required this.attackInterval,
    required this.detectionM,
    required this.deathAtLoss,
    required this.packSize,
  });

  final (double, double) walkKmh;
  final (double, double) runKmh;

  /// §6.1: how long it can hold its running speed.
  final Duration sprintBudget;

  /// §6.1: how long, walking, to get all of it back.
  final Duration sprintRecovery;

  final (double, double) bloodMl;

  /// §6.2: against the base damage row, which is the only thing that makes it
  /// a number rather than a decoration.
  final double attackMultiplier;
  final double baseDamageMl;
  final Duration attackInterval;

  /// §6.2: how far off it notices a player.
  final double detectionM;

  /// §6.2: the share of its blood it dies at, rather than all of it.
  final double deathAtLoss;

  final (int, int) packSize;

  /// §6.1a: a chase starts inside 60% of what it can see.
  double get chaseM => detectionM * 0.6;

  double get damageMl => baseDamageMl * attackMultiplier;
}

/// §6.1a: how far an enemy will follow before giving up.
const double kLeashM = 400;

/// §6.1a: how long without the player coming near before it goes home.
const Duration kContactLost = Duration(seconds: 45);

/// §6.1a: within this, contact is kept.
const double kContactM = 150;

/// §6.1a: exhaustion is not a stop. It is a slower approach.
const double kSpentSpeedFraction = 0.4;

/// One of them, at one moment.
class Enemy {
  const Enemy({
    required this.id,
    required this.kind,
    required this.position,
    required this.home,
    required this.bloodMl,
    required this.walkKmh,
    required this.runKmh,
    this.state = EnemyState.idle,
    this.bloodLostMl = 0,
    this.sprintLeft,
    this.sinceContact = Duration.zero,
  });

  /// Rolls the ranges of §6.2 once, at spawn. Two Walkers are not the same
  /// Walker: one is a little faster and one bleeds a little longer.
  factory Enemy.spawn({
    required String id,
    required EnemyKind kind,
    required GeoPoint at,
    required GeoPoint home,
    required math.Random random,
  }) {
    double between((double, double) range) =>
        range.$1 + random.nextDouble() * (range.$2 - range.$1);

    return Enemy(
      id: id,
      kind: kind,
      position: at,
      home: home,
      bloodMl: between(kind.bloodMl),
      walkKmh: between(kind.walkKmh),
      runKmh: between(kind.runKmh),
    );
  }

  final String id;
  final EnemyKind kind;
  final GeoPoint position;

  /// The centre of the hotspot it belongs to (§6.5), which the leash is
  /// measured from and which it walks back to.
  final GeoPoint home;

  final double bloodMl;
  final double bloodLostMl;

  final double walkKmh;
  final double runKmh;

  final EnemyState state;

  /// What is left of §6.1's stopwatch. Null means untouched.
  final Duration? sprintLeft;

  /// §6.1a: how long since the player was last within [kContactM].
  final Duration sinceContact;

  Duration get budget => sprintLeft ?? kind.sprintBudget;

  bool get isDead => bloodLostMl >= bloodMl * kind.deathAtLoss;

  /// How fast it is moving right now, in km/h.
  double get speedKmh => switch (state) {
    EnemyState.idle || EnemyState.alert || EnemyState.returning => walkKmh,
    EnemyState.chase => runKmh,
    EnemyState.spent => runKmh * kSpentSpeedFraction,
  };

  Enemy copyWith({
    GeoPoint? position,
    EnemyState? state,
    double? bloodLostMl,
    Duration? sprintLeft,
    Duration? sinceContact,
  }) => Enemy(
    id: id,
    kind: kind,
    position: position ?? this.position,
    home: home,
    bloodMl: bloodMl,
    walkKmh: walkKmh,
    runKmh: runKmh,
    state: state ?? this.state,
    bloodLostMl: bloodLostMl ?? this.bloodLostMl,
    sprintLeft: sprintLeft ?? this.sprintLeft,
    sinceContact: sinceContact ?? this.sinceContact,
  );

  /// The wound of §5.1.5, taken.
  Enemy hit(double bloodLoss) =>
      copyWith(bloodLostMl: bloodLostMl + bloodLoss);
}

/// One step of §6.1a, for one enemy.
///
/// [heardShot] is §6.1a's other way into a chase: a shot starts one whatever
/// the distance, which is what makes §5.6's noise the cost of shooting.
Enemy advanceEnemy(
  Enemy enemy, {
  required GeoPoint playerAt,
  required Duration elapsed,
  bool heardShot = false,
}) {
  if (enemy.isDead || elapsed <= Duration.zero) return enemy;

  final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  final distance = enemy.position.distanceTo(playerAt);

  // §6.1a: contact is the player being near, not the enemy trying.
  final near = distance <= kContactM;
  final sinceContact = near
      ? Duration.zero
      : enemy.sinceContact + elapsed;

  final beyondLeash = enemy.home.distanceTo(enemy.position) > kLeashM;
  final lostContact = sinceContact >= kContactLost;

  var state = _nextState(
    enemy,
    distance: distance,
    heardShot: heardShot,
    beyondLeash: beyondLeash,
    lostContact: lostContact,
  );

  // §6.1: the stopwatch. Spent only while sprinting, given back while walking.
  var budget = enemy.budget;
  if (state == EnemyState.chase) {
    budget -= elapsed;
    if (budget <= Duration.zero) {
      budget = Duration.zero;
      state = EnemyState.spent;
    }
  } else {
    final rate =
        enemy.kind.sprintBudget.inMilliseconds /
        enemy.kind.sprintRecovery.inMilliseconds;
    budget += Duration(milliseconds: (seconds * 1000 * rate).round());
    if (budget > enemy.kind.sprintBudget) budget = enemy.kind.sprintBudget;
  }

  final target = state == EnemyState.returning || state == EnemyState.idle
      ? enemy.home
      : playerAt;

  final moved = _towards(
    enemy.position,
    target,
    metres: enemy.speedKmh * seconds / 3.6,
  );

  return enemy.copyWith(
    position: state == EnemyState.idle ? enemy.position : moved,
    state: state,
    sprintLeft: budget,
    sinceContact: sinceContact,
  );
}

/// §6.1a's table, in the order its rows are written.
EnemyState _nextState(
  Enemy enemy, {
  required double distance,
  required bool heardShot,
  required bool beyondLeash,
  required bool lostContact,
}) {
  // Home first: the two rules that stop a player towing a train of enemies
  // across half a city.
  if (beyondLeash || lostContact) {
    return enemy.position.distanceTo(enemy.home) < 5
        ? EnemyState.idle
        : EnemyState.returning;
  }

  final noticed = heardShot || distance <= enemy.kind.detectionM;
  if (!noticed) {
    return enemy.state == EnemyState.returning
        ? EnemyState.returning
        : EnemyState.idle;
  }

  // Exhaustion lasts until the budget is worth something again. Flickering
  // between sprinting and not on every tick would read as a stutter.
  if (enemy.state == EnemyState.spent &&
      enemy.budget < enemy.kind.sprintBudget * 0.25) {
    return EnemyState.spent;
  }

  if (heardShot || distance <= enemy.kind.chaseM) {
    return enemy.budget > Duration.zero ? EnemyState.chase : EnemyState.spent;
  }

  return EnemyState.alert;
}

/// Straight at it (§6.3's MVP simplification: no routing, and walls do not
/// stop anything yet).
GeoPoint _towards(GeoPoint from, GeoPoint to, {required double metres}) {
  final distance = from.distanceTo(to);
  if (distance <= 0 || metres <= 0) return from;
  if (metres >= distance) return to;

  final fraction = metres / distance;
  return GeoPoint(
    from.latitude + (to.latitude - from.latitude) * fraction,
    from.longitude + (to.longitude - from.longitude) * fraction,
  );
}
