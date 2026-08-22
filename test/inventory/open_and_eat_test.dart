import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// OTWARTA PUSZKA (§4.7).
///
/// ⚠️ **Opening a tin and eating it are two different acts, and the first one
/// happens at the tap.**
///
/// Consuming a portion at the end of the bar — or restoring it at the next
/// boot — leaves a window in which the pack is lying: the bar is halfway
/// across and the tin is still sealed. Anything that ends the session in that
/// window hands the meal back whole, and closing the app becomes a way to eat
/// for free. It was reported exactly that way.
///
/// So the portion follows the bar, the same way a magazine's rounds do
/// (§4.2). Nothing has to be restored because nothing is ever deferred.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  Inventory packOf(List<CarriedItem> lines) => Inventory(carried: lines);

  group('opening one out of a stack', () {
    test('four tins become three and an open one', () {
      // What actually happens when somebody opens a tin: the stack does not
      // become "3.7 tins".
      final pack = packOf([
        const CarriedItem(
          itemId: 'food_canned_meat',
          count: 4,
        ).copyWith(uid: 'a.1'),
      ]);

      final opened = pack.openOne(pack.carried.single);

      expect(opened.inventory.carried, hasLength(2));
      expect(opened.inventory.carried.first.count, 3);
      expect(opened.line.count, 1);
    });

    test('and the open one has its own name (§11.1)', () {
      // ⚠️ It has a history now that the ones in the stack do not. Sharing a
      // uid would let a later edit find the wrong piece.
      final pack = packOf([
        const CarriedItem(
          itemId: 'food_canned_meat',
          count: 4,
        ).copyWith(uid: 'a.1'),
      ]);

      final opened = pack.openOne(pack.carried.single);

      expect(opened.line.uid, isNotNull);
      expect(opened.line.uid, isNot('a.1'));
    });

    test('a single tin is opened where it lies', () {
      final pack = packOf([
        const CarriedItem(itemId: 'food_canned_meat').copyWith(uid: 'a.1'),
      ]);

      final opened = pack.openOne(pack.carried.single);

      expect(opened.inventory.carried, hasLength(1));
      expect(opened.line.uid, 'a.1');
    });

    test('and a piece nobody holds is left alone', () {
      final pack = packOf([
        const CarriedItem(itemId: 'food_canned_meat').copyWith(uid: 'a.1'),
      ]);

      final stranger = const CarriedItem(
        itemId: 'food_canned_meat',
      ).copyWith(uid: 'b.9');

      expect(pack.openOne(stranger).inventory.carried, hasLength(1));
    });
  });

  group('the tin empties as it is eaten', () {
    Inventory withOpenTin() => packOf([
      const CarriedItem(itemId: 'food_canned_meat').copyWith(uid: 'a.1'),
    ]);

    test('a quarter of the way through, three quarters are left', () {
      final pack = withOpenTin();
      final after = pack.setPortion(pack.carried.single, 0.75);

      expect(after.line!.portion, closeTo(0.75, 1e-9));
    });

    test('and setting it again changes nothing that was not asked for', () {
      // ⚠️ Absolute rather than a decrement, so a tick that arrives late — or
      // twice in one frame — cannot make somebody eat more than they had.
      var pack = withOpenTin();
      var line = pack.carried.single;

      for (var i = 0; i < 5; i++) {
        final after = pack.setPortion(line, 0.6);
        pack = after.inventory;
        line = after.line!;
      }

      expect(line.portion, closeTo(0.6, 1e-9));
    });

    test('the last crumb takes the tin with it', () {
      final pack = withOpenTin();
      final after = pack.setPortion(pack.carried.single, 0.001);

      expect(after.inventory.carried, isEmpty);
      expect(after.line, isNull, reason: 'the handle goes with the piece');
    });

    test('and the handle travels with every change (§11.1)', () {
      // The lesson §5.3's magazine filling already learned: the line is
      // rebuilt by every edit, so a caller holding the old one is holding
      // nothing.
      final pack = withOpenTin();
      final after = pack.setPortion(pack.carried.single, 0.5);

      expect(after.line, isNotNull);
      expect(identical(after.line, pack.carried.single), isFalse);
      expect(after.line!.isSame(pack.carried.single), isTrue);
    });
  });

  test('a meal killed halfway leaves a half-eaten tin, by construction', () {
    // ⚠️ The reported bug, and the reason for the whole design. There is no
    // restore step here and nothing to get wrong at the next boot: the pack
    // was already telling the truth at every instant.
    var pack = packOf([
      const CarriedItem(
        itemId: 'food_canned_meat',
        count: 2,
      ).copyWith(uid: 'a.1'),
    ]);

    final opened = pack.openOne(pack.carried.first);
    pack = opened.inventory;

    // Halfway across the bar, and then the process dies.
    final half = pack.setPortion(opened.line, 0.5);
    pack = half.inventory;

    expect(pack.carried, hasLength(2));
    expect(pack.carried.first.count, 1, reason: 'one whole tin left');
    expect(pack.carried.last.portion, closeTo(0.5, 1e-9));
    expect(
      pack.massKg(catalogue),
      lessThan(
        packOf([
          const CarriedItem(itemId: 'food_canned_meat', count: 2),
        ]).massKg(catalogue),
      ),
      reason: 'half a tin weighs less than a whole one (§18.1a)',
    );
  });
}
