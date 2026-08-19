import 'dart:io';

import 'package:arls_za/combat/magazine_item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// MAGAZYNKI JAKO PRZEDMIOTY (§5.5.4, §4.2).
///
/// The old model was one integer on the weapon, which made a reload an
/// abstraction: press, wait, be full. Everything §5.5.4 is about went missing
/// with it — nothing to run out of but loose rounds, no reason to prepare
/// anywhere quiet, and no difference between a soldier with three full
/// magazines and one with three hundred loose rounds in a bag.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final rifle = catalogue['weapon_rifle_545']!;
  final pistol = catalogue['weapon_pistol_9mm']!;
  final smg = catalogue['weapon_smg_9mm']!;
  final revolver = catalogue['weapon_revolver_38']!;
  final mosin = catalogue['weapon_rifle_mosin']!;
  final pump = catalogue['weapon_shotgun_pump']!;

  group('how a weapon is fed (§4.2)', () {
    test('the revolver, the pump and the bolt gun take loose rounds', () {
      // ⚠️ Not a new decision — §4.2 already said so, in a `reload_note`
      // nobody could query. The prose said "loose rounds, 2.5 s each"; this
      // is the same fact where the code can read it.
      for (final weapon in [revolver, mosin, pump]) {
        expect(Feed.of(weapon), Feed.loose, reason: weapon.id);
      }
    });

    test('and everything else takes a magazine', () {
      for (final weapon in [rifle, pistol, smg]) {
        expect(Feed.of(weapon), Feed.magazine, reason: weapon.id);
      }
    });
  });

  group('what fits what', () {
    Magazine mag(String id, {int rounds = 0}) =>
        Magazine.of(catalogue[id]!, rounds: rounds)!;

    test('a magazine goes in by calibre', () {
      expect(mag('mag_rifle_545').fits(rifle), isTrue);
      expect(mag('mag_pistol_9mm').fits(pistol), isTrue);
    });

    test('and never in the wrong calibre', () {
      expect(mag('mag_rifle_545').fits(pistol), isFalse);
      expect(mag('mag_pistol_9mm').fits(rifle), isFalse);
    });

    test('a pistol magazine fits the submachine gun, and the other way', () {
      // Both are 9x19 and both really do — which is the sort of thing worth
      // finding on a walk, and the reason `fits` asks the calibre rather than
      // naming weapons.
      expect(mag('mag_pistol_9mm').fits(smg), isTrue);
      expect(mag('mag_smg_9mm').fits(pistol), isTrue);
    });

    test('nothing fits a weapon fed loose', () {
      for (final weapon in [revolver, mosin, pump]) {
        expect(mag('mag_rifle_545').fits(weapon), isFalse, reason: weapon.id);
        expect(mag('mag_pistol_9mm').fits(weapon), isFalse, reason: weapon.id);
      }
    });

    test('and a rifle is not a magazine', () {
      expect(Magazine.of(rifle), isNull);
      expect(Magazine.of(catalogue['med_bandage']!), isNull);
    });
  });

  group('what is in it', () {
    Magazine empty(String id) => Magazine.of(catalogue[id]!)!;

    test('a magazine found empty is empty', () {
      final mag = empty('mag_rifle_545');

      expect(mag.capacity, 30);
      expect(mag.rounds, 0);
      expect(mag.isEmpty, isTrue);
      expect(mag.room, 30);
    });

    test('filling takes what fits and says how much went', () {
      final filled = empty('mag_rifle_545').fill(12);

      expect(filled.took, 12);
      expect(filled.magazine.rounds, 12);
      expect(filled.magazine.fraction, closeTo(0.4, 0.001));
    });

    test('and never more than it holds', () {
      final filled = empty('mag_pistol_9mm').fill(99);

      expect(filled.took, 15);
      expect(filled.magazine.isFull, isTrue);
    });

    test('a full one takes nothing more', () {
      final full = empty('mag_pistol_9mm').fill(15).magazine;

      expect(full.fill(5).took, 0);
      expect(full.fill(5).magazine.rounds, 15);
    });

    test('a shot takes one out', () {
      final mag = empty('mag_rifle_545').fill(3).magazine;

      expect(mag.fired.rounds, 2);
      expect(mag.fired.fired.fired.rounds, 0);
    });

    test('and an empty one has nothing left to give', () {
      expect(empty('mag_rifle_545').fired.rounds, 0);
    });

    test('stripping one gives the rounds back', () {
      final mag = empty('mag_smg_9mm').fill(21).magazine;
      final stripped = mag.emptied;

      expect(stripped.took, 21);
      expect(stripped.magazine.isEmpty, isTrue);
    });
  });

  group('filling one is not reloading (§4.2, §5.5.4)', () {
    test('about a second a round, by thumb', () {
      expect(fillTime(30), const Duration(seconds: 30));
      expect(fillTime(0), Duration.zero);
    });

    test('which is far longer than the swap it makes possible', () {
      // ⚠️ The whole point of the split. Swapping a full magazine in is
      // §5.5.4's three and a half seconds, and anything within five metres
      // stops it. Filling one is half a minute — a thing done in a shelter,
      // ahead of time, which is what makes carrying a second full magazine
      // worth its two hundred grams.
      final swap = Duration(
        milliseconds: ((rifle.props['reload_seconds'] as num).toDouble() * 1000)
            .round(),
      );

      expect(fillTime(30), greaterThan(swap * 5));
    });
  });

  group('which rounds go in it', () {
    test('the calibre is looked up, not spelled out of the id', () {
      // ⚠️ `ammo_545x39` is `5.45x39` with the dot taken out, and
      // `ammo_12ga_buck` is not that pattern at all. A convention that holds
      // for five of eight rounds breaks on the sixth.
      expect(
        ammoFor('5.45x39', catalogue).map((item) => item.id),
        contains('ammo_545x39'),
      );
      expect(
        ammoFor('9x19', catalogue).map((item) => item.id),
        contains('ammo_9x19'),
      );
    });

    test('and a shotgun takes two different rounds', () {
      expect(ammoFor('12ga', catalogue), hasLength(2));
    });

    test('every magazine in the catalogue has ammunition that fits it', () {
      final magazines = catalogue.all.where(
        (item) => Magazine.of(item) != null,
      );

      expect(magazines, isNotEmpty);
      for (final item in magazines) {
        expect(
          ammoFor(Magazine.of(item)!.caliber, catalogue),
          isNotEmpty,
          reason: '${item.id} takes rounds nothing in the game makes',
        );
      }
    });

    test('and every magazine-fed weapon has a magazine that fits it', () {
      final magazines = [
        for (final item in catalogue.all)
          if (Magazine.of(item) != null) Magazine.of(item)!,
      ];

      for (final weapon in catalogue.all) {
        if (weapon.props['feed'] != 'magazine') continue;

        expect(
          magazines.where((mag) => mag.fits(weapon)),
          isNotEmpty,
          reason: '${weapon.id} is magazine-fed and nothing fits it',
        );
      }
    });
  });
}
