/// How much this player actually plays, and what the world does about it
/// (§6.5.3, §16.4).
///
/// §6.5.3 grows hotspots on a clock that runs whether or not anybody is
/// playing: a hundred per cent of active time and twenty-five of idle. Worked
/// through, that clock is almost entirely the calendar — someone playing two
/// hours a day reaches three level-ten hotspots in 8.2 days and someone who
/// never opens the app reaches them in 9.9. The pressure is built by the
/// calendar, and what the player does barely moves it.
///
/// That is wrong in both directions. A player with twenty minutes a day is
/// handed a world they cannot answer; a player with three hours is handed one
/// that never quite catches up with them. §16.4 asks the question outright —
/// can somebody with an hour a day keep up — and the honest answer is to
/// measure the hour rather than assume it.
///
/// **The rule: an hour played moves the world more than an hour away from it,
/// and an hour away still moves it.** Play is weighted several times over,
/// and under that sits a small floor that runs whatever anybody does — so a
/// fortnight's absence costs something without handing back three level-ten
/// hotspots, which is the outcome §6.5.3 says in as many words that it does
/// not want.
///
/// An inverse rule was tried first — more idle credit for the light player,
/// less for the heavy one — and it made the world of somebody with twenty
/// minutes a day run *twice as fast* as the world of somebody with an hour.
/// Compensating for a small habit turns into punishing it.
library;

/// The habit the pace is measured against: §16.4's own figure.
const double kReferencePlayHours = 1;

/// Never less than this, so a first session does not divide by nothing.
const double kMinPlayHours = 0.25;

/// How much an hour of playing is worth against an hour of the world sitting
/// there. Above one, because the pressure exists to be met.
const double kPlayWeight = 3.5;

/// What the world does with nobody in it, per hour. Small, and never zero:
/// §6.5.3 is explicit that a city spoils while nobody is looking.
const double kIdleFloor = 0.10;

/// Credited hours a day are held between these, so no habit turns the game
/// into a different one.
const double kCreditedMin = 2;
const double kCreditedMax = 16;

/// One day of playing, as the game measures it.
class PlayDay {
  const PlayDay({required this.day, required this.activeMinutes});

  /// Local calendar day. The unit a habit is actually formed in.
  final DateTime day;

  /// Minutes with the game actually running and tracking (§2.1a's active
  /// state), not minutes with the app installed.
  final int activeMinutes;
}

/// What the last week says about somebody (§16.4).
class PlayHabit {
  const PlayHabit(this.days);

  /// Most recent first. A week is long enough to survive one bad Tuesday and
  /// short enough to follow somebody whose life changed.
  final List<PlayDay> days;

  static const int window = 7;

  /// Mean hours a day over the window, never below [kMinPlayHours].
  ///
  /// Days with nothing in them count as zeros rather than being skipped: a
  /// week with one three-hour Saturday is not a three-hour-a-day habit.
  double get hoursPerDay {
    if (days.isEmpty) return kMinPlayHours;

    final counted = days.take(window).toList();
    var minutes = 0;
    for (final day in counted) {
      minutes += day.activeMinutes;
    }

    final hours = minutes / 60 / counted.length;
    return hours < kMinPlayHours ? kMinPlayHours : hours;
  }

  /// Hours of §6.5.3 credit this player earns in a real day.
  ///
  /// Their own play, weighted, plus the floor the world runs at regardless.
  /// Clamped so that neither a marathon nor a fortnight off turns this into a
  /// different game.
  double get creditedHoursPerDay {
    final played = days.isEmpty ? 0.0 : hoursPerDay;
    final credited = played * kPlayWeight + (24 - played) * kIdleFloor;

    if (credited < kCreditedMin) return kCreditedMin;
    if (credited > kCreditedMax) return kCreditedMax;
    return credited;
  }
}

/// §6.5.3's interval, unchanged: eight hours falling to a floor of two.
///
/// The adaptation is in what counts towards it, not in the figure itself —
/// a rule that shortened the interval for playing would be a treadmill, and
/// one that lengthened it would be a game that rewards not playing.
double promotionIntervalHours(int survivalDay) {
  final hours = 8 - 0.25 * survivalDay;
  return hours < 2 ? 2 : hours;
}

/// Real days to take a hotspot from level one to ten, for this habit.
///
/// The number §16.4 actually asks for, and the one to look at before changing
/// any of the constants above.
double daysToMaxLevel(PlayHabit habit, {int promotions = 9}) {
  final credited = habit.creditedHoursPerDay;
  if (credited <= 0) return double.infinity;

  var realHours = 0.0;
  for (var i = 0; i < promotions; i++) {
    final day = 1 + realHours / 24;
    realHours += promotionIntervalHours(day.floor()) / (credited / 24);
  }

  return realHours / 24;
}
