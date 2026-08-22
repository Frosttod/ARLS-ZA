import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/sim/body.dart';
import 'package:flutter_test/flutter_test.dart';

/// CZY TO SIĘ ZMIEŚCI, BEZ WKŁADANIA (§18.1a).
///
/// ⚠️ Asking used to mean attempting: the interface called [Inventory.add] and
/// threw the result away, which walks the whole pack twice and clones its line
/// list. Once per row, per action, per frame — thirty things on a shelf and
/// seven actions each is two hundred clones of the inventory in one frame, and
/// that is what makes a list stutter under a thumb.
///
/// The arithmetic has to stay exactly the arithmetic `add` does, so these
/// tests hold the two against each other rather than against a figure I typed
/// in.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  Inventory packOf(List<CarriedItem> lines) =>
      Inventory(carried: lines, packId: 'pack_daypack');

  group('it answers what add would answer', () {
    test('for an empty pack and a heavy pack alike', () {
      for (final pack in [
        packOf(const []),
        packOf(const [CarriedItem(itemId: 'weapon_rifle_545')]),
        packOf(const [
          CarriedItem(itemId: 'armor_vest_plate'),
          CarriedItem(itemId: 'weapon_rifle_mosin'),
          CarriedItem(itemId: 'food_canned_meat', count: 12),
        ]),
      ]) {
        final room = pack.roomLeft(body, catalogue);

        for (final id in [
          'med_bandage',
          'weapon_rifle_545',
          'armor_vest_plate',
          'food_canned_meat',
        ]) {
          final line = CarriedItem(itemId: id);
          final asked = room.holds(line, catalogue[id]!, catalogue: catalogue);
          final attempted = pack.add(id, catalogue, body: body).isAccepted;

          expect(
            asked,
            attempted,
            reason: '$id into a pack of ${pack.carried.length}',
          );
        }
      }
    });

    test('and counts the same partial acceptance', () {
      // §18.1a takes as many as fit rather than refusing the lot, and the
      // question has to give the same number.
      final pack = packOf(const [CarriedItem(itemId: 'armor_vest_plate')]);
      final room = pack.roomLeft(body, catalogue);

      const line = CarriedItem(itemId: 'ammo_545x39');
      final asked = room.room(
        line,
        catalogue['ammo_545x39']!,
        catalogue: catalogue,
        count: 400,
      );
      final change = pack.add('ammo_545x39', catalogue, body: body, count: 400);

      expect(asked, change.acceptedCount ?? 400);
    });

    test('a pack already over its limit takes nothing', () {
      // Negative room, not a crash and not a free pass.
      final pack = packOf(const [
        CarriedItem(itemId: 'armor_vest_plate', count: 20),
      ]);
      final room = pack.roomLeft(body, catalogue);

      expect(room.massKg, lessThan(0));
      expect(
        room.holds(
          const CarriedItem(itemId: 'med_bandage'),
          catalogue['med_bandage']!,
          catalogue: catalogue,
        ),
        isFalse,
      );
    });

    test('and a fitted rifle is measured with what is on it (§5.6.3)', () {
      // The mass of a scope is the reason a rifle does or does not fit, and
      // the question has to see it as clearly as the attempt does.
      final pack = packOf(const []);
      final room = pack.roomLeft(body, catalogue);

      const bare = CarriedItem(itemId: 'weapon_rifle_545');
      const loaded = CarriedItem(
        itemId: 'weapon_rifle_545',
        attachments: ['att_red_dot', 'mag_rifle_545'],
      );

      expect(
        room.room(
          bare,
          catalogue['weapon_rifle_545']!,
          catalogue: catalogue,
          count: 20,
        ),
        greaterThan(
          room.room(
            loaded,
            catalogue['weapon_rifle_545']!,
            catalogue: catalogue,
            count: 20,
          ),
        ),
      );
    });
  });

  test('the whole pack is walked once, not built into a new list', () {
    // ⚠️ `massKg` used to spread `[...carried, ...worn]` and walk that. It is
    // called from the carry gauges, from every fit check and from the pack
    // screen; a list built to be walked once is an allocation per call.
    //
    // The behaviour is what matters here: worn kit counts towards mass and
    // not towards bulk (§18.1a), and splitting the loop must not change that.
    final worn = Inventory(
      worn: const [CarriedItem(itemId: 'armor_vest_plate')],
      carried: const [CarriedItem(itemId: 'med_bandage')],
      packId: 'pack_daypack',
    );

    final vest = catalogue['armor_vest_plate']!;
    final gauze = catalogue['med_bandage']!;
    final pack = catalogue['pack_daypack']!;

    expect(
      worn.massKg(catalogue),
      closeTo(vest.weightKg + gauze.weightKg + pack.weightKg, 0.001),
    );
    expect(
      worn.volumeL(catalogue),
      closeTo(gauze.volumeL, 0.001),
      reason: 'a vest on the body does not fill the bag',
    );
  });
}
