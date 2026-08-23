import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/craft/salvage_batch.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/game/controllers/craft_controller.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

/// WARSZTAT MA WŁAŚCICIELA (§18.4, §18.6).
///
/// ⚠️ **The one that genuinely needs two others, and gets neither.**
///
/// §18.2 makes the pack and the shelves one pile at a bench. That is a real
/// dependency — but a controller importing two neighbours is a controller
/// nobody can test without dragging both along. This file is the proof that
/// the bench does not: everything below runs with a database and a catalogue,
/// no pack, no shelves, no widgets.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final recipes = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());

  final now = DateTime.utc(2026, 8, 10, 12);

  late SaveDatabase db;
  late CraftController bench;
  late int profileId;

  setUp(() async {
    db = SaveDatabase.memory();
    bench = CraftController(db);

    profileId = await db.createProfile(
      profile: ProfilesCompanion.insert(
        name: 'Ocalały',
        sex: 'M',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        deathMode: 'hardcore',
        rngSeed: 1,
        createdAt: now,
      ),
      vitals: (id) => VitalsCompanion.insert(
        profileId: Value(id),
        lastUpdate: now,
        bloodMl: 5000,
        waterMl: 2500,
        caloriesKcal: 2500,
        heartRateBpm: 60,
      ),
    );
    bench.bind(profileId: profileId);
  });

  tearDown(() async {
    bench.dispose();
    await db.close();
  });

  group('§2.1a: one bench, one thing on it', () {
    test('what goes on comes back off disk', () async {
      await bench.beginCraft(
        recipeId: 'spear',
        now: now,
        work: const Duration(minutes: 20),
      );

      final job = await bench.load();

      expect(job?.recipeId, 'spear');
      expect(job?.isSalvage, isFalse);
      expect(job?.readyAt, now.add(const Duration(minutes: 20)));
    });

    test('a second thing replaces the first rather than queueing', () async {
      // §18 never asks for a queue, and a person has one pair of hands.
      await bench.beginCraft(
        recipeId: 'spear',
        now: now,
        work: const Duration(minutes: 20),
      );
      await bench.beginSalvageOne(
        itemId: 'tool_multitool',
        condition: 100,
        now: now,
        work: const Duration(minutes: 5),
      );

      final job = await bench.load();

      expect(job?.recipeId, isNull);
      expect(job?.salvageItemId, 'tool_multitool');
    });

    test('and clearing leaves nothing', () async {
      await bench.beginCraft(
        recipeId: 'spear',
        now: now,
        work: const Duration(minutes: 20),
      );
      await bench.clear();

      expect(await bench.load(), isNull);
    });

    test('nothing is written before anybody says whose bench it is', () async {
      final loose = CraftController(db);
      addTearDown(loose.dispose);

      await loose.beginCraft(
        recipeId: 'spear',
        now: now,
        work: const Duration(minutes: 20),
      );

      expect(await loose.load(), isNull);
    });
  });

  group('§18.6: a sitting, whether it was written as one or as many', () {
    test('a batch comes back as its own list', () async {
      final batch = SalvageBatch([
        const SalvageStep(
          uid: 'a.1',
          itemId: 'tool_multitool',
          condition: 100,
          takes: Duration(minutes: 6),
        ),
        const SalvageStep(
          uid: 'b.1',
          itemId: 'tool_can_opener',
          condition: 60,
          takes: Duration(minutes: 4),
        ),
      ]);

      await bench.beginSalvage(batch, now: now);
      final job = (await bench.load())!;

      final back = CraftController.sittingOf(job);

      expect(back.length, 2);
      expect(back.head?.itemId, 'tool_multitool');
      expect(job.readyAt, now.add(const Duration(minutes: 10)));
    });

    test('a row from before sittings existed reads as a sitting of one', () {
      // ⚠️ The whole reason this is one function. Two kinds of row, and
      // nothing downstream should ever have to tell them apart again.
      final old = CraftJob(
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 7)),
        salvageItemId: 'tool_multitool',
        salvageCondition: 40,
      );

      final sitting = CraftController.sittingOf(old);

      expect(sitting.length, 1);
      expect(sitting.head?.itemId, 'tool_multitool');
      expect(sitting.head?.condition, 40);
      expect(sitting.total, const Duration(minutes: 7));
    });

    test('a making is not a sitting at all', () {
      final making = CraftJob(
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 7)),
        recipeId: 'spear',
      );

      expect(CraftController.sittingOf(making).isEmpty, isTrue);
    });
  });

  group('§18.6: the lock on what is spoken for', () {
    test('a piece in the sitting is found by name, not by object', () {
      // §11.1: object identity does not survive a restart, and the row is
      // rebuilt by every edit.
      final rifle = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'r.1');
      bench.sitting.value = [rifle];

      final sameRifle = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'r.1');
      final otherRifle = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(uid: 'r.2');

      expect(bench.inSitting(sameRifle), isTrue);
      expect(bench.inSitting(otherRifle), isFalse);
    });

    test('stopping lets go of everything', () {
      bench.job.value = CraftJob(startedAt: now, readyAt: now);
      bench.sitting.value = [
        const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'r.1'),
      ];

      bench.stop();

      expect(bench.job.value, isNull);
      expect(bench.sitting.value, isEmpty);
    });
  });

  group('§18.6: what is worth opening, asked once per answer', () {
    final full = CraftBench(
      atShelter: true,
      workshopLevel: 1,
      atHand: const {'tool_multitool'},
      materials: const {},
    );

    bool worth(CarriedItem line) => bench.worthTakingApart(
      line,
      bench: full,
      catalogue: catalogue,
      book: recipes,
    );

    test(
      'a piece somebody has already opened is always worth going back to',
      () {
        // ⚠️ Before any of the arithmetic. Half a rifle is not a rifle, and the
        // only thing left to do with it is finish.
        final started = const CarriedItem(
          itemId: 'food_canned_meat',
        ).copyWith(salvageSeconds: 30);

        expect(worth(started), isTrue);
      },
    );

    test('a tin of meat is not worth taking apart', () {
      expect(worth(const CarriedItem(itemId: 'food_canned_meat')), isFalse);
    });

    test('the same question twice gives the same answer', () {
      // The cache is the point: this is asked once per row of a scrolling
      // list, and each miss costs a recipe lookup, a material breakdown and a
      // largest-remainder allocation.
      const rifle = CarriedItem(itemId: 'weapon_rifle_545', condition: 90);

      expect(worth(rifle), worth(rifle));
    });

    test('and how worn it is changes it (§18.6)', () {
      // Condition scales the return, so it has to be part of the key — or the
      // first answer would be given for every state the thing is ever in.
      const good = CarriedItem(itemId: 'weapon_rifle_545', condition: 100);
      const ruined = CarriedItem(itemId: 'weapon_rifle_545', condition: 1);

      expect(worth(good), isTrue);
      expect(worth(ruined), isFalse);
    });
  });
}
