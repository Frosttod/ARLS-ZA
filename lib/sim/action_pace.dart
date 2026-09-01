/// How fast a thing being done actually gets done (§2.1a, §4.7, §10.2).
///
/// ⚠️ **One rule instead of three special cases.**
///
/// The game had three unrelated pieces of code answering the same question.
/// A shelter build stopped when the character left the site. A search was
/// cancelled outright by a step. A reload was broken by a body within five
/// metres. Each was a hand-written `if` in a different file, and adding a
/// fourth — "eating should be slower on the move" — would have been a fourth.
///
/// They are all one thing: **an action accrues time at a rate, and the rate
/// depends on what the character is doing while it runs.**
///
///     credited += elapsed × rate(pace, context)
///
/// A build runs at 1.0 whatever happens. A dressing runs at 1.0 standing
/// still, slower walking, and 0.0 at a run. A search runs at 0.0 the moment
/// the character is not where they started. Nothing needs a branch anywhere
/// else, and a new action is a row in a table rather than a new `if`.
library;

/// §4.7: how much longer a thing takes while moving.
///
/// Not a penalty invented here — it is the difference between doing something
/// with both hands and doing it while watching where your feet go. The figures
/// are a starting point for the walks, not a measurement.
const double kPaceWalking = 1.6;
const double kPaceBrisk = 2.5;

/// Below this the character counts as standing still (§10.2's own threshold
/// for a search, reused so that one speed does not mean two things).
const double kStillKmh = 0.5;

/// §2.2, §3.2, §8.1: what the tick is allowed to call movement.
///
/// ⚠️ **Three ways to be charged for a walk nobody took**, and all three
/// have been found on a phone:
///
/// * a lost signal — the position cannot be trusted at all, so nothing is
///   counted (§3.2)
/// * a mocked or impossible fix — §3.4 suspends the run, and a suspended run
///   charges nothing
/// * **a character under their own roof.** Reported after a night: the
///   receiver wandered a few metres at a time for eight hours, [bandForSpeed]
///   calls any speed above zero at least a slow walk, and the player woke to a
///   night's water drunk by somebody asleep in a chair. §8.1's zone is fifty
///   metres across and §2.1's zone factor already prices being indoors at
///   rest — charging movement on top of it pays twice for the same hour, out
///   of a reading nobody made.
///
/// Movement outdoors is paid at full price wherever it happens; this is only
/// about what counts as movement in the first place.
double countedSpeedKmh({
  required double reported,
  required bool sheltered,
  required bool trusted,
}) => sheltered || !trusted ? 0 : reported;

/// §2.3: swobodny marsz. 1,4 m/s — prędkość, którą człowiek wybiera sam,
/// kiedy nikt go nie goni i nie ma dokąd się spieszyć.
const double kWalkingKmh = 5;

/// Granica chodu i biegu — **jedna dla całej gry** (§2.2, §4.7, §5.6.1).
///
/// ⚠️ **Były dwie, i to jest usterka, którą ten komentarz zamyka.** Ta stała
/// istniała w dwóch bibliotekach naraz, pod tą samą nazwą i z dwiema różnymi
/// wartościami: 6,4 w `combat/awareness.dart` i 8 tutaj. Powyżej 6,4 gracz
/// hałasował jak biegnący i urywała mu się strona lektury; powyżej 8 przestawał
/// opatrywać ranę. Między jedną a drugą był jednocześnie biegnącym i
/// niebiegnącym, zależnie od tego, kto pytał. Nie kolidowały tylko dlatego, że
/// żaden plik nie importował obu naraz.
///
/// **7,2 km/h to prędkość przejścia chód→bieg** (*preferred transition speed*),
/// zmierzona i powtarzalna: około 2,0 m/s. Wypada też z liczby Froude'a —
/// przejście następuje przy Fr ≈ 0,5, czyli `v = √(0,5 · g · L)`, co dla nogi
/// długości 0,9 m daje 2,1 m/s. Poniżej człowiek chodzi, bo chodzenie jest
/// tańsze; powyżej biegnie, bo chodzenie przestaje być tańsze.
///
/// Powyżej tej granicy nie ma już pasm: 8 km/h i 25 km/h to dla hałasu (§5.6.1)
/// i dla rąk (§4.7) dokładnie to samo. Kolejne progi są gdzie indziej i mierzą
/// co innego — 15 km/h blokuje walkę (§3.5).
const double kRunningKmh = 7.2;

