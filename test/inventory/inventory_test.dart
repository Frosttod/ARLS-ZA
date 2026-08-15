import 'dart:io';

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
    const BodySpec(
      sex: Sex.male,
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
    ),
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
      final packs = catalogue.all
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
    // gives each material its character — metal is a mass problem, plastic and
    // fabric are volume problems, wood pinches on both at once.
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

    test('metal: 16 by mass, 108 by volume — mass binds', () {
      expectLimits('mat_metal', byMass: 16, byVolume: 108);
    });

    test('plastic: 60 by mass, 32 by volume — volume binds', () {
      expectLimits('mat_plastic', byMass: 60, byVolume: 32);
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
      expect(fits('mat_plastic'), 32, reason: 'volume, well before mass');
      expect(fits('mat_metal'), 30, reason: 'mass, well before volume');
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
        count: 26,
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
        count: 60,
      );

      // 48 kg of limit, less the 1.8 kg pack, over 1.5 kg a piece.
      expect(result.refusal, RefusalReason.tooHeavy);
      expect(result.acceptedCount, 30);
    });

    test('what fits is taken, rather than the whole pile refused', () {
      // A player standing over forty rounds with room for twelve gets twelve.
      final result = withTrekking().add(
        'mat_plastic',
        catalogue,
        body: body,
        count: 100,
      );

      expect(result.refusal, RefusalReason.noRoom);
      expect(result.acceptedCount, 32);
      expect(result.inventory.countOf('mat_plastic'), 32);
    });

    test('nothing fits at all is a refusal, not an empty acceptance', () {
      var inventory = withTrekking();
      inventory = inventory
          .add('mat_plastic', catalogue, body: body, count: 32)
          .inventory;

      final result = inventory.add('mat_plastic', catalogue, body: body);

      expect(result.isAccepted, isFalse);
      expect(result.acceptedCount, 0);
    });

    test('an item the catalogue lost is refused by name', () {
      final result = const Inventory().add('weapon_railgun', catalogue, body: body);

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

      expect(const Inventory().wearLine(copy, catalogue).worn.single.condition,
          62);
    });

    test('only one piece of a stack is put on', () {
      const two = CarriedItem(itemId: 'armor_vest_soft', count: 2);

      expect(const Inventory().wearLine(two, catalogue).worn.single.count, 1);
    });

    test('wearing by id still works, for anything that has no copy in hand', () {
      expect(
        const Inventory().wear('armor_vest_soft', catalogue).worn.single.itemId,
        'armor_vest_soft',
      );
    });

    test('the displaced piece keeps its own condition too', () {
      const old = CarriedItem(itemId: 'armor_vest_soft', condition: 25);
      const found = CarriedItem(itemId: 'armor_vest_soft', condition: 95);

      final after = const Inventory(worn: [old]).wearLine(found, catalogue);

      expect(after.worn.single.condition, 95);
      expect(after.carried.single.condition, 25);
    });
  });
}
