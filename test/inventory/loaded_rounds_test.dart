import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/inventory/inventory_store.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// NABOJE W BRONI PRZEŻYWAJĄ ZAMKNIĘCIE GRY (§5.3, §11.1).
///
/// ⚠️ Reported from a walk as "I lose thirty rounds every restart", and that
/// is exactly what happened. What was in the gun lived in one integer in the
/// interface and nothing ever wrote it down — so reloading took the rounds out
/// of the pack, put them somewhere that did not survive the process, and the
/// player was charged a magazine for closing the app.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  late SaveDatabase db;
  late int profileId;

  setUp(() async {
    db = SaveDatabase.memory();
    profileId = await insertProfile(db);
  });

  tearDown(() => db.close());

  Future<Inventory> roundTrip(Inventory inventory) async {
    final store = InventoryStore(db);
    await store.save(profileId, inventory);
    return (await store.load(profileId, catalogue)).inventory;
  }

  test('a loaded rifle is still loaded in the morning', () async {
    final loaded = const Inventory().wearLine(
      const CarriedItem(itemId: 'weapon_rifle_545', rounds: 30),
      catalogue,
    );

    final back = await roundTrip(loaded);
    final rifle = back.worn.firstWhere(
      (line) => line.itemId == 'weapon_rifle_545',
    );

    expect(rifle.rounds, 30);
  });

  test(
    'and a half-empty one keeps what is left, not a full magazine',
    () async {
      final loaded = const Inventory().wearLine(
        const CarriedItem(itemId: 'weapon_rifle_545', rounds: 7),
        catalogue,
      );

      final back = await roundTrip(loaded);

      expect(back.worn.single.rounds, 7);
    },
  );

  test('something that cannot hold rounds holds none', () async {
    final pack = const Inventory().withLine(
      const CarriedItem(itemId: 'med_bandage'),
      const CarriedItem(itemId: 'med_bandage'),
    );

    final back = await roundTrip(
      Inventory(carried: [const CarriedItem(itemId: 'med_bandage')]),
    );

    expect(pack.carried, isEmpty);
    expect(back.carried.single.rounds, isNull);
  });

  test('the weapon in hand is the line, not the id (§5.6.3)', () {
    // Two rifles are two rifles, and what is in one of them belongs to that
    // one. `withLine` has to reach into `worn`, which is where the hand is —
    // the same trap `attach` documents.
    const held = CarriedItem(itemId: 'weapon_rifle_545', rounds: 0);
    final inventory = const Inventory().wearLine(held, catalogue);
    final line = inventory.worn.single;

    final after = inventory.withLine(line, line.copyWith(rounds: 12));

    expect(after.worn.single.rounds, 12);
    expect(after.carried, isEmpty, reason: 'it did not move to the pack');
  });

  test('and rounds survive being put on a shelf or dropped', () {
    // The column is on all three tables for this reason: a loaded rifle put
    // down on the pavement is still loaded when it is picked up.
    const line = CarriedItem(itemId: 'weapon_rifle_545', rounds: 18);

    expect(line.copyWith(count: 1).rounds, 18);
  });
}
