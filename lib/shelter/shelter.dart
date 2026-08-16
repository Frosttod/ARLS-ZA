/// The place you come back to (§8).
///
/// One main shelter, where the player lives, and up to two camps for the
/// places they spend the rest of their day — work, a lecture hall, a
/// relative's flat. §8.5.3 argues that this is the whole answer to a game
/// played by an adult with a job: eight hours a day happen somewhere that is
/// not home, and without a camp those eight hours are nothing at all.
///
/// ⚠️ **The safe radius and the no-fire radius are the same number.** §8.1
/// says so in bold, because two different numbers make a ring where the enemy
/// can reach the player and the player cannot answer — which punishes standing
/// near your own door.
///
/// The coordinates of a main shelter are, in practice, the player's home
/// address (§8.2). They are written to the local database and nowhere else,
/// they never leave the phone, and the record is excluded from Android backup.
library;

import '../map/geometry.dart';

/// §8.3: what barricading a building actually takes, one person, no tools.
///
/// Doors, four windows, and clearing the inside — the table in §8.3 adds up to
/// three hours, and it is meant to be spent doing something else. Building
/// runs in the background against the clock (§2.1a.3), so this is a time to
/// come back to, not a bar to watch.
const Duration kShelterBuildTime = Duration(hours: 3);

/// §8.5.1: a camp is one afternoon, not one day.
const Duration kCampBuildTime = Duration(minutes: 40);

/// §8.3: a hammer and an axe take a third of the work out of it.
const double kToolBuildDiscount = 0.35;

/// §8.3: and Engineering at 100% takes another 30% off what is left.
const double kEngineeringBuildDiscount = 0.30;

/// §8.5.2: how many camps at once. Two, so choosing them is a decision.
const int kMaxCamps = 2;

/// §8.5.2: a camp next door to the shelter would just be a second shelter.
const double kCampSpacingM = 800;

/// §8.5.2: and one inside a hotspot would be a camp nobody can reach.
const double kCampFromHotspotM = 400;

/// §8.5.2: unvisited this long and it starts coming apart.
const Duration kCampDecayAfter = Duration(days: 14);

/// §8.5.2: and this long and it is gone, with whatever was in the chest.
const Duration kCampGoneAfter = Duration(days: 21);

/// What kind of place it is, and everything that follows from that (§8.5.1).
enum ShelterKind {
  /// §8.1: fifty metres, full sleep, modules, the lot. There is one.
  main(
    safeRadiusM: 50,
    buildTime: kShelterBuildTime,
    sleepQuality: 1,
    storageKg: 25,
    modular: true,
  ),

  /// §8.5.1: twenty metres, a chest, and sleep worth seven tenths of a night.
  camp(
    safeRadiusM: 20,
    buildTime: kCampBuildTime,
    sleepQuality: 0.70,
    storageKg: 30,
    modular: false,
  );

  const ShelterKind({
    required this.safeRadiusM,
    required this.buildTime,
    required this.sleepQuality,
    required this.storageKg,
    required this.modular,
  });

  /// §8.1: enemies do not come inside this, and the player does not shoot out
  /// of it. One number for both, deliberately.
  final double safeRadiusM;

  final Duration buildTime;

  /// §8.5.1: how much of a night's sleep an hour here is worth.
  final double sleepQuality;

  /// §18.2: what it holds before any module, in kilograms.
  final double storageKg;

  final bool modular;
}

/// §8.4: what can be built onto a main shelter, three levels each.
enum ShelterModule {
  /// §18.2: fifty kilograms a level, on top of the base twenty-five.
  storage,

  /// §8.4: repair, then complex recipes, then repair to new. Rebuilt from the
  /// document's own proposal — the original 3%-a-level version is one nobody
  /// would ever pay for, and the note in §8.4 says as much.
  workshop,

  /// §8.4: fifteen per cent off what a night of sleep has to cover, which in
  /// practice is an hour of the night given back for reading.
  lounge,

