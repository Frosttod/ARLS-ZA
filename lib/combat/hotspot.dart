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

/// §17.4: o ile więcej ich chodzi po ciemku, przy pełnej nocy.
///
/// Połowa. Wystarczy, żeby ta sama ulica była innym problemem o dwudziestej
/// drugiej niż o czternastej, i za mało, żeby noc była nie do przejścia —
/// §6.5.3 rośnie i bez tego.
const double kNightCrowdShare = 0.5;

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

/// §6.5.3: ile realnego czasu strefa rośnie o jeden poziom.
///
/// ⚠️ **Doba do dwóch dób, a nie osiem godzin świata.** Poprzednia formuła
/// liczyła w godzinach świata — osiem pierwszego dnia, ćwierć godziny mniej
/// każdego następnego, podłoga na dwóch — i po przeliczeniu przez tempo gry
/// dawała strefę rosnącą szybciej, niż da się ją zbić. Miasto ma się psuć
/// przez tygodnie, nie przez popołudnie.
const (double, double) kZoneGrowthHours = (24, 48);

/// Nawyk odniesienia z §16.4: godzina dziennie, czyli 5.8 h kredytu.
const double kReferenceCreditedHours = 5.8;

/// I granice, żeby żaden nawyk nie zamienił tego w inną grę: pół doby dla
/// kogoś, kto gra całymi dniami, cztery doby dla kogoś, kogo nie ma.
const double kZoneGrowthFloorHours = 12;
const double kZoneGrowthCeilingHours = 96;

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
int killPoints(EnemyKind kind, {required bool insideRadius}) =>
    insideRadius ? kKillInZone : kKillOutside;

/// §6.5.4: ile jest warte ciało padłe w strefie.
///
/// ⚠️ **Jednakowo, niezależnie od gatunku.** Punktacja po gatunku — Kroczący
/// dziesięć, Skoczek piętnaście, Brutal trzydzieści pięć — nagradzała
/// wybieranie najgroźniejszego celu, czyli dokładnie to, czego §6.5.4 nie
/// chce: strefę zbija się przez wytrzymałość, a nie przez jeden bohaterski
/// zamach. Kto to jest, decyduje o tym, ile kosztuje zabicie, a nie ile jest
/// warte.
const int kKillInZone = 10;