/// What kind of thing this is, for the purpose of the clock.
enum ActionPace {
  /// §2.1a.3: runs whether or not anybody is watching, and whether or not the
  /// app is open. Building, crafting, taking things apart, sleeping.
  ///
  /// The character is not doing it with their hands every second — they set it
  /// going and come back.
  unattended,

  /// §4.7: their own two hands. Eating, drinking, dressing a wound.
  ///
  /// ⚠️ Slowed by movement rather than cancelled by it, which is the change
  /// this enum exists to allow. A step used to throw the whole meal away.
  handsOn,

  /// §10.2: has to happen where it started. Searching a place, forcing a door.
  ///
  /// Not slowed — stopped. Half a shop searched from across the road is not a
  /// slower search, it is not a search.
  onTheSpot,
}

/// What the world is doing to the action, sampled each tick.
///
/// Comes from a GPS fix, which arrives at 1, 0.2 or 0.05 Hz (§3.3) — so
/// sampling the rate costs nothing extra and happens at exactly the moments
/// the speed is known.
class PaceContext {
  const PaceContext({
    this.speedKmh = 0,
    this.atStartingPlace = true,
    this.bodyRate = 1,
  });

  /// Ground speed from the last accepted fix.
  final double speedKmh;

  /// Whether the character is still where the action began, within whatever
  /// radius that action calls close enough.
  final bool atStartingPlace;

  /// §2.3, §2.5.4: how much a second of this body's work is worth.
  ///
  /// ⚠️ **The other half of the rate, and it was missing entirely.** The world
  /// slows an action down — a step, a walk — and so does the body: §2.3 puts a
  /// fifth on everything below twenty per cent of the day's calories, and
  /// §2.5.4 puts half on everything past twelve hours of sleep debt. Both
  /// figures were computed every tick and read by nothing that measures time.
  ///
  /// One is `SimStatus.workRate`; nothing here knows that, which is the point
  /// — `lib/sim` may not reach into the game loop, so the loop hands it down.
  final double bodyRate;

  /// Standing still, for anything that cares.
  bool get isStill => speedKmh < kStillKmh;
}

/// How much of one second counts, for an action of this [pace].
///
/// Nought means the clock is stopped, not that the action failed: §18.6's
/// dismantling and §8.3's building both keep what they have earned and go on
/// when the condition comes back. Whether stopping should also *end* something
/// is a decision for the action, not for its clock.
double rateFor(ActionPace pace, PaceContext context) {
  final world = switch (pace) {
    ActionPace.unattended => 1.0,

    ActionPace.onTheSpot => context.atStartingPlace ? 1.0 : 0.0,

    ActionPace.handsOn => switch (context.speedKmh) {
      < kStillKmh => 1.0,
      < kWalkingKmh => 1 / kPaceWalking,
      < kRunningKmh => 1 / kPaceBrisk,
      _ => 0.0,
    },
  };

  // ⚠️ Multiplied, not taken as the smaller of the two. A hungry person
  // dressing a wound while walking is slowed by both — they are two different
  // reasons for the same hands to be slower, not one reason twice.
  //
  // A stopped clock stays stopped: nought times anything is nought, which is
  // what "a search away from where it started is not a slower search" means.
  final body = context.bodyRate <= 0 ? 1.0 : context.bodyRate;

  return world * body;
}

/// How long [work] will really take at this rate, or null when it never ends.
///
/// For the interface: a player who starts a fifteen-minute job while walking
/// deserves to see twenty-four rather than fifteen and a surprise.
Duration? atThisRate(Duration work, double rate) {
  if (rate <= 0) return null;

  return Duration(milliseconds: (work.inMilliseconds / rate).round());
}
