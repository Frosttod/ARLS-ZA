import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/inventory/inventory_store.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/sim/body.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// §11.1. An inventory that does not survive the app being killed would mean
/// closing the game is a way to lose everything found — or, worse, a way to
/// duplicate it.
void main() {
  late SaveDatabase db;
  late InventoryStore store;
  late int profileId;

  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  setUp(() async {
    db = SaveDatabase.memory();
    store = InventoryStore(db);
    profileId = await insertProfile(db);
  });

  tearDown(() async => db.close());

  test('what went in comes back out', () async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .wear('cloth_winter_jacket')
        .add('mat_wood', catalogue, body: _body, count: 4)
        .inventory
        .add('med_bandage', catalogue, body: _body, count: 2)
        .inventory;

    await store.save(profileId, inventory);
    final loaded = await store.load(profileId, catalogue);

    expect(loaded.inventory.packId, 'pack_daypack');
    expect(loaded.inventory.countOf('mat_wood'), 4);
    expect(loaded.inventory.countOf('med_bandage'), 2);
    expect(loaded.inventory.worn.single.itemId, 'cloth_winter_jacket');
    expect(loaded.droppedItemIds, isEmpty);
  });

  test('worn stays worn, so the volume it does not cost stays uncosted', () async {
    // A coat read back as packed would suddenly fill a third of the rucksack.
    final inventory = const Inventory()
        .withPack('pack_trekking')
        .wear('cloth_winter_jacket');

    await store.save(profileId, inventory);
    final loaded = await store.load(profileId, catalogue);

    expect(loaded.inventory.volumeL(catalogue), 0);
    expect(loaded.inventory.massKg(catalogue), greaterThan(1.2));
  });

  test('a book keeps its own page count and progress (§4.6.3)', () async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add(
          'lit_textbook_medicine',
          catalogue,
          body: _body,
          pagesTotal: 340,
        )
        .inventory;

    await store.save(profileId, inventory);
    final loaded = await store.load(profileId, catalogue);

    expect(loaded.inventory.carried.single.pagesTotal, 340);
    // §4.6.4: mass follows the rolled page count, not the catalogue's midpoint.
    expect(
      loaded.inventory.carried.single.massKg(catalogue['lit_textbook_medicine']!),
      closeTo((340 * 1.5 + 80) / 1000, 0.001),
    );
  });

  test('saving twice does not double the contents', () async {
    final inventory = const Inventory()
        .add('mat_metal', catalogue, body: _body, count: 3)
        .inventory;

    await store.save(profileId, inventory);
    await store.save(profileId, inventory);

    expect((await store.load(profileId, catalogue)).inventory.countOf('mat_metal'), 3);
  });

  test('an item no catalogue defines is dropped and reported', () async {
    // What happens when a content pack is uninstalled. Guessing a mass for it
    // would put an object of unknown weight in a player's pack.
    await db
        .into(db.inventoryLines)
        .insert(
          InventoryLinesCompanion.insert(
            profileId: profileId,
            itemId: 'weapon_from_a_pack_that_left',
          ).copyWith(count: const Value(2)),
        );

    final loaded = await store.load(profileId, catalogue);

    expect(loaded.inventory.carried, isEmpty);
    expect(loaded.droppedItemIds, ['weapon_from_a_pack_that_left']);
  });

  test('deleting the profile takes its inventory with it', () async {
    await store.save(
      profileId,
      const Inventory().add('mat_wood', catalogue, body: _body).inventory,
    );

    await (db.delete(db.profiles)..where((t) => t.id.equals(profileId))).go();

    expect(await db.inventoryFor(profileId), isEmpty);
  });

  test('a half-drunk bottle is still half drunk after a restart', () async {
    // §4.7: otherwise closing the app would refill everything anybody had
    // started, and the time a bottle takes would mean nothing.
    var inventory = const Inventory()
        .withPack('pack_daypack')
        .add('drink_water_bottle_500', catalogue, body: _body)
        .inventory;
    inventory = inventory.consumePortion(inventory.carried.single, 0.6);

    await store.save(profileId, inventory);
    final loaded = await store.load(profileId, catalogue);

    expect(loaded.inventory.carried.single.portion, closeTo(0.4, 0.001));
  });

  test('everything whole reads back whole', () async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('med_bandage', catalogue, body: _body, count: 2)
        .inventory;

    await store.save(profileId, inventory);
    final loaded = await store.load(profileId, catalogue);

    expect(loaded.inventory.carried.single.portion, 1);
  });
}

/// §15.4's worked character: 80 kg, so 24 kg comfortable and 36 kg hard.
final _body = BodyProfile.from(
  const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
);
