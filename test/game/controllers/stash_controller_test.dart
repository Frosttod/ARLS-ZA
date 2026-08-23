import 'dart:io';

import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/stash_controller.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:arls_za/shelter/shelter_store.dart';
import 'package:arls_za/shelter/stash.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

/// PÓŁKI MAJĄ WŁAŚCICIELA (§18.2, §8.5.1).
///
/// ⚠️ **The shelves are not the pack, and this file is where that stays true.**
///
/// A shelf holds what it holds and refuses the rest. A pack has a body behind
/// it — comfort, a maximum, a surcharge for being over (§18.1a). They stay
/// simpler by not sharing a class, and now by not sharing an owner.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  const where = GeoPoint(52.4064, 16.9252);

  late SaveDatabase db;
  late StashController shelf;
  late int profileId;

  /// ⚠️ A real row, because `shelter_items` has a foreign key to it. A shelf
  /// belongs to a shelter — that constraint is the reason things left in one
  /// place cannot turn up in another.
  late Shelter home;

  setUp(() async {
    db = SaveDatabase.memory();
    shelf = StashController(db);

    profileId = await db.createProfile(
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
    shelf.bind(profileId: profileId);

    final id = await ShelterStore(db).begin(
      profileId,
      kind: ShelterKind.main,
      at: where,
      now: DateTime.utc(2026),
      buildTime: Duration.zero,
    );
    home = Shelter(
      id: id,
      kind: ShelterKind.main,
      position: where,
      startedAt: DateTime.utc(2026),
      buildTime: Duration.zero,
    );
  });

  tearDown(() async {
    shelf.dispose();
    await db.close();
  });

  group('with no shelter open', () {
    test('there is nothing to write to, and nothing is written', () async {
      shelf.shelves = Stash(
        capacityKg: 25,
        lines: [const CarriedItem(itemId: 'mat_metal', count: 4)],
      );

      // ⚠️ The rule this exists for: shelves saved against no shelter would
      // put one shelter's things into another's.
      await shelf.save();

      expect(shelf.openAt, isNull);
      expect(await db.stashFor(profileId, home.id), isEmpty);
    });
  });

  group('with one open', () {
    setUp(() async {
      await shelf.open(home, catalogue);
    });

    test('it remembers which shelves they are', () {
      expect(shelf.openAt?.id, home.id);
    });

    test('and what goes on them comes back off disk', () async {
      shelf.shelves = shelf.shelves
          .put(const CarriedItem(itemId: 'mat_metal', count: 4), catalogue)
          .stash;
      await shelf.save();

      final other = StashController(db)..bind(profileId: profileId);
      addTearDown(other.dispose);

      await other.open(home, catalogue);

      expect(other.counts()['mat_metal'], 4);
    });

    test('closing forgets both the shelves and where they were', () {
      shelf.close();

      expect(shelf.openAt, isNull);
      expect(shelf.shelves.lines, isEmpty);
    });
  });

  group('§18.1a: overflow goes on a shelf, never nowhere', () {
    test('what will not fit in a pack lands here', () async {
      await shelf.open(home, catalogue);
      await shelf.spill({'mat_metal': 3}, home, catalogue);

      expect(shelf.counts()['mat_metal'], 3);
    });

    test('it works without the shelves screen ever being opened', () async {
      // ⚠️ Reached when a bench job finishes. The player is standing in the
      // shelter; they have not opened a cupboard.
      expect(shelf.openAt, isNull);

      await shelf.spill({'mat_metal': 2}, home, catalogue);

      expect(shelf.counts()['mat_metal'], 2);
      expect(await db.stashFor(profileId, home.id), isNotEmpty);
    });

    test('a stack that will not fit loses one, not all of it', () async {
      // The shelves refuse a *line*, so a stack of five offered whole and
      // refused would lose five. Offered one at a time, what fits fits.
      await shelf.open(home, catalogue);
      await shelf.spill({'mat_metal': 400}, home, catalogue);

      final put = shelf.counts()['mat_metal'] ?? 0;

      expect(put, greaterThan(0), reason: 'some of it must get on the shelf');
      expect(put, lessThan(400), reason: 'and the shelf must fill up');
    });

    test('nothing at all is a write nobody makes', () async {
      await shelf.spill(const {}, home, catalogue);
      expect(await db.stashFor(profileId, home.id), isEmpty);
    });
  });

  test('the notifier survives everything, because screens hold it', () {
    final notifier = shelf.stash;

    shelf.close();
    shelf.bind(profileId: 9);

    expect(identical(shelf.stash, notifier), isTrue);
  });
}
