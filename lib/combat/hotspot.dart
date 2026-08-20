/// Ogniska: the pressure that builds on its own (§6.5).
///
/// Everything else in this game is something the player does. A hotspot is
/// something the game does back. It sits on the map, it grows on a clock that
/// runs whether or not anybody opens the app, and it is the reason §6.4's
/// ambient trickle — two Walkers to a square kilometre — is not the whole
/// world. Without it the combat model, the loot economy and the shelter have
/// all been tested one at a time and never once under the pressure they were
/// built for.
///
/// Three of them at most, anchored around the shelter, between five hundred
/// metres and two kilometres away. §6.5.1's geometry closes: a hotspot at the
/// minimum distance, grown to its maximum two-hundred-metre radius, still has
/// its edge three hundred metres from the door, and §8.1's safe zone is fifty
/// — a buffer of two hundred and fifty metres survives the worst case.
///
/// ⚠️ **A slot is a row, and an empty slot is still a row.** After a hotspot
/// is cleared its place rests for a day or two (§6.5.4) before another appears
/// somewhere else. Modelling that as the absence of a record would make "no
/// hotspot here yet" and "this one was just cleared" the same state, and they
/// are opposites: one is the game starting up, the other is a reward.
library;

import 'dart:math';

import '../map/geometry.dart';
import '../sim/play_habit.dart';
import 'enemy.dart';

/// §6.5.1: how many at once. Three, and the number is the whole difficulty
/// curve — a fourth would not fit around a shelter at these distances.
const int kMaxHotspots = 3;

/// §6.5.1: never nearer the shelter than this.
const double kHotspotMinFromShelterM = 500;

/// §6.5.1: nor further, or the pressure is somebody else's problem.
const double kHotspotMaxFromShelterM = 2000;

/// §6.5.1: between centres.
///
/// ⚠️ At the maximum radius of 200 m, two centres 450 m apart leave 50 m of
/// clear ground between their edges. Without this rule two level-ten hotspots
/// could merge into an impassable area 800 m across.
const double kHotspotMinApartM = 450;

/// §6.5.2: the hard ceiling on the radius, reached at level ten.
const double kHotspotMaxRadiusM = 200;

/// §6.5.2: where a new one starts.
const double kHotspotFirstRadiusM = 20;

/// §6.5.2: what each promotion adds, drawn between these.
const (double, double) kHotspotGrowthM = (14, 26);

/// §6.5.4: how long a hotspot stays furious after losing a level.
const Duration kAgitationLength = Duration(minutes: 10);

/// §6.5.4's safety valve: agitation does not renew this far from the centre.
///
/// ⚠️ The one rule here that exists to let a player lose. Agitation is meant
/// to be hard, not to be a death spiral with no way out — walking away has to
/// stay an option, or the mechanic punishes the attempt rather than the
/// mistake.
const double kAgitationEscapeM = 400;

/// §6.5.4: integrity comes back at this share of the maximum, per hour.
const double kIntegrityRegenPerHour = 0.05;

/// §6.5.4: how long a cleared slot stays empty, drawn between these.
const (Duration, Duration) kRestAfterClearing = (
  Duration(hours: 24),
  Duration(hours: 48),
);

/// §6.5.3: the spread on a promotion interval, so the clock is not a metronome.
const (double, double) kPromotionJitter = (0.6, 1.4);

/// §6.5.2, one row (level 1–10).
class HotspotLevel {
  const HotspotLevel({
    required this.level,
    required this.enemyCap,
    required this.respawn,
    required this.leaperPercent,
    required this.brutePercent,
  });

  final int level;

  /// How many of them may exist from here at once.
  final int enemyCap;

  /// How long a place in that count stays empty after something dies in it.
  final Duration respawn;

  /// §6.5.2's composition, as the share of each spawn.
  final int leaperPercent;
  final int brutePercent;
}

