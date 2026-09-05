/// What the home-screen widget says about the body (§2, §12, §13.1).
///
/// A 4×1 widget is roughly eight words wide. That is the whole design problem:
/// the game knows two dozen things about a character and the launcher has room
/// for four bars and a line of text, so what goes in has to be decided rather
/// than trimmed at the end.
///
/// **Three bars and a pulse, because those are the three that fail slowly.**
/// Water, calories and sleep are the axes a player can act on hours ahead —
/// they are the reason to look at the widget at all instead of opening the
/// game. Blood is not here: it does not drain while nobody is playing, and a
/// bar that only moves during a fight is a bar that is always full on a home
/// screen.
///
/// **And one line of what is wrong right now.** Ordered by what would kill
/// first, capped at [kAilmentsShown], because a widget that lists everything
/// is one nobody reads — see [ailmentsOf].
///
/// Pure and Flutter-free: what is *shown* is decided here and tested under
/// `dart test`; the words and the platform channel live in `ui/`.
library;

import '../sim/physiology.dart';
import '../sim/tick.dart';

/// §5.6.1: how close counts as "something is out there" for the widget.
///
/// ⚠️ **Not a detection radius.** 150 m is the band §5.5.2 already warns in —
/// far enough that the player has a choice about it, close enough that the
/// choice is real. Anything nearer than this is a fact the widget must not sit
/// on; anything further is somebody else's problem.
const double kEnemyNearM = 150;

/// How many things can be wrong at once before the widget stops listing them.
///
/// Three fits a 4×1 at a readable size. A fourth is the one nobody reads, and
/// listing it costs the legibility of the three that matter.
const int kAilmentsShown = 3;

/// A live reading goes stale the moment the app stops running.
///
/// ⚠️ **The widget must not keep claiming an enemy is nearby.** Water and
/// sleep decay predictably and a ten-minute-old figure is still nearly true;
/// where a Walker was standing ten minutes ago is not information, it is a
/// guess dressed as one. Anything in [live] is dropped past this age.
const Duration kFreshFor = Duration(minutes: 10);

/// §2.3: five per cent of starting mass, which is where the tiers of
/// `starvationState` begin charging for it. Below that is a fortnight of
/// eating badly and costs nothing, so saying it on a home screen would be
/// crying wolf.
const double kWastingShows = 0.05;

/// §2.5.5: one whole night of shortfall, which is where `sleepStrainState`
/// begins charging. "Somebody who stayed up once is not chronically anything."
const double kSleeplessShows = 1;

/// Something the player would want to know from a home screen, in the order
/// that decides which three survive the cut.
///
/// The order is the ranking: earlier is more urgent. It is not alphabetical
/// and it is not the order the systems were written in — it is what would put
/// the character on the ground first.
enum Ailment {
  /// §2.6: losing blood now. Nothing outranks this.
  bleeding(live: true),

  /// §2.6: already lost enough for it to show.
  shock(live: true),

  /// §5.5.2: something within [kEnemyNearM].
  enemy(live: true),

  /// §2.5.4: falling asleep on your feet.
  microsleeps(live: false),

  /// §2.3: the long axis of going without food, once it costs something.
  wasting(live: false),

  /// §2.3, §2.5.4: thirst or hunger far enough gone to cost accuracy and time.
  thirsty(live: false),
  starving(live: false),

  /// §2.5.5: weeks of not sleeping enough.
  sleepless(live: false);

  const Ailment({required this.live});

  /// Whether this fact is only true while the game is actually running.
  ///
  /// A live fact is dropped once the reading is older than [kFreshFor]; the
  /// rest are still broadly true hours later, because they describe a body
  /// rather than a street.
  final bool live;
}

/// Everything wrong with this character right now, worst first.
///
/// [nearestEnemyM] is null when nothing is known about the street — with no
/// position there is no answer, and "no enemies" is not the same answer as
/// "nobody looked".
List<Ailment> ailmentsOf({
  required SimStatus status,
  required BleedTier bleeding,
  double? nearestEnemyM,
}) => [
  if (bleeding != BleedTier.none) Ailment.bleeding,
  if (status.blood.shockClass != ShockClass.none) Ailment.shock,
  if (nearestEnemyM != null && nearestEnemyM <= kEnemyNearM) Ailment.enemy,
  if (status.sleep.microsleeps) Ailment.microsleeps,
  // ⚠️ **Measured, not compared to the constant.** `StarvationState` and
  // `SleepStrainState` are classes without an `==`, so
  // `status.wasting != StarvationState.healthy` is reference inequality and is
  // *always true* — the first version of this list showed every character as
  // starving and sleepless from the first second of a run. The thresholds
  // below are the ones §2.3 and §2.5.5 already use to start charging for it:
  // five per cent of body mass, and a whole night of shortfall.
  if (status.wasting.lostFraction >= kWastingShows) Ailment.wasting,
  if (status.thirst.accuracyPenalty < 1) Ailment.thirsty,
  if (status.hunger.actionTimeMultiplier > 1) Ailment.starving,
  if (status.chronicSleep.strain >= kSleeplessShows) Ailment.sleepless,
];

/// The reading the launcher holds, as numbers rather than as words.
///
/// Percentages rather than millilitres: the widget has no room for units, and
/// the figure a player acts on from a home screen is "how close to empty", not
/// "how many millilitres". The game itself still shows both (§12).
class HomeStatus {
  const HomeStatus({
    required this.waterPct,
    required this.kcalPct,
    required this.sleepPct,
    required this.bpm,
    required this.ailments,
    required this.at,
  });

  /// Reads the three bars off the same status the HUD draws, so the widget and
  /// the game can never disagree about how thirsty somebody is.
  factory HomeStatus.of({
    required SimState state,
    required SimStatus status,
    required BleedTier bleeding,
    double? nearestEnemyM,
  }) => HomeStatus(
    waterPct: _pct(status.thirst.fraction),
    kcalPct: _pct(status.hunger.fraction),
    sleepPct: _pct(1 - state.sleepDebt.inSeconds / kDailySleepNeed.inSeconds),
    bpm: state.heartRateBpm.round(),
    ailments: ailmentsOf(
      status: status,
      bleeding: bleeding,
      nearestEnemyM: nearestEnemyM,
    ),
    at: state.lastUpdate,
  );

  final int waterPct;
  final int kcalPct;
  final int sleepPct;
  final int bpm;

  /// Worst first, and possibly longer than the widget can show — see [shown].
  final List<Ailment> ailments;

  final DateTime at;

  /// What actually fits, given how old this reading is.
  ///
  /// Live facts drop out once the reading is stale: the widget would rather
  /// say nothing about the street than say something that stopped being true
  /// while the phone was in a pocket.
  List<Ailment> shown({required DateTime now}) {
    final stale = now.difference(at) > kFreshFor;
    return [
      for (final ailment in ailments)
        if (!stale || !ailment.live) ailment,
    ].take(kAilmentsShown).toList();
  }

  /// How many were left out of [shown], for the "+2" the widget draws.
  int over({required DateTime now}) {
    final stale = now.difference(at) > kFreshFor;
    final fitting = ailments.where((one) => !stale || !one.live).length;
    return fitting > kAilmentsShown ? fitting - kAilmentsShown : 0;
  }

  /// ⚠️ Clamped, and that is not defensive coding. §2.2 lets a character carry
  /// more water than a day needs after a long drink, which is a fraction above
  /// one — and a progress bar handed 108 renders as an empty one on some
  /// launchers rather than a full one.
  static int _pct(double fraction) {
    final value = (fraction * 100).round();
    if (value < 0) return 0;
    return value > 100 ? 100 : value;
  }
}
