/// Waking up somewhere else (§16.6, §19.1).
///
/// A player finishes a session in Poznań, takes a night train, and opens the
/// game in Kraków. The app was shut the whole time, so from the simulation's
/// point of view eight offline hours passed and nothing else — the anti-cheat
/// of §3.4 never sees a fix to compute a speed from, the filter of §3.2 starts
/// clean, and the 500 km is never credited as distance walked. All of that is
/// already true and there are tests that keep it true.
///
/// What changes is the *place*, and the whole rest of the game stands on that:
/// the map, the POI of §10, the shelter of §8. So this decides one thing —
/// whether the player has moved somewhere the game has to talk about.
///
/// **The threshold is there to explain, not to measure.** Twenty-five
/// kilometres is far past a walk between two sessions and far short of any
/// journey worth mentioning. Being over-eager costs the player one sentence;
/// being too blunt leaves them looking at a blank screen with no reason given.
library;

import '../map/geometry.dart';

/// What the game found when the session opened.
enum RelocationVerdict {
  /// Same place, near enough. Nothing to say.
  none,

  /// Somewhere else, and the map they have covers it. The game carries on and
  /// mentions it once.
  covered,

  /// Somewhere else, and there is no map for it. Nothing can be drawn and §10
  /// has nowhere to put anything, so the player is sent to the region screen.
  uncovered,
}

class Relocation {
  const Relocation({required this.verdict, required this.distanceM});

  static const Relocation none = Relocation(
    verdict: RelocationVerdict.none,
    distanceM: 0,
  );

  final RelocationVerdict verdict;

  /// How far from where the last session ended. Shown to the player rounded to
  /// kilometres — it is the one concrete thing the game can say without asking
  /// a network what the place is called.
  final double distanceM;

  bool get happened => verdict != RelocationVerdict.none;

  int get kilometres => (distanceM / 1000).round();
}

/// Twenty-five kilometres. See the library note for why this number is not a
/// measurement.
const double kRelocationThresholdM = 25000;

/// Decides whether the session opened somewhere else.
///
/// [lastKnown] is the position the previous session wrote down; null on a first
/// run, when there is nothing to have moved from. [trusted] must already have
/// passed the accuracy gate and the mock check of §3.2 — a wild fix or a
/// spoofed one is not a journey.
Relocation detectRelocation({
  required GeoPoint? lastKnown,
  required GeoPoint? trusted,
  required bool mapCoversHere,
  double thresholdM = kRelocationThresholdM,
}) {
  if (lastKnown == null || trusted == null) return Relocation.none;

  final distance = lastKnown.distanceTo(trusted);
  if (distance < thresholdM) return Relocation.none;

  return Relocation(
    verdict: mapCoversHere
        ? RelocationVerdict.covered
        : RelocationVerdict.uncovered,
    distanceM: distance,
  );
}
