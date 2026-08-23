import 'dart:io';

import 'package:arls_za/combat/weapon_load.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/inventory/inventory_store.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/sim/body.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// KTÓRY TO JEST EGZEMPLARZ (§11.1).
///
/// ⚠️ Object identity is not identity. Every edit rebuilds the line and every
/// save rebuilds all of them, so `identical` answers "is this the very object
/// I was handed" — a different question from "is this the same rifle" that
/// happens to agree right up until an `await` on the database lands between
/// capturing a handle and using it.
///
/// That gap cost real things here: rounds spent into nothing because withLine
/// matched nobody, a dismantling bar under the wrong row, a scope fitted to a
/// copy that was no longer in the pack.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  group('what makes two lines the same line', () {
    test('a rebuilt copy is still the same piece', () {
      // The case that broke everything: `copyWith` makes a new object, and
      // every edit in this codebase goes through one.
      final rifle = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'a.1');
      final reloaded = rifle.copyWith(rounds: 30);

      expect(identical(rifle, reloaded), isFalse, reason: 'a new object');
      expect(rifle.isSame(reloaded), isTrue, reason: 'the same rifle');
    });

    test('two of a kind are never the same piece', () {
      // ⚠️ Never value equality. Two full bottles are two bottles, and
      // per-piece state exists so they can diverge.
      final first = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'a.1');
      final second = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'a.2');

      expect(first.isSame(second), isFalse);
    });

    test('and without names it falls back to the object', () {
      // Everything built in a test, and every line written by older code. A
      // piece nobody has saved has no history to be confused with.
      const bare = CarriedItem(itemId: 'med_bandage');
      final other = const CarriedItem(itemId: 'med_bandage').copyWith(count: 1);

      expect(bare.isSame(bare), isTrue);
      expect(bare.isSame(other), isFalse);
    });

    test('a name is never dropped by an edit', () {
      final named = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'a.1');

      expect(named.copyWith(rounds: 12).uid, 'a.1');
      expect(named.copyWith(condition: 50).uid, 'a.1');
      expect(named.copyWith(salvageSeconds: 90).uid, 'a.1');
    });

    test('and no two fresh names collide', () {
      final names = {for (var i = 0; i < 2000; i++) newLineId()};

      expect(names, hasLength(2000));
    });
  });

  group('the edit finds its piece across a rebuild', () {
    test('withLine works on a copy, not only on the very object', () {
      // ⚠️ This is the bug. `withLine` silently returns an unchanged copy when
      // it matches nobody — so a stale handle spent the loose rounds and put
      // them nowhere.
      final pack = Inventory(
        carried: [
          const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'a.1'),
        ],
      );

      // What a reload from the database hands back: same values, new object.
      final stale = pack.carried.single.copyWith();

      final after = pack.withLine(stale, stale.copyWith(rounds: 30));

      expect(after.carried.single.rounds, 30);
    });

    test('and so does taking rounds out of a magazine', () {
      final pack = Inventory(
        carried: [
          const CarriedItem(
            itemId: 'mag_rifle_545',
          ).copyWith(uid: 'a.1', rounds: 30),
        ],
      );
      final stale = pack.carried.single.copyWith();

      final out = emptyMagazine(pack, stale, catalogue);

      expect(out.isDone, isTrue, reason: 'a stale handle used to be refused');
      expect(out.moved, 30);
    });

    test('and fitting a scope to a rifle rebuilt by a save', () {
      final pack = Inventory(
        worn: [
          const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'a.1'),
        ],
        carried: [
          const CarriedItem(itemId: 'att_red_dot').copyWith(uid: 'a.2'),
        ],
      );

      final after = pack.attach(
        pack.worn.single.copyWith(),
        pack.carried.single.copyWith(),
        catalogue,
      );

      expect(after.worn.single.attachments, ['att_red_dot']);
      expect(after.carried, isEmpty);
    });

    test('removeLine takes the piece it was pointed at', () {
      final pack = Inventory(
        carried: [
          const CarriedItem(itemId: 'med_bandage').copyWith(uid: 'a.1'),
          const CarriedItem(itemId: 'med_bandage').copyWith(uid: 'a.2'),
        ],
      );

      final left = pack.removeLine(pack.carried.last.copyWith())!;

      expect(left.carried.single.uid, 'a.1');
    });
  });

  group('a name survives the app being closed (§11.1)', () {
    late SaveDatabase db;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
    });

    tearDown(() => db.close());

    test('the same piece comes back with the same name', () async {
      final store = InventoryStore(db);
      final before = Inventory(
        carried: [
          const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'a.1'),
        ],
      );

      await store.save(profileId, before);
      final after = (await store.load(profileId, catalogue)).inventory;

      expect(after.carried.single.uid, 'a.1');
      expect(before.carried.single.isSame(after.carried.single), isTrue);
    });

    test('and a row written before names existed gets one', () async {
      // The upgrade path. A null name would make every old line fall back to
      // object identity for ever, which is the state this replaces.
      final store = InventoryStore(db);
      await store.save(
        profileId,
        const Inventory(carried: [CarriedItem(itemId: 'med_bandage')]),
      );

      final after = (await store.load(profileId, catalogue)).inventory;

      expect(after.carried.single.uid, isNotNull);
    });

    test('two of a kind keep two names, not one', () async {
      final store = InventoryStore(db);
      await store.save(
        profileId,
        const Inventory(
          carried: [
            CarriedItem(itemId: 'weapon_rifle_545', rounds: 30),
            CarriedItem(itemId: 'weapon_rifle_545', rounds: 7),
          ],
        ),
      );

      final after = (await store.load(profileId, catalogue)).inventory;
      final names = after.carried.map((line) => line.uid).toSet();

      expect(names, hasLength(2));
    });
  });

  test('anything the world makes arrives with a name', () {
    // The very next tap after picking something up is a control holding a
    // handle to it.
    final change = const Inventory().add('med_bandage', catalogue, body: body);

    expect(change.inventory.carried.single.uid, isNotNull);
  });

  test('and anything picked back up keeps the one it had', () {
    final change = const Inventory().add(
      'weapon_rifle_545',
      catalogue,
      body: body,
      uid: 'a.1',
    );

    expect(change.inventory.carried.single.uid, 'a.1');
  });

  group('a name each, however many arrive at once (§11.1)', () {
    // ⚠️ Reported from a walk, with a photograph: two part-drunk bottles, and
    // starting one of them drew a bar under both. §2.1a allows one action, so
    // there was one action — what there were two of was rows answering to it.
    //
    // The mechanism was here. [CarriedItem.copyWith] carries the uid through,
    // which is what it is for, so splitting a stack of three into three
    // pieces handed them one name between them. Everything downstream asks
    // [CarriedItem.isSame], and isSame compares uids.
    final catalogue = ItemCatalogue.load([
      for (final asset in kBundledItemAssets)
        ItemSource(asset, File(asset).readAsStringSync()),
    ]);
    final body = BodyProfile.from(
      const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
    );

    test('three of a thing with its own state are three names', () {
      final out = const Inventory().add(
        'tool_multitool',
        catalogue,
        body: body,
        count: 3,
        condition: 80,
      );

      final lines = out.inventory.carried;
      expect(lines, hasLength(3), reason: 'each has its own condition');
      expect(
        lines.map((line) => line.uid).toSet(),
        hasLength(3),
        reason: 'three pieces, three names',
      );
    });

    test('and no piece answers to another', () {
      final out = const Inventory().add(
        'tool_multitool',
        catalogue,
        body: body,
        count: 3,
        condition: 80,
      );

      final lines = out.inventory.carried;
      for (final line in lines) {
        final answering = lines.where(line.isSame).length;
        expect(
          answering,
          1,
          reason: 'an act on one piece must not find the other two',
        );
      }
    });

    test('the first keeps the name it arrived with', () {
      // A thing put on the pavement and picked up again is the same thing
      // (§4.8), so a caller that knows the name keeps it.
      final out = const Inventory().add(
        'tool_multitool',
        catalogue,
        body: body,
        count: 2,
        condition: 80,
        uid: 'from.the.ground',
      );

      expect(out.inventory.carried.first.uid, 'from.the.ground');
      expect(out.inventory.carried.last.uid, isNot('from.the.ground'));
    });
  });
}
