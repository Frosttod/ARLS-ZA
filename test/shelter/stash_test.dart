import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/shelter/stash.dart';
import 'package:arls_za/shelter/stash_store.dart';
import 'package:arls_za/shelter/shelter_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// PÓŁKA W SCHRONIE (§18.2, §8.5.1).
///
/// §18.1a gives a character two hard limits and no way to grow them, so
/// everything found on a walk is a choice between carrying it and leaving it on
/// the ground, where §4.8 gives it a day. A shelf turns that into a choice
/// between carrying it and keeping it — which is most of what makes a base a
/// base rather than a bed.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  // Real items, so every figure below is the game's own.
  //
  //   mat_metal   1,5 kg · 0,6 l   — mass runs out first
  //   mat_wood    2,0 kg · 4,0 l   — bulk runs out first

  // A barricaded house before any module: §8.5.1's twenty-five kilograms, and
  // §18.1a's three litres to the kilogram.
  Stash empty() => const Stash(capacityKg: 25);

  group('what a shelf will take', () {
    test('the house holds twenty-five kilos and seventy-five litres', () {
      expect(empty().capacityKg, 25);
      expect(empty().capacityL, 75);
    });

    test('and a level of Storage adds fifty (§8.4)', () {
      final built = Shelter(
        id: 1,
        kind: ShelterKind.main,
        position: const GeoPoint(52.4, 16.9),
        startedAt: DateTime.utc(2026, 8, 1),
        buildTime: kShelterBuildTime,
        modules: const {ShelterModule.storage: 2},
      );

      expect(built.storageKg, 125);
    });

    test('mass refuses first when the thing is dense', () {
      // Sixteen lengths of metal: 24 kg against a limit of 25, and 9,6 l
      // against a limit of 75. There is bulk to spare and no weight.
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal', count: 16), catalogue)
          .stash;

      expect(stash.massKg(catalogue), closeTo(24, 0.001));

      final full = stash.put(const CarriedItem(itemId: 'mat_metal'), catalogue);

      expect(full.moved, isFalse);
      expect(full.stash.lines, hasLength(1), reason: 'stacked, not added');
    });

    test('and bulk refuses first when it is not (§18.1a)', () {
      // ⚠️ Which limit bites is a question about density, and the first
      // version of this test got it wrong: a shelf holds three litres to the
      // kilogram, so anything heavier than 0,33 kg/l runs out of weight first
      // and everything lighter runs out of room. Wood is 0,5 — it fails on
      // mass like the metal above. Plastic is 0,2, and it is the one that
      // shows §18.1a's asymmetry.
      //
      //   mat_plastic  0,4 kg · 2,0 l
      const shed = Stash(capacityKg: 100);

      final stash = shed
          .put(const CarriedItem(itemId: 'mat_plastic', count: 149), catalogue)
          .stash;

      expect(stash.volumeL(catalogue), closeTo(298, 0.001));
      expect(stash.massKg(catalogue), closeTo(59.6, 0.001));

      // Two more is four litres against two left, while forty kilograms of
      // the weight limit are still unused.
      final full = stash.put(
        const CarriedItem(itemId: 'mat_plastic', count: 2),
        catalogue,
      );

      expect(full.moved, isFalse);
      expect(shed.capacityL - stash.volumeL(catalogue), lessThan(4));
      expect(shed.capacityKg - stash.massKg(catalogue), greaterThan(30));
    });

    test('a refusal keeps the shelf exactly as it was', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal', count: 16), catalogue)
          .stash;

      final refused = stash.put(
        const CarriedItem(itemId: 'mat_metal', count: 4),
        catalogue,
      );

      expect(refused.stash.lines, stash.lines);
      expect(refused.moved, isFalse);
    });
  });

  group('what stacks and what does not', () {
    test('two of the same plain thing are one line', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal'), catalogue)
          .stash
          .put(const CarriedItem(itemId: 'mat_metal'), catalogue)
          .stash;

      expect(stash.lines, hasLength(1));
      expect(stash.lines.single.count, 2);
    });

    test('a half-drunk bottle never joins a stack of full ones (§4.7)', () {
      final stash = empty()
          .put(
            const CarriedItem(itemId: 'drink_water_bottle_500', count: 2),
            catalogue,
          )
          .stash
          .put(
            const CarriedItem(itemId: 'drink_water_bottle_500', portion: 0.5),
            catalogue,
          )
          .stash;

      expect(stash.lines, hasLength(2));
    });

    test('nor does a rifle with something bolted to it (§5.6.3)', () {
      // The one with the suppressor is the one worth carrying to a town, and
      // the other is the one to leave. They are not interchangeable, so they
      // are not one line.
      final stash = empty()
          .put(const CarriedItem(itemId: 'weapon_rifle_545'), catalogue)
          .stash
          .put(
            const CarriedItem(
              itemId: 'weapon_rifle_545',
              attachments: ['att_red_dot'],
            ),
            catalogue,
          )
          .stash;

      expect(stash.lines, hasLength(2));
    });

    test('and a fitted rifle weighs what it weighs on the shelf', () {
      final stash = empty()
          .put(
            const CarriedItem(
              itemId: 'weapon_rifle_545',
              attachments: ['att_red_dot'],
            ),
            catalogue,
          )
          .stash;

      expect(stash.massKg(catalogue), closeTo(3.45, 0.001));
    });
  });

  group('taking things off again', () {
    test('one of a stack leaves the rest', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal', count: 3), catalogue)
          .stash;

      final took = stash.take(0, count: 1);

      expect(took.taken?.count, 1);
      expect(took.stash.lines.single.count, 2);
    });

    test('the last of a line takes the line', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal'), catalogue)
          .stash;

      expect(stash.take(0).stash.lines, isEmpty);
    });

    test('more than there is takes what there is', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal', count: 2), catalogue)
          .stash;

      final took = stash.take(0, count: 99);

      expect(took.taken?.count, 2);
      expect(took.stash.lines, isEmpty);
    });

    test('and reaching for a line that is not there changes nothing', () {
      final stash = empty();

      expect(stash.take(4).taken, isNull);
      expect(stash.take(4).stash.lines, isEmpty);
    });
  });

  group('across a restart, and across a camp falling down', () {
    late SaveDatabase db;
    late StashStore store;
    late int profileId;
    late Shelter house;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
      store = StashStore(db);

      // A real row, through the real store: the foreign key under the stash
      // points at it, and a hand-made id would not be there to point at.
      final t0 = DateTime.utc(2026, 8, 1);
      await ShelterStore(db).begin(
        profileId,
        kind: ShelterKind.main,
        at: const GeoPoint(52.4, 16.9),
        now: t0,
        buildTime: kShelterBuildTime,
      );

      house = (await ShelterStore(db).load(profileId, t0)).single;
    });

    tearDown(() => db.close());

    test('what was left on the shelf is there in the morning', () async {
      final stash = const Stash(capacityKg: 25)
          .put(const CarriedItem(itemId: 'mat_metal', count: 4), catalogue)
          .stash
          .put(
            const CarriedItem(
              itemId: 'weapon_rifle_545',
              condition: 62,
              attachments: ['att_red_dot'],
            ),
            catalogue,
          )
          .stash;

      await store.save(profileId, house.id, stash);
      final back = await store.load(profileId, house, catalogue);

      expect(back.lines, hasLength(2));
      expect(back.capacityKg, 25);

      final rifle = back.lines.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      expect(rifle.condition, 62);
      expect(rifle.attachments, ['att_red_dot']);
    });

    test('saving again replaces rather than doubles', () async {
      await store.save(
        profileId,
        house.id,
        const Stash(
          capacityKg: 25,
        ).put(const CarriedItem(itemId: 'mat_metal'), catalogue).stash,
      );
      await store.save(
        profileId,
        house.id,
        const Stash(capacityKg: 25)
            .put(const CarriedItem(itemId: 'mat_metal', count: 2), catalogue)
            .stash,
      );

      final back = await store.load(profileId, house, catalogue);

      expect(back.lines, hasLength(1));
      expect(back.lines.single.count, 2);
    });

    test('a shelter that is gone takes the chest with it (§8.5.2)', () async {
      // ⚠️ Not code — the foreign key. §8.5.2 is a rule about what a player
      // loses by never coming back, and a rule enforced in the schema cannot
      // be forgotten by a caller.
      await store.save(
        profileId,
        house.id,
        const Stash(
          capacityKg: 25,
        ).put(const CarriedItem(itemId: 'mat_metal'), catalogue).stash,
      );

      await db.removeShelter(house.id);

      expect(await db.stashFor(profileId, house.id), isEmpty);
    });
  });
}
