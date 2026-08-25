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

  // ⚠️ An arbitrary shelf, not the game's own figure. The tests below are
  // about what a shelf does with what is put on it; twenty-five is simply a
  // round number that makes the arithmetic readable. What a *shelter* holds is
  // asserted against [ShelterKind] instead, just underneath.
  Stash empty() => const Stash(capacityKg: 25);

  group('what a shelf will take', () {
    test('a shelf is three litres to the kilogram (§18.1a)', () {
      expect(empty().capacityKg, 25);
      expect(empty().capacityL, 75);
    });

    test('the main shelter holds a hundred kilos before any module', () {
      // ⚠️ Forty, against §18.2's twenty-five. Measured against the pack
      // rather than the document: §18.1a gives an eighty-kilogram character
      // thirty-six kilograms of carry, so twenty-five could not hold what the
      // player walked in with — a place to leave two things, not a base.
      expect(ShelterKind.main.storageKg, 100);
      expect(ShelterKind.camp.storageKg, 30);
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

      expect(built.storageKg, 200, reason: '100 + two levels of fifty');
    });

    test('mass refuses first when the thing is dense', () {
      // Thirty-three pieces of metal: 24,75 kg against a limit of 25, and 9,9 l
      // against a limit of 75. There is bulk to spare and no weight.
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal', count: 33), catalogue)
          .stash;

      expect(stash.massKg(catalogue), closeTo(24.75, 0.001));

      final full = stash.put(const CarriedItem(itemId: 'mat_metal'), catalogue);

      expect(full.moved, isFalse);
      expect(full.stash.lines, hasLength(1), reason: 'stacked, not added');
    });

    test('and bulk refuses first when it is not (§18.1a)', () {
      // ⚠️ Which limit bites is a question about density: a shelf holds three
      // litres to the kilogram, so anything heavier than 0,33 kg/l runs out of
      // weight first and everything lighter runs out of room.
      //
      // ⚠️ **Fabric is the only thing left on the other side of that line, and
      // barely.** Plastic used to be — 0,4 kg in 2,0 l was 0,2 kg/l — but that
      // was a piece of plastic four fifths made of air, and it was cut to 0,8 l
      // for being unbelievable. At 0,5 kg/l it now fails on mass like metal and
      // wood. Fabric sits at 0,30 against a threshold of 0,333: ten per cent of
      // margin, and §18.1a's whole second limit rests on it.
      //
      //   mat_fabric  0,3 kg · 1,0 l
      const shed = Stash(capacityKg: 100);

      final stash = shed
          .put(const CarriedItem(itemId: 'mat_fabric', count: 299), catalogue)
          .stash;

      expect(stash.volumeL(catalogue), closeTo(299, 0.001));
      expect(stash.massKg(catalogue), closeTo(89.7, 0.001));

      // Two more is two litres against one left, while ten kilograms of the
      // weight limit are still unused.
      final full = stash.put(
        const CarriedItem(itemId: 'mat_fabric', count: 2),
        catalogue,
      );

      expect(full.moved, isFalse);
      expect(shed.capacityL - stash.volumeL(catalogue), lessThan(2));
      expect(shed.capacityKg - stash.massKg(catalogue), greaterThan(10));
    });

    test('a refusal keeps the shelf exactly as it was', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'mat_metal', count: 33), catalogue)
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

    test('nor do two bare rifles, because rifles do not stack (§11.1)', () {
      // ⚠️ **The shelf used to ask only about history, never about the item.**
      //
      // Two rifles at the same condition with nothing bolted to them have no
      // history to tell apart, so they became one row reading ×2 — and one
      // of the two uids went with it. Everything that works piece by piece
      // could then reach only one of them: §18.6's dismantling offered one
      // rifle where there were two, and the second was unreachable without
      // taking the pile down.
      //
      // The pack has asked `definition.stackable` since it was written. §18.2
      // makes the shelf the same pile at a bench, so it answers the same way.
      final stash = empty()
          .put(
            const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'a.1'),
            catalogue,
          )
          .stash
          .put(
            const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'a.2'),
            catalogue,
          )
          .stash;

      expect(stash.lines, hasLength(2));
      expect(stash.lines.map((line) => line.uid), ['a.1', 'a.2']);
    });

    test('and a heap of them arrives as pieces with a name each', () {
      // Anything that hands the shelf a count of three has to come apart into
      // three things the shelf can tell from one another — the same rule the
      // pack learned after three knives shared one name between them.
      final stash = empty()
          .put(
            const CarriedItem(
              itemId: 'weapon_rifle_545',
              count: 3,
            ).copyWith(uid: 'a.1'),
            catalogue,
          )
          .stash;

      expect(stash.lines, hasLength(3));
      expect(stash.lines.every((line) => line.count == 1), isTrue);
      expect(stash.lines.map((line) => line.uid).toSet(), hasLength(3));
    });

    test('a stackable thing still stacks, or the fix broke the shelf', () {
      final stash = empty()
          .put(const CarriedItem(itemId: 'med_bandage', count: 2), catalogue)
          .stash
          .put(const CarriedItem(itemId: 'med_bandage'), catalogue)
          .stash;

      expect(stash.lines, hasLength(1));
      expect(stash.lines.single.count, 3);
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

    test(
      'a heap written by an older shelf comes apart on the way in',
      () async {
        // ⚠️ **Rows like this are already on disk.**
        //
        // The shelf used to stack anything whose history was blank without ever
        // asking the item whether it stacks at all, so two bare rifles became
        // one row with a count of two and one of the two uids was lost. Fixing
        // [Stash.put] stops it happening again and does nothing at all for the
        // saves it already happened to — and a save that heals only when
        // somebody happens to take the pile down is a save that does not heal.
        //
        // Built by hand rather than through [Stash.put], because [Stash.put] is
        // exactly what will no longer produce it.
        await store.save(
          profileId,
          house.id,
          Stash(
            capacityKg: 25,
            lines: [
              const CarriedItem(
                itemId: 'weapon_rifle_545',
                count: 3,
              ).copyWith(uid: 'old.1'),
            ],
          ),
        );

        final back = await store.load(profileId, house, catalogue);

        expect(back.lines, hasLength(3));
        expect(back.lines.every((line) => line.count == 1), isTrue);
        expect(back.lines.map((line) => line.uid).toSet(), hasLength(3));

        // The first keeps the name the row had — a thing put down and picked up
        // again is the same thing — and the rest are named now.
        expect(back.lines.first.uid, 'old.1');
      },
    );

    test('and a real stack is still one row after a restart', () async {
      await store.save(
        profileId,
        house.id,
        const Stash(capacityKg: 25)
            .put(const CarriedItem(itemId: 'mat_metal', count: 5), catalogue)
            .stash,
      );

      final back = await store.load(profileId, house, catalogue);

      expect(back.lines, hasLength(1));
      expect(back.lines.single.count, 5);
    });

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
      expect(back.capacityKg, ShelterKind.main.storageKg);

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

  test('§18.2: an unopened shelf is empty, and empty is not full', () {
    // ⚠️ The reading that produced the field report. A controller starts with
    // `Stash(capacityKg: 0)` — correct, because it has not read anything yet —
    // and [Stash.fits] against nought is quite properly false. The bug was
    // never here: it was every screen that asked this question before the
    // shelves had been read, and then showed the answer as a rule about space.
    const unread = Stash(capacityKg: 0);

    expect(unread.lines, isEmpty);
    expect(
      unread.fits(const CarriedItem(itemId: 'mat_metal', count: 1), catalogue),
      isFalse,
      reason: 'nought capacity is full, and that is why nobody may ask yet',
    );
  });
}
