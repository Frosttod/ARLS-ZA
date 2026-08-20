import 'dart:io';

import 'package:arls_za/combat/magazine_item.dart';
import 'package:arls_za/combat/weapon_load.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// ŁADOWANIE BRONI (§5.3, §5.5.4, §4.2).
///
/// Reloading used to be one number going up: press, wait, be full. These tests
/// are about it being things moving instead — a magazine out with what was left
/// in it, a fuller one in, and loose rounds thumbed into the empty one
/// somewhere quiet.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  CarriedItem rifle({int rounds = 0, List<String> attachments = const []}) =>
      CarriedItem(
        itemId: 'weapon_rifle_545',
        rounds: rounds,
        attachments: attachments,
      );

  Inventory holding(CarriedItem weapon, {List<CarriedItem> pack = const []}) =>
      Inventory(worn: [weapon], carried: pack);

  group('what is in the weapon', () {
    test('a fitted magazine decides the capacity, not the rifle', () {
      // The whole point of magazines being things: the same rifle with a box
      // and with a drum is the same rifle.
      final box = WeaponLoad.of(
        rifle(attachments: const ['mag_rifle_545']),
        catalogue,
      )!;
      final drum = WeaponLoad.of(
        rifle(attachments: const ['mag_rifle_545_drum']),
        catalogue,
      )!;

      expect(box.capacity, 30);
      expect(drum.capacity, 60);
    });

    test('a rifle with no magazine is waiting for one, not broken', () {
      final bare = WeaponLoad.of(rifle(), catalogue)!;

      expect(bare.needsMagazine, isTrue);
      expect(bare.feed, Feed.magazine);
    });

    test('and a revolver never needs one', () {
      final wheel = WeaponLoad.of(
        const CarriedItem(itemId: 'weapon_revolver_38'),
        catalogue,
      )!;

      expect(wheel.feed, Feed.loose);
      expect(wheel.needsMagazine, isFalse);
      expect(wheel.capacity, 6);
    });
  });

  group('swapping a magazine (§5.5.4)', () {
    test('the fullest one that fits goes in', () {
      final pack = holding(
        rifle(),
        pack: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 8),
          CarriedItem(itemId: 'mag_rifle_545', rounds: 30),
        ],
      );

      final out = swapMagazine(pack, pack.worn.single, catalogue);

      expect(out.isDone, isTrue);
      expect(out.inventory.worn.single.rounds, 30);
      expect(out.inventory.worn.single.attachments, contains('mag_rifle_545'));
    });

    test('and the one that comes out keeps what was left in it', () {
      // ⚠️ The whole reason this is not "set rounds to thirty". Somebody who
      // swaps at half empty keeps that half and finds it later — which is what
      // gives a fight something to tidy up after.
      final pack = holding(
        rifle(rounds: 9, attachments: const ['mag_rifle_545']),
        pack: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 30)],
      );

      final out = swapMagazine(pack, pack.worn.single, catalogue);

      expect(out.inventory.worn.single.rounds, 30);
      expect(
        out.inventory.carried.where((line) => line.rounds == 9),
        hasLength(1),
        reason: 'the half-empty one is back in the pack, still half empty',
      );
    });

    test('a half-empty magazine never merges into the full ones (§4.7)', () {
      final pack = holding(
        rifle(rounds: 9, attachments: const ['mag_rifle_545']),
        pack: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 30),
          CarriedItem(itemId: 'mag_rifle_545', rounds: 30),
        ],
      );

      final out = swapMagazine(pack, pack.worn.single, catalogue);
      final mags = out.inventory.carried
          .where((line) => line.itemId == 'mag_rifle_545')
          .toList();

      expect(mags, hasLength(2));
      expect(mags.map((line) => line.rounds), containsAll([30, 9]));
    });

    test('swapping for one no fuller is refused, not three wasted seconds', () {
      final pack = holding(
        rifle(rounds: 30, attachments: const ['mag_rifle_545']),
        pack: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 12)],
      );

      final out = swapMagazine(pack, pack.worn.single, catalogue);

      expect(out.refusal, LoadRefusal.nothingFuller);
      expect(out.inventory.worn.single.rounds, 30, reason: 'nothing moved');
    });

    test('with nothing that fits, it says so', () {
      final pack = holding(
        rifle(),
        pack: const [CarriedItem(itemId: 'mag_pistol_9mm', rounds: 15)],
      );

      expect(
        swapMagazine(pack, pack.worn.single, catalogue).refusal,
        LoadRefusal.noMagazine,
      );
    });

    test('and a revolver is refused outright', () {
      final pack = holding(const CarriedItem(itemId: 'weapon_revolver_38'));

      expect(
        swapMagazine(pack, pack.worn.single, catalogue).refusal,
        LoadRefusal.notAWeapon,
      );
    });
  });

  group('filling one by thumb (§4.2)', () {
    test('loose rounds go in and leave the pack', () {
      final pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 0),
          CarriedItem(itemId: 'ammo_545x39', count: 12),
        ],
      );

      final out = fillMagazine(pack, pack.carried.first, catalogue);

      expect(out.moved, 12);
      expect(out.inventory.carried.first.rounds, 12);
      expect(
        out.inventory.carried.where((l) => l.itemId == 'ammo_545x39'),
        isEmpty,
        reason: 'a round is in the magazine or in the bag, never both',
      );
    });

    test('never more than it holds, and the rest stays loose', () {
      final pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 0),
          CarriedItem(itemId: 'ammo_545x39', count: 50),
        ],
      );

      final out = fillMagazine(pack, pack.carried.first, catalogue);

      expect(out.moved, 30);
      expect(
        out.inventory.carried
            .firstWhere((l) => l.itemId == 'ammo_545x39')
            .count,
        20,
      );
    });

    test('a full one is refused', () {
      final pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 30),
          CarriedItem(itemId: 'ammo_545x39', count: 50),
        ],
      );

      expect(
        fillMagazine(pack, pack.carried.first, catalogue).refusal,
        LoadRefusal.full,
      );
    });

    test('and so is one with nothing to put in it', () {
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 0)],
      );

      expect(
        fillMagazine(pack, pack.carried.first, catalogue).refusal,
        LoadRefusal.noRounds,
      );
    });
  });

  group('a weapon fed a round at a time (§4.2)', () {
    test('rounds go straight from the pack into the cylinder', () {
      final pack = holding(
        const CarriedItem(itemId: 'weapon_revolver_38'),
        pack: const [CarriedItem(itemId: 'ammo_38special', count: 10)],
      );

      final out = loadLoose(pack, pack.worn.single, catalogue);

      expect(out.moved, 6, reason: 'six chambers');
      expect(out.inventory.worn.single.rounds, 6);
      expect(
        out.inventory.carried
            .firstWhere((l) => l.itemId == 'ammo_38special')
            .count,
        4,
      );
    });

    test('a full cylinder takes nothing', () {
      final pack = holding(
        const CarriedItem(itemId: 'weapon_revolver_38', rounds: 6),
        pack: const [CarriedItem(itemId: 'ammo_38special', count: 10)],
      );

      expect(
        loadLoose(pack, pack.worn.single, catalogue).refusal,
        LoadRefusal.full,
      );
    });
  });

  group('emptying one (§4.2)', () {
    test('the rounds come back out and go loose', () {
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 30)],
      );

      final out = emptyMagazine(pack, pack.carried.first, catalogue);

      expect(out.moved, 30);
      expect(out.inventory.carried.first.rounds, 0);
      expect(
        out.inventory.carried
            .firstWhere((l) => l.itemId == 'ammo_545x39')
            .count,
        30,
      );
    });

    test('and land on the stack that is already there, not beside it', () {
      // ⚠️ The reason this is a test: emptying is called once per round while
      // the bar crosses, so appending would leave thirty rows of one round.
      final pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 30),
          CarriedItem(itemId: 'ammo_545x39', count: 5),
        ],
      );

      final out = emptyMagazine(pack, pack.carried.first, catalogue);
      final loose = out.inventory.carried
          .where((l) => l.itemId == 'ammo_545x39')
          .toList();

      expect(loose, hasLength(1));
      expect(loose.single.count, 35);
    });

    test('an empty one is refused', () {
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 0)],
      );

      expect(
        emptyMagazine(pack, pack.carried.first, catalogue).refusal,
        LoadRefusal.noRounds,
      );
    });
  });

  group('a round at a time (§4.2)', () {
    // What the bar is for. The count has to move while it crosses, which means
    // the same call has to work thirty times with a limit of one rather than
    // once with a limit of thirty.
    test('thirty single-round fills reach exactly a full magazine', () {
      var pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 0),
          CarriedItem(itemId: 'ammo_545x39', count: 40),
        ],
      );
      var line = pack.carried.first;

      for (var i = 0; i < 30; i++) {
        final out = fillMagazine(pack, line, catalogue, limit: 1);
        expect(out.moved, 1, reason: 'round ${i + 1}');
        pack = out.inventory;
        line = out.line!;
        expect(line.rounds, i + 1);
      }

      expect(line.rounds, 30);
      expect(
        pack.carried.firstWhere((l) => l.itemId == 'ammo_545x39').count,
        10,
        reason: 'nothing was created or destroyed on the way',
      );
      expect(
        fillMagazine(pack, line, catalogue, limit: 1).refusal,
        LoadRefusal.full,
      );
    });

    test('and emptying one at a time gives every round back', () {
      var pack = Inventory(
        carried: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 12)],
      );
      var line = pack.carried.first;

      for (var i = 0; i < 12; i++) {
        final out = emptyMagazine(pack, line, catalogue, limit: 1);
        pack = out.inventory;
        line = out.line!;
        expect(line.rounds, 11 - i);
      }

      expect(
        pack.carried.firstWhere((l) => l.itemId == 'ammo_545x39').count,
        12,
      );
      expect(
        pack.carried.where((l) => l.itemId == 'ammo_545x39'),
        hasLength(1),
      );
    });

    test('the line comes back so a second magazine is never touched', () {
      // ⚠️ The bug this exists to stop: finding "the magazine" by item id
      // between rounds picks whichever comes first, and a player who owns two
      // watches the wrong one fill.
      final pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 30),
          CarriedItem(itemId: 'mag_rifle_545', rounds: 0),
          CarriedItem(itemId: 'ammo_545x39', count: 10),
        ],
      );

      final out = fillMagazine(pack, pack.carried[1], catalogue, limit: 1);

      expect(out.line!.rounds, 1);
      expect(out.inventory.carried[0].rounds, 30, reason: 'untouched');
      expect(out.inventory.carried[1].rounds, 1);
    });
  });

  group('a handle that went stale (§11.1)', () {
    // ⚠️ The quiet way rounds went missing between a walk and a restart.
    //
    // Everything here finds its line by identity, and `withLine` returns an
    // unchanged copy when it finds nothing. Handed a line captured before
    // something else rebuilt the pack, a fill took the loose rounds out and
    // put them nowhere: they left the bag, never reached the magazine, and
    // were gone by the next save. Refused now, out loud.
    test('filling a magazine that is not in this pack moves nothing', () {
      // ⚠️ copyWith, not a const: Dart hands out one instance for identical
      // const objects, so a const "stale" copy would be the very line in the
      // pack and prove nothing. This is what a rebuilt pack really gives you
      // — the same values, a different object.
      final stale = const CarriedItem(
        itemId: 'mag_rifle_545',
      ).copyWith(rounds: 0);
      final pack = Inventory(
        carried: const [
          CarriedItem(itemId: 'mag_rifle_545', rounds: 0),
          CarriedItem(itemId: 'ammo_545x39', count: 40),
        ],
      );

      final out = fillMagazine(pack, stale, catalogue);

      expect(out.refusal, LoadRefusal.gone);
      expect(
        out.inventory.carried
            .firstWhere((l) => l.itemId == 'ammo_545x39')
            .count,
        40,
        reason: 'not one round left the bag',
      );
    });

    test('and neither does emptying one', () {
      final stale = const CarriedItem(
        itemId: 'mag_rifle_545',
      ).copyWith(rounds: 30);
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 30)],
      );

      final out = emptyMagazine(pack, stale, catalogue);

      expect(out.refusal, LoadRefusal.gone);
      expect(out.inventory.carried.single.rounds, 30);
      expect(out.inventory.carried, hasLength(1), reason: 'nothing appeared');
    });

    test('nor swapping into a weapon nobody is holding', () {
      final stale = const CarriedItem(
        itemId: 'weapon_rifle_545',
      ).copyWith(count: 1);
      final pack = Inventory(
        carried: const [CarriedItem(itemId: 'mag_rifle_545', rounds: 30)],
      );

      final out = swapMagazine(pack, stale, catalogue);

      expect(out.refusal, LoadRefusal.gone);
      expect(out.inventory.carried.single.rounds, 30);
    });
  });
}
