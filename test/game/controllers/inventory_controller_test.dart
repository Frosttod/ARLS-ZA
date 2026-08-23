import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/inventory_controller.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/sim/body.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

/// PLECAK MA WŁAŚCICIELA (§18.1a, §11.1).
///
/// ⚠️ **The point of this file is that it exists at all.**
///
/// Everything below used to live on a six-and-a-half-thousand-line
/// `State`, which meant testing "does the pack know how much room is left"
/// required a widget, a binding, a pump and a whole running game. So it was
/// not tested — and §18.1a's two limits were read off a cache nobody could
/// reach.
///
/// A controller is constructible with a database and nothing else. That is the
/// whole exit criterion of this phase.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  late SaveDatabase db;
  late InventoryController pack;

  setUp(() async {
    db = SaveDatabase.memory();
    pack = InventoryController(db);
  });

  tearDown(() async {
    pack.dispose();
    await db.close();
  });

  Future<int> makeProfile() => db.createProfile(
    profile: ProfilesCompanion.insert(
      name: 'Ocalały',
      sex: 'M',
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      deathMode: 'hardcore',
      rngSeed: 1,
      createdAt: DateTime.utc(2026),
    ),
    vitals: (id) => VitalsCompanion.insert(
      profileId: Value(id),
      lastUpdate: DateTime.utc(2026),
      bloodMl: 5000,
      waterMl: 2500,
      caloriesKcal: 2500,
      heartRateBpm: 60,
    ),
  );

  group('before anybody says whose pack it is', () {
    test('it holds an empty one and answers rather than throwing', () {
      // ⚠️ The notifiers exist from the first frame so screens can be handed
      // one before the character has loaded. Everything must therefore have a
      // sensible answer with no character at all.
      expect(pack.isBound, isFalse);
      expect(pack.pack.carried, isEmpty);
      expect(pack.counts(), isEmpty);
      expect(pack.ids(), isEmpty);
      expect(pack.room().massKg, 0);
    });

    test('and writing goes nowhere rather than to the wrong profile', () async {
      pack.pack = Inventory(
        carried: [const CarriedItem(itemId: 'food_canned_meat')],
      );

      // No exception, and nothing on disk: there is no profile to write to.
      await pack.save();
      expect(pack.pack.carried, hasLength(1));
    });
  });

  group('once it knows', () {
    late int profileId;

    setUp(() async {
      profileId = await makeProfile();
      pack.bind(profileId: profileId, catalogue: catalogue, body: body);
    });

    test('what goes in comes back off disk', () async {
      pack.pack = Inventory(
        carried: [
          const CarriedItem(itemId: 'food_canned_meat', count: 3),
          const CarriedItem(itemId: 'drink_water_bottle_500'),
        ],
      );
      await pack.save();

      // A second controller over the same database: what one wrote, the other
      // reads. Nothing is being remembered in memory here.
      final other = InventoryController(db)
        ..bind(profileId: profileId, catalogue: catalogue, body: body);
      addTearDown(other.dispose);

      await other.load(catalogue);

      expect(other.counts()['food_canned_meat'], 3);
      expect(other.counts()['drink_water_bottle_500'], 1);
    });

    test('counts are by item and ids include what is worn', () {
      pack.pack = Inventory(
        carried: [const CarriedItem(itemId: 'food_canned_meat', count: 2)],
        worn: [const CarriedItem(itemId: 'tool_multitool')],
      );

      expect(pack.counts(), {'food_canned_meat': 2});
      expect(pack.ids(), {'food_canned_meat', 'tool_multitool'});
      expect(
        pack.carries('tool_multitool'),
        isTrue,
        reason: 'a multitool in the hand is a multitool to hand (§18.3)',
      );
    });

    test('§18.1a: room left comes down as things go in', () {
      final empty = pack.room().massKg;

      pack.pack = Inventory(
        carried: [const CarriedItem(itemId: 'food_canned_meat', count: 10)],
      );

      expect(pack.room().massKg, lessThan(empty));
    });

    test('and the answer is cached on the pack it was asked about', () {
      // ⚠️ Identity, not contents. Every edit replaces the whole Inventory, so
      // a reference comparison is exact — and this is asked once per row of a
      // list somebody is scrolling.
      pack.pack = Inventory(
        carried: [const CarriedItem(itemId: 'food_canned_meat')],
      );

      final first = pack.room();
      expect(identical(pack.room(), first), isTrue);

      pack.pack = Inventory(
        carried: [const CarriedItem(itemId: 'food_canned_meat', count: 9)],
      );
      expect(identical(pack.room(), first), isFalse);
    });

    test('§4.7: one portion is written without rewriting the pack', () async {
      // The reported freeze: the wholesale write deletes every row and inserts
      // them back, once a second, for the length of a meal.
      pack.pack = Inventory(
        carried: [
          const CarriedItem(
            itemId: 'food_canned_meat',
          ).copyWith(uid: 'a.1', portion: 1),
          const CarriedItem(
            itemId: 'drink_water_bottle_500',
          ).copyWith(uid: 'b.1'),
        ],
      );
      await pack.save();

      await pack.savePortion('a.1', 0.42);

      final rows = await db.inventoryFor(profileId);
      final tin = rows.firstWhere((row) => row.uid == 'a.1');
      final bottle = rows.firstWhere((row) => row.uid == 'b.1');

      expect(tin.portion, closeTo(0.42, 1e-9));
      expect(
        bottle.portion,
        closeTo(1, 1e-9),
        reason: 'nothing else may move when one mouthful is written down',
      );
    });
  });

  test('the notifier survives everything, because screens hold it', () {
    // ⚠️ Created once and never replaced. A screen that took a reference at
    // boot must still have the right one an hour later — this codebase has
    // found the opposite bug six times.
    final notifier = pack.inventory;

    pack.pack = Inventory(
      carried: [const CarriedItem(itemId: 'food_canned_meat')],
    );
    pack.bind(profileId: 7, catalogue: catalogue, body: body);

    expect(identical(pack.inventory, notifier), isTrue);
  });
}
