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

/// §6.4: how far out the ambient trickle is kept stocked.
///
/// Wider than §5.5.6's three-hundred-metre cap so that something can walk in
/// from outside it, and no wider than the loot spawner's near ring, so the
/// game is not simulating a district nobody is in.
const double kAmbientRadiusM = 600;

class CombatSession {
  const CombatSession({
    required this.seed,
    this.enemies = const [],
    this.open,
  });

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
  }) {
    final moved = [
      for (final enemy in enemies)
        if (!enemy.isDead)
          advanceEnemy(enemy, playerAt: playerAt, elapsed: elapsed),
    ];

    // §6.4: the hotspots of §6.5 will be passed in when they exist. Until
    // then the ambient trickle is the whole population, which is the one part
    // of §6.4 that does not depend on them.
    final spawn = spawnEnemies(
      playerAt: playerAt,
      existing: moved,
      origins: origins.isEmpty
          ? [SpawnOrigin.ambient(centre: playerAt, radiusM: kAmbientRadiusM)]
          : origins,
      // The hour is in the seed so the street repopulates as the day goes on
      // without reshuffling every time the app is opened (§10, §11).
      seed: seed ^ now.hour ^ (now.day << 5),
      shelterAt: shelterAt,
      obstacles: obstacles,
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

  /// A wound from §5.1.5, landed on one of them.
  CombatSession wound(String enemyId, double bloodLossMl) => CombatSession(
    seed: seed,
    enemies: [
      for (final enemy in enemies)
        enemy.id == enemyId ? enemy.hit(bloodLossMl) : enemy,
    ],
    open: open,
  );
}
