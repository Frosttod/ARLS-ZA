import 'dart:io';

import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_stats.dart';
import 'package:test/test.dart';

/// §4.2–§4.7. Which way is better.
///
/// The readings themselves are already in the data; what this adds is the one
/// thing the data cannot say — that two hundred joules more is an improvement
/// and two hundred grams more is not. Get that backwards and a comparison
/// screen confidently recommends the worse vest.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  ItemDefinition item(String id) => catalogue[id]!;

  ItemStat readingOf(ItemDefinition definition, String key) =>
      statsOf(definition).firstWhere((stat) => stat.key == key);

  group('what is worth reading about an item', () {
    test('a firearm carries the numbers that decide a shot', () {
      final keys = statsOf(
        catalogue.all.firstWhere((it) => it.kind == ItemKind.firearm),
      ).map((stat) => stat.key);

      expect(keys, contains('energy'));
      expect(keys, contains('moa'));
      expect(keys, contains('range'));
    });

    test('mass and bulk are on everything, being the two costs (§18.1a)', () {
      for (final definition in catalogue.all) {
        final keys = statsOf(definition).map((stat) => stat.key);
        expect(keys, containsAll(['mass', 'bulk']), reason: definition.id);
      }
    });

    test('an item with no numbers of its own still has those two', () {
      final wood = statsOf(item('mat_wood'));

      expect(wood.map((stat) => stat.key), ['mass', 'bulk']);
    });

    test('a missing prop is left out rather than shown as zero', () {
      // Zero rounds and zero MOA on a knife would both be lies.
      final keys = statsOf(item('melee_knife')).map((stat) => stat.key);

      expect(keys, isNot(contains('magazine')));
    });
  });

  group('which direction counts as better', () {
    test('lighter is better', () {
      expect(readingOf(item('mat_wood'), 'mass').higherIsBetter, isFalse);
    });

    test('a tighter group is better, though the number is smaller', () {
      final rifle = catalogue.all.firstWhere(
        (it) => it.kind == ItemKind.firearm && it.props['moa'] != null,
      );

      expect(readingOf(rifle, 'moa').higherIsBetter, isFalse);
    });

    test('more insulation is better', () {
      expect(
        readingOf(item('cloth_winter_jacket'), 'insulation').higherIsBetter,
        isTrue,
      );
    });

    test('carrying more is better, weighing more is not, on the same pack', () {
      final pack = item('pack_daypack');

      expect(readingOf(pack, 'capacity').higherIsBetter, isTrue);
      expect(readingOf(pack, 'mass').higherIsBetter, isFalse);
    });
  });

  group('improvement follows the reading, not the arithmetic', () {
    const heavier = ItemStat(
      key: 'mass',
      value: 2,
      unit: 'kg',
      higherIsBetter: false,
    );
    const lighter = ItemStat(
      key: 'mass',
      value: 1,
      unit: 'kg',
      higherIsBetter: false,
    );

    test('a smaller number is a gain where smaller is better', () {
      expect(improvement(lighter, heavier), greaterThan(0));
    });

    test('and a loss the other way round', () {
      expect(improvement(heavier, lighter), lessThan(0));
    });

    test('equal readings are neither', () {
      expect(improvement(lighter, lighter), 0);
    });

    test('a reading with no better direction never claims one', () {
      const calibre = ItemStat(
        key: 'calibre',
        value: 9,
        unit: 'mm',
        higherIsBetter: null,
      );
      const other = ItemStat(
        key: 'calibre',
        value: 7.62,
        unit: 'mm',
        higherIsBetter: null,
      );

      expect(improvement(calibre, other), 0);
    });
  });

  group('what is worth putting side by side', () {
    test('a vest against a vest', () {
      final vests = catalogue.all
          .where(
            (it) =>
                it.kind == ItemKind.armor && it.props['slot'] == 'torso_armor',
          )
          .toList();

      expect(vests.length, greaterThan(1), reason: 'needs two to compare');
      expect(comparable(vests[0], vests[1]), isTrue);
    });

    test('but not a vest against a jacket — they do not displace each other', () {
      expect(
        comparable(item('armor_vest_soft'), item('cloth_winter_jacket')),
        isFalse,
      );
    });

    test('nor a rifle against a tin of beans', () {
      expect(comparable(item('melee_knife'), item('food_canned_meat')), isFalse);
    });

    test('nothing is compared with itself', () {
      expect(comparable(item('melee_knife'), item('melee_knife')), isFalse);
    });

    test('two of a kind with no slot at all still compare', () {
      final knives = catalogue.all
          .where((it) => it.kind == ItemKind.melee && it.props['slot'] == null)
          .toList();

      expect(knives.length, greaterThan(1));
      expect(comparable(knives[0], knives[1]), isTrue);
    });
  });

  group('how a reading reads', () {
    test('a unit is on it', () {
      expect(readingOf(item('food_canned_meat'), 'kcal').formatted,
          endsWith('kcal'));
    });

    test('decimals are where they earn their place', () {
      // Two hundredths of a clo is a real difference between garments; two
      // hundredths of a kilocalorie is noise.
      expect(readingOf(item('cloth_winter_jacket'), 'insulation').decimals, 2);
      expect(readingOf(item('food_canned_meat'), 'kcal').decimals, 0);
    });
  });
}
