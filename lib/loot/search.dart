/// Searching, which is the only way anything gets picked up (§10.2, §19.3).
///
/// Two kinds, and they cost the same currency: time standing still.
///
/// **Reconnaissance** (§10.2) is forty-five seconds of stillness that reveals
/// what is around — the state of the places already visible, the procedural
/// points that are not, and eventually the enemies. §10.2.1 refuses it a
/// cooldown on purpose: a timer that costs nothing is not a decision, it is an
/// alarm clock teaching the player to watch a screen instead of walking.
/// Forty-five seconds is sixty metres not covered, and that is the cost.
///
/// **Searching an object** (§19.3) is thirty, ninety or a hundred and eighty
/// seconds, and the player chooses which. Longer reaches deeper into the table
/// (§10.3.5) and makes eighty metres of noise the whole time (§5.6). Take a
/// little and leave, or risk the three minutes.
///
/// Both obey the presence rule of §2.1a: they tick only while the app is open
/// and the position is trusted. A search that continued in a pocket would be a
/// search the player did not make.
library;

import '../map/geometry.dart';
import 'loot_table.dart';

/// §10.2.1: moving further than this cancels reconnaissance.
///
/// Eight metres is the same dead zone the position filter uses (§3.2), so
/// standing still in the game means exactly what standing still means to the
/// GPS, and a player is never cancelled by scatter.
const double kStillnessM = 8;

/// §10.2.1.
const Duration kAreaSearchTime = Duration(seconds: 45);

/// §10.2.1: repeating a search here tells you nothing new until this has
/// passed. Not a cooldown — the search still runs, it just has nothing to add.
const Duration kAreaSearchMemory = Duration(minutes: 10);

/// §10.2.2, at Reconnaissance 0 with no binoculars in daylight.
const double kBaseSearchRadiusM = 100;

/// §19.3, §5.6: how far a search is heard.
const double kSearchNoiseM = 80;

/// How close the player has to be to search a place.
///
/// A lootbox sits on a position the map gave it, which is a building's centre
/// as often as its door. Twenty-five metres is the slack that makes standing
/// "at" a supermarket mean what a player thinks it means.
const double kSearchReachM = 25;

/// The radius reconnaissance covers (§10.2.2).
///
/// Written as the doc writes it, factor by factor, because each one is somebody
/// else's system: the skill is §7, the binoculars are an item, darkness is
/// §17.4 and the weather is §17.7. The spread is deliberate — §10.2.2 warns
/// that going from 100 m to 300 m on a single item would multiply the searched
/// area ninefold and make the game feel broken until it was found.
double searchRadiusM({
  double scouting = 0,
  bool binoculars = false,
  double darkness = 0,
  double weather = 1,
}) =>
    kBaseSearchRadiusM *
    (1 + 1.0 * scouting) *
    (binoculars ? 1.5 : 1.0) *
    (1 - 0.5 * darkness) *
    weather;

/// What a search is doing right now.
enum SearchState {
  running,

  /// §10.2.1: the player moved. Not a failure — a decision they made with
  /// their legs.
  cancelledByMovement,

  /// The player stopped it, or something else did.
  cancelled,

  /// §2.1a: the app went away, or the position stopped being trusted.
  lostPresence,

  done,
}

/// One search in progress: either kind.
///
/// A value rather than a running timer. The game loop advances it with the
/// clock it already has, so a search behaves the same whether the frame rate is
/// sixty or one — and so a test can run three minutes in a microsecond.
class Search {
  const Search({
    required this.anchor,
    required this.startedAt,
    required this.requiredTime,
    this.elapsed = Duration.zero,
    this.state = SearchState.running,
    this.targetPoiId,
    this.depth,
  });

  /// Reconnaissance: forty-five seconds where the player is standing.
  factory Search.area({required GeoPoint at, required DateTime now}) =>
      Search(anchor: at, startedAt: now, requiredTime: kAreaSearchTime);

  /// §19.3: a place, and how thoroughly.
  factory Search.object({
    required GeoPoint at,
    required DateTime now,
    required String poiId,
    required SearchDepth depth,
  }) => Search(
    anchor: at,
    startedAt: now,
    requiredTime: Duration(seconds: depth.seconds),
    targetPoiId: poiId,
    depth: depth,
  );

  /// Where the player was when it started. Everything is measured from here.
  final GeoPoint anchor;

  final DateTime startedAt;
  final Duration requiredTime;
  final Duration elapsed;
  final SearchState state;

  /// The box being searched, or null for reconnaissance.
  final String? targetPoiId;

  /// How deep, for an object search. Null for reconnaissance.
  final SearchDepth? depth;

  bool get isArea => targetPoiId == null;
  bool get isRunning => state == SearchState.running;

  Duration get remaining {
    final left = requiredTime - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  double get progress => requiredTime.inMicroseconds <= 0
      ? 1
      : (elapsed.inMicroseconds / requiredTime.inMicroseconds).clamp(0.0, 1.0);

  /// Advances by [delta].
  ///
  /// [at] is where the player is now, and null means the position is not
  /// trusted — which ends the search, because §2.1a will not let one run on a
  /// position the game is guessing at.
  Search advance(Duration delta, {required GeoPoint? at, bool present = true}) {
    if (!isRunning) return this;

    if (!present || at == null) {
      return _endedAs(SearchState.lostPresence);
    }
    if (at.distanceTo(anchor) > kStillnessM) {
      return _endedAs(SearchState.cancelledByMovement);
    }

    final next = elapsed + delta;
    if (next >= requiredTime) {
      return _copy(elapsed: requiredTime, state: SearchState.done);
    }
    return _copy(elapsed: next);
  }

  Search cancel() => isRunning ? _endedAs(SearchState.cancelled) : this;

  Search _endedAs(SearchState state) => _copy(state: state);

  Search _copy({Duration? elapsed, SearchState? state}) => Search(
    anchor: anchor,
    startedAt: startedAt,
    requiredTime: requiredTime,
    elapsed: elapsed ?? this.elapsed,
    state: state ?? this.state,
    targetPoiId: targetPoiId,
    depth: depth,
  );
}

/// What reconnaissance revealed, and where it was done.
///
/// Kept so §10.2.1's rule can be honoured: searching the same spot again is
/// allowed, and tells the player nothing new for ten minutes.
class AreaKnowledge {
  const AreaKnowledge({
    required this.at,
    required this.radiusM,
    required this.completedAt,
    required this.revealedPoiIds,
  });

  final GeoPoint at;
  final double radiusM;
  final DateTime completedAt;

  /// The places this search made visible — the procedural ones, which §10.2.3
  /// says are invisible until somebody looks.
  final Set<String> revealedPoiIds;

  /// Whether a search here would say anything the player does not already know.
  ///
  /// The overlap test is deliberately generous: a player who walks fifty metres
  /// and looks again is looking at mostly the same ground.
  bool covers(GeoPoint point, DateTime now) =>
      now.difference(completedAt) < kAreaSearchMemory &&
      at.distanceTo(point) <= radiusM / 2;
}
