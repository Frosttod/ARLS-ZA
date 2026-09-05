/// The one scripted thing in the game (§15.6).
///
/// §15.6 asks for a single Walker a hundred and twenty metres away, on ground
/// §3.5 allows, with its damage cut and no power to kill — and seven lines that
/// arrive as the fight teaches them rather than on a timer. It is the only
/// place the game arranges anything, and the document says so in as many words.
///
/// ⚠️ **The two lines that matter are the fifth and the seventh**, and §15.6
/// says why: the noise ring and the ammunition bill are what put the economy of
/// the whole game into a player's head in the first minute. Everything before
/// them is scaffolding to reach them honestly — a fight the player actually
/// had, not a slideshow.
///
/// Pure and Flutter-free: this decides *which line is owed*, and the words and
/// the spawning live in `ui/` and `main.dart`.
library;

/// Where the tutorial Walker is put (§15.6).
///
/// Far enough to be noticed rather than met, close enough to walk to — and
/// §3.5's filter still refuses roads, water and private ground, so the
/// direction is chosen rather than the distance.
const double kFirstFightM = 120;

/// The id that marks it, so nothing else in the game has to be special-cased.
const String kFirstFightEnemyId = 'first.walker';

/// §15.6: what the scripted enemy is allowed to do to a player.
///
/// A quarter of a swing, and never past [kFirstFightFloor] of blood. Not a
/// difficulty setting — the character has to *feel* the hit, or the lesson is
/// that Walkers are harmless, which is the opposite of the lesson.
const double kFirstFightDamage = 0.25;

/// The share of maximum blood the scripted fight will not take anybody below.
///
/// §2.6 puts class II shock around here: visibly hurt, nowhere near the ground.
const double kFirstFightFloor = 0.80;

/// One line of §15.6's sequence.
enum FirstFightStep {
  /// Something is out there, and it has noticed.
  spotted,

  /// Tap it.
  aim,

  /// The lesson: standing still is the whole of §5.1.
  standStill,

  /// §5.6.5: the ring the shot just drew. One of the two that matter.
  noise,

  /// An empty magazine, with it still coming.
  reload,

  /// §15.6's last line, and the point of the exercise: what that cost.
  bill,
}

/// What the fight has taught so far.
///
/// ⚠️ **Advances in order and never goes back.** A player who shoots before
/// being told to aim has learned the lesson the hard way and does not need the
/// line; the sequence skips forward rather than waiting for a step that will
/// never come now.
class FirstFight {
  const FirstFight({this.said = const {}, this.shots = 0, this.over = false});

  /// Which lines have already been said.
  final Set<FirstFightStep> said;

  /// §15.6's seventh line is a number, so somebody has to count.
  final int shots;

  final bool over;

  bool get isDone => over && said.contains(FirstFightStep.bill);

  /// The line owed right now, or null.
  FirstFightStep? due({
    required bool enemyAlive,
    required bool noticed,
    required bool targeted,
    required bool standing,
    required bool magazineEmpty,
    required bool shotFired,
  }) {
    if (isDone) return null;

    // The order is the script. Each guard is the event §15.6 attaches the line
    // to, and `said` is what stops it arriving twice.
    if (noticed && !said.contains(FirstFightStep.spotted)) {
      return FirstFightStep.spotted;
    }
    if (!said.contains(FirstFightStep.spotted)) return null;

    if (targeted && !said.contains(FirstFightStep.aim)) {
      return FirstFightStep.aim;
    }
    // ⚠️ Only while moving, and only before the first shot. Told to a player
    // already standing still it is a correction of something they did right.
    if (targeted &&
        !standing &&
        shots == 0 &&
        !said.contains(FirstFightStep.standStill)) {
      return FirstFightStep.standStill;
    }
    if (shotFired && !said.contains(FirstFightStep.noise)) {
      return FirstFightStep.noise;
    }
    if (magazineEmpty &&
        enemyAlive &&
        shots > 0 &&
        !said.contains(FirstFightStep.reload)) {
      return FirstFightStep.reload;
    }
    if (!enemyAlive && shots > 0 && !said.contains(FirstFightStep.bill)) {
      return FirstFightStep.bill;
    }
    return null;
  }

  FirstFight take(FirstFightStep step) =>
      FirstFight(said: {...said, step}, shots: shots, over: over);

  FirstFight fired() => FirstFight(said: said, shots: shots + 1, over: over);

  FirstFight ended() => FirstFight(said: said, shots: shots, over: true);

  /// §15.6: a swing from the scripted Walker, tamed.
  ///
  /// [bloodMl] and [maxMl] are the player's own; the blow is cut to
  /// [kFirstFightDamage] and then whatever is left is refused if it would take
  /// them below [kFirstFightFloor]. Both halves are needed: the cut alone
  /// still kills somebody who walked in already bleeding.
  static double tame({
    required double blowMl,
    required double bloodMl,
    required double maxMl,
  }) {
    final cut = blowMl * kFirstFightDamage;
    final floor = maxMl * kFirstFightFloor;
    final room = bloodMl - floor;
    if (room <= 0) return 0;
    return cut > room ? room : cut;
  }

  /// `said,shots,over` — the wire format, because this has to survive the app
  /// being closed mid-fight like everything else in §11.1.
  String get wire =>
      '${said.map((step) => step.name).join(',')}|$shots|${over ? 1 : 0}';

  static FirstFight parse(String? wire) {
    if (wire == null || wire.isEmpty) return const FirstFight();

    final parts = wire.split('|');
    final names = parts.first.split(',').toSet();

    return FirstFight(
      said: {
        for (final step in FirstFightStep.values)
          if (names.contains(step.name)) step,
      },
      shots: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      over: parts.length > 2 && parts[2] == '1',
    );
  }
}
