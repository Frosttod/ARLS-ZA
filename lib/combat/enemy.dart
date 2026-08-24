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
import '../safety/spawn_exclusion.dart';

/// §5.5.1: how badly hurt something looks, as far as anybody can tell.
///
/// An estimate on purpose. §5.5.1 makes the accuracy of it a Reconnaissance
/// skill, which is §7 and does not exist yet — so it is three words rather
/// than a number, and three words is all a person could honestly give at two
/// hundred metres.
enum EnemyCondition { healthy, wounded, critical }

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

/// §5.6.2: how long an enemy turns over the place a sound came from.
///
/// A minute read as a bug from the other end of the street: they arrive, and
/// then they circle one spot for so long that the sound stops looking like
/// something they are answering and starts looking like something they are
/// stuck on. Half of that is still long enough for the shot to have cost the
/// player the ground, which is the whole point of §5.6.3.
const Duration kInvestigateFor = Duration(seconds: 30);

/// §5.6.2: the longest anything will walk towards a sound before losing it.
///
/// ⚠️ **Without this, a distant shot made a permanent hunter.**
///
/// [kInvestigateFor] counts down only once the body has *arrived* at the
/// noise, which is right for searching a street corner and catastrophic for
/// getting there. A gunshot carries seven hundred metres (§5.6.1) and a Walker
/// covers about three kilometres an hour, so the walk alone is a quarter of an
/// hour — and anything whose leash (§6.1a) will not let it reach the sound
/// never arrives at all. It walks out, gets pulled home, goes idle, hears the
/// same remembered noise, and sets off again. For ever.
///
/// Reported from a walk as exactly that: shoot from a distance, and they are
/// still looking after closing and reopening the game.
///
/// Three minutes is the walk a sound is worth. Past it the trail is cold —
/// which is what §5.6.2 means by a noise being a place rather than a person.
const Duration kWalkToNoiseFor = Duration(minutes: 3);

/// §6.1a: how much longer a hurt one keeps looking.
///
/// Something that has been shot does not wander home on the same schedule as
/// something that heard a bang. It has the best evidence in the game that a
/// person is nearby — a hole in it — and giving up at forty-five seconds made
/// the second shot cheaper than the first.
const double kWoundedContactFactor = 2.5;

/// §6.1a: how far an idle one drifts from where it belongs before turning
/// back. Small — this is milling about, not patrolling.
const double kWanderRadiusM = 40;

/// How sharply a wandering thing may change its mind, in degrees a second.
///
/// Slowly. Something that jinks about the screen reads as a bug rather than as
/// a body, and a marker that changes direction every second is unreadable.
const double kWanderTurnPerSecond = 12;

/// §7: how much of an enemy's detection radius Scouting takes away.
///
/// ⚠️ §7's own figure, and the only one of the four skills whose effect the
/// player never sees a number for — you cannot watch a fight that did not
/// happen. Which is why the profile screen spells it out: at full mastery a
/// Walker notices you at eighty-four metres instead of a hundred and twenty.
const double kScoutingStealth = 0.30;

