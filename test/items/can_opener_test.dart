import 'dart:io';

import 'package:arls_za/inventory/item_use.dart';
import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:test/test.dart';

/// §4.1: a tin is not food until something has been through the lid.
///
/// ⚠️ **Reported from the field, and it was true of the whole game: the can
/// opener did nothing.** `needs_opener` had sat in `food.json` since stage 4
/// and no code had ever read it, so a kilogram of single-purpose steel bought
/// exactly nothing — which is the same defect as a rule that exists only in a
/// comment.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  ItemDefinition item(String id) => catalogue[id]!;

  test('a sealed tin cannot be eaten with bare hands', () {
    expect(useOf(item('food_canned_meat'), opener: false), isNull);
    expect(useOf(item('food_canned_vegetables'), opener: false), isNull);
  });

  test('and can be with something that opens it', () {
    final use = useOf(item('food_canned_meat'), opener: true);

    expect(use, isNotNull);
    expect(use!.kcal, greaterThan(0));
  });

  test('an apple never needed anybody', () {
    expect(useOf(item('food_apple'), opener: false), isNotNull);
    expect(useOf(item('food_crackers'), opener: false), isNotNull);
  });

  test('what opens a tin comes from the data, not from a list of ids', () {
    // A content pack may ship a third one; a hard-coded pair would be a second
    // answer to a question the catalogue already answers.
    expect(opensCans([item('tool_can_opener')]), isTrue);
    expect(opensCans([item('tool_multitool')]), isTrue);

    expect(opensCans([item('melee_knife')]), isFalse);
    expect(opensCans([item('food_apple'), item('med_bandage')]), isFalse);
    expect(opensCans(const []), isFalse);
  });

  test('and the opener now buys something for its weight', () {
    // The whole point of the fix: before it, this tool was 200 g of nothing.
    final opener = item('tool_can_opener');

    expect(opener.props['opens_cans'], isTrue);
    expect(opener.weightKg, greaterThan(0));
    expect(
      useOf(item('food_canned_meat'), opener: opensCans([opener])),
      isNotNull,
    );
  });
}
