import 'dart:io';

import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/shelter/recipes.dart';
import 'package:arls_za/shelter/shelter.dart';
import 'package:flutter_test/flutter_test.dart';

/// RECEPTURY MODUŁÓW (§18.2, §18.3).
///
/// §18.2 says the full four-module build is 731 kg — "weeks, not a weekend",
/// about thirty round trips with a full pack. That number is the whole reason
/// the Lounge competes with the Storage module instead of being a nicety, so
/// it is worth a test that fails when somebody softens a row.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  double massOf(Map<String, int> materials) {
    var total = 0.0;
    for (final entry in materials.entries) {
      total += catalogue[entry.key]!.weightKg * entry.value;
    }
    return total;
  }

  group('the masses of §18.2 come out of the item table', () {
    test('a camp is 31.8 kg', () {
      expect(massOf(kCampMaterials), closeTo(31.8, 0.05));
    });

    test('storage L1 is 49 kg and L3 is 103', () {
      expect(
        massOf(nextLevelOf(ShelterModule.storage, have: 0)!.materials),
        closeTo(49.0, 0.05),
      );
      expect(
        massOf(nextLevelOf(ShelterModule.storage, have: 2)!.materials),
        closeTo(103.0, 0.05),
      );
    });

    test('workshop L3 is 121.4 kg', () {
      expect(
        massOf(nextLevelOf(ShelterModule.workshop, have: 2)!.materials),
        closeTo(121.4, 0.05),
      );
    });

    test('and everything to L3 is the 731 kg §18.2 promises', () {
      var total = 0.0;
      for (final recipe in kShelterRecipes) {
        total += massOf(recipe.materials);
      }

      expect(total, closeTo(731, 1.5));
    });
  });

  group('what can be built next', () {
    test('one level at a time', () {
      expect(nextLevelOf(ShelterModule.lounge, have: 0)?.level, 1);
      expect(nextLevelOf(ShelterModule.lounge, have: 2)?.level, 3);
    });

    test('and nothing past three', () {
      expect(nextLevelOf(ShelterModule.lounge, have: 3), isNull);
    });

    test('what is missing is named, not just refused', () {
      final missing = missingFor(
        {'mat_wood': 20, 'mat_metal': 6},
        {'mat_wood': 14},
      );

      expect(missing, {'mat_wood': 6, 'mat_metal': 6});
    });

    test('and nothing is missing when it is all there', () {
      expect(missingFor({'mat_wood': 2}, {'mat_wood': 5}), isEmpty);
    });
  });

  group('tools decide the work (§18.3)', () {
    final storage = nextLevelOf(ShelterModule.storage, have: 0)!;

    test('a hammer is the baseline', () {
      expect(
        moduleWork(storage, hasHammer: true),
        storage.work,
      );
    });

    test('a multitool takes half again as long', () {
      expect(
        moduleWork(storage, hasMultitool: true).inMinutes,
        (storage.work.inMinutes * 1.6).round(),
      );
    });

    test('and bare hands cannot do it at all', () {
      expect(
        toolsAllow(storage, hasHammer: false, hasMultitool: false),
        isFalse,
      );
    });

    test('a second workshop level needs both, with no alternative', () {
      final workshop2 = nextLevelOf(ShelterModule.workshop, have: 1)!;

      expect(
        toolsAllow(workshop2, hasHammer: true, hasMultitool: false),
        isFalse,
      );
      expect(
        toolsAllow(workshop2, hasHammer: true, hasMultitool: true),
        isTrue,
      );
    });

    test('a workshop shortens everything built after it (§8.4)', () {
      final bare = moduleWork(storage, hasHammer: true);
      final withL3 = moduleWork(storage, hasHammer: true, workshopLevel: 3);

      expect(withL3.inMinutes, (bare.inMinutes * 0.7).round());
    });
  });
}