/// §17.4: how much better they notice in the dark.
///
/// ⚠️ **§2.5.2's whole argument for a night raid rests on this**, and it was
/// not implemented — "przeciwnicy wykrywają lepiej (+20%)" was a line in the
/// document and nothing else, so walking a town at midnight was strictly
/// safer than at noon once the noise rule is set aside.
///
/// Not because they see better: §6.2 gives a Walker eyes that barely work.
/// A person moving at night is louder, slower and lit by a phone screen, and
/// §6.2's radius is the only place this game has to put any of that.
const double kNightDetection = 0.20;

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
    this.heardAt,
    this.investigateLeft = Duration.zero,
    this.walkedToNoise = Duration.zero,
    this.hurrying = false,
    this.headingDeg,
    this.sightFactor = 1,
    this.bleedMlPerSecond = 0,
  });

  /// Rolls the ranges of §6.2 once, at spawn. Two Walkers are not the same
  /// Walker: one is a little faster and one bleeds a little longer.
  factory Enemy.spawn({
    required String id,
    required EnemyKind kind,
    required GeoPoint at,
    required GeoPoint home,
    required math.Random random,
    double sightFactor = 1,
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
      sightFactor: sightFactor,
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

  /// §5.6.2: where a sound came from, which is where it walks to — never
  /// straight to the player. That one rule is what leaves room for tactics:
  /// shoot, move, watch.
  final GeoPoint? heardAt;

  /// §5.6.2: how much turning the place over is left before it gives up.
  final Duration investigateLeft;

  /// §5.6.2: how long it has been walking towards the noise.
  ///
  /// ⚠️ Separate from [investigateLeft], which is the search *at* the place
  /// and only starts once the body has arrived. Something that cannot arrive —
  /// too far to walk, or held back by §6.1a's leash — never started that clock
  /// at all, so it never forgot the sound. See [kWalkToNoiseFor].
  final Duration walkedToNoise;

  /// §5.6.2: whether it is on its way to something startling.
  ///
  /// Only ever true while investigating: once it arrives, or gives up, it is
  /// walking again like everything else.
  final bool hurrying;

  /// §2.6: how fast it is losing blood from what has already hit it.
  ///
  /// Three good hits can put something down before it reaches the player,
  /// which is what makes backing away from a wounded one a tactic rather than
  /// cowardice.
  final double bleedMlPerSecond;

  /// §5.6.1's built-up damping, applied to what it can notice.
  ///
  /// A street of six-storey blocks is not a field: something forty metres away
  /// behind two buildings is not seen, and the same walls that swallow a shot
  /// swallow a silhouette. One factor rather than a line of sight per pair,
  /// because §6.2 gives detection as a radius and this keeps it one.
  final double sightFactor;

  /// Which way it is facing, as a compass bearing, or null while it is not
  /// moving at all.
  ///
  /// ⚠️ Where it is *going*, never what it can see. Detection in §6.2 is a
  /// radius and nothing else, so drawing this as a field of view would be a
  /// lie a player would act on — the same reason §3.6 refuses to leave the
  /// player's own cone pointing the last way they walked.
  final double? headingDeg;

  Duration get budget => sprintLeft ?? kind.sprintBudget;

  /// How far this one actually notices anything, here (§6.2, §5.6.1).
  double get sightM => kind.detectionM * sightFactor;

  /// §6.1a: it charges inside sixty per cent of what it can see.
  double get chaseM => sightM * 0.6;

  /// §5.6.2, §6.1a: whether this one is actually onto the player.
  ///
  /// ⚠️ **Not the same as "not idle".** Something walking towards a noise
  /// three streets away is busy, is not idle, and is not on anybody — and
  /// counting it as a pursuer kept §5.6.2's hunt warm on every tick, so the
  /// street never went cold and a restart put hunters back for ever.
  ///
  /// Onto means one of two things: coming for the player, or close enough to
  /// see them. A sound is neither.
  bool isOnto(GeoPoint playerAt, {double scouting = 0, double darkness = 0}) {
    if (state == EnemyState.chase || state == EnemyState.spent) return true;

    return state == EnemyState.alert &&
        position.distanceTo(playerAt) <=
            sightAgainst(scouting, darkness: darkness);
  }

  /// §6.2, §7: how far this one notices **this** player.
  ///
  /// ⚠️ Not the same question as [sightM], and the difference is the whole of
  /// §7's Scouting: [sightM] is what the enemy can see, this is what it sees
  /// *of somebody who knows how to move*. Thirty per cent at full mastery,
  /// which turns a Walker's hundred and twenty metres into eighty-four.
  ///
  /// A radius rather than a roll, because §6.2 gives detection as a radius and
  /// nothing else. Making stealth a dice roll here would put a coin flip
  /// between the player and a fight they thought they had avoided.
  double sightAgainst(double scouting, {double darkness = 0}) =>
      sightM *
      (1 - kScoutingStealth * scouting.clamp(0.0, 1.0)) *
      (1 + kNightDetection * darkness.clamp(0.0, 1.0));

  bool get isDead => bloodLostMl >= bloodMl * kind.deathAtLoss;

  /// §5.5.1: healthy, wounded or critical, against what it takes to kill it.
  ///
  /// Measured against the threshold rather than against its whole volume: a
  /// Walker dies at 45% and a Brute at 50%, so half a Brute's blood is not
  /// half a Brute.
  EnemyCondition get condition {
    final spent = bloodLostMl / (bloodMl * kind.deathAtLoss);

    if (spent >= 0.66) return EnemyCondition.critical;
    if (spent >= 0.25) return EnemyCondition.wounded;
    return EnemyCondition.healthy;
  }

  /// §5.5.2: how much sprint it has left, 0–1.
  ///
  /// The tactical fact of a group fight: one that has burned its budget can be
  /// walked away from, and one that has not cannot.
  double get sprintLeftFraction =>
      (budget.inMilliseconds / kind.sprintBudget.inMilliseconds).clamp(
        0.0,
        1.0,
      );

  /// How fast it is moving right now, in km/h.
  double get speedKmh => switch (state) {
    // §5.6.2: a body on its way to a gunshot is running, not strolling. What
    // it does when it gets there is still a search — this is only how it
    // covers the ground, and it is the difference between a shot that costs
    // something and a shot that is a note in a log.
    EnemyState.alert when hurrying => runKmh,
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
    GeoPoint? heardAt,
    bool forgetNoise = false,
    Duration? investigateLeft,
    Duration? walkedToNoise,
    bool? hurrying,
    double? headingDeg,
    double? sightFactor,
    double? bleedMlPerSecond,
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
    heardAt: forgetNoise ? null : heardAt ?? this.heardAt,
    hurrying: forgetNoise ? false : (hurrying ?? this.hurrying),
    walkedToNoise: forgetNoise
        ? Duration.zero
        : walkedToNoise ?? this.walkedToNoise,
    investigateLeft: forgetNoise
        ? Duration.zero
        : investigateLeft ?? this.investigateLeft,
    headingDeg: headingDeg ?? this.headingDeg,
    sightFactor: sightFactor ?? this.sightFactor,
    bleedMlPerSecond: bleedMlPerSecond ?? this.bleedMlPerSecond,
  );

  /// The wound of §5.1.5, taken.
  ///
  /// [bleedMlPerSecond] adds to whatever is already open: a second hole does
  /// not close the first.
  Enemy hit(double bloodLoss, {double bleeding = 0}) => copyWith(
    bloodLostMl: bloodLostMl + bloodLoss,
    bleedMlPerSecond: bleedMlPerSecond + bleeding,
  );

  /// §2.6: how long until what is already open finishes it, or null if
  /// nothing is open.
  ///
  /// Worth knowing outside the tick because a wound outlives the session that
  /// made it: something shot and left bleeding goes on bleeding while the
  /// phone is in a pocket, and whoever throws that session away has to settle
  /// it rather than let the death evaporate.
  Duration? get bleedsOutIn {
    if (isDead || bleedMlPerSecond <= 0) return null;

    final left = bloodMl * kind.deathAtLoss - bloodLostMl;
    if (left <= 0) return Duration.zero;

    return Duration(milliseconds: (left / bleedMlPerSecond * 1000).ceil());
  }

  /// §2.6: how much blood it has left, 0–1, against what kills it.
  double get bloodLeft =>
      (1 - bloodLostMl / (bloodMl * kind.deathAtLoss)).clamp(0.0, 1.0);

  bool get isBleeding => bleedMlPerSecond > 0;

  /// §5.6.2: something was heard over there.
  ///
  /// [chasing] for a sound made close enough to place the shooter directly —
  /// inside a third of the radius, where there is nothing left to work out.
  Enemy hears(GeoPoint at, {bool chasing = false, bool hurrying = false}) =>
      copyWith(
        heardAt: at,
        investigateLeft: kInvestigateFor,
        // A fresh sound is a fresh walk. Without this a body that gave up on
        // one noise would give up on the next one instantly.
        walkedToNoise: Duration.zero,
        hurrying: hurrying,
        state: chasing && budget > Duration.zero
            ? EnemyState.chase
            : EnemyState.alert,
        sinceContact: Duration.zero,
      );
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
  SpawnFilter? ground,
  double scouting = 0,
  double darkness = 0,
}) {
  if (enemy.isDead || elapsed <= Duration.zero) return enemy;

  final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

  // §2.6: what is already open goes on costing, whatever it does next.
  if (enemy.isBleeding) {
    final bled = enemy.hit(enemy.bleedMlPerSecond * seconds);
    if (bled.isDead) return bled;
    enemy = bled;
  }
  final distance = enemy.position.distanceTo(playerAt);

  // §6.1a: contact is the player being near, not the enemy trying.
  final near = distance <= kContactM;
  final sinceContact = near ? Duration.zero : enemy.sinceContact + elapsed;

  final beyondLeash = enemy.home.distanceTo(enemy.position) > kLeashM;
  final lostContact =
      sinceContact >=
      (enemy.bloodLostMl > 0
          ? kContactLost * kWoundedContactFactor
          : kContactLost);

  var state = _nextState(
    enemy,
    distance: distance,
    heardShot: heardShot,
    beyondLeash: beyondLeash,
    lostContact: lostContact,
    scouting: scouting,
    darkness: darkness,
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

  // §5.6.2: a sound is a place, and the place is what it walks to. Only while
  // the player is not the nearer answer — something in front of you beats
  // something you heard.
  final noise = enemy.heardAt;
  final seen = distance <= enemy.sightAgainst(scouting, darkness: darkness);
  final investigating = noise != null && !seen && state != EnemyState.returning;

  var left = enemy.investigateLeft;
  var walked = enemy.walkedToNoise;
  var forget = false;
  if (investigating) {
    // Ten metres, because what it is searching is a street corner rather than
    // a point, and because §6.1a has it milling about while it looks.
    if (enemy.position.distanceTo(noise) <= 10) {
      left -= elapsed;
      if (left <= Duration.zero) {
        left = Duration.zero;
        forget = true;
        state = EnemyState.returning;
      }
    } else {
      // ⚠️ The walk has a clock of its own, and it did not. A sound it cannot
      // reach — too far, or past the leash — left it walking out and being
      // pulled back for the rest of the session.
      walked += elapsed;
      if (walked >= kWalkToNoiseFor) {
        forget = true;
        state = EnemyState.returning;
      }
    }
  } else if (seen) {
    forget = true;
  }

  // ⚠️ Also while it is being pulled home. `investigating` is false in the
  // returning state, so without this the walk clock stops the moment the leash
  // takes hold — and the leash is exactly the case this exists for.
  if (state == EnemyState.returning && noise != null && !forget) {
    walked += elapsed;
    if (walked >= kWalkToNoiseFor) forget = true;
  }

  // §6.1a: idle is random movement about its own patch, not standing to
  // attention. It keeps its heading and turns a little at a time, and only
  // hard about when it has drifted too far from where it belongs.
  // Turning is always gradual, whether it is drifting or heading back: a
  // marker that spins on the spot reads as a bug rather than as a body.
  final drift = enemy.headingDeg ?? _seedHeading(enemy);
  final wanted = enemy.position.distanceTo(enemy.home) > kWanderRadiusM
      ? enemy.position.bearingTo(enemy.home)
      : drift +
            kWanderTurnPerSecond *
                seconds *
                (_wobble(enemy, now: enemy.sinceContact) - 0.5) *
                2;

  final wanderBearing = _steer(
    from: drift,
    towards: wanted,
    maxTurn: kWanderTurnPerSecond * seconds,
  );

  // Where it wants to be heading, before anything is said about how fast it
  // may turn.
  final wantedBearing = switch (state) {
    EnemyState.returning => enemy.position.bearingTo(enemy.home),
    EnemyState.idle =>
      investigating ? enemy.position.bearingTo(noise) : wanderBearing,
    _ => enemy.position.bearingTo(investigating ? noise : playerAt),
  };

  // ⚠️ Nothing turns on the spot. A chase may swing quickly because it is
  // following something that moves; a thing milling about turns slowly, and
  // one walking home turns no faster than it wanders. Found on a walk: an
  // enemy that lost contact spun a hundred and eighteen degrees in one second
  // to face home, which reads as a bug rather than as a body.
  final steered = _steer(
    from: enemy.headingDeg ?? wantedBearing,
    towards: wantedBearing,
    maxTurn:
        (state == EnemyState.chase || state == EnemyState.spent ? 60 : 12) *
        seconds,
  );

  final step = enemy.speedKmh * seconds / 3.6;
  final target = _step(enemy.position, bearing: steered, metres: step);

  final moved = _towards(enemy.position, target, metres: step, ground: ground);

  return enemy.copyWith(
    position: moved,
    // Facing where it is walking. Something that has stopped keeps the way it
    // last faced rather than snapping north.
    headingDeg: moved.distanceTo(enemy.position) < 0.05
        ? enemy.headingDeg
        : enemy.position.bearingTo(moved),
    state: state,
    sprintLeft: budget,
    sinceContact: sinceContact,
    forgetNoise: forget,
    investigateLeft: left,
    walkedToNoise: walked,
  );
}

/// §6.1a's table, in the order its rows are written.
EnemyState _nextState(
  Enemy enemy, {
  required double distance,
  required bool heardShot,
  required bool beyondLeash,
  required bool lostContact,
  double scouting = 0,
  double darkness = 0,
}) {
  // ⚠️ §6.1a's contact rule and §5.6.2's search would otherwise contradict
  // each other: an enemy sent to a noise is *supposed* to be somewhere the
  // player is not, and giving up after forty-five seconds would cut every
  // sixty-second search short. The leash still holds — that one is about
  // distance from home, which a sound does not excuse.
  final searching =
      enemy.heardAt != null && enemy.investigateLeft > Duration.zero;

  // Home first: the two rules that stop a player towing a train of enemies
  // across half a city.
  if (beyondLeash || (lostContact && !searching)) {
    // Its patch, not a point on it: §6.1a's idle state is milling about, so
    // "home" is anywhere it would be milling.
    return enemy.position.distanceTo(enemy.home) < kWanderRadiusM
        ? EnemyState.idle
        : EnemyState.returning;
  }

  final noticed =
      heardShot || distance <= enemy.sightAgainst(scouting, darkness: darkness);
  if (!noticed) {
    // §5.6.2: a sound already heard is still worth walking to, so it stays
    // alert rather than forgetting the moment the player is out of sight.
    if (enemy.heardAt != null && enemy.state != EnemyState.returning) {
      return enemy.state == EnemyState.chase
          ? EnemyState.chase
          : EnemyState.alert;
    }

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

  if (heardShot || distance <= enemy.chaseM) {
    return enemy.budget > Duration.zero ? EnemyState.chase : EnemyState.spent;
  }

  return EnemyState.alert;
}

/// Towards it, round whatever cannot be walked through.
///
/// §6.3 settles for straight lines in the MVP and says routing over the OSM
/// graph comes later. This is neither: it is one step at a time, and where
/// that step would land in a river or inside a wall it is tried at an angle
/// instead. A thing that swims a lake to reach somebody is a thing nobody
/// believes in, and the cost of not believing in it is the whole atmosphere.
///
/// It is deliberately local. Something can still walk into a courtyard and
/// press against the far wall, because it has no idea the courtyard is one —
/// and that is honest for a creature with no map.
GeoPoint _towards(
  GeoPoint from,
  GeoPoint to, {
  required double metres,
  SpawnFilter? ground,
}) {
  final distance = from.distanceTo(to);
  if (distance <= 0 || metres <= 0) return from;

  final step = metres >= distance ? distance : metres;
  final bearing = from.bearingTo(to);

  // Straight first, then further and further off it. Fifteen degrees is a
  // shoulder's width at a stride, and a hundred and five is as far round as a
  // thing will go before it simply waits.
  for (final turn in const [0.0, 15, -15, 35, -35, 60, -60, 105, -105]) {
    final at = _step(from, bearing: bearing + turn, metres: step);
    if (ground == null || ground.refuse(at) == null) return at;
  }

  return from;
}

/// One step of [metres] on a compass [bearing].
GeoPoint _step(
  GeoPoint from, {
  required double bearing,
  required double metres,
}) => from.offsetBy(metres: metres, bearingDeg: bearing);

/// A starting direction for something that has never moved.
///
/// From its own id, so the same Walker always sets off the same way and a
/// restart does not shuffle the street.
double _seedHeading(Enemy enemy) => (enemy.id.hashCode % 360).abs().toDouble();

/// A number between nought and one that changes slowly for one enemy.
///
/// Not a fresh random each tick: that averages out to walking in a straight
/// line with a tremor. This wanders.
double _wobble(Enemy enemy, {required Duration now}) {
  final seed = enemy.id.hashCode ^ (now.inSeconds ~/ 7);
  return (seed % 1000).abs() / 1000;
}

/// Turns [from] towards [towards] by at most [maxTurn] degrees.
///
/// The short way round, so something facing north-west turning to north-east
/// goes over the top rather than the long way about.
double _steer({
  required double from,
  required double towards,
  required double maxTurn,
}) {
  var difference = (towards - from) % 360;
  if (difference > 180) difference -= 360;

  final turn = difference.abs() <= maxTurn
      ? difference
      : (difference.isNegative ? -maxTurn : maxTurn);

  final heading = (from + turn) % 360;
  return heading < 0 ? heading + 360 : heading;
}
