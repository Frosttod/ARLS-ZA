/// Where the things come from, and where they are never allowed to (§6.4,
/// §5.5.6).
///
/// Two rules do the work. **Nothing appears inside a hundred and fifty metres**
/// — a Walker that materialised at eighty would be a Walker that came out of
/// nothing, and the game would be a jump scare rather than a fight somebody
/// walked into. And **nothing appears where §3.5 says a person must not be
/// sent**: a carriageway, a level crossing, a school, somebody's garden. That
/// list exists because this game moves a real person around a real city, and it
/// applies to what spawns as hard as it applies to loot.
///
/// The cap is the third: eight of them within three hundred metres, because
/// past that the simulation costs frames and the fight stops being winnable by
/// anything except luck. Extra enemies are not queued or teleported — they
/// simply are not made, and the ones already out there keep coming.
library;

import 'dart:math';

import '../map/geometry.dart';
import '../safety/spawn_exclusion.dart';
import 'enemy.dart';

/// §6.4: never nearer than this to the player.
const double kSpawnMinM = 150;

/// §6.4: nor inside this of the shelter (§8.1's safe zone plus room).
const double kShelterKeepOutM = 200;

/// §5.5.6: the radius the cap is counted over.
const double kActiveRadiusM = 300;

/// §5.5.6: how many may be simulated inside it.
const int kActiveCap = 8;

/// §5.5.6, §6.5.5: what a Horde is allowed to raise that to.
const int kHordeCap = 12;

/// §6.4: ambient spawn away from any hotspot — nought to two a square
/// kilometre, Walkers only and never in a group.
const double kAmbientPerKm2Max = 2;

/// One place enemies can come from (§6.5), or the whole map for the ambient
/// trickle.
class SpawnOrigin {
  const SpawnOrigin({
    required this.id,
    required this.centre,
    required this.radiusM,
    required this.kinds,
    required this.capacity,
  });

  /// The ambient trickle of §6.4: single Walkers, anywhere, rarely.
  factory SpawnOrigin.ambient({
    required GeoPoint centre,
    required double radiusM,
  }) {
    final areaKm2 = pi * radiusM * radiusM / 1e6;
    return SpawnOrigin(
      id: 'ambient',
      centre: centre,
      radiusM: radiusM,
      kinds: const [EnemyKind.walker],
      capacity: (areaKm2 * kAmbientPerKm2Max).floor(),
    );
  }

  final String id;
  final GeoPoint centre;
  final double radiusM;

  /// What this place produces, in the order it is drawn from.
  final List<EnemyKind> kinds;

  /// How many may exist from here at once (§6.5.2's table, per level).
  final int capacity;
}

/// What one pass of the spawner decided.
class EnemySpawn {
  const EnemySpawn({required this.enemies, required this.added});

  /// Everything that should exist after this pass.
  final List<Enemy> enemies;

  final List<Enemy> added;
}

/// Decides what should exist around the player now (§6.4).
///
/// [obstacles] are the §3.5 features near the area, exactly as the loot
/// spawner takes them: the same tiles produced both, and refusing a place to
/// stand is the same question whether the thing standing there is a box or a
/// Walker.
EnemySpawn spawnEnemies({
  required GeoPoint playerAt,
  required List<Enemy> existing,
  required List<SpawnOrigin> origins,
  required int seed,
  GeoPoint? shelterAt,
  List<MapFeature> obstacles = const [],
  int cap = kActiveCap,
}) {
  final filter = SpawnFilter(obstacles);
  final alive = [for (final enemy in existing) if (!enemy.isDead) enemy];

  final enemies = [...alive];
  final added = <Enemy>[];

  final random = Random(seed);
  var serial = 0;

  for (final origin in origins) {
    final fromHere = enemies.where((enemy) => enemy.id.startsWith('${origin.id}.')).length;

    for (var i = fromHere; i < origin.capacity; i++) {
      final at = _placeIn(
        origin,
        playerAt: playerAt,
        shelterAt: shelterAt,
        filter: filter,
        random: random,
      );
      if (at == null) break;

      // §5.5.6: the cap is counted where the player is standing, and it only
      // stops what would land inside it. A hotspot a kilometre away is not
      // held back by a fight here — nothing is queued or teleported, it is
      // simply not made, and the ones already out there keep coming.
      if (at.distanceTo(playerAt) <= kActiveRadiusM) {
        final near = enemies
            .where(
              (enemy) =>
                  enemy.position.distanceTo(playerAt) <= kActiveRadiusM,
            )
            .length;
        if (near >= cap) break;
      }

      final kind = origin.kinds[random.nextInt(origin.kinds.length)];
      final enemy = Enemy.spawn(
        id: '${origin.id}.${seed.toUnsigned(16)}.${serial++}',
        kind: kind,
        at: at,
        home: origin.centre,
        random: random,
      );

      enemies.add(enemy);
      added.add(enemy);
    }
  }

  return EnemySpawn(enemies: enemies, added: added);
}

/// A point inside [origin] that every rule of §6.4 allows, or null.
///
/// Tried a fixed number of times rather than searched: a hotspot squeezed
/// between a motorway and a school may have no legal point at all, and a
/// spawner that hunted for one would hang the frame instead of simply putting
/// nothing there.
GeoPoint? _placeIn(
  SpawnOrigin origin, {
  required GeoPoint playerAt,
  required GeoPoint? shelterAt,
  required SpawnFilter filter,
  required Random random,
}) {
  const attempts = 24;

  for (var i = 0; i < attempts; i++) {
    // Uniform over the disc: the square root is what stops everything piling
    // into the middle of the hotspot.
    final angle = random.nextDouble() * 2 * pi;
    final distance = origin.radiusM * sqrt(random.nextDouble());

    final at = GeoPoint(
      origin.centre.latitude + distance * cos(angle) / metresPerDegreeLat,
      origin.centre.longitude +
          distance * sin(angle) / metresPerDegreeLon(origin.centre.latitude),
    );

    if (at.distanceTo(playerAt) < kSpawnMinM) continue;
    if (shelterAt != null && at.distanceTo(shelterAt) < kShelterKeepOutM) {
      continue;
    }
    if (filter.refuse(at) != null) continue;

    return at;
  }

  return null;
}