  /// §8.4: three per cent more out of every meal and every bottle.
  laboratory;

  static const maxLevel = 3;
}

/// How long this place takes to put up, with what is to hand (§8.3).
///
/// Tools first, then skill, multiplied rather than added: a third off three
/// hours is an hour, and thirty per cent of what is left is not the same as
/// thirty per cent of the whole. §8.3's own floor of about an hour and twenty
/// minutes falls out of the two of them together, so there is no separate
/// clamp pretending to be a rule.
Duration buildTimeFor(
  ShelterKind kind, {
  bool hasTools = false,
  double engineering = 0,
}) {
  final tools = hasTools ? 1 - kToolBuildDiscount : 1.0;
  final skill =
      1 - kEngineeringBuildDiscount * engineering.clamp(0.0, 1.0);

  return Duration(
    milliseconds: (kind.buildTime.inMilliseconds * tools * skill).round(),
  );
}

/// A shelter or a camp, built or being built.
class Shelter {
  const Shelter({
    required this.id,
    required this.kind,
    required this.position,
    required this.startedAt,
    required this.buildTime,
    this.modules = const {},
    this.visitedAt,
    this.building,
    this.buildingLevel = 0,
    this.buildingReadyAt,
  });

  final int id;
  final ShelterKind kind;
  final GeoPoint position;

  /// When the work began. Building runs against the clock rather than against
  /// screen time (§2.1a.3): three hours of watching a progress bar is not
  /// gameplay, and the phone is usually in a pocket for them.
  final DateTime startedAt;

  /// What it was going to take when it was started, tools and skill included.
  /// Kept on the record rather than recomputed, so a hammer lost halfway
  /// through does not lengthen a job that is nearly done.
  final Duration buildTime;

  /// §8.4: level per module, absent meaning nought.
  final Map<ShelterModule, int> modules;

  /// §8.5.2: when the player was last inside it. Camps that nobody comes back
  /// to fall down.
  final DateTime? visitedAt;

  /// §8.4: the module going up right now, or null when none is.
  final ShelterModule? building;

  /// Which level of it.
  final int buildingLevel;

  /// §18.2: when that module is finished. Against the clock, like the shelter
  /// itself — a nine-hour workshop is not a progress bar to sit and watch.
  final DateTime? buildingReadyAt;

  DateTime get readyAt => startedAt.add(buildTime);

  /// The shelter as it will be once whatever is going up has gone up.
  ///
  /// Applied on read rather than by a timer: a module finished while the app
  /// was dead is finished all the same, and this is the only place that has to
  /// know it.
  Shelter settledAt(DateTime now) {
    final module = building;
    final ready = buildingReadyAt;
    if (module == null || ready == null || now.isBefore(ready)) return this;

    return Shelter(
      id: id,
      kind: kind,
      position: position,
      startedAt: startedAt,
      buildTime: buildTime,
      modules: {...modules, module: buildingLevel},
      visitedAt: visitedAt,
    );
  }

  bool isReadyAt(DateTime now) => !now.isBefore(readyAt);

  /// 0–1, for the one bar worth drawing.
  double progressAt(DateTime now) {
    if (buildTime <= Duration.zero) return 1;

    final done = now.difference(startedAt).inMilliseconds;
    return (done / buildTime.inMilliseconds).clamp(0.0, 1.0);
  }

  int levelOf(ShelterModule module) => modules[module] ?? 0;

  /// §8.1: whether the player is standing inside the safe radius.
  ///
  /// Only once it is finished. A half-barricaded building keeps nothing out,
  /// and a safe zone that starts the moment the first nail goes in would make
  /// the three hours free.
  bool coversAt(GeoPoint at, DateTime now) =>
      isReadyAt(now) && position.distanceTo(at) <= kind.safeRadiusM;

  /// §18.2, §8.4: what it holds, in kilograms.
  double get storageKg =>
      kind.storageKg + 50 * levelOf(ShelterModule.storage).toDouble();