/// §6.5.2's table, exactly.
///
/// ⚠️ Level ten's Brute share is **25%** — the document says "full composition"
/// and names no figure, so this is the one number here that is a decision
/// rather than a transcription. It continues the 10/15/20 run of levels seven
/// to nine.
const List<HotspotLevel> kHotspotLevels = [
  HotspotLevel(
    level: 1,
    enemyCap: 1,
    respawn: Duration(minutes: 15),
    leaperPercent: 0,
    brutePercent: 0,
  ),
  HotspotLevel(
    level: 2,
    enemyCap: 2,
    respawn: Duration(minutes: 13),
    leaperPercent: 0,
    brutePercent: 0,
  ),
  HotspotLevel(
    level: 3,
    enemyCap: 3,
    respawn: Duration(minutes: 12),
    leaperPercent: 0,
    brutePercent: 0,
  ),
  HotspotLevel(
    level: 4,
    enemyCap: 4,
    respawn: Duration(minutes: 10),
    leaperPercent: 20,
    brutePercent: 0,
  ),
  HotspotLevel(
    level: 5,
    enemyCap: 5,
    respawn: Duration(minutes: 9),
    leaperPercent: 30,
    brutePercent: 0,
  ),
  HotspotLevel(
    level: 6,
    enemyCap: 6,
    respawn: Duration(minutes: 8),
    leaperPercent: 35,
    brutePercent: 0,
  ),
  HotspotLevel(
    level: 7,
    enemyCap: 8,
    respawn: Duration(minutes: 6),
    leaperPercent: 35,
    brutePercent: 10,
  ),
  HotspotLevel(
    level: 8,
    enemyCap: 9,
    respawn: Duration(minutes: 5),
    leaperPercent: 35,
    brutePercent: 15,
  ),
  HotspotLevel(
    level: 9,
    enemyCap: 11,
    respawn: Duration(minutes: 4),
    leaperPercent: 35,
    brutePercent: 20,
  ),
  HotspotLevel(
    level: 10,
    enemyCap: 12,
    respawn: Duration(minutes: 3),
    leaperPercent: 35,
    brutePercent: 25,
  ),
];

/// The row for [level], clamped to the table.
HotspotLevel levelRow(int level) =>
    kHotspotLevels[level.clamp(1, kHotspotLevels.length) - 1];

/// §6.5.2: the radius at [level], worked out rather than stored.
///
/// ⚠️ Derived from the seed on purpose. Each promotion adds a random fourteen
/// to twenty-six metres, and losing a level has to give exactly those metres
/// back (§6.5.4) — which a stored radius cannot do, because the draw that made
/// it is gone. Recomputing from the seed makes shrinking the exact inverse of
/// growing, and costs one loop of at most nine steps.
double hotspotRadiusM(int seed, int level) {
  if (level <= 0) return 0;

  var radius = kHotspotFirstRadiusM;
  final random = Random(seed);
  final (low, high) = kHotspotGrowthM;

  for (var step = 1; step < level; step++) {
    radius += low + random.nextDouble() * (high - low);
  }

  return radius > kHotspotMaxRadiusM ? kHotspotMaxRadiusM : radius;
}

/// §6.5.4: what killing one of them is worth to the integrity of its hotspot.
///
/// Half outside the radius, which is the whole trade §6.5.4 offers: luring
/// them out is safer and exactly twice as slow. Rounded down, so a Walker
/// dragged into the open is worth five and not five and a half.
int killPoints(EnemyKind kind, {required bool insideRadius}) {
  final full = switch (kind) {
    EnemyKind.walker => 10,
    EnemyKind.leaper => 15,
    EnemyKind.brute => 35,
  };
  return insideRadius ? full : full ~/ 2;
}

/// §6.5.4: how much a hotspot at [level] can take before losing one.
int integrityMaxAt(int level) => 60 + 20 * level;

/// §6.5.2, §6.5.4: what a hotspot at [level] sends out.
///
/// A bag rather than a distribution, because the spawner draws uniformly from
/// a list — a hundred entries makes the percentages exact and costs nothing
/// worth measuring.
///
/// [agitated] shifts everything one rung up (§6.5.4): every Walker becomes a
/// Leaper and every Leaper a Brute. That is what makes knocking a level off a
/// level-ten hotspot a fight against twelve Brutes rather than a victory lap.
List<EnemyKind> compositionAt(int level, {bool agitated = false}) {
  final row = levelRow(level);

  final brute = row.brutePercent;
  final leaper = row.leaperPercent;
  final walker = 100 - brute - leaper;

  final bag = <EnemyKind>[
    for (var i = 0; i < walker; i++)
      agitated ? EnemyKind.leaper : EnemyKind.walker,
    for (var i = 0; i < leaper; i++)
      agitated ? EnemyKind.brute : EnemyKind.leaper,
    for (var i = 0; i < brute; i++) EnemyKind.brute,
  ];

  return bag.isEmpty ? const [EnemyKind.walker] : bag;
}

