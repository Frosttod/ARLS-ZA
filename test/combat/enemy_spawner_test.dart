import 'dart:math';

import 'package:arls_za/combat/enemy.dart';
import 'package:arls_za/combat/enemy_spawner.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
import 'package:test/test.dart';

/// §6.4, §5.5.6. Where the things come from.
///
/// Two of these rules are about a person walking around a real city rather
/// than about balance: nothing appears within a hundred and fifty metres, and
/// nothing appears anywhere §3.5 forbids sending somebody. The third is the
/// cap, which keeps a fight winnable by something other than luck.
void main() {
  const player = GeoPoint(52.4084, 16.9342);

  GeoPoint north(double metres) => GeoPoint(
    player.latitude + metres / metresPerDegreeLat,
    player.longitude,
  );

  SpawnOrigin hotspot({
    double at = 400,
    double radiusM = 120,
    int capacity = 4,
    List<EnemyKind> kinds = const [EnemyKind.walker],
  }) => SpawnOrigin(
    id: 'h1',
    centre: north(at),
    radiusM: radiusM,
    kinds: kinds,
    capacity: capacity,
  );

  EnemySpawn run({
    List<Enemy> existing = const [],
    List<SpawnOrigin>? origins,
    GeoPoint? shelterAt,
    List<MapFeature> obstacles = const [],
    int seed = 1,
    int cap = kActiveCap,
  }) => spawnEnemies(
    playerAt: player,
    existing: existing,
    origins: origins ?? [hotspot()],
    seed: seed,
    shelterAt: shelterAt,
    obstacles: obstacles,
    cap: cap,
  );

  group('nothing comes out of nothing (§6.4)', () {
    test('never inside a hundred and fifty metres', () {
      // A Walker that materialised at eighty metres is a jump scare, not a
      // fight somebody walked into.
      for (var seed = 0; seed < 40; seed++) {
        final spawn = run(
          seed: seed,
          origins: [hotspot(at: 200, radiusM: 180, capacity: 6)],
        );

        for (final enemy in spawn.added) {
          expect(
            enemy.position.distanceTo(player),
            greaterThanOrEqualTo(kSpawnMinM),
            reason: 'seed $seed',
          );
        }
      }
    });

    test('a hotspot sitting on the player produces nothing at all', () {
      // Rather than pushing them outwards: a hotspot has a fixed centre
      // (§6.5.1), and moving its spawns would move the hotspot.
      final spawn = run(origins: [hotspot(at: 0, radiusM: 100)]);

      expect(spawn.added, isEmpty);
    });

    test('never within two hundred metres of the shelter', () {
      for (var seed = 0; seed < 30; seed++) {
        final spawn = run(
          seed: seed,
          origins: [hotspot(at: 500, radiusM: 200, capacity: 6)],
          shelterAt: north(600),
        );

        for (final enemy in spawn.added) {
          expect(
            enemy.position.distanceTo(north(600)),
            greaterThanOrEqualTo(kShelterKeepOutM),
            reason: 'seed $seed',
          );
        }
      }
    });

    test('never where §3.5 says a person must not be sent', () {
      // The same list that keeps loot off a carriageway. This game moves a
      // real body around a real city, and a marker is a marker.
      final motorway = MapFeature(
        tags: const {'highway': 'motorway'},
        shape: FeatureShape.line,
        geometry: [north(300), north(600)],
      );

      final spawn = run(
        origins: [hotspot(at: 450, radiusM: 150, capacity: 8)],
        obstacles: [motorway],
      );

      for (final enemy in spawn.added) {
        expect(
          SpawnFilter([motorway]).refuse(enemy.position),
          isNull,
          reason: enemy.id,
        );
      }
    });

    test('a hotspot with nowhere legal in it puts nothing there', () {
      // Better an empty street than a frame spent hunting for a point that
      // does not exist.
      // §3.5 takes the geometry of a sensitive place as the zone itself, so
      // the school has to actually contain the hotspot.
      final school = MapFeature(
        tags: const {'amenity': 'school'},
        shape: FeatureShape.area,
        geometry: [
          GeoPoint(north(300).latitude, player.longitude - 0.01),
          GeoPoint(north(300).latitude, player.longitude + 0.01),
          GeoPoint(north(600).latitude, player.longitude + 0.01),
          GeoPoint(north(600).latitude, player.longitude - 0.01),
        ],
      );

      final spawn = run(
        origins: [
          SpawnOrigin(
            id: 'h1',
            centre: north(450),
            radiusM: 30,
            kinds: const [EnemyKind.walker],
            capacity: 4,
          ),
        ],
        obstacles: [school],
      );

      expect(spawn.added, isEmpty);
    });
  });

  group('the cap of §5.5.6', () {
    test('eight within three hundred metres, and no more', () {
      final spawn = run(
        origins: [hotspot(at: 250, radiusM: 60, capacity: 20)],
      );

      final near = spawn.enemies
          .where((e) => e.position.distanceTo(player) <= kActiveRadiusM)
          .length;

      expect(near, lessThanOrEqualTo(kActiveCap));
    });

    test('what is already out there counts against it', () {
      final crowd = [
        for (var i = 0; i < 8; i++)
          Enemy.spawn(
            id: 'old.$i',
            kind: EnemyKind.walker,
            at: north(200.0 + i),
            home: north(200),
            random: Random(i),
          ),
      ];

      final spawn = run(existing: crowd, origins: [hotspot(at: 250)]);

      expect(spawn.added, isEmpty);
    });

    test('the dead free their place', () {
      final crowd = [
        for (var i = 0; i < 8; i++)
          Enemy.spawn(
            id: 'old.$i',
            kind: EnemyKind.walker,
            at: north(200.0 + i),
            home: north(200),
            random: Random(i),
          ).hit(9000),
      ];

      final spawn = run(existing: crowd, origins: [hotspot(at: 250)]);

      expect(spawn.added, isNotEmpty);
      expect(spawn.enemies.every((enemy) => !enemy.isDead), isTrue);
    });

    test('a Horde may raise it (§6.5.5)', () {
      final spawn = run(
        origins: [hotspot(at: 250, radiusM: 60, capacity: 20)],
        cap: kHordeCap,
      );

      final near = spawn.enemies
          .where((e) => e.position.distanceTo(player) <= kActiveRadiusM)
          .length;

      expect(near, greaterThan(kActiveCap));
      expect(near, lessThanOrEqualTo(kHordeCap));
    });

    test('far-off hotspots are not capped by a fight elsewhere', () {
      // The cap is about what the player is standing in, not about the world.
      final spawn = run(
        origins: [
          hotspot(at: 250, radiusM: 60, capacity: 20),
          SpawnOrigin(
            id: 'far',
            centre: north(1500),
            radiusM: 100,
            kinds: const [EnemyKind.walker],
            capacity: 3,
          ),
        ],
      );

      expect(
        spawn.added.where((enemy) => enemy.id.startsWith('far.')),
        hasLength(3),
      );
    });
  });

  group('what a place produces', () {
    test('a hotspot fills to its own capacity', () {
      final spawn = run(origins: [hotspot(capacity: 3)]);

      expect(spawn.added, hasLength(3));
    });

    test('and is not refilled while its own are still alive', () {
      final first = run(origins: [hotspot(capacity: 3)]);
      final second = run(existing: first.enemies, origins: [hotspot(capacity: 3)]);

      expect(second.added, isEmpty);
      expect(second.enemies, hasLength(3));
    });

    test('everything it makes belongs to it', () {
      // The home is what the leash of §6.1a is measured from.
      final spawn = run(origins: [hotspot()]);

      for (final enemy in spawn.added) {
        expect(enemy.home.latitude, closeTo(north(400).latitude, 1e-9));
      }
    });

    test('and stands inside it', () {
      final spawn = run(origins: [hotspot(at: 400, radiusM: 120)]);

      for (final enemy in spawn.added) {
        expect(enemy.position.distanceTo(north(400)), lessThanOrEqualTo(120));
      }
    });

    test('a mixed hotspot can produce any of its kinds (§6.5.2)', () {
      final kinds = <EnemyKind>{};
      for (var seed = 0; seed < 25; seed++) {
        final spawn = run(
          seed: seed,
          origins: [
            hotspot(
              at: 400,
              capacity: 6,
              kinds: const [EnemyKind.walker, EnemyKind.leaper],
            ),
          ],
        );
        kinds.addAll(spawn.added.map((enemy) => enemy.kind));
      }

      expect(kinds, containsAll(<EnemyKind>[
        EnemyKind.walker,
        EnemyKind.leaper,
      ]));
    });

    test('the ambient trickle is two a square kilometre at most (§6.4)', () {
      final ambient = SpawnOrigin.ambient(centre: player, radiusM: 1000);

      // A disc of a kilometre's radius is about 3.14 km².
      expect(ambient.capacity, 6);
      expect(ambient.kinds, [EnemyKind.walker]);
    });

    test('and it is Walkers alone, never a group of anything else', () {
      final spawn = run(
        origins: [SpawnOrigin.ambient(centre: player, radiusM: 500)],
      );

      expect(
        spawn.added.every((enemy) => enemy.kind == EnemyKind.walker),
        isTrue,
      );
    });
  });

  test('the same seed gives the same street', () {
    // §11: a restart mid-walk must not reshuffle what is around the player.
    final a = run(seed: 7);
    final b = run(seed: 7);

    expect(a.added.length, b.added.length);
    for (var i = 0; i < a.added.length; i++) {
      expect(a.added[i].position.latitude, a.added[i].position.latitude);
      expect(
        a.added[i].position.latitude,
        closeTo(b.added[i].position.latitude, 1e-12),
      );
    }
  });

  group('one id per body (§6.4)', () {
    test('a second pass does not reuse an id from the first', () {
      // ⚠️ Found on a phone as two markers for one Walker. The serial began at
      // nought on every pass, so the second pass — which starts at slot one,
      // because slot nought is already filled — handed the new body the id the
      // old one already had. Everything downstream keys off that id: the dot,
      // the glyph over it, the body it leaves behind.
      final origins = [
        SpawnOrigin.ambient(centre: player, radiusM: 600),
      ];

      var enemies = <Enemy>[];
      for (var pass = 0; pass < 6; pass++) {
        enemies = spawnEnemies(
          playerAt: player,
          existing: enemies,
          origins: origins,
          seed: 11,
        ).enemies;
      }

      final ids = enemies.map((enemy) => enemy.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'two enemies sharing an id: $ids',
      );
    });
  });
}