/// I połowa za ciało poza kołem. Cały handel §6.5.4: wywabianie jest
/// bezpieczniejsze i dokładnie dwa razy wolniejsze.
const int kKillOutside = 5;

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
  final (low, high) = kZoneGrowthHours;
  final base = low + random.nextDouble() * (high - low);

  // §16.4: doba do dwóch dób **dla nawyku odniesienia** — godziny dziennie.
  // Kto gra więcej, temu miasto rośnie szybciej; kto zniknął na tydzień,
  // wraca do świata, który poszedł dalej, ale nie oszalał.
  final credited = habit.creditedHoursPerDay;
  final factor = credited <= 0 ? 1.0 : kReferenceCreditedHours / credited;

  final hours = (base * factor).clamp(
    kZoneGrowthFloorHours,
    kZoneGrowthCeilingHours,
  );

  return Duration(milliseconds: (hours * 3600 * 1000).round());
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
    this.surgedAt,
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

  /// §6.5.4: kiedy ostatnio wyrzuciła wysyp. Null, jeśli nigdy.
  final DateTime? surgedAt;

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

  /// §6.5.2, §17.4: what it may have out at once — agitation and the dark.
  ///
  /// [darkness] is §17.4's index, nought at midday and one at night.
  ///
  /// ⚠️ **Noc musi kosztować.** §17.4 dawała nocy tylko piątą część promienia
  /// wykrycia i nic poza tym, więc wyjście po ciemku było tańsze niż w dzień:
  /// widać ich stożki z daleka, a jest ich tyle samo. Teraz jest ich o połowę
  /// więcej, i to jest powód, dla którego szuka się w dzień, a wraca przed
  /// zmierzchem.
  int enemyCapAt(DateTime now, {double darkness = 0}) {
    if (isResting) return 0;

    final base = levelRow(level).enemyCap;
    // §6.5.4: half again, rounded up — the point of agitation is that the
    // ground you just cleared fills back in faster than you emptied it.
    final agitated = isAgitatedAt(now) ? base * 3 / 2 : base.toDouble();

    return (agitated * (1 + kNightCrowdShare * darkness.clamp(0.0, 1.0)))
        .ceil();
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

  /// §6.5.4: czy ta strefa odpowiada na cios wysypem.
  ///
  /// Rzut robi wołający — model niczego nie losuje sam, żeby ten sam bieg dał
  /// się odtworzyć (§11). Tutaj rozstrzyga się tylko, czy wolno.
  bool maySurgeAt(DateTime now) {
    if (isResting) return false;

    final last = surgedAt;
    return last == null || now.difference(last) >= kSurgeCooldown;
  }

  /// Ilu ich wychodzi ponad limit, i kiedy to było.
  Hotspot surged({required DateTime at}) =>
      copyWith(surgedAt: at, agitatedUntil: at.add(kAgitationLength));

  /// §6.5.4: limit powiększony o wysyp, jeśli któryś jeszcze trwa.
  int surgeExtraAt(DateTime now) =>
      isAgitatedAt(now) ? (levelRow(level).enemyCap * kSurgeShare).ceil() : 0;

  /// §6.5.4: five per cent of the maximum an hour, and never past it.
  ///
  /// A player who walks away half way through comes back to a hotspot that has
  /// healed — possible, and expensive, which is the point.
  /// ⚠️ **Nie leczy się, kiedy gracz stoi w środku.** Pasek odbudowujący się
  /// w trakcie walki czyta się jak błąd, nawet gdy wobec tempa zabijania jest
  /// arytmetycznie bez znaczenia — a §12 mówi, że to, co widać, ma znaczyć to,
  /// co się dzieje.
  Hotspot regenerated(Duration elapsed, {GeoPoint? playerAt}) {
    if (isResting || elapsed <= Duration.zero) return this;
    if (playerAt != null && covers(playerAt)) return this;

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
    DateTime? surgedAt,
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
    surgedAt: surgedAt ?? this.surgedAt,
  );
}

/// §6.5.1: somewhere to put a new one, or null if there is nowhere.
///
/// ⚠️ **Rejection sampling rather than arithmetic**, and deliberately. The
/// constraints are a ring around the shelter, a minimum distance from every
/// other centre, and §3.5's exclusions — which are polygons, not circles.
/// Solving that in closed form would be a geometry library; drawing points and
/// throwing away the ones that fail is twenty lines and obviously correct.
///
/// Null rather than a forced placement when nothing fits. A hotspot on a
/// motorway or in a hospital car park is worse than one hotspot fewer: §3.5's
/// exclusions exist because this game sends real people to real places.
GeoPoint? placeHotspot({
  required GeoPoint shelterAt,
  required List<GeoPoint> taken,
  required Random random,
  bool Function(GeoPoint at)? allows,
  int attempts = 60,
}) {
  for (var attempt = 0; attempt < attempts; attempt++) {
    final bearing = random.nextDouble() * 2 * pi;

    // ⚠️ Square-rooted, so the points are spread evenly over the *ring* rather
    // than bunched against its inner edge. A uniform radius puts half of them
    // in the first third of the area.
    final inner = kHotspotMinFromShelterM * kHotspotMinFromShelterM;
    final outer = kHotspotMaxFromShelterM * kHotspotMaxFromShelterM;
    final metres = sqrt(inner + random.nextDouble() * (outer - inner));

    final at = shelterAt.offsetBy(
      metres: metres,
      bearingDeg: bearing * 180 / pi,
    );

    if (taken.any((other) => other.distanceTo(at) < kHotspotMinApartM)) {
      continue;
    }
    if (allows != null && !allows(at)) continue;

    return at;
  }

  return null;
}

