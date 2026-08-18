import 'dart:io';

import 'package:arls_za/combat/attachment.dart';
import 'package:arls_za/items/item.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:test/test.dart';

/// §5.1, §5.3, §5.6.3. What is bolted to the weapon.
///
/// An attachment is not a tool: on its own it does nothing. Each one moves a
/// number the combat model already reads, and every one of them is rare
/// enough to change how the game is played rather than to add a percentage —
/// which is what §5.6.3 says a suppressor is for, and is just as true of the
/// rest.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  ItemDefinition item(String id) => catalogue[id]!;

  final carbine = item('weapon_rifle_545');
  final shotgun = item('weapon_shotgun_pump');

  group('what goes on what (§10.3.3)', () {
    test('a suppressor fits the calibres it names', () {
      expect(fitsWeapon(item('tool_suppressor'), carbine), isTrue);
    });

    test('and not the ones it does not', () {
      // The same string that decides whether ammunition fits. A typo makes an
      // attachment useless rather than universal.
      expect(fitsWeapon(item('tool_suppressor'), shotgun), isFalse);
    });

    test('an optic clamps to a rail and does not care what is under it', () {
      expect(fitsWeapon(item('att_red_dot'), carbine), isTrue);
      expect(fitsWeapon(item('att_red_dot'), shotgun), isTrue);
    });

    test('nothing goes on a knife', () {
      expect(fitsWeapon(item('att_red_dot'), item('melee_knife')), isFalse);
    });

    test('and a tin of beans is not an attachment', () {
      expect(fitsWeapon(item('food_canned_meat'), carbine), isFalse);
    });
  });

  group('what they change', () {
    FittedWeapon fitted(List<String> ids, {ItemDefinition? weapon}) =>
        FittedWeapon(
          weapon: weapon ?? carbine,
          attachments: [for (final id in ids) item(id)],
        );

    test('a bare weapon is its own numbers', () {
      final bare = fitted(const []);

      expect(bare.moa, (carbine.props['moa'] as num).toDouble());
      expect(bare.magazine, (carbine.props['magazine'] as num).toInt());
      expect(bare.noiseRangeM, (carbine.props['noise_range_m'] as num));
    });

    test('an optic tightens the group', () {
      expect(fitted(['att_red_dot']).moa, lessThan(fitted(const []).moa));
    });

    test('a laser settles the sights faster (§5.3)', () {
      // Two seconds of standing still against one is, in §5.1.3's arithmetic,
      // the difference between a shot and no shot at all.
      expect(fitted(['att_laser']).settleMultiplier, closeTo(0.6, 0.01));
    });

    test('a suppressor is worth about three and a half times (§5.6.3)', () {
      final quiet = fitted(['tool_suppressor']).noiseRangeM;

      expect(quiet, closeTo(fitted(const []).noiseRangeM * 0.29, 1));
    });

    test('but costs a little accuracy for it', () {
      expect(
        fitted(['tool_suppressor']).moa,
        greaterThan(fitted(const []).moa),
      );
    });

    test('an extended magazine holds ten more and seats slower', () {
      final long = fitted(['att_extended_mag']);

      expect(long.magazine, fitted(const []).magazine + 10);
      expect(long.reloadTime, greaterThan(fitted(const []).reloadTime));
    });

    test('they stack, each doing its own job', () {
      final full = fitted([
        'att_red_dot',
        'att_foregrip',
        'tool_suppressor',
        'att_extended_mag',
      ]);

      expect(full.moa, lessThan(fitted(const []).moa));
      expect(full.magazine, fitted(const []).magazine + 10);
      expect(full.noiseRangeM, lessThan(fitted(const []).noiseRangeM));
      expect(full.settleMultiplier, lessThan(1));
    });

    test('and no pile of clamp-on parts makes a match rifle', () {
      // A floor here is cheaper than the day somebody discovers MOA can go
      // negative.
      final many = FittedWeapon(
        weapon: carbine,
        attachments: [for (var i = 0; i < 6; i++) item('att_red_dot')],
      );

      expect(many.moa, greaterThanOrEqualTo(1));
      expect(many.settleMultiplier, greaterThanOrEqualTo(0.35));
    });

    test('a weapon light throws light, and the rest throw none', () {
      expect(fitted(['att_weapon_light']).lightRadiusM, 20);
      expect(fitted(['att_red_dot']).lightRadiusM, 0);
    });
  });

  group('carried is fitted, for now', () {
    test('what fits is picked out of the pack', () {
      final fitted = FittedWeapon.from(
        weapon: carbine,
        carried: [
          item('att_red_dot'),
          item('food_canned_meat'),
          item('tool_suppressor'),
        ],
      );

      expect(fitted.attachments, hasLength(2));
    });

    test('and what does not fit is left in it', () {
      final fitted = FittedWeapon.from(
        weapon: shotgun,
        carried: [item('tool_suppressor'), item('att_extended_mag')],
      );

      expect(fitted.attachments, isEmpty);
    });
  });

  group('the price of them (§10)', () {
    test('every attachment is rare or rarer', () {
      for (final attachment in catalogue.ofKind(ItemKind.attachment)) {
        expect(
          attachment.rarity,
          anyOf(Rarity.rare, Rarity.veryRare),
          reason: attachment.id,
        );
      }
    });

    test('each one says what it fits and what it changes', () {
      for (final attachment in catalogue.ofKind(ItemKind.attachment)) {
        final props = attachment.props;

        expect(
          props['attaches_to'],
          isA<List<dynamic>>(),
          reason: attachment.id,
        );
        expect(
          props.keys.any(
            (key) => const {
              'moa_delta',
              'settle_multiplier',
              'magazine_bonus',
              'noise_range_multiplier',
              'light_radius_m',
            }.contains(key),
          ),
          isTrue,
          reason: '${attachment.id} does nothing at all',
        );
      }
    });

    test('and what it takes to make one (§7)', () {
      // Found, or built by somebody who has spent the skill. Never bought.
      for (final attachment in catalogue.ofKind(ItemKind.attachment)) {
        expect(
          attachment.props['craft_skill'],
          isA<num>(),
          reason: attachment.id,
        );
        expect(
          (attachment.props['craft_skill'] as num) >= 40,
          isTrue,
          reason: attachment.id,
        );
      }
    });
  });
}
