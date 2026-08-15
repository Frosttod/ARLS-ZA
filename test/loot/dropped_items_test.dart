import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/loot/dropped_items.dart';
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
      await store.drop(profileId, itemAt(now.subtract(const Duration(days: 2))));
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
  });
}
