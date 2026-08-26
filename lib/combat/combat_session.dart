/// Everything hostile that is currently out there (§5.5, §6.1a, §6.4).
///
/// One place where the three combat models meet: the spawner decides what
/// exists, the state machine decides what each of them is doing, and the noise
/// system decides which of them turn towards a sound. Kept apart from the game
/// loop because none of it needs a clock of its own — it is a function of where
/// the player is and how long has passed, which is exactly what §11's tick
/// already provides.
///
/// Nothing here is persisted. A Walker is not a place: §6.4 makes them from
/// hotspots and from the ambient trickle whenever the game is running, so
/// writing them down would only mean loading yesterday's fight on a street the
/// player has already left.
library;

import '../map/geometry.dart';
import '../safety/spawn_exclusion.dart';
import 'enemy.dart';
import 'enemy_spawner.dart';
import 'noise.dart';
import 'sanctuary.dart';

/// How far away something has to be before the game stops thinking about it.
///
/// A player walks kilometres in a session. Without this every Walker ever made
/// would still be in the list at the end of it, wandering a street nobody is
/// on — and §6.1a's leash sends them home, which is precisely where nobody is
/// looking. Beyond this they are forgotten, and the ground they stood on is
/// repopulated from scratch if the player ever comes back.
const double kForgetEnemiesM = 900;

/// A gap longer than this and the world moved on without us.
///
/// §11.1.2 replays a gap for the body because a body keeps burning calories
/// with the phone in a pocket. A street does not: what a Walker did during
/// eight hours of sleep is not knowable and not worth pretending to know, so
/// the street is simply repopulated.
const Duration kCombatGapForgotten = Duration(minutes: 5);

/// §11.1.2: what a gap in the tick means for the street.
enum CombatGap {
  /// No time passed. A snapshot can be published without the simulation clock
  /// having moved — a position update does it — and treating that as a gap
  /// wiped the street out from under the player every few seconds.
  none,

  /// The first tick of a session: nothing to walk through, but the street is
  /// whatever it already was rather than nothing.
  first,

  /// Time to walk through.
  step,

  /// Longer than anybody can account for. §11.1.2: what a Walker did over
  /// eight hours is not knowable, so the street is repopulated rather than
  /// guessed at — after whatever was already bleeding has been settled, and
  /// after whatever was at arm's length has had its five minutes (§5.5.3).
  forgotten,
}

/// Which of the four this tick is.
///
/// ⚠️ A function rather than three conditions in a build-adjacent method,
/// because two of the four were found on a phone rather than reasoned out and
/// the difference between them is one comparison nobody can see the shape of.
CombatGap gapBetween({DateTime? since, required DateTime now}) {
  if (since == null) return CombatGap.first;

  final elapsed = now.difference(since);
  if (elapsed <= Duration.zero) return CombatGap.none;

  return elapsed > kCombatGapForgotten ? CombatGap.forgotten : CombatGap.step;
}

/// §6.4: how far out the ambient trickle is kept stocked.
///
/// Wider than §5.5.6's three-hundred-metre cap so that something can walk in
/// from outside it, and no wider than the loot spawner's near ring, so the
/// game is not simulating a district nobody is in.
const double kAmbientRadiusM = 600;

class CombatSession {
  const CombatSession({required this.seed, this.enemies = const [], this.open});

  /// §11: the same seed gives the same street, whatever the app does in
  /// between.
  final int seed;

  final List<Enemy> enemies;

  /// §5.6.2: the sound still ringing, if any. Further shots inside its window
  /// fold into it rather than calling a second crowd.
  final NoiseEvent? open;

  /// Everything close enough to matter to the player right now (§5.5.6).
  List<Enemy> near(GeoPoint playerAt) => [
    for (final enemy in enemies)
      if (enemy.position.distanceTo(playerAt) <= kActiveRadiusM) enemy,
  ];

  /// One step of the world: what exists, and what each of them is doing.
  CombatSession advance({
    required GeoPoint playerAt,
    required Duration elapsed,
    required DateTime now,
    List<SpawnOrigin> origins = const [],
    List<MapFeature> obstacles = const [],
    GeoPoint? shelterAt,
    List<Sanctuary> sanctuaries = const [],
    bool denseUrban = false,
    // §7: how well this player moves. Nothing here rolls for it — see
    // [Enemy.sightAgainst].
    double scouting = 0,
    // §17.4: they notice a fifth further in the dark.
    double darkness = 0,
    void Function(Enemy dead)? onDeath,
  }) {
    // §3.5's features are what a person may not be sent through; most of them
    // — water, private land, a railway — are also what a body cannot walk
    // through. Reused rather than read twice.
    final ground = SpawnFilter(obstacles);
    // The dead, and everything the player has walked away from. Somebody who
    // covers three kilometres would otherwise finish the walk simulating every
    // street they crossed.
    // ⚠️ Deaths are reported, not merely dropped. Most of them do not happen
    // at the moment of the shot any more: §2.6's bleeding means a hit thing
    // runs on and falls over somewhere else entirely, in the middle of a tick.
    // Whoever is watching has to be told, or the body it should have left is a
    // body nobody ever hears about.
    final moved = <Enemy>[];
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      if (enemy.position.distanceTo(playerAt) > kForgetEnemiesM) continue;

      final after = advanceEnemy(
        enemy,
        playerAt: playerAt,
        elapsed: elapsed,
        ground: ground,
        scouting: scouting,
        darkness: darkness,
      );

      if (after.isDead) {
        onDeath?.call(after);
        continue;
      }
      moved.add(after);
    }

