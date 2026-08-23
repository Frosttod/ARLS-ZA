import 'dart:io';

import 'package:arls_za/combat/attachment.dart';
import 'package:arls_za/inventory/body_slots.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/sim/body.dart';
import 'package:test/test.dart';

/// §18.1a. Two limits and no third one: the tests that matter here are the
/// ones §18.1a states as outcomes — twelve pieces of wood, thirty-two of
/// plastic — because those are the numbers a player feels when deciding what
/// to leave behind.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  // §18.1a's own worked example: 80 kg body, so 24 kg comfortable and 36 kg
  // hard, with a 65 l trekking pack.
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  Inventory withTrekking() => const Inventory().withPack('pack_trekking');

  group('the limits themselves', () {
    test('come from the body until a pack changes them (§1.3)', () {
      final limits = const Inventory().limits(body, catalogue);

      expect(limits.comfortKg, closeTo(24, 0.01));
      expect(limits.maxKg, closeTo(36, 0.01));
      expect(limits.capacityL, kPocketCapacityL);
    });

    test('a trekking pack lifts comfort 24 -> 36 kg (§10.3.4)', () {
      final limits = withTrekking().limits(body, catalogue);

      expect(limits.comfortKg, closeTo(36, 0.01));
      expect(limits.capacityL, 65);
    });

    test('every pack in the catalogue helps more than the last', () {
      final packs =
          catalogue.all
              .where((item) => item.props['capacity_l'] != null)
              .toList()
            ..sort(
              (a, b) => (a.props['capacity_l']! as num).compareTo(
                b.props['capacity_l']! as num,
              ),
            );

      var previous = 0.0;
      for (final pack in packs) {
        final bonus = (pack.props['comfort_carry_bonus_kg']! as num).toDouble();
        expect(bonus, greaterThanOrEqualTo(previous), reason: pack.id);
        previous = bonus;
      }
    });
  });

  group('§18.1a\'s table, which is the point of having two limits', () {
    // The doc's worked figures: how many pieces fit inside 24 kg of comfort
    // carry, and inside a 65 l pack. Which of the two runs out first is what
    // gives each material its character.
    //
    // ⚠️ **Plastic used to be the volume problem and is not any more.** It was
    // 0.4 kg in 2.0 l — a fifth of the density of the stuff itself, which is a
    // piece of plastic that is four fifths air. Cut down to 0.8 l it is honest
    // and it binds by mass like everything else.
    //
    // Fabric is now the only material that runs out of bulk first, and that
    // matters: §18.1a has two limits so that both of them bite, and after this
    // change exactly one material makes the second one bite. Wood comes close
    // (12 against 16). If a third material is ever added, this is the gap it
    // should fill.
    void expectLimits(
      String itemId, {
      required int byMass,
      required int byVolume,
    }) {
      final item = catalogue[itemId]!;
      expect((24 / item.weightKg).floor(), byMass, reason: '$itemId by mass');
      expect((65 / item.volumeL).floor(), byVolume, reason: '$itemId by bulk');
    }

    test('wood: 12 by mass, 16 by volume — mass binds', () {
      expectLimits('mat_wood', byMass: 12, byVolume: 16);
    });

    test('metal: 32 by mass, 216 by volume — mass binds', () {
      // ⚠️ A hand-sized piece at 0.75 kg, not an armful at 1.5. Exactly half,
      // so §18.2's build rows hold to the gram when their counts double.
      expectLimits('mat_metal', byMass: 32, byVolume: 216);
    });

    test('plastic: 60 by mass, 81 by volume — mass binds now', () {
      expectLimits('mat_plastic', byMass: 60, byVolume: 81);
    });

    test('fabric: 80 by mass, 65 by volume — volume binds', () {
      expectLimits('mat_fabric', byMass: 80, byVolume: 65);
    });

    test('component: 30 by mass, 162 by volume — mass binds', () {
      expectLimits('mat_component', byMass: 30, byVolume: 162);
    });

    test('the pack stops filling at whichever runs out first', () {
      // Same query against the real inventory, where the hard limit is 36 kg
      // (§1.3) rather than the comfortable 24 the table illustrates.
      int fits(String itemId) => const Inventory()
          .withPack('pack_trekking')
          .add(itemId, catalogue, body: body, count: 500)
          .inventory
          .countOf(itemId);

      // 36 + 12 kg of limit against 2.0 kg a piece, and 65 l against 4.0 l.
      expect(fits('mat_wood'), 16, reason: 'volume runs out first');
      expect(fits('mat_fabric'), 65, reason: 'volume, well before mass');
      expect(fits('mat_metal'), 61, reason: 'mass, well before volume');
    });
  });

  group('what happens at a limit', () {
    test('a load over comfortable is allowed, and only costs (§1.3)', () {
      // The game may never slow a real walking player down. The price of an
      // overloaded pack is metabolic, not a refusal.
      var inventory = withTrekking();
      final result = inventory.add(
        'mat_metal',
        catalogue,
        body: body,
        count: 52,
      );
      inventory = result.inventory;

      expect(result.isAccepted, isTrue);
      // 39 kg on a body whose comfortable load with this pack is 36.
      expect(inventory.massKg(catalogue), greaterThan(36));
      expect(inventory.isOverComfort(body, catalogue), isTrue);
    });

    test('a load over the hard limit is refused — it cannot be lifted', () {
      final result = withTrekking().add(
        'mat_metal',
        catalogue,
        body: body,
        count: 120,
      );

      // 48 kg of limit, less the 1.8 kg pack, over 0.75 kg a piece.
      expect(result.refusal, RefusalReason.tooHeavy);
      expect(result.acceptedCount, 61);
    });

    test('what fits is taken, rather than the whole pile refused', () {
      // A player standing over forty rounds with room for twelve gets twelve.
      final result = withTrekking().add(
        'mat_fabric',
        catalogue,
        body: body,
        count: 100,
      );

      // ⚠️ Fabric, not plastic. Plastic used to run out of room first and no
      // longer does — see the note on §18.1a's table above.
      expect(result.refusal, RefusalReason.noRoom);
      expect(result.acceptedCount, 65);
      expect(result.inventory.countOf('mat_fabric'), 65);
    });

    test('nothing fits at all is a refusal, not an empty acceptance', () {
      var inventory = withTrekking();
      inventory = inventory
          .add('mat_fabric', catalogue, body: body, count: 65)
          .inventory;

      final result = inventory.add('mat_fabric', catalogue, body: body);

      expect(result.isAccepted, isFalse);
      expect(result.acceptedCount, 0);
    });

    test('an item the catalogue lost is refused by name', () {
      final result = const Inventory().add(
        'weapon_railgun',
        catalogue,
        body: body,
      );

      expect(result.refusal, RefusalReason.unknownItem);
    });
  });

  group('worn kit', () {
    test('costs mass but not volume — a coat is not in the rucksack', () {
      final worn = withTrekking().wear('cloth_winter_jacket');

      expect(worn.massKg(catalogue), greaterThan(1.2));
      expect(worn.volumeL(catalogue), 0);
    });

    test('the full combat kit of §10.3.4 fits, and leaves room', () {
      // The design's own load-out. If this does not fit, the game is a
      // rucksack simulator and §10.3.4's ~35 shelter trips do not happen.
      var inventory = withTrekking();
      for (final id in const [
        'cloth_winter_jacket',
        'cloth_winter_trousers',
        'cloth_boots',
        'armor_helmet_ballistic',
        'weapon_rifle_545',
        'melee_machete',
      ]) {
        inventory = inventory.wear(id);
      }

      for (final line in const [
        ('ammo_545x39', 60),
        ('drink_water_bottle_1500', 1),
        ('food_canned_meat', 2),
        ('food_energy_bar', 3),
        ('med_first_aid_kit', 1),
        ('med_tourniquet', 1),
        ('tool_multitool', 1),
        ('tool_flashlight', 1),
        ('tool_binoculars', 1),
      ]) {
        final result = inventory.add(
          line.$1,
          catalogue,
          body: body,
          count: line.$2,
        );
        expect(result.isAccepted, isTrue, reason: line.$1);
        inventory = result.inventory;
      }

      final limits = inventory.limits(body, catalogue);
      expect(inventory.massKg(catalogue), lessThan(limits.maxKg));
      expect(inventory.volumeL(catalogue), lessThan(limits.capacityL));
      // §10.3.4 wants roughly 21 kg and 35 l left over for loot.
      expect(limits.maxKg - inventory.massKg(catalogue), greaterThan(15));
      expect(limits.capacityL - inventory.volumeL(catalogue), greaterThan(30));
    });

    test('a second coat replaces the first rather than layering', () {
      // §4.4 gives every garment a slot. Without it a player wears four vests
      // for four times the protection, and the dev fill button showed exactly
      // that: two winter jackets on one character.
      final dressed = const Inventory()
          .withPack('pack_daypack')
          .wear('cloth_winter_jacket', catalogue)
          .wear('cloth_winter_jacket', catalogue);

      expect(dressed.worn, hasLength(1));
      // The one taken off is in the pack, not gone: nothing the game removes
      // from a player should vanish.
      expect(dressed.countOf('cloth_winter_jacket'), 1);
    });

    test('different slots stack, because that is what clothing is', () {
      final dressed = const Inventory()
          .wear('cloth_thermal_underwear', catalogue)
          .wear('cloth_fleece', catalogue)
          .wear('cloth_winter_jacket', catalogue)
          .wear('cloth_boots', catalogue);

      expect(dressed.worn, hasLength(4));
    });

    test('taking something off puts it in the pack, not on the floor', () {
      final dressed = const Inventory()
          .withPack('pack_daypack')
          .wear('armor_vest_soft', catalogue);

      final undressed = dressed.takeOff('armor_vest_soft');

      expect(undressed.worn, isEmpty);
      expect(undressed.countOf('armor_vest_soft'), 1);
    });

    test('and is never refused for want of room', () {
      // A vest comes off whether or not the pack can take it. Refusing would
      // mean the game makes somebody keep wearing armour because their bag is
      // full; the overflow is reported instead (§18.1a).
      var inventory = const Inventory().wear('armor_vest_plate', catalogue);
      inventory = inventory
          .add('mat_plastic', catalogue, body: body, count: 6)
          .inventory;

      final undressed = inventory.takeOff('armor_vest_plate');

      expect(undressed.worn, isEmpty);
      expect(undressed.overflowL(body, catalogue), greaterThan(0));
    });

    test('taking off something not worn changes nothing', () {
      final dressed = const Inventory().wear('cloth_boots', catalogue);

      expect(dressed.takeOff('armor_vest_soft').worn, hasLength(1));
    });

    test('insulation adds up across garments, not per garment (§4.4)', () {
      final dressed = const Inventory()
          .wear('cloth_thermal_underwear', catalogue)
          .wear('cloth_fleece', catalogue)
          .wear('cloth_winter_jacket', catalogue);

      expect(dressed.insulationClo(catalogue), closeTo(0.8 + 1.0 + 2.2, 0.001));
    });
  });

  group('armour, which only protects where it covers (§4.4)', () {
    final armoured = const Inventory().wear('armor_vest_soft');

    test('a hit inside the covered fraction is reduced', () {
      expect(
        armoured.protectionAgainst(
          catalogue: catalogue,
          slot: 'torso_armor',
          hitRoll: 0.2,
        ),
        2,
      );
    });

    test('a hit outside it is not — 55% coverage is not 100%', () {
      expect(
        armoured.protectionAgainst(
          catalogue: catalogue,
          slot: 'torso_armor',
          hitRoll: 0.9,
        ),
        0,
      );
    });

    test('a hit to a limb ignores a vest entirely', () {
      expect(
        armoured.protectionAgainst(
          catalogue: catalogue,
          slot: 'arms',
          hitRoll: 0.1,
        ),
        0,
      );
    });

    test('blunt damage bypasses half of it (§4.3)', () {
      expect(
        armoured.protectionAgainst(
          catalogue: catalogue,
          slot: 'torso_armor',
          hitRoll: 0.2,
          blunt: true,
        ),
        1,
      );
    });
  });

  group('books, which each weigh their own page count (§4.6.4)', () {
    test('a long copy weighs more than a short one of the same title', () {
      final light = const Inventory()
          .withPack('pack_trekking')
          .add(
            'lit_encyclopedia_medicine',
            catalogue,
            body: body,
            pagesTotal: 400,
          )
          .inventory;
      final heavy = const Inventory()
          .withPack('pack_trekking')
          .add(
            'lit_encyclopedia_medicine',
            catalogue,
            body: body,
            pagesTotal: 900,
          )
          .inventory;

      // §4.6.4: 1.12 kg against 2.02 kg, and the second is 8% of comfort carry.
      expect(light.massKg(catalogue) - 1.8, closeTo(1.12, 0.01));
      expect(heavy.massKg(catalogue) - 1.8, closeTo(2.02, 0.01));
    });

    test('two copies are two entries, because each has its own progress', () {
      final shelf = const Inventory()
          .withPack('pack_trekking')
          .add(
            'lit_guide_survival',
            catalogue,
            body: body,
            count: 2,
            pagesTotal: 120,
          )
          .inventory;

      expect(shelf.carried, hasLength(2));
      expect(shelf.countOf('lit_guide_survival'), 2);
    });
  });

  group('swapping the pack', () {
    test('a smaller pack can leave the player over the limit, and says so', () {
      // The game does not get to decide what a player throws away.
      var inventory = withTrekking();
      inventory = inventory
          .add('mat_plastic', catalogue, body: body, count: 30)
          .inventory;

      final downgraded = inventory.withPack('pack_school');

      expect(downgraded.overflowL(body, catalogue), greaterThan(0));
      expect(inventory.overflowL(body, catalogue), 0);
    });

    test('dropping what you do not have fails rather than half-succeeding', () {
      final inventory = withTrekking()
          .add('mat_wood', catalogue, body: body, count: 3)
          .inventory;

      expect(inventory.remove('mat_wood', count: 5), isNull);
      expect(inventory.remove('mat_wood', count: 3)!.carried, isEmpty);
    });
  });

  test('the shelter store has both limits too (§18.1a)', () {
    // 125 kg of capacity is 375 l, which stops 312 pieces of plastic that fit
    // by mass alone and would need 624 l.
    expect(const StoreLimits(125).capacityL, 375);
  });

  group('two of a kind are two different things to own', () {
    // A knife at 30% and a knife at 80% share an item id and nothing else that
    // matters. Everything that acts on "the knife" has to act on the one that
    // was pointed at.
    Inventory pair() {
      const sharp = CarriedItem(itemId: 'melee_knife', condition: 80);
      const blunt = CarriedItem(itemId: 'melee_knife', condition: 30);
      return const Inventory(carried: [sharp, blunt]);
    }

    test('the copy that was dropped is the copy that leaves', () {
      final inventory = pair();
      final blunt = inventory.carried[1];

      final after = inventory.removeLine(blunt)!;

      expect(after.carried.single.condition, 80);
    });

    test('and the other one, when it is the other one', () {
      final inventory = pair();
      final sharp = inventory.carried[0];

      final after = inventory.removeLine(sharp)!;

      expect(after.carried.single.condition, 30);
    });

    test('a copy that is no longer there still drops something', () {
      // A stale tap from a screen built before the last change. Better one
      // knife gone than a button that silently does nothing.
      const gone = CarriedItem(itemId: 'melee_knife', condition: 55);

      expect(pair().removeLine(gone)!.carried, hasLength(1));
    });

    test('dropping more of a copy than there is drops nothing', () {
      final inventory = const Inventory()
          .withPack('pack_trekking')
          .add('mat_wood', catalogue, body: body, count: 2)
          .inventory;

      expect(inventory.removeLine(inventory.carried.first, count: 5), isNull);
    });

    test('part of a stack leaves the rest of that stack', () {
      final inventory = const Inventory()
          .withPack('pack_trekking')
          .add('mat_wood', catalogue, body: body, count: 4)
          .inventory;

      final after = inventory.removeLine(inventory.carried.first, count: 3)!;

      expect(after.carried.single.count, 1);
    });
  });

  group('what is put on is the piece that was put on', () {
    test('a worn-out vest does not become a new one by being worn', () {
      // Found on a phone: wearing the 40% vest produced a vest with no
      // condition at all, which is the game quietly repairing kit.
      const battered = CarriedItem(itemId: 'armor_vest_soft', condition: 40);

      final after = const Inventory(
        carried: [battered],
      ).removeLine(battered)!.wearLine(battered, catalogue);

      expect(after.worn.single.condition, 40);
    });

    test('a book keeps its own pages when it goes on the body', () {
      const copy = CarriedItem(
        itemId: 'armor_vest_soft',
        condition: 62,
        count: 1,
      );

      expect(
        const Inventory().wearLine(copy, catalogue).worn.single.condition,
        62,
      );
    });

    test('only one piece of a stack is put on', () {
      const two = CarriedItem(itemId: 'armor_vest_soft', count: 2);

      expect(const Inventory().wearLine(two, catalogue).worn.single.count, 1);
    });

    test(
      'wearing by id still works, for anything that has no copy in hand',
      () {
        expect(
          const Inventory()
              .wear('armor_vest_soft', catalogue)
              .worn
              .single
              .itemId,
          'armor_vest_soft',
        );
      },
    );

    test('the displaced piece keeps its own condition too', () {
      const old = CarriedItem(itemId: 'armor_vest_soft', condition: 25);
      const found = CarriedItem(itemId: 'armor_vest_soft', condition: 95);

      final after = const Inventory(worn: [old]).wearLine(found, catalogue);

      expect(after.worn.single.condition, 95);
      expect(after.carried.single.condition, 25);
    });
  });

  group('changing bags in a street', () {
    // Found on a phone: a 45 l daypack swapped for a 30 l shopping bag was
    // destroyed, because the old pack was offered to the new one and a bag
    // with no room refused it. Nothing a player owns is destroyed by an action
    // they took to keep it.
    Inventory loadedDaypack() => const Inventory()
        .withPack('pack_daypack')
        .add('mat_wood', catalogue, body: body, count: 10)
        .inventory;

    test('the old pack ends up in the new one', () {
      final full = loadedDaypack();
      const bag = CarriedItem(itemId: 'pack_shopping_bag');

      final after = full.wearPack(bag);

      expect(after.packId, 'pack_shopping_bag');
      expect(
        after.carried.map((line) => line.itemId),
        contains('pack_daypack'),
      );
    });

    test('even when the new one is far too small for it', () {
      // 40 l of wood into a 30 l bag: over the limit, and every piece of it
      // still owned.
      final full = loadedDaypack();
      final woodBefore = full.countOf('mat_wood');

      final after = full.wearPack(
        const CarriedItem(itemId: 'pack_shopping_bag'),
      );

      expect(after.countOf('mat_wood'), woodBefore);
      expect(after.overflowL(body, catalogue), greaterThan(0));
    });

    test('the new pack leaves the contents, being worn now', () {
      final full = loadedDaypack()
          .add('pack_shopping_bag', catalogue, body: body)
          .inventory;
      final bag = full.carried.firstWhere(
        (line) => line.itemId == 'pack_shopping_bag',
      );

      final after = full.wearPack(bag);

      expect(
        after.carried.where((line) => line.itemId == 'pack_shopping_bag'),
        isEmpty,
      );
    });

    test(
      'the first pack of the game comes from nowhere and leaves nothing',
      () {
        final after = const Inventory().wearPack(
          const CarriedItem(itemId: 'pack_school'),
        );

        expect(after.packId, 'pack_school');
        expect(after.carried, isEmpty);
      },
    );

    test('a pack put on through wearLine is worn as a pack, not as a coat', () {
      // §4.4: the back slot is read from packId, so a pack that landed in
      // [worn] would be a pack nobody is carrying anything in.
      final after = const Inventory().wearLine(
        const CarriedItem(itemId: 'pack_military'),
        catalogue,
      );

      expect(after.packId, 'pack_military');
      expect(after.worn, isEmpty);
    });
  });

  group('taking the pack off', () {
    // Found on a phone: the back slot was the one thing that could not be
    // taken off, on the reasoning that a pack is swapped rather than removed.
    // A player who wants to put their bag down disagrees.
    test('the pack ends up in hand', () {
      final after = const Inventory().withPack('pack_daypack').takeOffPack();

      expect(after.packId, isNull);
      expect(after.carried.single.itemId, 'pack_daypack');
    });

    test('what was inside stays owned', () {
      final loaded = const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body, count: 6)
          .inventory;

      final after = loaded.takeOffPack();

      expect(after.countOf('mat_wood'), 6);
    });

    test('and twelve litres of pockets say what it costs (§18.1a)', () {
      // The honest outcome, not a refusal: without a pack there are pockets,
      // and the overflow is the player's problem to solve.
      final loaded = const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body, count: 6)
          .inventory;

      final after = loaded.takeOffPack();

      expect(after.limits(body, catalogue).capacityL, 12);
      expect(after.overflowL(body, catalogue), greaterThan(0));
    });

    test('taking off nothing is not an error', () {
      expect(const Inventory().takeOffPack().packId, isNull);
    });

    test('takeOff by id finds the pack too, the screen having one button', () {
      final after = const Inventory()
          .withPack('pack_trekking')
          .takeOff('pack_trekking');

      expect(after.packId, isNull);
      expect(after.carried.single.itemId, 'pack_trekking');
    });

    test('a garment is still taken off the way it always was', () {
      final after = const Inventory()
          .withPack('pack_trekking')
          .wear('cloth_boots', catalogue)
          .takeOff('cloth_boots');

      expect(after.worn, isEmpty);
      expect(after.packId, 'pack_trekking');
      expect(after.carried.single.itemId, 'cloth_boots');
    });
  });

  group('a bottle put down half way through (§4.7)', () {
    // Losing the whole bottle for stopping would teach a player never to start
    // one near a corner they might have to run round; getting it all back
    // would make the time it takes meaningless. Half drunk is half gone.
    Inventory withWater({int count = 1}) => const Inventory()
        .withPack('pack_daypack')
        .add('drink_water_bottle_500', catalogue, body: body, count: count)
        .inventory;

    test('half of it drunk leaves half of it', () {
      final inventory = withWater();
      final after = inventory.consumePortion(inventory.carried.single, 0.5);

      expect(after.carried.single.portion, closeTo(0.5, 0.001));
    });

    test('and the half left is half as heavy', () {
      final inventory = withWater();
      final whole = inventory.massKg(catalogue);
      final after = inventory.consumePortion(inventory.carried.single, 0.5);
      final pack = catalogue['pack_daypack']!.weightKg;

      expect(after.massKg(catalogue) - pack, closeTo((whole - pack) / 2, 0.01));
    });

    test('but takes the same room, the bottle being the same bottle', () {
      final inventory = withWater();
      final before = inventory.volumeL(catalogue);
      final after = inventory.consumePortion(inventory.carried.single, 0.5);

      expect(after.volumeL(catalogue), closeTo(before, 0.001));
    });

    test('a second sitting drinks half of what is left, not half a bottle', () {
      var inventory = withWater();
      inventory = inventory.consumePortion(inventory.carried.single, 0.5);
      inventory = inventory.consumePortion(inventory.carried.single, 0.5);

      expect(inventory.carried.single.portion, closeTo(0.25, 0.001));
    });

    test('the last mouthful finishes it rather than leaving a crumb', () {
      final inventory = withWater();
      final after = inventory.consumePortion(inventory.carried.single, 0.97);

      expect(after.carried, isEmpty);
    });

    test('drinking one of three splits it off, leaving two whole ones', () {
      final inventory = withWater(count: 3);
      final after = inventory.consumePortion(inventory.carried.single, 0.5);

      final whole = after.carried.where((line) => line.portion >= 1).single;
      final part = after.carried.where((line) => line.portion < 1).single;

      expect(whole.count, 2);
      expect(part.count, 1);
      expect(part.portion, closeTo(0.5, 0.001));
    });

    test('a part-used piece does not stack with a full one found later', () {
      var inventory = withWater(count: 2);
      inventory = inventory.consumePortion(inventory.carried.single, 0.5);
      inventory = inventory
          .add('drink_water_bottle_500', catalogue, body: body)
          .inventory;

      // The full ones go together; the half bottle stays its own line.
      expect(
        inventory.carried.where((line) => line.portion >= 1).single.count,
        2,
      );
      expect(inventory.carried.where((line) => line.portion < 1), hasLength(1));
    });

    test('a piece that is no longer carried changes nothing', () {
      const gone = CarriedItem(itemId: 'drink_water_bottle_500');
      final inventory = withWater();

      expect(inventory.consumePortion(gone, 0.5).carried, hasLength(1));
    });

    test('putting it down at once keeps all of it', () {
      final inventory = withWater();
      final after = inventory.consumePortion(inventory.carried.single, 0);

      expect(after.carried.single.portion, 1);
    });
  });

  group('what is in the hand (§5.5.1)', () {
    // Found on a phone: a knife in the pack could not be equipped at all,
    // because §4.4 only gives garments a slot and a blade is not a garment.
    // The game still has to know which weapon is out — it is the one that
    // fires, and the one a clinch is fought with.
    test('a knife can be taken in hand', () {
      final after = const Inventory().wearLine(
        const CarriedItem(itemId: 'melee_knife'),
        catalogue,
      );

      expect(after.worn.single.itemId, 'melee_knife');
    });

    test('and a rifle displaces it, rather than being held as well', () {
      // Two blades are not held at once for two blades' worth of reach.
      final armed = const Inventory()
          .wearLine(const CarriedItem(itemId: 'melee_knife'), catalogue)
          .wearLine(const CarriedItem(itemId: 'weapon_rifle_22lr'), catalogue);

      expect(armed.worn.single.itemId, 'weapon_rifle_22lr');
      expect(armed.carried.single.itemId, 'melee_knife');
    });

    test('a coat is untouched by any of it', () {
      final dressed = const Inventory()
          .wearLine(const CarriedItem(itemId: 'cloth_winter_jacket'), catalogue)
          .wearLine(const CarriedItem(itemId: 'melee_knife'), catalogue);

      expect(dressed.worn, hasLength(2));
    });

    test('a weapon in hand costs mass and no volume, like anything worn', () {
      // §18.1a: what is on the body is carried, not packed.
      final armed = const Inventory()
          .withPack('pack_daypack')
          .wearLine(const CarriedItem(itemId: 'melee_machete'), catalogue);

      expect(armed.volumeL(catalogue), closeTo(0, 0.001));
      expect(armed.massKg(catalogue), greaterThan(0));
    });

    test('the hand is where the figure looks for it', () {
      expect(wearSlotOf(catalogue['melee_knife']!), BodySlot.hand.wire);
      expect(wearSlotOf(catalogue['cloth_boots']!), BodySlot.feet.wire);
    });
  });

  group('what is bolted to which weapon (§5.6.3)', () {
    Inventory armed() => const Inventory()
        .withPack('pack_daypack')
        .add('weapon_rifle_545', catalogue, body: body)
        .inventory
        .add('att_red_dot', catalogue, body: body)
        .inventory;

    test('onto the rifle in the hand, which is where it matters', () {
      // Found on a phone: fitting anything to the weapon actually being
      // carried did nothing at all — attach only ever looked in `carried`, and
      // a weapon in the hand is `worn`. The one rifle a player wants a light
      // on is the one they are holding.
      var kit = armed();
      final rifle = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      kit = kit.wearLine(rifle, catalogue);

      final held = kit.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545');
      final optic = kit.carried.firstWhere((l) => l.itemId == 'att_red_dot');

      final after = kit.attach(held, optic, catalogue);

      expect(
        after.worn
            .firstWhere((l) => l.itemId == 'weapon_rifle_545')
            .attachments,
        ['att_red_dot'],
      );
      expect(after.carried.where((l) => l.itemId == 'att_red_dot'), isEmpty);
    });

    test('and off it again, back into the pack', () {
      var kit = armed();
      final rifle = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      kit = kit.wearLine(rifle, catalogue);

      final held = kit.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545');
      final optic = kit.carried.firstWhere((l) => l.itemId == 'att_red_dot');
      kit = kit.attach(held, optic, catalogue);

      final fitted = kit.worn.firstWhere((l) => l.itemId == 'weapon_rifle_545');
      final after = kit.detach(fitted, 'att_red_dot', catalogue, body: body);

      expect(
        after.worn
            .firstWhere((l) => l.itemId == 'weapon_rifle_545')
            .attachments,
        isEmpty,
      );
      expect(
        after.carried.where((l) => l.itemId == 'att_red_dot'),
        hasLength(1),
      );
    });

    test('and a rifle picked up off the pavement keeps its sights', () {
      // ⚠️ Putting one down used to strip it: the sights, the suppressor and
      // the long magazine simply stopped existing, because the row they were
      // written to had nowhere to put them. They are the rarest things in the
      // game (§5.6.3) and they were evaporating on the pavement.
      final back = const Inventory()
          .withPack('pack_daypack')
          .add(
            'weapon_rifle_545',
            catalogue,
            body: body,
            attachments: const ['tool_suppressor', 'att_red_dot'],
          )
          .inventory;

      expect(
        back.carried
            .firstWhere((l) => l.itemId == 'weapon_rifle_545')
            .attachments,
        ['tool_suppressor', 'att_red_dot'],
      );
    });

    test('and a fitted weapon weighs what is on it (§18.1a)', () {
      // ⚠️ It did not, and that made every attachment free to carry. §18.1a's
      // whole point is that mass is the thing a player runs out of — a bolt-on
      // that costs nothing is a bolt-on nobody would ever leave behind.
      var kit = armed();
      final rifle = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final bare = kit.massKg(catalogue);

      kit = kit.attach(
        rifle,
        kit.carried.firstWhere((l) => l.itemId == 'att_red_dot'),
        catalogue,
      );

      expect(
        kit.massKg(catalogue),
        closeTo(bare, 0.001),
        reason: 'it moved from the pack onto the rifle, so nothing changed',
      );

      final fitted = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      expect(
        fitted.massKg(catalogue['weapon_rifle_545']!, catalogue: catalogue),
        greaterThan(fitted.massKg(catalogue['weapon_rifle_545']!)),
        reason: 'the rifle itself is heavier for wearing it',
      );
    });

    test('an optic goes onto the rifle and out of the pack', () {
      final kit = armed();
      final rifle = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final optic = kit.carried.firstWhere((l) => l.itemId == 'att_red_dot');

      final after = kit.attach(rifle, optic, catalogue);

      expect(
        after.carried
            .firstWhere((l) => l.itemId == 'weapon_rifle_545')
            .attachments,
        ['att_red_dot'],
      );
      expect(after.carried.where((l) => l.itemId == 'att_red_dot'), isEmpty);
    });

    test('and comes off again into the pack', () {
      var kit = armed();
      final rifle = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final optic = kit.carried.firstWhere((l) => l.itemId == 'att_red_dot');
      kit = kit.attach(rifle, optic, catalogue);

      final fitted = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final after = kit.detach(fitted, 'att_red_dot', catalogue, body: body);

      expect(
        after.carried
            .firstWhere((l) => l.itemId == 'weapon_rifle_545')
            .attachments,
        isEmpty,
      );
      expect(after.countOf('att_red_dot'), 1);
    });

    test('two rifles in one pack are two rifles', () {
      // The whole reason this lives on the piece: the one with the suppressor
      // is the one worth carrying into a town.
      var kit = const Inventory()
          .withPack('pack_trekking')
          .add('weapon_rifle_545', catalogue, body: body)
          .inventory
          .add('weapon_rifle_545', catalogue, body: body)
          .inventory
          .add('att_red_dot', catalogue, body: body)
          .inventory;

      final first = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final optic = kit.carried.firstWhere((l) => l.itemId == 'att_red_dot');
      kit = kit.attach(first, optic, catalogue);

      final rifles = kit.carried
          .where((l) => l.itemId == 'weapon_rifle_545')
          .toList();

      expect(rifles.where((l) => l.attachments.isNotEmpty), hasLength(1));
      expect(rifles.where((l) => l.attachments.isEmpty), hasLength(1));
    });

    test('what does not fit is refused', () {
      // §10.3.3's calibre string, again: a suppressor for 5.45 is not a
      // shotgun part.
      var kit = const Inventory()
          .withPack('pack_daypack')
          .add('weapon_shotgun_pump', catalogue, body: body)
          .inventory
          .add('tool_suppressor', catalogue, body: body)
          .inventory;

      final shotgun = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_shotgun_pump',
      );
      final can = kit.carried.firstWhere((l) => l.itemId == 'tool_suppressor');

      expect(
        kit
            .attach(shotgun, can, catalogue)
            .carried
            .firstWhere((l) => l.itemId == 'weapon_shotgun_pump')
            .attachments,
        isEmpty,
      );
    });

    test('a second of the same is refused', () {
      // Two red dots on one rifle is not a thing, and the arithmetic would
      // happily stack it.
      var kit = armed().add('att_red_dot', catalogue, body: body).inventory;
      final rifle = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final optics = kit.carried
          .where((l) => l.itemId == 'att_red_dot')
          .toList();

      kit = kit.attach(rifle, optics.first, catalogue);
      final fitted = kit.carried.firstWhere(
        (l) => l.itemId == 'weapon_rifle_545',
      );
      final again = kit.attach(fitted, optics.last, catalogue);

      expect(
        again.carried
            .firstWhere((l) => l.itemId == 'weapon_rifle_545')
            .attachments,
        hasLength(1),
      );
    });

    test('and so is one rail too many', () {
      expect(attachmentSlots(catalogue['weapon_revolver_38']!), 1);
      expect(attachmentSlots(catalogue['weapon_rifle_545']!), 3);
      expect(attachmentSlots(catalogue['melee_knife']!), 0);
    });
  });
  group('what comes back with a thing that was put down (§4.7)', () {
    test('a half-drunk bottle is still half drunk', () {
      // ⚠️ Found while wiring the shelter shelves: `add` rebuilt the line from
      // its arguments and had no argument for how much was left, so a bottle
      // taken off a shelf was full again. Unlimited water for two taps.
      final back = withTrekking().add(
        'drink_water_bottle_500',
        catalogue,
        body: body,
        portion: 0.5,
      );

      expect(back.isAccepted, isTrue);
      expect(back.inventory.carried.single.portion, 0.5);
    });

    test('and a book remembers the page it was left on', () {
      final back = withTrekking().add(
        'lit_leaflet_first_aid',
        catalogue,
        body: body,
        pagesTotal: 300,
        pagesRead: 120,
      );

      expect(back.inventory.carried.single.pagesRead, 120);
    });
  });
}
