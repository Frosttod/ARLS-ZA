/// What happened while nobody was playing (§16.3, §2.1).
///
/// §2.1 describes the catch-up tick as arithmetic and stops there. From the
/// player's side it is not arithmetic: they open the app after a night's sleep
/// or a day at work and everything has moved — water down a third, a Decay
/// Zone a level higher, and no account of any of it. §16.3 names that the most
/// common moment somebody stops playing, which is a strong claim and a
/// believable one, because the alternative reading of an unexplained change is
/// "the game lost my progress".
///
/// So: one page, once, saying what the hours cost.
///
/// ⚠️ **Only what is genuinely known.** Hordes (§6.5.5) are post-MVP and do
/// not exist, so the screen does not mention them — a summary that lists a
/// thing the game cannot compute is a summary the player learns to distrust.
/// Blows taken with the screen off (§5.5.3) keep their own line under the HUD
/// rather than being repeated here.
///
/// Pure and Flutter-free.
library;

import '../sim/tick.dart';

/// Below this, the catch-up is not worth a page of its own.
///
/// ⚠️ Six hours rather than the "three days" §16.3 imagines, and rather than
/// the twenty minutes it would be tempting to use. Two hours of absence costs
/// about eight per cent of a day's water — inside the noise of a bar somebody
/// glances at. Six is a night or a working day: the first gap where a player
/// opening the app finds a *different* character rather than the one they put
/// down.
const Duration kAwayWorthTelling = Duration(hours: 6);

/// Holds the state the app was left in until the catch-up has run.
///
/// ⚠️ **Two moments, and they are not the same one.** Resuming is when the
/// old state can still be read; the hours are charged by the first tick after
/// it. Asking at the wrong moment compares a state with itself and reports an
/// absence that cost nothing — which is exactly what the first version of this
/// did.
class AwayWatch {
  ({SimState state, List<int> zones})? _left;

  /// Called as the app goes back to the foreground, before the catch-up.
  void left({required SimState state, required List<int> zones}) {
    _left = (state: state, zones: zones);
  }

  /// The account, once [now] is genuinely later than what was put down.
  ///
  /// Returns null while there is nothing to compare, and clears itself as soon
  /// as it answers: one absence is worth one page.
  AwaySummary? caughtUp(SimState now, List<int> zones) {
    final left = _left;
    if (left == null || !now.lastUpdate.isAfter(left.state.lastUpdate)) {
      return null;
    }

    _left = null;
    return AwaySummary.between(
      before: left.state,
      after: now,
      zonesBefore: left.zones,
      zonesAfter: zones,
    );
  }
}

/// The account of one absence.
class AwaySummary {
  const AwaySummary({
    required this.away,
    required this.waterLostMl,
    required this.kcalLost,
    required this.sleepOwed,
    required this.zonesGrown,
    required this.highestZone,
  });

  /// Works out the difference the catch-up made.
  ///
  /// [before] is the state as it stood when the app went away; [after] is the
  /// same character once the missing hours have been charged. Both come from
  /// the loop, so nothing here re-derives physiology — this is subtraction,
  /// and it stays subtraction.
  factory AwaySummary.between({
    required SimState before,
    required SimState after,
    List<int> zonesBefore = const [],
    List<int> zonesAfter = const [],
  }) {
    final grown = <int>[];
    for (var index = 0; index < zonesAfter.length; index++) {
      final was = index < zonesBefore.length ? zonesBefore[index] : 0;
      if (zonesAfter[index] > was) grown.add(zonesAfter[index]);
    }

    return AwaySummary(
      away: after.lastUpdate.difference(before.lastUpdate),
      // ⚠️ Losses only. A player who drank before closing the app comes back
      // with *more* water than they left, and "water: +200 ml" on a page
      // about an absence reads as the game giving something away.
      waterLostMl: _dropped(before.waterMl, after.waterMl),
      kcalLost: _dropped(before.caloriesKcal, after.caloriesKcal),
      sleepOwed: after.sleepDebt - before.sleepDebt,
      zonesGrown: grown.length,
      highestZone: grown.isEmpty ? 0 : grown.reduce((a, b) => a > b ? a : b),
    );
  }

  final Duration away;
  final double waterLostMl;
  final double kcalLost;

  /// How much more sleep is owed than when the app was closed. Can be
  /// negative — a night in a shelter pays the debt down while nobody watches.
  final Duration sleepOwed;

  final int zonesGrown;

  /// The level the worst of them reached, or 0 if none grew.
  final int highestZone;

  /// Whether this absence is worth a page.
  ///
  /// Long enough to have changed something, and something must actually have
  /// changed: a character asleep in a shelter for eight hours has lost almost
  /// nothing, and telling them so is a dialog between them and the game they
  /// wanted to open.
  bool get worthShowing =>
      away >= kAwayWorthTelling &&
      (waterLostMl >= 100 || kcalLost >= 100 || zonesGrown > 0);

  static double _dropped(double before, double after) =>
      before > after ? before - after : 0;
}