    // §8.1: they wait at the edge. Pushed back out rather than stopped, so
    // something that walked at a shelter ends up standing on the boundary
    // facing it — which is the picture §8.1 asks for, and the reason nobody
    // can camp their own doorway.
    final held = sanctuaries.isEmpty
        ? moved
        : [
            for (final enemy in moved)
              enemy.copyWith(position: keepOut(enemy.position, sanctuaries)),
          ];

    // §6.4: the hotspots of §6.5 will be passed in when they exist. Until
    // then the ambient trickle is the whole population, which is the one part
    // of §6.4 that does not depend on them.
    final spawn = spawnEnemies(
      playerAt: playerAt,
      existing: held,
      // ⚠️ **Hotspots *and* the trickle, never one instead of the other.**
      //
      // This read `origins.isEmpty ? [ambient] : origins`, so the moment §6.5
      // put a hotspot on the map §6.4's two-Walkers-a-square-kilometre stopped
      // existing — and an empty street between hotspots would have been
      // genuinely, permanently empty. The trickle is what makes walking
      // anywhere cost attention; the hotspots are what make somewhere cost
      // more than that.
      origins: [
        ...origins,
        SpawnOrigin.ambient(centre: playerAt, radiusM: kAmbientRadiusM),
      ],
      // The hour is in the seed so the street repopulates as the day goes on
      // without reshuffling every time the app is opened (§10, §11).
      seed: seed ^ now.hour ^ (now.day << 5),
      shelterAt: shelterAt,
      obstacles: obstacles,
      // §5.6.1: the built-up damping cuts both ways. Walls that swallow a shot
      // swallow a silhouette, so something in a street of blocks notices less
      // far than the same thing in a field.
      sightFactor: denseUrban ? 0.7 : 1,
    );

    return CombatSession(
      seed: seed,
      enemies: spawn.enemies,
      open: open != null && open!.isOpenAt(now) ? open : null,
    );
  }

  /// §5.6: something was heard, and some of them turn towards it.
  CombatSession heard(NoiseEvent event, {required GeoPoint playerAt}) {
    final folded = accumulate(open, event);

    return CombatSession(
      seed: seed,
      enemies: respondToNoise(enemies, event: folded, playerAt: playerAt),
      open: folded,
    );
  }

  /// §2.6: everything already bleeding that would not survive [elapsed].
  ///
  /// ⚠️ For the moment a session is thrown away rather than advanced. §11.1.2
  /// is right that what a Walker *did* over eight hours is not knowable, so
  /// the street is remade — but a wound is not a walk. Something with a hole
  /// in it and a known rate has exactly one future, and dropping the session
  /// used to delete it: a player who shot something, watched it run, and put
  /// the phone away came back to no body and no kill.
  ///
  /// The position is the last one seen. It is a guess about where it fell and
  /// it is the honest one — that is the last place the player saw it, and
  /// inventing a better answer would mean inventing the path it took.
  List<Enemy> bledOutOver(Duration elapsed) => [
    for (final enemy in enemies)
      if (!enemy.isDead)
        if ((enemy.bleedsOutIn ?? elapsed + const Duration(seconds: 1)) <=
            elapsed)
          enemy,
  ];

  /// A wound from §5.1.5, landed on one of them.
  ///
  /// [from] is where the player was standing when it landed. Given it, the one
  /// that was hit comes straight for that spot: §6.1a's ways into a chase are
  /// sight and sound, and being shot is better evidence than either — it does
  /// not have to work out where the person is, it has just been told. Without
  /// this a wounded Walker went on searching the place the *noise* came from,
  /// which made the second round cheaper than the first and read, from the
  /// player's side, as a thing that did not care it had been hit.
  CombatSession wound(
    String enemyId,
    double bloodLossMl, {
    double bleeding = 0,
    GeoPoint? from,
  }) => CombatSession(
    seed: seed,
    enemies: [
      for (final enemy in enemies)
        if (enemy.id != enemyId)
          enemy
        else
          switch (enemy.hit(bloodLossMl, bleeding: bleeding)) {
            // Nothing chases anything once it is down.
            final hurt when hurt.isDead || from == null => hurt,
            final hurt => hurt.hears(from, chasing: true),
          },
    ],
    open: open,
  );
}