/// §6.5.3: everything that has happened to this slot since [from].
///
/// ⚠️ **Settled on read, never by a timer.** A hotspot grows on the clock and
/// the clock runs with the app shut (§6.5.3) — so coming back after two days
/// has to produce the same hotspot as playing through them. Promotions are
/// applied one at a time rather than in a lump, because each one draws its own
/// interval from [nextPromotionIn] and a single jump would lose the jitter.
///
/// [habit] is §16.4's measured pace: the world grows at the rate this player
/// actually plays at, not at wall-clock speed.
Hotspot settleHotspot(
  Hotspot spot, {
  required DateTime now,
  required Random random,
  required PlayHabit habit,
  GeoPoint? shelterAt,
  bool Function(GeoPoint at)? allows,
}) {
  var current = spot;

  // The rest is over: somewhere else, level one.
  final resting = current.restingUntil;
  if (current.isResting) {
    if (resting == null || now.isBefore(resting)) return current;
    if (shelterAt == null) return current;

    final where = placeHotspot(
      shelterAt: shelterAt,
      taken: const [],
      random: random,
      allows: allows,
    );
    if (where == null) return current;

    return current.reborn(
      centre: where,
      seed: random.nextInt(1 << 30),
      at: resting,
      until: promotionDelay(survivalDay: 1, habit: habit, random: random),
    );
  }

  // ⚠️ Bounded. A save from a fortnight ago must not turn into a loop that
  // runs ten thousand times — and cannot legitimately need more than the nine
  // promotions there are.
  for (var step = 0; step < 12; step++) {
    if (current.level >= kHotspotLevels.length) break;
    if (now.isBefore(current.nextLevelAt)) break;

    final at = current.nextLevelAt;
    current = current.promoted(
      at: at,
      until: promotionDelay(
        survivalDay: at.difference(current.bornAt).inDays + 1,
        habit: habit,
        random: random,
      ),
    );
  }

  return current;
}

/// §6.5.4: co się dzieje, kiedy ktoś zacznie zbijać strefę.
///
/// ⚠️ **Dziesięć procent, i nie częściej niż raz na godzinę.** Strefa, która
/// odpowiada na każdy cios, jest ścianą; strefa, która nie odpowiada nigdy,
/// jest workiem treningowym. Rzut przy każdym trafieniu z blokadą godziny daje
/// trzecią rzecz: wejście do środka jest zakładem, a nie rachunkiem, i przegrać
/// go można raz na wyprawę, nie co minutę.
///
/// Blokada jest na dysku (`surgedAt`), bo inaczej zdejmowałoby się ją
/// restartem — a to jest kara za wejście do strefy, nie za granie bez przerwy.
const double kSurgeChance = 0.10;
const Duration kSurgeCooldown = Duration(minutes: 60);

/// Ile ich wychodzi z wysypu, ponad limit.
///
/// Połowa limitu poziomu, w górę: na piątce trzech, na dziesiątce sześciu. Nie
/// tyle, żeby to była śmierć, i dość, żeby przestać liczyć na to, że wiadomo,
/// ilu ich jest.
const double kSurgeShare = 0.5;

/// §6.5.4, §10.3: co zostaje po zbitej strefie.
///
/// ⚠️ **Bo dotąd nie zostawało nic.** Zbicie strefy do zera to dwie godziny
/// ciągłej walki przeciw rosnącemu oporowi — i jedyną nagrodą był spokój,
/// czyli brak czegoś. Skrytka jest tym, po co się tam w ogóle idzie: rzeczy z
/// górnej półki, których nie ma w żadnym mieszkaniu.
///
/// Lista, nie tabela lootu, bo to nie jest miejsce na mapie — to jest wynik.
/// I celowo krótka: cztery rzeczy, które zmieniają wyprawę, zamiast dwudziestu,
/// które zmieniają liczbę w plecaku.
const Map<String, (int, int)> kZoneCache = {
  'mat_component': (4, 8),
  'mat_metal': (10, 18),
  'med_first_aid_kit': (1, 2),
  'ammo_545x39': (30, 60),
};
