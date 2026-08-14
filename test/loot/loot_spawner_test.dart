import 'dart:io';
import 'dart:math';

import 'package:arls_za/loot/loot_spawner.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/map/poi_source.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
import 'package:test/test.dart';

/// §10. The spawner decides what a player walks to, so the tests are about the
/// promises made to that player: something is always close enough to be worth
/// the walk, a marker does not move once it exists, and nothing is ever put
/// somewhere a person should not stand (§3.5).
void main() {
  final tables = LootTableSet.parse(
    File('assets/data/loot_tables.json').readAsStringSync(),
  );
  final spawner = LootSpawner(tables: tables);

  const centre = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 13, 12);

  /// A place [metres] north of the centre.
  Poi poiAt(double metres, {String selector = 'poi.subclass=pharmacy'}) => Poi(
    position: GeoPoint(
      centre.latitude + metres / metresPerDegreeLat,
      centre.longitude,
    ),
    selectors: [selector],
    name: null,
    layer: 'poi',
  );

  /// A spread of places at increasing distance, as a real street would give.
  List<Poi> spread(int count, {double stepM = 100}) => [
    for (var i = 1; i <= count; i++)
      Poi(
        position: GeoPoint(
          centre.latitude + (i * stepM) / metresPerDegreeLat,
          centre.longitude + (i.isEven ? 0.0004 : -0.0004),
        ),
        selectors: const ['poi.subclass=pharmacy'],
        name: null,
        layer: 'poi',
      ),
  ];

  group('the cap of §10', () {
    test('never more than fifteen active within 2 km', () {
      final plan = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 7,
      );

      expect(plan.boxes, hasLength(kMaxActiveBoxes));
    });

    test('a full map adds nothing on the next pass', () {
      final first = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 7,
      );
      final second = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: first.boxes,
        now: now.add(const Duration(minutes: 5)),
        seed: 7,
      );

      expect(second.added, isEmpty);
      expect(second.boxes, hasLength(kMaxActiveBoxes));
    });

    test('a looted box frees room for another', () {
      final random = Random(1);
      final first = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 7,
      );
      final emptied = [
        first.boxes.first.lootedAtTime(now, random),
        ...first.boxes.skip(1),
      ];

      final second = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: emptied,
        now: now.add(const Duration(minutes: 1)),
        seed: 7,
      );

      expect(second.added, hasLength(1));
    });
  });

  group('the near ring, which is what makes the walk worth taking', () {
    test('five land within 600 m when the places exist', () {
      // Fifteen points spread evenly over a 2 km disc leaves the nearest one
      // 400-900 m away. That is a journey for a tin of beans, so the ring is
      // filled first.
      final plan = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 3,
      );

      final near = plan.boxes
          .where((box) => box.position.distanceTo(centre) <= kNearRingM)
          .length;

      expect(near, greaterThanOrEqualTo(kNearRing));
    });

    test('the nearest box is a few minutes away, not a few kilometres', () {
      final plan = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 11,
      );

      final nearest = plan.boxes
          .map((box) => box.position.distanceTo(centre))
          .reduce(min);

      expect(nearest, lessThan(400));
    });

    test('they are not all on one corner', () {
      // Taking the five closest would put every box on the same street.
      final plan = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 5,
      );

      final distances =
          plan.boxes
              .map((box) => box.position.distanceTo(centre))
              .where((d) => d <= kNearRingM)
              .toList()
            ..sort();

      expect(distances.last - distances.first, greaterThan(120));
    });

    test('a thin map gives what it has rather than failing', () {
      final plan = spawner.plan(
        centre: centre,
        candidates: [poiAt(300), poiAt(1500)],
        existing: const [],
        now: now,
        seed: 2,
      );

      expect(plan.boxes, hasLength(2));
    });
  });

  group('respawn (§10)', () {
    test('a looted box comes back between four and eight hours later', () {
      final box = LootBox(
        poiId: 'x',
        position: centre,
        tableId: 'poi_pharmacy',
        spawnedAt: now,
      );

      for (var seed = 0; seed < 50; seed++) {
        final looted = box.lootedAtTime(now, Random(seed));
        final wait = looted.respawnAt!.difference(now);

        expect(wait, greaterThanOrEqualTo(kRespawnMin));
        expect(wait, lessThan(kRespawnMax));
      }
    });

    test('it is empty until then, and full after', () {
      final looted = LootBox(
        poiId: 'x',
        position: centre,
        tableId: 'poi_pharmacy',
        spawnedAt: now,
      ).lootedAtTime(now, Random(4));

      expect(looted.isActiveAt(now.add(const Duration(hours: 2))), isFalse);
      expect(looted.isActiveAt(now.add(const Duration(hours: 9))), isTrue);
    });

    test('a refill keeps the place and the table', () {
      final looted = LootBox(
        poiId: 'apteka',
        position: centre,
        tableId: 'poi_pharmacy',
        spawnedAt: now,
      ).lootedAtTime(now, Random(4));

      final plan = spawner.plan(
        centre: centre,
        candidates: const [],
        existing: [looted],
        now: now.add(const Duration(hours: 9)),
        seed: 1,
      );

      final refilled = plan.boxes.single;
      expect(refilled.poiId, 'apteka');
      expect(refilled.tableId, 'poi_pharmacy');
      expect(refilled.lootedAt, isNull);
    });

    test('§10.1 shortens the wait where the map is thin', () {
      final backup = LootBox(
        poiId: 'x',
        position: centre,
        tableId: 'proc_waste',
        spawnedAt: now,
      ).lootedAtTime(now, Random(9), backup: true);

      expect(
        backup.respawnAt!.difference(now),
        lessThan(kRespawnBackupMax),
      );
    });
  });

  group('what is never spawned on', () {
    test('a point §3.5 refuses', () {
      // A pharmacy whose recorded position falls in the carriageway is not a
      // place to send somebody, however good the loot would be.
      final road = MapFeature(
        tags: const {'highway': 'primary'},
        shape: FeatureShape.line,
        geometry: [
          GeoPoint(centre.latitude + 0.0027, centre.longitude - 0.01),
          GeoPoint(centre.latitude + 0.0027, centre.longitude + 0.01),
        ],
      );

      final plan = spawner.plan(
        centre: centre,
        candidates: [poiAt(300)],
        existing: const [],
        now: now,
        seed: 1,
        obstacles: [road],
      );

      expect(plan.boxes, isEmpty);
    });

    test('a place that already has a box', () {
      final poi = poiAt(300);
      final first = spawner.plan(
        centre: centre,
        candidates: [poi],
        existing: const [],
        now: now,
        seed: 1,
      );
      final second = spawner.plan(
        centre: centre,
        candidates: [poi],
        existing: first.boxes,
        now: now,
        seed: 1,
      );

      expect(second.added, isEmpty);
      expect(second.boxes, hasLength(1));
    });

    test('a procedural point far from the player, in a city', () {
      // 4165 car parks against 427 grocery shops within 2 km of the middle of
      // Poznań: without this rule a city spawns nothing else.
      final farCarPark = poiAt(1500, selector: 'poi.subclass=parking');

      expect(
        spawner
            .plan(
              centre: centre,
              candidates: [farCarPark],
              existing: const [],
              now: now,
              seed: 1,
            )
            .boxes,
        isEmpty,
      );
    });

    test('but a near one fills the ring when a shop cannot', () {
      // Found on a walk: standing on a residential estate, every one of those
      // 427 shops was more than 600 m away, so the near ring stayed empty and
      // the game had nothing in it. A car park is a real place, and §10.1
      // already prices it at 55%.
      final nearCarPark = poiAt(200, selector: 'poi.subclass=parking');

      final plan = spawner.plan(
        centre: centre,
        candidates: [nearCarPark],
        existing: const [],
        now: now,
        seed: 1,
      );

      expect(plan.boxes, hasLength(1));
      expect(plan.boxes.single.tableId, 'proc_abandoned_car');
    });

    test('an invented place fills the ring where a city has nothing near', () {
      // Measured on the southern edge of Poznań: fifteen boxes placed, the
      // nearest 653 m away and nothing inside the ring, in a district §10.1's
      // two-kilometre density test calls dense. The averages were right and
      // the player was standing in a gap.
      final invented = poiAt(150, selector: 'generated.roadside');

      final plan = spawner.plan(
        centre: centre,
        candidates: [invented, poiAt(1400)],
        existing: const [],
        now: now,
        seed: 6,
      );

      expect(
        plan.boxes.map((box) => box.tableId),
        contains('proc_roadside'),
      );
    });

    test('and a real shop always wins the ring over a car park', () {
      final plan = spawner.plan(
        centre: centre,
        candidates: [
          poiAt(200, selector: 'poi.subclass=parking'),
          poiAt(300),
          poiAt(400),
          poiAt(500),
          poiAt(550),
          poiAt(580),
        ],
        existing: const [],
        now: now,
        seed: 4,
      );

      expect(
        plan.boxes.where((box) => box.tableId == 'proc_abandoned_car'),
        isEmpty,
        reason: 'five real places were within the ring',
      );
    });
  });

  group('what the player is promised', () {
    test('a marker walked to is still there when they arrive', () {
      final plan = spawner.plan(
        centre: centre,
        candidates: spread(200),
        existing: const [],
        now: now,
        seed: 8,
      );
      final target = plan.boxes.first;

      // Half an hour of walking, re-planning all the way.
      var boxes = plan.boxes;
      for (var minute = 5; minute <= 30; minute += 5) {
        boxes = spawner
            .plan(
              centre: target.position,
              candidates: spread(200),
              existing: boxes,
              now: now.add(Duration(minutes: minute)),
              seed: 8,
            )
            .boxes;
      }

      expect(boxes.where((box) => box.poiId == target.poiId), hasLength(1));
    });

    test('the same hour and seed decide the same world', () {
      // §11: a session replays from its seed, and where the loot was is part
      // of the session.
      List<String> run() => spawner
          .plan(
            centre: centre,
            candidates: spread(200),
            existing: const [],
            now: now,
            seed: 42,
          )
          .boxes
          .map((box) => box.poiId)
          .toList();

      expect(run(), run());
    });

    test('boxes far behind are forgotten rather than carried for ever', () {
      final far = LootBox(
        poiId: 'left behind',
        position: GeoPoint(centre.latitude + 0.1, centre.longitude),
        tableId: 'poi_pharmacy',
        spawnedAt: now,
      );

      final plan = spawner.plan(
        centre: centre,
        candidates: const [],
        existing: [far],
        now: now,
        seed: 1,
      );

      expect(plan.forgotten, hasLength(1));
      expect(plan.boxes, isEmpty);
    });
  });
}
