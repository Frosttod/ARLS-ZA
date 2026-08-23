import 'dart:io';

import 'package:arls_za/craft/craft_job.dart';
import 'package:arls_za/craft/item_recipe.dart';
import 'package:arls_za/craft/salvage_batch.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:test/test.dart';

/// CO WIDAĆ NA LIŚCIE DO ROZBIÓRKI (§18.6, §18.2, §12).
///
/// ⚠️ **What is worn is shown and refused, never left out.**
///
/// Reported from a walk as a question: does the list show what I have on me?
/// It did not — it asked the pack and the shelves and nothing else. The rifle
/// is the one thing in this game most worth taking apart, and it is almost
/// always in the player's hands rather than stowed, so the list did not work
/// for the case it exists for.
///
/// It is still not taken off automatically. A sitting that undressed somebody
/// would be a second action inside the first (§2.1a), and the bad case is not
/// hypothetical: the third piece could be the rucksack, which takes §18.1a's
/// carry limits down with it while the rest of the sitting is standing in it.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final recipes = RecipeBook.parse(File(kRecipesAsset).readAsStringSync());

  final bench = CraftBench(
    atShelter: true,
    workshopLevel: 1,
    atHand: const {'tool_multitool'},
    materials: const {},
  );

  CarriedItem rifle(String uid) =>
      const CarriedItem(itemId: 'weapon_rifle_545').copyWith(uid: uid);

  List<SalvageOffer> offers({
    List<CarriedItem> carried = const [],
    List<CarriedItem> worn = const [],
    List<CarriedItem> shelved = const [],
  }) => offersFrom(
    carried: carried,
    worn: worn,
    shelved: shelved,
    bench: bench,
    catalogue: catalogue,
    book: recipes,
  );

  group('the three piles', () {
    test('what is in the pack is offered plainly', () {
      final list = offers(carried: [rifle('a.1')]);

      expect(list, hasLength(1));
      expect(list.single.isBlocked, isFalse);
      expect(list.single.fromShelf, isFalse);
    });

    test('§18.2: what is on the shelves is offered too', () {
      // A bench makes the pack and the shelves one pile. Making somebody carry
      // their own scrap off their own shelf first is bookkeeping.
      final list = offers(shelved: [rifle('a.1')]);

      expect(list.single.fromShelf, isTrue);
      expect(list.single.isBlocked, isFalse);
    });

    test('what is on the body is offered, and refused', () {
      final list = offers(worn: [rifle('a.1')]);

      expect(list, hasLength(1), reason: 'it must be on the list at all');
      expect(list.single.blocked, SalvageBlock.worn);
    });

    test('and it still says what it would give and cost', () {
      // ⚠️ Blocked is not empty. The player has to be able to see that the
      // rifle *is* worth taking apart and that one step stands in front of it.
      final list = offers(worn: [rifle('a.1')]);

      expect(list.single.yields, isNotEmpty);
      expect(list.single.takes, greaterThan(Duration.zero));
    });
  });

  test('the order is pack, then body, then shelves', () {
    // The order the screen reads them in, and the order a player thinks in:
    // what I am carrying, what I am wearing, what I left at home.
    final list = offers(
      carried: [rifle('pack')],
      worn: [rifle('body')],
      shelved: [rifle('shelf')],
    );

    expect(list.map((offer) => offer.line.uid), ['pack', 'body', 'shelf']);
  });

  group('§18.6: what a step of a running sitting gives back', () {
    // ⚠️ Reported from a walk: a finished piece in the queue said "Gotowe."
    // and nothing else, so the one moment a player most wants the answer —
    // *what did I actually get* — was the moment the screen went quiet.
    test('a step answers the same as the offer it came from', () {
      final offer = offers(carried: [rifle('a.1')]).single;

      final fromStep = yieldOf(
        offer.toStep(),
        bench: bench,
        catalogue: catalogue,
        book: recipes,
      );

      expect(
        fromStep,
        offer.yields,
        reason: 'the queue and the picker must never disagree',
      );
    });

    test('and how worn it was travels with the step (§18.6)', () {
      // The piece is gone by the time this is asked, so the condition has to
      // come off the row rather than off an item nobody holds any more.
      final ruined = yieldOf(
        const SalvageStep(
          itemId: 'weapon_rifle_545',
          condition: 1,
          takes: Duration(minutes: 5),
        ),
        bench: bench,
        catalogue: catalogue,
        book: recipes,
      );

      expect(ruined, isEmpty, reason: 'a wreck gives nothing back');
    });
  });

  group('what never reaches the list', () {
    test('a piece with no name of its own (§11.1)', () {
      // A sitting is written down and read back after a restart, and a piece
      // it cannot name again is a piece it would find by guessing.
      final list = offers(
        carried: [const CarriedItem(itemId: 'weapon_rifle_545')],
      );

      expect(list, isEmpty);
    });

    test('and a thing with nothing in it worth getting back (§18.6)', () {
      final list = offers(
        carried: [
          const CarriedItem(itemId: 'food_canned_meat').copyWith(uid: 'a.1'),
        ],
      );

      expect(list, isEmpty);
    });

    test('including one worn — a blocked row still has to be worth it', () {
      final list = offers(
        worn: [
          const CarriedItem(itemId: 'food_canned_meat').copyWith(uid: 'a.1'),
        ],
      );

      expect(list, isEmpty);
    });
  });
}
