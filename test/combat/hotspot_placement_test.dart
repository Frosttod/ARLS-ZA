import 'dart:io';
import 'dart:math';

import 'package:arls_za/combat/hotspot.dart';
import 'package:arls_za/combat/hotspot_store.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/play_habit.dart';
import 'package:test/test.dart';

import '../db/db_fixture.dart';

/// OGNISKA ISTNIEJĄ (§6.5.1, §6.5.3, §11.1).
///
/// ⚠️ **The whole of §6.5 was built and nothing used it.**
///
/// `hotspot.dart` has had the placement distances, the ten-level table, the
/// agitation rules and the clearing rest since stage 5 — and no file outside it
/// mentioned `Hotspot`. So §6.4's ambient trickle, two Walkers to a square
/// kilometre, was the entire population of the world, and the combat model,
/// the loot economy and the shelter had each been walked alone and never once
/// under the pressure all three were designed for.
///
/// This is the half that makes them real: somewhere to be, a row to live in,
/// and a clock that runs with the app shut.
void main() {
  const home = GeoPoint(52.4084, 16.9342);
  final t0 = DateTime.utc(2026, 8, 24, 12);

  group('§6.5.1: where one may stand', () {
    test('always in the ring around the shelter', () {
      for (var seed = 0; seed < 50; seed++) {
        final at = placeHotspot(
          shelterAt: home,
          taken: const [],
          random: Random(seed),
        );

        expect(at, isNotNull, reason: 'nothing placed for seed $seed');

        final metres = home.distanceTo(at!);
        expect(metres, greaterThanOrEqualTo(kHotspotMinFromShelterM - 1));
        expect(metres, lessThanOrEqualTo(kHotspotMaxFromShelterM + 1));
      }
    });

    test('and never on top of another (§6.5.1)', () {
      // ⚠️ Two level-ten circles 450 m apart still leave 50 m of clear ground
      // between their edges. Closer and they merge into an impassable area
      // eight hundred metres across.
      final taken = <GeoPoint>[];

      for (var slot = 0; slot < kMaxHotspots; slot++) {
        final at = placeHotspot(
          shelterAt: home,
          taken: taken,
          random: Random(slot),
        );
        expect(at, isNotNull);
        taken.add(at!);
      }

      for (var a = 0; a < taken.length; a++) {
        for (var b = a + 1; b < taken.length; b++) {
          expect(
            taken[a].distanceTo(taken[b]),
            greaterThanOrEqualTo(kHotspotMinApartM),
          );
        }
      }
    });

    test('§3.5: nowhere the game may not send a person', () {
      // Null rather than a forced placement. A hotspot on a motorway is worse
      // than one hotspot fewer — §3.5's exclusions exist because this game
      // sends real people to real places.
      expect(
        placeHotspot(
          shelterAt: home,
          taken: const [],
          random: Random(1),
          allows: (_) => false,
        ),
        isNull,
      );
    });

    test('and the geometry closes against §8.1', () {
      // The worst case: nearest allowed distance, grown to the widest radius.
      // Its edge still has to clear the shelter's safe zone by a long way.
      const worst = kHotspotMinFromShelterM - kHotspotMaxRadiusM;

      expect(worst, greaterThan(250));
    });
  });

  group('§6.5.3: it grows with the app shut', () {
    Hotspot fresh() => Hotspot.born(
      id: '1.0',
      seed: 7,
      centre: home,
      at: t0,
      until: const Duration(hours: 8),
    );

    Hotspot settle(Hotspot spot, DateTime now) => settleHotspot(
      spot,
      now: now,
      random: Random(1),
      habit: const PlayHabit([]),
      shelterAt: home,
    );

    test('nothing happens before its time', () {
      final after = settle(fresh(), t0.add(const Duration(hours: 7)));

      expect(after.level, 1);
    });

    test('and a week away is not a week of nothing', () {
      // ⚠️ The point of §6.5.3. A hotspot that only grew while somebody
      // watched would be a hotspot nobody ever had to come home to.
      final after = settle(fresh(), t0.add(const Duration(days: 7)));

      expect(after.level, greaterThan(1));
    });

    test('one at a time, so the jitter survives', () {
      // Applying a fortnight in a lump would lose §6.5.3's spread and make the
      // clock a metronome.
      final after = settle(fresh(), t0.add(const Duration(days: 30)));

      expect(after.level, lessThanOrEqualTo(kHotspotLevels.length));
      expect(after.nextLevelAt.isAfter(t0), isTrue);
    });

    test('and it stops at ten', () {
      var spot = fresh();
      for (var day = 1; day <= 60; day++) {
        spot = settle(spot, t0.add(Duration(days: day)));
      }

      expect(spot.level, kHotspotLevels.length);
    });

    test('a resting slot fills again somewhere else (§6.5.4)', () {
      final cleared = fresh().demoted(
        at: t0,
        restFor: const Duration(hours: 24),
      );

      // Knocked all the way down: the slot is resting rather than a hotspot.
      var spot = cleared;
      for (var i = 0; i < 12 && !spot.isResting; i++) {
        spot = spot.demoted(at: t0, restFor: const Duration(hours: 24));
      }
      expect(spot.isResting, isTrue);

      final reborn = settle(spot, t0.add(const Duration(hours: 25)));

      expect(reborn.isResting, isFalse);
      expect(reborn.level, 1);
      expect(
        home.distanceTo(reborn.centre),
        greaterThanOrEqualTo(kHotspotMinFromShelterM - 1),
      );
    });
  });

  group('§11.1: three slots, and an empty one is still a row', () {
    late SaveDatabase db;
    late HotspotStore store;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
      store = HotspotStore(db);
    });

    tearDown(() => db.close());

    test('a hotspot survives the app being killed', () async {
      final spot = Hotspot.born(
        id: '$profileId.0',
        seed: 12345,
        centre: home,
        at: t0,
        until: const Duration(hours: 8),
      );

      await store.save(profileId, 0, spot);
      final back = (await store.load(profileId))[0]!;

      expect(back.seed, spot.seed);
      expect(back.level, spot.level);
      expect(back.centre.distanceTo(spot.centre), lessThan(1));
      expect(back.nextLevelAt, spot.nextLevelAt);
      expect(back.radiusM, spot.radiusM);
    });

    test('and so does a resting one (§6.5.4)', () {
      // ⚠️ The reason a slot is a row. Modelling a cleared slot as the
      // *absence* of a record would make "no hotspot here yet" and "this one
      // was just cleared" the same state, and they are opposites: one is the
      // game starting up, the other is a reward the player earned.
      expect(() async {
        final resting = Hotspot(
          id: '$profileId.1',
          seed: 9,
          centre: home,
          level: 0,
          integrity: 0,
          bornAt: t0,
          nextLevelAt: t0,
          restingUntil: t0.add(const Duration(hours: 30)),
        );

        await store.save(profileId, 1, resting);
        final back = (await store.load(profileId))[1]!;

        expect(back.isResting, isTrue);
        expect(back.restingUntil, resting.restingUntil);
      }, returnsNormally);
    });
  });

  test('§6.4, §6.5: the trickle and the hotspots, never one or the other', () {
    // ⚠️ The session read `origins.isEmpty ? [ambient] : origins`, so the
    // moment a hotspot existed §6.4's two-Walkers-a-square-kilometre stopped
    // existing with it — and the street *between* hotspots would have been
    // genuinely, permanently empty.
    // ⚠️ Comments excluded. The note explaining the old shape *quotes* it, and
    // a budget that fires on its own explanation is a budget nobody keeps.
    final code = [
      for (final line in File(
        'lib/combat/combat_session.dart',
      ).readAsLinesSync())
        if (!line.trim().startsWith('//')) line,
    ].join();

    expect(
      code.contains('origins.isEmpty'),
      isFalse,
      reason: 'a hotspot switches the ambient population off again',
    );
    expect(code.contains('...origins,'), isTrue);
    expect(code.contains('SpawnOrigin.ambient('), isTrue);
  });

  test('§6.5.6: and the map is told about them', () {
    // The circle is the marker. Without this the pressure exists and nothing
    // on screen says where it is.
    final main = File('lib/main.dart').readAsStringSync();
    final markers = File('lib/ui/map_markers.dart').readAsStringSync();

    expect(main.contains('origins: _fires.originsAt(now'), isTrue);
    expect(main.contains('hotspots: _fires.hotspots.value'), isTrue);
    expect(markers.contains('MarkerKind.hotspot'), isTrue);

    // ⚠️ And it counts as danger. Drawn in the reach-ring colour it would read
    // as an invitation — the same shade as a shop you can walk into.
    expect(markers.contains('marker.kind == MarkerKind.hotspot'), isTrue);
  });
}
