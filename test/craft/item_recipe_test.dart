import 'dart:io';

import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// WYTWARZANIE I ROZBIÓRKA (§18.4, §18.6).
///
/// The half of the economy that runs indoors. Before a firearm turns up, a
/// spear and a torn-up shirt are the whole answer to something walking at you
/// — and §18.6's forty per cent is the rule that stops a pack of scrap from
/// being a substitute for going outside.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final book = checkedAgainst(
    RecipeBook.parse(File(kRecipesAsset).readAsStringSync()),
    catalogue,
  );

  group('the recipes as shipped (§18.4)', () {
    test('they read, and they name real things', () {
      expect(book.problems, isEmpty, reason: book.problems.join(' | '));
      expect(book.recipes, isNotEmpty);
    });

    test('a spear is one wood, one metal, one fabric — and makes two', () {
      // ⚠️ One log gives two shafts. It used to take two logs and make one
      // spear, so three quarters of the wood vanished at the bench.
      final spear = book.making('melee_spear')!;

      expect(spear.materials, {'mat_wood': 1, 'mat_metal': 1, 'mat_fabric': 1});
      expect(spear.count, 2);
      expect(spear.work, const Duration(minutes: 25));
      expect(spear.workshopLevel, 1);
    });

    test('the medical rows need no workshop and no tools', () {
      // §18.4 puts them under "available without a workshop": a dressing can
      // be made before there is a workshop module to make it in.
      for (final id in [
        'med_bandage_improvised',
        'med_pressure_improvised',
        'med_tourniquet_improvised',
        'med_splint_improvised',
      ]) {
        final recipe = book.making(id)!;
        expect(recipe.workshopLevel, 0, reason: id);
        expect(recipe.toolsAnyOf, isEmpty, reason: id);
      }
    });

    test('a stake takes a knife or a multitool, and either will do', () {
      // ⚠️ "Or" matters. The shelter's own tool rule was a single id for
      // months and quietly made one tool the only answer.
      final stake = book.making('melee_spike')!;

      expect(craftToolsAllow(stake, const ['melee_knife']), isTrue);
      expect(craftToolsAllow(stake, const ['tool_multitool']), isTrue);
      expect(craftToolsAllow(stake, const ['melee_hammer']), isFalse);
      expect(craftToolsAllow(stake, const []), isFalse);
    });

    test('and a dressing takes nothing at all', () {
      expect(
        craftToolsAllow(book.making('med_bandage_improvised')!, const []),
        isTrue,
      );
    });
  });

  group('what the workshop is worth (§18.3)', () {
    test('nothing without one, thirty per cent at level three', () {
      final club = book.making('melee_club_studded')!;

      expect(craftWork(club), const Duration(minutes: 35));
      expect(craftWork(club, workshopLevel: 3).inMinutes, 24);
    });

    test('and Engineering takes another thirty off', () {
      final club = book.making('melee_club_studded')!;

      final best = craftWork(club, workshopLevel: 3, engineering: 1);
      expect(best.inMinutes, 17, reason: '35 × 0.7 × 0.7');
    });
  });

  group('the spear is the reason this exists', () {
    test('it reaches further than anything else a player can hold', () {
      // §18.4 has three craftable weapons and this is the one that matters:
      // before a firearm turns up, reach is the entire defence. Something
      // that has to close to 0.8 m to swing is something that has already
      // reached you.
      final reach = <String, double>{
        for (final item in catalogue.all)
          if (item.props['reach_m'] case final num r) item.id: r.toDouble(),
      };

      final best = reach.entries.reduce((a, b) => a.value >= b.value ? a : b);

      expect(best.key, 'melee_spear');
      expect(best.value, greaterThan(reach['melee_axe']!));
    });

    test('and it is worse than an axe at everything else', () {
      // Which is what keeps it a stopgap rather than an upgrade. It is made
      // because there is no axe, not instead of one.
      final spear = catalogue['melee_spear']!;
      final axe = catalogue['melee_axe']!;

      expect(
        spear.props['blood_ml_per_hit'],
        lessThan(axe.props['blood_ml_per_hit']! as num),
      );
    });
  });

  group('taking things apart (§18.6)', () {
    test('a rifle comes to one piece of metal', () {
      // ⚠️ The arithmetic §18.6 does not do. Forty per cent of a 3.3 kg rifle
      // is 0.88 units of metal, and floored per material that is nought —
      // which is what the section says literally and cannot possibly mean.
      // One budget for the whole item, rounded once.
      final back = salvageOf(catalogue['weapon_rifle_545']!, book);

      expect(back, {'mat_metal': 1});
    });

    test('and a pistol comes to nothing, which is correct', () {
      // You do not get scrap out of something that small. A dismantling that
      // returns nothing has to be refused before the minutes are spent, not
      // discovered afterwards.
      expect(salvageOf(catalogue['weapon_pistol_9mm']!, book), isEmpty);
    });

    test('a worn thing gives back less than a good one', () {
      // §18.6 insists on this, and says why: without it the cheapest metal in
      // the game is ruined weapons picked up to be broken.
      final good = salvageOf(catalogue['armor_vest_soft']!, book);
      final ruined = salvageOf(
        catalogue['armor_vest_soft']!,
        book,
        condition: 20,
      );

      var goodTotal = 0;
      for (final count in good.values) {
        goodTotal += count;
      }
      var ruinedTotal = 0;
      for (final count in ruined.values) {
        ruinedTotal += count;
      }

      expect(ruinedTotal, lessThan(goodTotal));
    });

    test('nothing ever gives back more than it was made of', () {
      // The one invariant that keeps recycling from being a farm. §18.6 is
      // explicit: exploration stays the way you get materials.
      for (final item in catalogue.all) {
        final content = materialContent(item, book);
        if (content.isEmpty) continue;

        var inside = 0.0;
        for (final units in content.values) {
          inside += units;
        }

        var back = 0;
        for (final count in salvageOf(
          item,
          book,
          share: salvageShare(engineering: 1, workshopLevel: 3),
        ).values) {
          back += count;
        }

        expect(
          back,
          lessThanOrEqualTo(inside.ceil()),
          reason: '${item.id} gave back more than it held',
        );
      }
    });

    test('the best a player can ever get is sixty-five per cent', () {
      // §18.6: fifty-five at full Engineering, plus ten points for a workshop
      // at level two. Nothing else touches it.
      expect(salvageShare(), closeTo(0.40, 0.001));
      expect(salvageShare(engineering: 1), closeTo(0.55, 0.001));
      expect(
        salvageShare(engineering: 1, workshopLevel: 2),
        closeTo(0.65, 0.001),
      );
      expect(
        salvageShare(workshopLevel: 3),
        closeTo(0.50, 0.001),
        reason: 'a workshop without the skill is still ten points',
      );
    });

    test('a made thing is measured by its recipe, not by its mass', () {
      // The recipe *is* the material value where there is one. Guessing from
      // mass would let a player make something cheap and break it for more.
      //
      // ⚠️ **Per piece, and the run makes two.** Reading the run's materials
      // as one spear's content was a material duplicator: a run cost three
      // units and produced two spears that each came apart into two. Found by
      // the crafted-gear budget, which asks every made thing whether it gives
      // back more than it cost.
      final spear = catalogue['melee_spear']!;

      expect(book.making('melee_spear')!.count, 2);
      expect(materialContent(spear, book), {
        'mat_wood': 0.5,
        'mat_metal': 0.5,
        'mat_fabric': 0.5,
      });
    });

    test('and never gives back everything it cost', () {
      final spear = catalogue['melee_spear']!;
      final back = salvageOf(spear, book);

      var total = 0;
      for (final count in back.values) {
        total += count;
      }

      expect(total, lessThan(4), reason: 'four units went in');
    });

    test('food and books come apart into nothing', () {
      for (final id in ['food_canned_meat', 'lit_novel']) {
        final item = catalogue[id];
        if (item == null) continue;
        expect(salvageOf(item, book), isEmpty, reason: id);
      }
    });

    test('it takes three minutes at least and a quarter hour at most', () {
      final nothing = salvageTime(const {});
      final quick = salvageTime(const {'mat_fabric': 1});
      final long = salvageTime(const {'mat_fabric': 20});

      expect(nothing, kSalvageTime.$1);
      expect(quick, greaterThan(kSalvageTime.$1));
      expect(long, kSalvageTime.$2);
      expect(
        salvageTime(materialContent(catalogue['weapon_rifle_545']!, book)),
        greaterThan(kSalvageTime.$1),
      );
    });

    test('and it takes a multitool, whatever the thing is', () {
      expect(canSalvageWith(const ['tool_multitool']), isTrue);
      expect(canSalvageWith(const ['melee_hammer']), isFalse);
    });
  });
}