/// §6.5.3: how long until this hotspot grows again, in real time.
///
/// Two conversions, and they are easy to confuse. §6.5.3's interval is in
/// *world* hours — eight on day one, falling a quarter-hour a day to a floor
/// of two. What turns that into a wait somebody actually sits through is the
/// player's own pace from §16.4: a habit earning eighteen credited hours a day
/// runs the world at three quarters of the calendar, and a habit earning
/// thirty runs it faster than one.
Duration promotionDelay({
  required int survivalDay,
  required PlayHabit habit,
  required Random random,
}) {
  final (low, high) = kPromotionJitter;
  final worldHours =
      promotionIntervalHours(survivalDay) *
      (low + random.nextDouble() * (high - low));

  final pace = habit.creditedHoursPerDay / 24;
  final realHours = pace <= 0 ? worldHours : worldHours / pace;

  return Duration(milliseconds: (realHours * 3600 * 1000).round());
}

/// One of §6.5.1's three places, live or resting.
class Hotspot {
  const Hotspot({
    required this.id,
    required this.seed,
    required this.centre,
    required this.level,
    required this.integrity,
    required this.bornAt,
    required this.nextLevelAt,
    this.agitatedUntil,
    this.restingUntil,
  });

  /// A fresh one at level one (§6.5.2).
  factory Hotspot.born({
    required String id,
    required int seed,
    required GeoPoint centre,
    required DateTime at,
    required Duration until,
  }) => Hotspot(
    id: id,
    seed: seed,
    centre: centre,
    level: 1,
    integrity: integrityMaxAt(1).toDouble(),
    bornAt: at,
    nextLevelAt: at.add(until),
  );

  final String id;

  /// What the radius is drawn from. Stable for the life of the slot.
  final int seed;

  /// §6.5.1: fixed for the whole life of the hotspot. A pressure point that
  /// wandered would be weather, not a place.
  final GeoPoint centre;

  /// 1–10 while it exists, 0 while the slot is resting.
  final int level;

  final double integrity;
  final DateTime bornAt;

  /// When it grows next. Meaningless while resting.
  final DateTime nextLevelAt;

  /// §6.5.4: furious until this moment, or null.
  final DateTime? agitatedUntil;

  /// §6.5.4: the slot is empty until this moment, or null.
  final DateTime? restingUntil;

  bool get isResting => level <= 0;

  double get radiusM => hotspotRadiusM(seed, level);

  int get integrityMax => integrityMaxAt(level);

  double get integrityFraction =>
      integrityMax <= 0 ? 0 : (integrity / integrityMax).clamp(0.0, 1.0);

  bool isAgitatedAt(DateTime now) {
    final until = agitatedUntil;
    return until != null && now.isBefore(until);
  }

  /// Whether [at] is inside the circle drawn on the map (§6.5.6).
  bool covers(GeoPoint at) => !isResting && centre.distanceTo(at) <= radiusM;

  /// §6.5.2: what it may have out at once, agitation included.
  int enemyCapAt(DateTime now) {
    if (isResting) return 0;

    final base = levelRow(level).enemyCap;
    // §6.5.4: half again, rounded up — the point of agitation is that the
    // ground you just cleared fills back in faster than you emptied it.
    return isAgitatedAt(now) ? (base * 3 / 2).ceil() : base;
  }

  /// §6.5.2, §6.5.4: how long a place in that count stays empty.
  Duration respawnAt(DateTime now) {
    final base = levelRow(level).respawn;
    return isAgitatedAt(now) ? base ~/ 3 : base;
  }

