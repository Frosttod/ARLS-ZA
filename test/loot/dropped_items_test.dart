import 'dart:io';
import 'dart:math';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/loot/dropped_items.dart';
import 'package:arls_za/loot/search.dart' show kStillnessM;
import 'package:arls_za/loot/dropped_store.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// §4.8. Dropping is the other half of §18.1a's two carry limits: a full pack
/// is only a decision if what comes out of it goes somewhere. If leaving
/// something behind destroyed it, "this is too heavy" would always be answered
/// by throwing it away, and nobody deliberates over that.
void main() {
  const here = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 15, 12);

  DroppedItem itemAt(
    DateTime droppedAt, {
    String itemId = 'mat_wood',
    int id = 0,
    int count = 1,
  }) => DroppedItem(
    id: id,
    itemId: itemId,
    count: count,
    position: here,
    droppedAt: droppedAt,
  );

  group('the two rules of §4.8', () {
    test('a pile is still there the next evening', () {
      final item = itemAt(now);

      expect(item.isAliveAt(now.add(const Duration(hours: 23))), isTrue);
      expect(item.remainingAt(now.add(const Duration(hours: 20))).inHours, 4);
    });

    test('and gone after a day', () {
      // World time, not play time: a week away comes back to an empty street,
      // which is what a week does to a bag left in one.
      final item = itemAt(now);

      expect(item.isAliveAt(now.add(const Duration(hours: 25))), isFalse);
      expect(item.remainingAt(now.add(const Duration(days: 7))), Duration.zero);
    });

    test('fifty at once, and the oldest go first', () {
      // The cap is not flavour. Fifty circles is the difference between a map
      // somebody reads and one carpeted in a fortnight of old bandages.
      final items = [
        for (var i = 0; i < 60; i++)
          itemAt(now.subtract(Duration(minutes: i)), id: i),
      ];

      final sweep = sweepDropped(items, now);

      expect(sweep.kept, hasLength(kMaxDroppedItems));
      expect(sweep.removed, hasLength(10));
      expect(
        sweep.kept.map((item) => item.id),
        isNot(contains(59)),
        reason: 'the oldest is the one nobody is walking back towards',
      );
      expect(sweep.kept.map((item) => item.id), contains(0));
    });

    test('an expired pile never costs a fresh one its place', () {
      // Expiry before the cap, in that order.
      final items = [
        for (var i = 0; i < 40; i++)
          itemAt(now.subtract(const Duration(days: 2)), id: i),
        for (var i = 40; i < 70; i++) itemAt(now, id: i),
      ];

      final sweep = sweepDropped(items, now);

      expect(sweep.kept, hasLength(30));
      expect(sweep.kept.every((item) => item.id >= 40), isTrue);
    });
  });

  group('across a restart', () {
    late SaveDatabase db;
    late DroppedStore store;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      store = DroppedStore(db);
      profileId = await insertProfile(db);
    });

    tearDown(() async => db.close());

    test('what was put down is where it was put down', () async {
      await store.drop(profileId, itemAt(now, count: 4));

      final loaded = (await store.load(profileId, now)).single;

      expect(loaded.itemId, 'mat_wood');
      expect(loaded.count, 4);
      expect(loaded.position.distanceTo(here), lessThan(0.5));
    });

    test('wear and reading progress survive being put down (§4.6.3)', () async {
      // Dropping something is not a way to repair it, and a part-read book
      // keeps its place.
      await store.drop(
        profileId,
        DroppedItem(
          id: 0,
          itemId: 'lit_guide_survival',
          position: here,
          droppedAt: now,
          condition: 41,
          pagesTotal: 160,
          pagesRead: 88,
        ),
      );

      final loaded = (await store.load(profileId, now)).single;

      expect(loaded.condition, 41);
      expect(loaded.pagesTotal, 160);
      expect(loaded.pagesRead, 88);
    });

    test('reading sweeps what has expired out of the database too', () async {
      await store.drop(
        profileId,
        itemAt(now.subtract(const Duration(days: 2))),
      );
      await store.drop(profileId, itemAt(now));

      expect(await store.load(profileId, now), hasLength(1));
      expect(
        await db.groundItemsFor(profileId),
        hasLength(1),
        reason: 'the sweep deletes rather than just hiding',
      );
    });

    test('picking something up takes it off the ground', () async {
      await store.drop(profileId, itemAt(now));
      final loaded = (await store.load(profileId, now)).single;

      await store.take(loaded.id);

      expect(await store.load(profileId, now), isEmpty);
    });

    test('deleting the character clears the ground with them', () async {
      await store.drop(profileId, itemAt(now));

      await (db.delete(db.profiles)..where((t) => t.id.equals(profileId))).go();

      expect(await store.load(profileId, now), isEmpty);
    });

    test(
      'a pack with room for two of five leaves three on the ground',
      () async {
        // §4.8, §18.1a: what a full pack could not take stays where it was put.
        // Deleting the row for a partial pick-up would destroy the rest of it.
        final store = DroppedStore(db);
        final now = DateTime.utc(2026, 8, 15, 12);
        await store.drop(
          profileId,
          DroppedItem(
            id: 0,
            itemId: 'mat_wood',
            count: 5,
            position: const GeoPoint(52.4084, 16.9342),
            droppedAt: now,
          ),
        );

        final row = (await store.load(profileId, now)).single;
        await store.takeSome(row.id, left: 3);

        expect((await store.load(profileId, now)).single.count, 3);
      },
    );

    test('and taking the last of it clears the row', () async {
      final store = DroppedStore(db);
      final now = DateTime.utc(2026, 8, 15, 12);
      await store.drop(
        profileId,
        DroppedItem(
          id: 0,
          itemId: 'mat_wood',
          count: 2,
          position: const GeoPoint(52.4084, 16.9342),
          droppedAt: now,
        ),
      );

      final row = (await store.load(profileId, now)).single;
      await store.takeSome(row.id, left: 0);

      expect(await store.load(profileId, now), isEmpty);
    });
  });

  test('§10.2: and the game actually scatters what a search turns up', () {
    // ⚠️ Source-level, because scatteredFrom() could be perfect and the search
    // still drop everything on the pin — which is the defect this project
    // keeps finding: a function that works and nothing calls.
    final main = File('lib/main.dart').readAsStringSync();

    expect(main.contains('store.dropScattered('), isTrue);
    expect(
      main.contains('position: box.position,'),
      isFalse,
      reason: 'a haul is still landing on one point',
    );
  });

  group('§10.2: a search scatters what it turns up', () {
    const box = GeoPoint(52.4084, 16.9342);

    test('never onto the point the place is drawn at', () {
      // ⚠️ Everything a place gave up used to land on the box's own
      // coordinates, so fourteen things shared one position — the map drew a
      // single dot with a number on it and the ground read like a vending
      // machine tray.
      for (var seed = 0; seed < 50; seed++) {
        final at = scatteredFrom(box, Random(seed));

        expect(at.distanceTo(box), greaterThan(0.5), reason: 'seed $seed');
      }
    });

    test('a metre to three, and never further', () {
      final (near, far) = kSearchScatterM;

      for (var seed = 0; seed < 200; seed++) {
        final metres = scatteredFrom(box, Random(seed)).distanceTo(box);

        expect(metres, greaterThanOrEqualTo(near - 0.01));
        expect(metres, lessThanOrEqualTo(far + 0.01));
      }
    });

    test('and everything it scatters is still within arm reach (§4.8)', () {
      // The scatter has to separate them without putting any of them out of
      // range of the player standing where they searched.
      final (_, far) = kSearchScatterM;

      expect(far, lessThan(kStillnessM));
    });

    test('in a direction nobody chose', () {
      final bearings = {
        for (var seed = 0; seed < 40; seed++)
          (scatteredFrom(box, Random(seed)).latitude > box.latitude),
      };

      expect(bearings, hasLength(2), reason: 'they all went the same way');
    });
  });

  group('what is underfoot, as one list (§4.8)', () {
    // A player standing where they emptied their pack has a heap, and the
    // panel could only ever offer them the nearest thing in it. Getting the
    // rifle out meant picking up six bandages first.
    const here = GeoPoint(52.4084, 16.9342);

    DroppedItem lying(
      String itemId, {
      required int id,
      double metres = 0,
      int count = 1,
      double? condition,
    }) => DroppedItem(
      id: id,
      itemId: itemId,
      count: count,
      condition: condition,
      position: GeoPoint(
        here.latitude + metres / metresPerDegreeLat,
        here.longitude,
      ),
      droppedAt: DateTime.utc(2026, 8, 15, 12),
    );

    test('three drops of one thing are three things on the ground', () {
      // ⚠️ They used to be merged into "Bandaż ×3", and that was written when
      // a search dropped everything on a single point — where merging was the
      // only thing that made the list readable. Now §10.2 scatters a haul over
      // a metre to three, and merging hides exactly what the scatter is for:
      // which of them is two metres away and which is fourteen.
      final piles = pilesWithin(
        [
          lying('med_bandage', id: 1),
          lying('med_bandage', id: 2, metres: 2),
          lying('med_bandage', id: 3, metres: 4),
        ],
        here,
        reachM: 15,
      );

      expect(piles, hasLength(3));
      expect(piles.map((pile) => pile.count), everyElement(1));
      expect(
        piles.map((pile) => pile.distanceM.round()),
        [0, 2, 4],
        reason: 'each keeps the coordinates it was dropped at',
      );
    });

    test('a stack counts as what is in it, not as one row', () {
      final piles = pilesWithin(
        [lying('mat_wood', id: 1, count: 4)],
        here,
        reachM: 15,
      );

      expect(piles.single.count, 4);
    });

    test('two rifles of different condition stay two piles', () {
      // Which of them goes in the pack is exactly the choice worth having.
      final piles = pilesWithin(
        [
          lying('weapon_rifle_22lr', id: 1, condition: 40),
          lying('weapon_rifle_22lr', id: 2, condition: 90, metres: 1),
        ],
        here,
        reachM: 15,
      );

      expect(piles, hasLength(2));
      expect(
        piles.map((pile) => pile.condition),
        containsAll(<double>[40, 90]),
      );
    });

    test('the nearest pile comes first', () {
      final piles = pilesWithin(
        [
          lying('mat_wood', id: 1, metres: 9),
          lying('med_bandage', id: 2, metres: 1),
        ],
        here,
        reachM: 15,
      );

      expect(piles.first.itemId, 'med_bandage');
      expect(piles.first.distanceM, lessThan(2));
    });

    test('and each says how far away it actually is', () {
      final piles = pilesWithin(
        [
          lying('med_bandage', id: 1, metres: 10),
          lying('med_bandage', id: 2, metres: 3),
        ],
        here,
        reachM: 15,
      );

      expect(piles, hasLength(2));
      expect(piles.first.distanceM, closeTo(3, 0.5));
      expect(piles.first.parts.single.id, 2, reason: 'nearest first');
      expect(piles.last.distanceM, closeTo(10, 0.5));
    });

    test('and nothing past the fifteen metres §10.2.1 reaches', () {
      final piles = pilesWithin(
        [
          lying('med_bandage', id: 1, metres: 14),
          lying('med_bandage', id: 2, metres: 16),
        ],
        here,
        reachM: 15,
      );

      expect(piles.single.parts.single.id, 1);
    });

    test('what is out of reach is not on the list', () {
      final piles = pilesWithin(
        [
          lying('med_bandage', id: 1, metres: 2),
          lying('mat_wood', id: 2, metres: 40),
        ],
        here,
        reachM: 15,
      );

      expect(piles, hasLength(1));
      expect(piles.single.itemId, 'med_bandage');
    });

    test('an empty street is an empty list', () {
      expect(pilesWithin(const [], here, reachM: 15), isEmpty);
    });
  });

  group('what is bolted to a thing on the ground (§5.6.3)', () {
    DroppedItem rifle({
      List<String> attachments = const [],
      double metres = 0,
    }) => DroppedItem(
      id: 1,
      itemId: 'weapon_rifle_545',
      attachments: attachments,
      position: const GeoPoint(
        52.4064,
        16.9252,
      ).offsetBy(metres: metres, bearingDeg: 0),
      droppedAt: DateTime.utc(2026, 8, 16, 12),
    );

    test('a bare rifle and a suppressed one are two piles', () {
      // ⚠️ Merging them would let a player pick up the wrong one, and for the
      // rarest things in the game (§5.6.3) that is not a small mistake.
      final piles = pilesWithin(
        [
          rifle(),
          rifle(attachments: const ['tool_suppressor'], metres: 2),
        ],
        const GeoPoint(52.4064, 16.9252),
        reachM: 20,
      );

      expect(piles, hasLength(2));
    });

    test('and two identical ones are still two things two metres apart', () {
      final piles = pilesWithin(
        [
          rifle(attachments: const ['att_red_dot']),
          rifle(attachments: const ['att_red_dot'], metres: 2),
        ],
        const GeoPoint(52.4064, 16.9252),
        reachM: 20,
      );

      expect(piles, hasLength(2));
      expect(
        piles.map((pile) => pile.attachments),
        everyElement(['att_red_dot']),
      );
    });

    test('a pile carries what is on it', () {
      final piles = pilesWithin(
        [
          rifle(attachments: const ['tool_suppressor']),
        ],
        const GeoPoint(52.4064, 16.9252),
        reachM: 20,
      );

      expect(piles.single.attachments, ['tool_suppressor']);
    });
  });
}
