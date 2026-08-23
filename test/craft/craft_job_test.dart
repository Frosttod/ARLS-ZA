import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/craft/craft_store.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/data/db/database.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/inventory/inventory_store.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/db_fixture.dart';

/// CO STOI NA WARSZTACIE (§18.4, §18.6, §2.1a.3).
///
/// Making and unmaking run against the wall clock, not against a bar somebody
/// watches. A forty-five minute pack is something to come back to, and the
/// whole reason there is a row in the database at all.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final book = checkedAgainst(
    RecipeBook.parse(File(kRecipesAsset).readAsStringSync()),
    catalogue,
  );

  final now = DateTime.utc(2026, 8, 20, 12);

  CraftBench bench({
    bool atShelter = true,
    int workshopLevel = 0,
    Set<String> atHand = const {},
    Map<String, int> materials = const {},
    bool busy = false,
  }) => CraftBench(
    atShelter: atShelter,
    workshopLevel: workshopLevel,
    atHand: atHand,
    materials: materials,
    busy: busy,
  );

  group('whether a thing can be started (§18.4)', () {
    final dressing = book.making('med_bandage_improvised')!;
    final spear = book.making('melee_spear')!;

    test('dressings need one of fabric and nothing else', () {
      // ⚠️ One, and the sitting makes four of them. A dressing is 50 g and the
      // smallest thing anybody can pick up is a 0.3 kg bolt of cloth — a recipe
      // cannot cost a fraction of a unit, so this used to cost three whole ones
      // and make a single dressing, and 95% of the cloth vanished.
      expect(refusalFor(dressing, bench(materials: {'mat_fabric': 1})), isNull);
      expect(
        refusalFor(dressing, bench(materials: {})),
        CraftRefusal.noMaterials,
      );
    });

    test('a spear needs the workshop, and says so', () {
      final have = {'mat_wood': 4, 'mat_metal': 2, 'mat_fabric': 2};

      expect(
        refusalFor(
          spear,
          bench(materials: have, atHand: const {'melee_hammer'}),
        ),
        CraftRefusal.noWorkshop,
      );
      expect(
        refusalFor(
          spear,
          bench(
            materials: have,
            atHand: const {'melee_hammer'},
            workshopLevel: 1,
          ),
        ),
        isNull,
      );
    });

    test('and a tool, of which either will do', () {
      final have = {'mat_wood': 4, 'mat_metal': 2, 'mat_fabric': 2};

      expect(
        refusalFor(spear, bench(materials: have, workshopLevel: 1)),
        CraftRefusal.noTool,
      );
      expect(
        refusalFor(
          spear,
          bench(
            materials: have,
            workshopLevel: 1,
            atHand: const {'tool_multitool'},
          ),
        ),
        isNull,
      );
    });

    test('nothing is made away from a shelter (§2.1a)', () {
      // Making is a shelter activity: it ticks with the app closed because the
      // character is standing where they keep their things.
      expect(
        refusalFor(
          dressing,
          bench(atShelter: false, materials: {'mat_fabric': 9}),
        ),
        CraftRefusal.notAtShelter,
      );
    });

    test('and not two at once', () {
      expect(
        refusalFor(dressing, bench(busy: true, materials: {'mat_fabric': 9})),
        CraftRefusal.busy,
      );
    });
  });

  group('whether a thing can be taken apart (§18.6)', () {
    CraftRefusal? refuse(String id, CraftBench b, {double condition = 100}) =>
        salvageRefusalFor(
          id,
          b,
          catalogue: catalogue,
          book: book,
          condition: condition,
        );

    test('it takes a multitool', () {
      expect(refuse('weapon_rifle_545', bench()), CraftRefusal.noTool);
      expect(
        refuse('weapon_rifle_545', bench(atHand: const {'tool_multitool'})),
        isNull,
      );
    });

    test('something with nothing in it is refused before the minutes', () {
      // ⚠️ Before, not after. Forty per cent of a pistol is nothing at all,
      // and finding that out at the end of a quarter of an hour is the worst
      // way for a player to learn the rule.
      expect(
        refuse('weapon_pistol_9mm', bench(atHand: const {'tool_multitool'})),
        CraftRefusal.nothingBack,
      );
    });

    test('and so is something ruined enough to be worth nothing', () {
      final good = bench(atHand: const {'tool_multitool'});

      expect(refuse('weapon_rifle_545', good), isNull);
      expect(
        refuse('weapon_rifle_545', good, condition: 5),
        CraftRefusal.nothingBack,
      );
    });

    test('the preview is what the job will actually hand back', () {
      final it = bench(atHand: const {'tool_multitool'});

      expect(
        salvagePreview(
          'weapon_rifle_545',
          it,
          catalogue: catalogue,
          book: book,
        ),
        {'mat_metal': 1},
      );
    });
  });

  group('the clock (§2.1a.3)', () {
    test('a job knows how far along it is', () {
      final job = CraftJob(
        recipeId: 'craft_spear',
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 20)),
      );

      expect(job.progressAt(now), 0);
      expect(job.progressAt(now.add(const Duration(minutes: 10))), 0.5);
      expect(job.isDoneAt(now.add(const Duration(minutes: 19))), isFalse);
      expect(job.isDoneAt(now.add(const Duration(minutes: 20))), isTrue);
    });

    test('and never reads as more than finished', () {
      final job = CraftJob(
        recipeId: 'craft_spear',
        startedAt: now,
        readyAt: now.add(const Duration(minutes: 20)),
      );

      expect(job.progressAt(now.add(const Duration(days: 3))), 1);
      expect(job.remainingAt(now.add(const Duration(days: 3))), Duration.zero);
    });
  });

  group('it survives the app being closed (§11.1)', () {
    late SaveDatabase db;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
    });

    tearDown(() => db.close());

    test('a making comes back as a making', () async {
      final store = CraftStore(db);
      await store.beginCraft(
        profileId,
        recipeId: 'craft_spear',
        now: now,
        work: const Duration(minutes: 25),
      );

      final back = (await store.load(profileId))!;

      expect(back.recipeId, 'craft_spear');
      expect(back.isSalvage, isFalse);
      expect(back.readyAt, now.add(const Duration(minutes: 25)));
    });

    test('and a dismantling keeps what the thing was worth', () async {
      // ⚠️ The condition travels with the job, because the item itself is
      // already gone from the pack — it left when the work started, so that a
      // rifle being taken apart cannot also be fired.
      final store = CraftStore(db);
      await store.beginSalvage(
        profileId,
        itemId: 'weapon_rifle_545',
        condition: 63,
        now: now,
        work: const Duration(minutes: 9),
      );

      final back = (await store.load(profileId))!;

      expect(back.isSalvage, isTrue);
      expect(back.salvageItemId, 'weapon_rifle_545');
      expect(back.salvageCondition, 63);
      expect(back.recipeId, isNull);
    });

    test('only one thing is ever on the bench', () async {
      // A person has one pair of hands. §18 never asks for a queue, and a
      // queue would need an order nobody has specified.
      final store = CraftStore(db);
      await store.beginCraft(
        profileId,
        recipeId: 'craft_spear',
        now: now,
        work: const Duration(minutes: 25),
      );
      await store.beginCraft(
        profileId,
        recipeId: 'craft_spike',
        now: now,
        work: const Duration(minutes: 8),
      );

      expect((await store.load(profileId))!.recipeId, 'craft_spike');
    });

    test('and clearing it leaves nothing behind', () async {
      final store = CraftStore(db);
      await store.beginCraft(
        profileId,
        recipeId: 'craft_spear',
        now: now,
        work: const Duration(minutes: 25),
      );
      await store.clear(profileId);

      expect(await store.load(profileId), isNull);
    });
  });

  group('stopping half way (§18.6)', () {
    test('a job resumed keeps the work already done', () {
      // ⚠️ The bar picks up where it was left. Starting the job in the past by
      // however long it has already had is what does it, and it means a
      // dismantling somebody comes back to three times still takes exactly
      // the minutes §18.6 asked for.
      const whole = Duration(minutes: 12);
      const done = Duration(minutes: 5);

      final resumed = CraftJob(
        salvageItemId: 'weapon_rifle_545',
        salvageCondition: 100,
        startedAt: now.subtract(done),
        readyAt: now.subtract(done).add(whole),
      );

      expect(resumed.progressAt(now), closeTo(5 / 12, 0.001));
      expect(resumed.remainingAt(now), const Duration(minutes: 7));
    });

    test('and the whole thing still takes the same time', () {
      const whole = Duration(minutes: 12);
      var done = Duration.zero;

      // Three sittings of two minutes, then whatever is left.
      for (var i = 0; i < 3; i++) {
        final job = CraftJob(
          salvageItemId: 'weapon_rifle_545',
          startedAt: now.subtract(done),
          readyAt: now.subtract(done).add(whole),
        );
        expect(job.isDoneAt(now), isFalse);
        done += const Duration(minutes: 2);
      }

      final last = CraftJob(
        salvageItemId: 'weapon_rifle_545',
        startedAt: now.subtract(done),
        readyAt: now.subtract(done).add(whole),
      );

      expect(last.remainingAt(now), const Duration(minutes: 6));
      expect(last.isDoneAt(now.add(const Duration(minutes: 6))), isTrue);
    });

    test('a piece opened at all is a piece that no longer works', () {
      // The rule that makes stopping a decision rather than a free look
      // inside. Half a rifle is not a rifle.
      const untouched = CarriedItem(itemId: 'weapon_rifle_545');
      final opened = untouched.copyWith(salvageSeconds: 1);

      expect(untouched.isPartlyDismantled, isFalse);
      expect(opened.isPartlyDismantled, isTrue);
    });

    test('and one second counts, because nought would read as untouched', () {
      final barely = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(salvageSeconds: 1);

      expect(barely.isPartlyDismantled, isTrue);
    });
  });

  group('it survives the pack being put down (§4.8, §18.2)', () {
    late SaveDatabase db;
    late int profileId;

    setUp(() async {
      db = SaveDatabase.memory();
      profileId = await insertProfile(db);
    });

    tearDown(() => db.close());

    test('a half-dismantled rifle is still half-dismantled tomorrow', () async {
      final store = InventoryStore(db);
      await store.save(
        profileId,
        Inventory(
          carried: [
            const CarriedItem(
              itemId: 'weapon_rifle_545',
            ).copyWith(salvageSeconds: 200, rounds: 12),
          ],
        ),
      );

      final back = (await store.load(profileId, catalogue)).inventory;

      expect(back.carried.single.salvageSeconds, 200);
      expect(back.carried.single.rounds, 12, reason: 'and still loaded');
    });
  });
}
