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

  group('§18.2: onto the shelves from a screen that never opened them', () {
    // ⚠️ **The asymmetry reported from the field.** Magazyn → Ekwipunek worked
    // and Ekwipunek → Magazyn did not, while the *same item* moved happily
    // from the shelves screen. The shelves screen had opened the shelves; the
    // pack screen had not, so it was asking questions of the empty stash a
    // controller starts with — capacity nought, which [Stash.fits] correctly
    // reads as full. Every item, refused, with a message that looked like a
    // rule about space.
    const spanner = CarriedItem(itemId: 'tool_multitool', count: 1);

    test('the shelves are read in first, whoever asks', () async {
      expect(shelf.openAt, isNull, reason: 'nobody has opened them');

      final left = await shelf.shelve(
        spanner,
        place: home,
        catalogue: catalogue,
        from: const Inventory(carried: [spanner]),
      );

      expect(left?.carried, isEmpty);
      expect(shelf.shelves.lines.single.itemId, 'tool_multitool');
    });

    test('and what was already on them is still there afterwards', () async {
      // ⚠️ The half of this that was never a refusal but a loss. Had a move
      // got past the capacity of nought, `saveTo` would have written the empty
      // stash plus one item back over the real shelves as their contents.
      await shelf.open(home, catalogue);
      await shelf.shelve(
        const CarriedItem(itemId: 'mat_metal', count: 3),
        place: home,
        catalogue: catalogue,
        from: const Inventory(
          carried: [CarriedItem(itemId: 'mat_metal', count: 3)],
        ),
      );
      shelf.close();

      await shelf.shelve(
        spanner,
        place: home,
        catalogue: catalogue,
        from: const Inventory(carried: [spanner]),
      );

      expect(
        shelf.shelves.lines.map((line) => line.itemId),
        containsAll(<String>['mat_metal', 'tool_multitool']),
      );
      expect(await db.stashFor(profileId, home.id), hasLength(2));
    });

    test('it is on disk before the pack is told anything', () async {
      await shelf.shelve(
        spanner,
        place: home,
        catalogue: catalogue,
        from: const Inventory(carried: [spanner]),
      );

      expect(await db.stashFor(profileId, home.id), hasLength(1));
    });

    test('a shelf with no room refuses, and takes nothing', () async {
      await shelf.open(home, catalogue);
      shelf.shelves = const Stash(capacityKg: 0);

      final left = await shelf.shelve(
        spanner,
        place: home,
        catalogue: catalogue,
        from: const Inventory(carried: [spanner]),
      );

      expect(left, isNull, reason: 'null is the refusal');
      expect(shelf.shelves.lines, isEmpty);
    });

    test('and the game actually goes through it', () {
      // ⚠️ Source-level, because [shelve] could be perfect and the pack screen
      // still put things away against its own copy of an empty stash — which
      // is exactly what it was doing.
      final main = File('lib/main.dart').readAsStringSync();

      expect(main.contains('_shelf.shelve('), isTrue);
      expect(
        main.contains('_stash.value.put('),
        isFalse,
        reason: 'a screen is moving things onto shelves it never opened',
      );
      expect(
        main.contains('if (_shelf.openAt == null) return null;'),
        isTrue,
        reason: 'unread shelves are answering "full" again',
      );
    });

    test('opening the same shelves twice does not read them twice', () async {
      await shelf.open(home, catalogue);
      final before = shelf.shelves;

      await shelf.ensureOpen(home, catalogue);

      expect(identical(shelf.shelves, before), isTrue);
    });
  });
}
