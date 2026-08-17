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
import 'obstacle.dart';

/// §10.2.1: moving further than this cancels reconnaissance.
///
/// The doc's eight metres is the position filter's dead zone (§3.2), and on
/// paper matching it means the game agrees with the receiver about what
/// standing still is. On a street it does not: measured on a real walk in
/// Poznań, shifting weight between two feet between buildings was enough to
/// cancel a search. Fifteen metres is still far short of a step taken with
/// intent — a walking pace covers it in eleven seconds — and it is what stops
/// the mechanic from feeling broken.
const double kStillnessM = 15;

/// How many readings in a row must fall outside [kStillnessM] before a search
/// is abandoned.
///
/// One stray fix is a stray fix. Cancelling forty-five seconds of a player's
/// time on a single outlier is the kind of unfairness nobody reports as a bug —
/// they just stop using the feature.
const int kStillnessStrikes = 2;

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
    this.breach,
    this.usingItemId,
    this.usingLabel,
    this.strikes = 0,
  });

  /// Reconnaissance: forty-five seconds where the player is standing.
  factory Search.area({required GeoPoint at, required DateTime now}) =>
      Search(anchor: at, startedAt: now, requiredTime: kAreaSearchTime);

  /// §19.3: getting through what shuts a place.
  ///
  /// A search like any other, because it costs the same thing — time standing
  /// where somebody can hear you.
  factory Search.breach({
    required GeoPoint at,
    required DateTime now,
    required String poiId,
    required BarrierBreach breach,
  }) => Search(
    anchor: at,
    startedAt: now,
    requiredTime: Duration(seconds: breach.seconds),
    targetPoiId: poiId,
    breach: breach,
  );

  /// §4.7: using something, which costs the time the item's own data says.
  ///
  /// Here rather than in a class of its own because it is the same thing from
  /// the player's side — a bar, a countdown, and one way out — and two timers
  /// with two ways of being cancelled is how they end up disagreeing.
  ///
  /// Stillness is not required: somebody can eat while walking, and §10.2's
  /// eight-metre rule exists for reconnaissance rather than for a sandwich.
  factory Search.using({
    required GeoPoint at,
    required DateTime now,
    required String itemId,
    required Duration duration,
    required String label,
  }) => Search(
    anchor: at,
    startedAt: now,
    requiredTime: duration,
    usingItemId: itemId,
    usingLabel: label,
  );

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

  /// The way in being made, for a breach. Null for anything else.
  final BarrierBreach? breach;

  bool get isBreach => breach != null;

  /// What is being used (§4.7), and what to call it while it happens.
  final String? usingItemId;
  final String? usingLabel;

  bool get isUse => usingItemId != null;

  /// How far this is heard (§5.6.1). Forcing a door carries 150 m; a search
  /// carries 80; standing still and looking around carries nothing at all.
  double get noiseM =>
      breach?.noiseM ?? (isArea ? 0 : kSearchNoiseM);

  /// Consecutive readings that fell outside the circle. Reset by any reading
  /// inside it, so a wander out and back does not accumulate.
  final int strikes;

  bool get isArea =>
      targetPoiId == null && breach == null && usingItemId == null;
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
  ///
  /// ⚠️ **Using something is exempt from both rules, position included.**
  /// Found on a phone: a bandage started in a stairwell was lost along with
  /// the wound it was for, because the signal went. Eating, drinking and first
  /// aid are things a body does, not things the GPS witnesses — they ask no
  /// question about where anybody stood, so there is nothing for a lost
  /// position to invalidate. §2.1a.3 asks for presence for *field* work, and
  /// swallowing is not field work. Anything else — searching, breaking in —
  /// keeps both rules.
  Search advance(Duration delta, {required GeoPoint? at, bool present = true}) {
    if (!isRunning) return this;

    if (!isUse && (!present || at == null)) {
      return _endedAs(SearchState.lostPresence);
    }
    // Using something is not searching: a person can drink while walking.
    if (!isUse && at!.distanceTo(anchor) > kStillnessM) {
      final missed = strikes + 1;
      return missed >= kStillnessStrikes
          ? _endedAs(SearchState.cancelledByMovement)
          // The clock keeps running through a single stray fix. A player who
          // really walked off will produce another one a second later.
          : _copy(elapsed: elapsed + delta, strikes: missed);
    }

    final next = elapsed + delta;
    if (next >= requiredTime) {
      return _copy(elapsed: requiredTime, state: SearchState.done, strikes: 0);
    }
    return _copy(elapsed: next, strikes: 0);
  }

  Search cancel() => isRunning ? _endedAs(SearchState.cancelled) : this;

  Search _endedAs(SearchState state) => _copy(state: state);

  Search _copy({Duration? elapsed, SearchState? state, int? strikes}) => Search(
    anchor: anchor,
    startedAt: startedAt,
    requiredTime: requiredTime,
    elapsed: elapsed ?? this.elapsed,
    state: state ?? this.state,
    targetPoiId: targetPoiId,
    depth: depth,
    breach: breach,
    usingItemId: usingItemId,
    usingLabel: usingLabel,
    strikes: strikes ?? this.strikes,
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