  /// §6.5.2, §6.5.4: what it sends out right now.
  List<EnemyKind> compositionNow(DateTime now) =>
      compositionAt(level, agitated: isAgitatedAt(now));

  /// §6.5.4: what killing one of its own is worth against it.
  ///
  /// [at] is where the thing died, not where the player was standing: §6.5.4
  /// pays half for a body outside the circle, and the circle is the thing
  /// being neutralised.
  Hotspot damagedBy(EnemyKind kind, {required GeoPoint at}) {
    if (isResting) return this;

    final points = killPoints(kind, insideRadius: covers(at));
    final left = integrity - points;

    return copyWith(integrity: left < 0 ? 0 : left);
  }

  /// §6.5.4: five per cent of the maximum an hour, and never past it.
  ///
  /// A player who walks away half way through comes back to a hotspot that has
  /// healed — possible, and expensive, which is the point.
  Hotspot regenerated(Duration elapsed) {
    if (isResting || elapsed <= Duration.zero) return this;

    final hours = elapsed.inMilliseconds / 3600000;
    final back = integrityMax * kIntegrityRegenPerHour * hours;
    final healed = integrity + back;

    return copyWith(
      integrity: healed > integrityMax ? integrityMax.toDouble() : healed,
    );
  }

  /// §6.5.3: one level up, with the metres that come with it.
  Hotspot promoted({required DateTime at, required Duration until}) {
    if (isResting || level >= kHotspotLevels.length) {
      return copyWith(nextLevelAt: at.add(until));
    }

    final next = level + 1;
    return copyWith(
      level: next,
      // A promotion arrives with the wall repaired: §6.5.4's maximum moves up
      // with the level, and arriving at a new level already damaged would make
      // a hotspot easiest at the moment it became hardest.
      integrity: integrityMaxAt(next).toDouble(),
      nextLevelAt: at.add(until),
    );
  }

  /// §6.5.4: integrity reached zero.
  ///
  /// One level off, the radius back to exactly what it was at that level, the
  /// integrity full at the new one, and ten minutes of fury. Taking a level-ten
  /// hotspot to nothing means doing this ten times against rising resistance —
  /// which is the operation §6.5.4 describes and the reason it takes an
  /// afternoon and a full pack.
  Hotspot demoted({required DateTime at, required Duration restFor}) {
    if (isResting) return this;

    final next = level - 1;
    if (next <= 0) {
      return copyWith(
        level: 0,
        integrity: 0,
        agitatedUntil: null,
        restingUntil: at.add(restFor),
      );
    }

    return copyWith(
      level: next,
      integrity: integrityMaxAt(next).toDouble(),
      agitatedUntil: at.add(kAgitationLength),
    );
  }

  /// §6.5.4's valve: fury does not follow somebody who left.
  ///
  /// Called with where the player is. Beyond four hundred metres the ten
  /// minutes are simply dropped — withdrawing works, and it is meant to.
  Hotspot settledIfAbandoned(GeoPoint playerAt) {
    if (agitatedUntil == null) return this;
    if (centre.distanceTo(playerAt) <= kAgitationEscapeM) return this;

    return copyWith(agitatedUntil: null, clearAgitation: true);
  }

  /// The slot's rest is over: somewhere else, level one (§6.5.4).
  Hotspot reborn({
    required GeoPoint centre,
    required int seed,
    required DateTime at,
    required Duration until,
  }) => Hotspot.born(id: id, seed: seed, centre: centre, at: at, until: until);

  Hotspot copyWith({
    int? level,
    double? integrity,
    DateTime? nextLevelAt,
    DateTime? agitatedUntil,
    DateTime? restingUntil,
    bool clearAgitation = false,
    bool clearResting = false,
  }) => Hotspot(
    id: id,
    seed: seed,
    centre: centre,
    level: level ?? this.level,
    integrity: integrity ?? this.integrity,
    bornAt: bornAt,
    nextLevelAt: nextLevelAt ?? this.nextLevelAt,
    agitatedUntil: clearAgitation
        ? null
        : (agitatedUntil ?? this.agitatedUntil),
    restingUntil: clearResting ? null : (restingUntil ?? this.restingUntil),
  );
}
