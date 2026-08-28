import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/craft/salvage_batch.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:test/test.dart';

/// TRZY SZTUKI TO TRZY SZTUKI (§18.6, §11.1, §12).
///
/// ⚠️ **A stack is several pieces, and the screen offered one.**
///
/// Reported from a walk: three of one stackable thing are one row in the pack
/// with a count on it, the disassembly list quoted the minutes for one, and
/// there was no way to ask for the other two. The row was not wrong about the
/// price of a single piece — it simply had no way to say *how many*.
///
/// So a pick is now a thing **and a number**, and everything downstream — the
/// running total, the summary, the sitting itself — multiplies by it. The
/// alternative the report also offered, summing the whole stack automatically,
/// was the worse of the two: §18.6 destroys what it opens, and a screen that
/// quietly took all three of somebody's pieces because they ticked a box
/// would be the most expensive misread in the game.
void main() {
  /// ⚠️ **A stackable thing worth taking apart, and the shipped catalogue has
  /// none.** It used to: improvised tourniquets are stackable and made of
  /// fabric, so §18.6 gave fabric back. Then [materialContent] learned to
  /// divide a recipe by the number of pieces it makes — six tourniquets come
  /// out of one rag, so each holds a sixth of one, and a sixth of a rag is not
  /// recoverable. That was a fix for a material duplicator, and the loss is
  /// the right one.
  ///
  /// The mechanism below is about **rows and counts**, not about tourniquets,
  /// and it is still exactly as real. So the case it needs is built here
  /// rather than borrowed from a balance table that has every right to move:
  /// a stackable piece holding two whole units, which is what a thing has to
  /// hold before an unskilled pair of hands can get anything out of it.
  const spares = '''
{"schema": 1, "items": [{
  "id": "mat_spare_part", "type": "crafting",
  "name": {"pl": "Część zamienna", "en": "Spare part"},
  "weight_kg": 0.2, "volume_l": 0.3, "stackable": true, "rarity": "common",
  "loot_tags": ["garage"],
  "props": {"salvage": {"mat_metal": 1.4, "mat_plastic": 0.6}}
}]}
''';

  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
    const ItemSource('test://spares.json', spares),
  ]);
  final recipes = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());

  final bench = CraftBench(
    atShelter: true,
    workshopLevel: 1,
    atHand: const {'tool_multitool'},
    materials: const {},
  );

  CarriedItem stack(int count, {int? started}) => const CarriedItem(
    itemId: 'mat_spare_part',
  ).copyWith(uid: 'a.1', count: count, salvageSeconds: started);

  SalvageOffer offerOf(CarriedItem line) => offersFrom(
    carried: [line],
    worn: const [],
    shelved: const [],
    bench: bench,
    catalogue: catalogue,
    book: recipes,
  ).single;

  test('the pack really does stack this, or the test proves nothing', () {
    // ⚠️ The whole report rests on it. If the item stopped stacking, every
    // assertion below would pass against a case that cannot happen.
    expect(catalogue['mat_spare_part']?.stackable, isTrue);
    expect(offerOf(stack(3)).yields, isNotEmpty);
  });

  group('how many there are to offer', () {
    test('a stack of three offers three', () {
      expect(offerOf(stack(3)).available, 3);
    });

    test('a single piece offers one', () {
      expect(offerOf(stack(1)).available, 1);
    });

    test('and a stack somebody already started on offers one (§18.6)', () {
      // ⚠️ Partial progress is written on the *line*, and a line stands for
      // three pieces. A stack that is half undone cannot say which of its
      // three is the half, so the honest answer is to finish the open one
      // before splitting hairs about the rest.
      expect(offerOf(stack(3, started: 60)).available, 1);
    });
  });

  group('what a pick costs and gives', () {
    test('two of them take twice as long', () {
      final offer = offerOf(stack(3));

      expect(SalvagePick(offer, 2).takes, offer.takes * 2);
    });

    test('and give twice as much', () {
      final offer = offerOf(stack(3));
      final one = offer.yields;
      final two = SalvagePick(offer, 2).yields;

      expect(two.keys, one.keys);
      for (final key in one.keys) {
        expect(two[key], one[key]! * 2);
      }
    });

    test('the running total counts pieces, not rows', () {
      // The number under the list, and the one the reported bug got wrong: a
      // row asking for three quoted the price of one.
      final offer = offerOf(stack(3));

      expect(totalTime([SalvagePick(offer, 3)]), offer.takes * 3);
    });
  });

  group('the sitting it becomes', () {
    test('three of a stack are three steps', () {
      // §18.6's ordering is what makes stopping half way honest, and that
      // only works if each piece is its own step.
      final batch = batchOf([SalvagePick(offerOf(stack(3)), 3)]);

      expect(batch.length, 3);
      expect(batch.total, offerOf(stack(3)).takes * 3);
    });

    test('and they share a uid, because they share a row (§11.1)', () {
      // The pack holds one entry with a count, not three entries. Each step
      // takes one off that entry as its turn finishes.
      final batch = batchOf([SalvagePick(offerOf(stack(3)), 3)]);

      expect(batch.steps.map((step) => step.uid).toSet(), {'a.1'});
    });

    test('asking for more than there are is capped, never invented', () {
      // ⚠️ The pack behind the picker can shrink while it is open. A number
      // remembered from before that must not conjure a fourth piece.
      final batch = batchOf([SalvagePick(offerOf(stack(2)), 9)]);

      expect(batch.length, 2);
    });

    test('and nought still means one piece, not none', () {
      // Nought reaches here only from a rounding slip upstream; the picker
      // treats nought as unticked. Making it a piece is the safe reading —
      // the alternative is a sitting with an empty step in it.
      expect(batchOf([SalvagePick(offerOf(stack(3)), 0)]).length, 1);
    });
  });

  test('§18.6: the pieces still come apart one after another', () {
    // Half way through three of them, one is metal and two are exactly
    // as they were. That is the promise the whole model rests on, and adding
    // counts must not have quietly turned it into a single long bar.
    final offer = offerOf(stack(3));
    final batch = batchOf([SalvagePick(offer, 3)]);

    final settled = batch.settledAt(offer.takes);

    expect(settled.done, hasLength(1));
    expect(settled.left, hasLength(2));
  });

  test('a sitting of several rows and several pieces adds up', () {
    final tourniquets = offerOf(stack(2));
    final rifle = offersFrom(
      carried: [
        const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: 'r.1'),
      ],
      worn: const [],
      shelved: const [],
      bench: bench,
      catalogue: catalogue,
      book: recipes,
    ).single;

    final picks = [SalvagePick(tourniquets, 2), SalvagePick(rifle, 1)];

    expect(totalTime(picks), tourniquets.takes * 2 + rifle.takes);
    expect(batchOf(picks).length, 3);

    final total = totalYield(picks);
    for (final entry in tourniquets.yields.entries) {
      expect(total[entry.key], greaterThanOrEqualTo(entry.value * 2));
    }
  });
}
