import 'dart:io';

import 'package:arls_za/combat/magazine.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:test/test.dart';

/// §5.3, §5.5.4. What is actually in the weapon.
///
/// A round in the pack is not a round in the rifle, and the difference is the
/// whole of §5.5.4: a magazine change with something at arm's length is not a
/// thing that finishes. Letting it finish would make the clinch a formality
/// rather than the emergency it is.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  final rifle = catalogue['weapon_rifle_545']!;
  final now = DateTime.utc(2026, 8, 16, 12);

  group('what the weapon says about itself', () {
    test('the magazine is the one in the data', () {
      expect(magazineSize(rifle), (rifle.props['magazine'] as num).toInt());
    });

    test('and so is the time it takes to change', () {
      expect(
        reloadTime(rifle).inMilliseconds,
        ((rifle.props['reload_seconds'] as num) * 1000).round(),
      );
    });

    test('something with neither still answers', () {
      // A content pack may ship a weapon that never thought about it.
      final knife = catalogue['melee_knife']!;

      expect(magazineSize(knife), 1);
      expect(reloadTime(knife), const Duration(seconds: 3));
    });
  });

  group('topping up (§5.3)', () {
    test('an empty rifle takes a full magazine', () {
      expect(
        roundsToLoad(weapon: rifle, loaded: 0, carried: 60),
        magazineSize(rifle),
      );
    });

    test('a half-full one takes only what fits', () {
      expect(
        roundsToLoad(
          weapon: rifle,
          loaded: magazineSize(rifle) - 3,
          carried: 60,
        ),
        3,
      );
    });

    test('and loose rounds are loaded, not whole magazines', () {
      // A survivor with a pocket, not an armourer with spare mags: four rounds
      // is four rounds, and fighting with a part-filled magazine is normal.
      expect(roundsToLoad(weapon: rifle, loaded: 0, carried: 4), 4);
    });

    test('a full weapon takes nothing', () {
      expect(
        roundsToLoad(weapon: rifle, loaded: magazineSize(rifle), carried: 60),
        0,
      );
    });

    test('and an empty pack gives nothing', () {
      expect(roundsToLoad(weapon: rifle, loaded: 0, carried: 0), 0);
    });
  });

  group('§5.5.4: five metres ends it', () {
    test('something at arm\'s length stops the change', () {
      expect(reloadBrokenBy([4.2]), isTrue);
    });

    test('exactly five metres is close enough', () {
      expect(reloadBrokenBy([5]), isTrue);
    });

    test('six metres is not', () {
      expect(reloadBrokenBy([6, 40, 300]), isFalse);
    });

    test('the nearest of them settles it', () {
      expect(reloadBrokenBy([300, 90, 3]), isTrue);
    });

    test('an empty street never breaks one', () {
      expect(reloadBrokenBy(const []), isFalse);
    });

    test('what it is doing does not matter', () {
      // Hands stop when a body is that close, and the game is not going to
      // argue about intent.
      expect(reloadBrokenBy([2]), isTrue);
    });
  });

  group('the change itself', () {
    test('it is done when its time comes', () {
      final reload = Reload(
        weaponId: 'weapon_rifle_545',
        readyAt: now.add(const Duration(seconds: 3)),
        total: const Duration(seconds: 3),
      );

      expect(reload.isDoneAt(now), isFalse);
      expect(reload.isDoneAt(now.add(const Duration(seconds: 3))), isTrue);
    });

    test('and reads as a bar on the way there', () {
      const total = Duration(seconds: 4);
      final reload = Reload(
        weaponId: 'w',
        readyAt: now.add(total),
        total: total,
      );

      expect(reload.progressAt(now, total: total), closeTo(0, 0.01));
      expect(
        reload.progressAt(now.add(const Duration(seconds: 2)), total: total),
        closeTo(0.5, 0.01),
      );
      // The reload carries its own denominator, so a bar can be drawn without
      // asking the weapon how long it takes — which matters because the weapon
      // can change under a running reload.
      expect(
        reload.progress(now.add(const Duration(seconds: 2))),
        closeTo(0.5, 0.01),
      );

      expect(
        reload.progressAt(now.add(const Duration(seconds: 9)), total: total),
        1,
      );
    });
  });
}