  /// §18.1a: bulk runs out before mass does, at three litres to the kilogram.
  double get storageL => storageKg * 3;

  /// §2.5.3, §8.4, §8.5.1: what an hour of night in here is worth.
  ///
  /// A camp gives seven tenths of a night; the Lounge gives back fifteen per
  /// cent a level of what the night has to cover. §2.5.4 explains why that is
  /// worth building: fewer hours asleep is more hours awake with a book.
  double get sleepRate =>
      kind.sleepQuality * (1 + 0.15 * levelOf(ShelterModule.lounge));

  /// §8.4: three per cent a level out of everything eaten and drunk.
  double get nutritionRate => 1 + 0.03 * levelOf(ShelterModule.laboratory);

  /// §8.4: the best condition this workshop can bring something back to.
  /// Nought where there is no workshop — a repair nobody can make.
  double get repairCeiling => switch (levelOf(ShelterModule.workshop)) {
    0 => 0,
    1 => 0.60,
    2 => 0.85,
    _ => 1.0,
  };

  /// §8.5.2: falling down, but still there.
  bool isDecayingAt(DateTime now) =>
      kind == ShelterKind.camp &&
      visitedAt != null &&
      now.difference(visitedAt!) >= kCampDecayAfter;

  /// §8.5.2: gone, with whatever was in the chest.
  bool isLostAt(DateTime now) =>
      kind == ShelterKind.camp &&
      visitedAt != null &&
      now.difference(visitedAt!) >= kCampGoneAfter;

  Shelter copyWith({
    Map<ShelterModule, int>? modules,
    DateTime? visitedAt,
    GeoPoint? position,
    DateTime? startedAt,
    Duration? buildTime,
  }) => Shelter(
    id: id,
    kind: kind,
    position: position ?? this.position,
    startedAt: startedAt ?? this.startedAt,
    buildTime: buildTime ?? this.buildTime,
    modules: modules ?? this.modules,
    visitedAt: visitedAt ?? this.visitedAt,
    building: building,
    buildingLevel: buildingLevel,
    buildingReadyAt: buildingReadyAt,
  );
}

/// Why a camp cannot go here (§8.5.2), or null when it can.
enum CampRefusal {
  /// Two is the limit, and it is the limit so that choosing is a decision.
  tooMany,

  /// Under 800 m from the shelter, which would make it a second front door.
  tooCloseToShelter,

  /// Under 800 m from the other camp.
  tooCloseToCamp,

  /// Under 400 m from the middle of a hotspot: a camp nobody can walk into.
  tooCloseToHotspot,
}

/// Whether a camp can be put up here, and if not, why not (§8.5.2).
CampRefusal? campRefusalAt(
  GeoPoint at, {
  required List<Shelter> existing,
  List<GeoPoint> hotspots = const [],
}) {
  final camps = [
    for (final place in existing)
      if (place.kind == ShelterKind.camp) place,
  ];
  if (camps.length >= kMaxCamps) return CampRefusal.tooMany;

  for (final place in existing) {
    if (place.position.distanceTo(at) >= kCampSpacingM) continue;
    return place.kind == ShelterKind.main
        ? CampRefusal.tooCloseToShelter
        : CampRefusal.tooCloseToCamp;
  }

  for (final hotspot in hotspots) {
    if (hotspot.distanceTo(at) < kCampFromHotspotM) {
      return CampRefusal.tooCloseToHotspot;
    }
  }
  return null;
}

/// The place the player is standing in, or null for the open (§2.1, §8.1).
///
/// The main shelter wins a tie, which it can only do if a camp was somehow put
/// up inside it: it is the better zone on every axis, so preferring it can
/// never cost the player anything.
Shelter? shelterAt(
  GeoPoint at,
  List<Shelter> shelters, {
  required DateTime now,
}) {
  Shelter? found;
  for (final place in shelters) {
    if (!place.coversAt(at, now)) continue;
    if (found == null || place.kind == ShelterKind.main) found = place;
  }
  return found;
}
