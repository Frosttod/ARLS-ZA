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
  ///
  /// Fifty metres apart: at the beta spawn radius a hundred-metre step runs
  /// out of ground before it runs out of places, and the cap would never be
  /// the thing being tested.
  List<Poi> spread(int count, {double stepM = 50}) => [
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
    test('never more than fifteen active inside the radius', () {
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
        // Both inside the beta radius: the point of this test is that two
        // places produce two boxes, not that a distant one is dropped.
        candidates: [poiAt(300), poiAt(1000)],
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

      expect(backup.respawnAt!.difference(now), lessThan(kRespawnBackupMax));
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

      expect(plan.boxes.map((box) => box.tableId), contains('proc_roadside'));
    });

    test('an invented car survives a street full of real shops', () {
      // ⚠️ Found on a walk through dense Poznań: the near ring filled with
      // real shops on the first pass, the fallback pool was never reached, and
      // a city produced no cars and no bins at all. §10.1's rule about car
      // parks is about 4165 *tagged* ones drowning the map; a handful of
      // invented street furniture is not that, and it carries what §18.2 is
      // short of.
      final invented = [
        for (var i = 1; i <= 3; i++)
          Poi(
            position: GeoPoint(
              centre.latitude + (i * 40) / metresPerDegreeLat,
              centre.longitude + 0.0006,
            ),
            selectors: const ['generated.car'],
            name: null,
            layer: 'generated',
          ),
      ];

      final plan = spawner.plan(
        centre: centre,
        candidates: [...spread(20), ...invented],
        existing: const [],
        now: now,
        seed: 9,
      );

      expect(
        plan.boxes.where((box) => box.tableId == 'proc_abandoned_car'),
        isNotEmpty,
        reason: 'a city with twenty shops still has cars parked in it',
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

  group('somebody got here first (§19.3)', () {
    // A world where every single door is shut is a world nobody else lived in,
    // and it makes the first hour of the game a lockpicking exercise with no
    // lockpicks. Some places are simply open.
    List<LootBox> spawnMany(int seed) => spawner
        .plan(
          centre: centre,
          candidates: spread(15, stepM: 120),
          existing: const [],
          now: now,
          seed: seed,
        )
        .added;

    test('not every locked place is locked', () {
      var open = 0;
      var shut = 0;
      for (var seed = 0; seed < 40; seed++) {
        for (final box in spawnMany(seed)) {
          box.isOpen ? open++ : shut++;
        }
      }

      expect(open, greaterThan(0), reason: 'a city nobody has been through');
      expect(shut, greaterThan(0), reason: 'and nothing left to break into');
    });

    test('a door stands open about a third of the time', () {
      // Rough, because it is a share rather than a rule: what matters is that
      // it is neither rare nor the usual case.
      var open = 0;
      var total = 0;
      for (var seed = 0; seed < 60; seed++) {
        for (final box in spawnMany(seed)) {
          total++;
          if (box.isOpen) open++;
        }
      }

      expect(open / total, closeTo(0.35, 0.12));
    });

    test('the same shop is open every time it is planned', () {
      // Seeded from the place, not the clock: a door that stood open yesterday
      // stands open today, or the world stops being a place.
      final first = spawnMany(7).map((box) => (box.poiId, box.isOpen)).toSet();
      final again = spawnMany(7).map((box) => (box.poiId, box.isOpen)).toSet();

      expect(again, first);
    });

    test('a place with no barrier is open, having nothing to shut it', () {
      final plan = LootSpawner(tables: tables, backupMode: true).plan(
        centre: centre,
        candidates: [poiAt(200, selector: 'landuse.class=residential')],
        existing: const [],
        now: now,
        seed: 3,
      );

      for (final box in plan.added) {
        final barrier = tables[box.tableId]?.barrier;
        if (barrier == null) expect(box.openedAt, isNull, reason: box.tableId);
      }
    });
  });

  group('how much of a place there is to search (§10.3.5)', () {
    LootBox box() => LootBox(
      poiId: 'p1',
      position: centre,
      tableId: 'poi_pharmacy',
      spawnedAt: now,
    );

    final random = Random(1);

    test('three quick looks and it is bare', () {
      var place = box();
      for (var i = 0; i < 3; i++) {
        expect(
          place.canSearchAt(SearchDepth.shallow),
          isTrue,
          reason: 'pass $i',
        );
        place = place.searchedAt(SearchDepth.shallow, now, random);
      }

      expect(place.canSearchAt(SearchDepth.shallow), isFalse);
      expect(place.lootedAt, isNotNull);
    });

    test('two thorough ones', () {
      var place = box().searchedAt(SearchDepth.thorough, now, random);

      expect(place.canSearchAt(SearchDepth.thorough), isTrue);
      place = place.searchedAt(SearchDepth.thorough, now, random);

      expect(place.canSearchAt(SearchDepth.shallow), isFalse);
      expect(place.lootedAt, isNotNull);
    });

    test('one deep one, and there is nothing left to look at', () {
      // What the player asked for in as many words: having taken the place
      // apart, there is no quicker pass left to make.
      final place = box().searchedAt(SearchDepth.deep, now, random);

      expect(place.canSearchAt(SearchDepth.shallow), isFalse);
      expect(place.canSearchAt(SearchDepth.thorough), isFalse);
      expect(place.lootedAt, isNotNull);
    });

    test('and a deep search is only ever the first thing done to a place', () {
      final touched = box().searchedAt(SearchDepth.shallow, now, random);

      expect(touched.canSearchAt(SearchDepth.deep), isFalse);
    });

    test('a quick look leaves room for a thorough one', () {
      final place = box().searchedAt(SearchDepth.shallow, now, random);

      expect(place.canSearchAt(SearchDepth.thorough), isTrue);
      expect(place.canSearchAt(SearchDepth.shallow), isTrue);
    });

    test('but the two together leave nothing behind them', () {
      final place = box()
          .searchedAt(SearchDepth.shallow, now, random)
          .searchedAt(SearchDepth.thorough, now, random);

      expect(place.canSearchAt(SearchDepth.shallow), isFalse);
      expect(place.lootedAt, isNotNull);
    });

    test('a place is not emptied while there is still something to find', () {
      final place = box().searchedAt(SearchDepth.shallow, now, random);

      expect(place.lootedAt, isNull, reason: 'two thirds of it is untouched');
      expect(place.isActiveAt(now), isTrue);
    });

    test('a refill is a full place again', () {
      // §10: the shelves are restocked, and so is what it takes to strip them.
      final emptied = box().searchedAt(SearchDepth.deep, now, random);
      final refilled = emptied.refilledAt(now.add(const Duration(hours: 6)));

      expect(refilled.searchUnits, 0);
      expect(refilled.canSearchAt(SearchDepth.deep), isTrue);
    });

    test('the door somebody forced is still forced after a refill', () {
      final opened = box().openedAtTime(now);
      final refilled = opened
          .searchedAt(SearchDepth.deep, now, random)
          .refilledAt(now.add(const Duration(hours: 6)));

      expect(refilled.isOpen, isTrue);
    });
  });
}
