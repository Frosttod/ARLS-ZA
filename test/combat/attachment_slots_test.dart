import 'dart:io';

import 'package:arls_za/combat/attachment.dart';
import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// MIEJSCA NA BRONI (§5.6.3).
///
/// A weapon is not a bag with a number of pockets. It has a barrel, a rail, a
/// grip and a magazine well, and each of them holds one thing. These tests are
/// about that being true in the data as well as in the sentence.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);

  group('every part knows where it goes', () {
    test('nothing that fits a weapon is homeless', () {
      // ⚠️ The interface offers places, not parts. A part with no place would
      // simply never appear on any button — invisible, not broken, which is
      // the worst way for it to be wrong.
      final homeless = [
        for (final item in catalogue.all)
          if (item.props.containsKey('attaches_to') && slotOf(item) == null)
            item.id,
      ];

      expect(homeless, isEmpty);
    });

    test('and the property is not the body one', () {
      // `slot` is where a garment sits on the body (§4.4). Naming this the
      // same made every attachment look like clothing for a body part that
      // does not exist, and the figure screen said so.
      for (final item in catalogue.all) {
        if (slotOf(item) == null) continue;
        expect(item.props['slot'], isNull, reason: item.id);
      }
    });

    test('a magazine goes in the magazine well', () {
      expect(slotOf(catalogue['mag_rifle_545']!), AttachmentSlot.magazine);
    });

    test('a suppressor goes on the barrel, an optic on top', () {
      expect(slotOf(catalogue['tool_suppressor']!), AttachmentSlot.barrel);
      expect(slotOf(catalogue['att_red_dot']!), AttachmentSlot.optic);
    });
  });

  group('one thing per place', () {
    CarriedItem rifle({List<String> attachments = const []}) =>
        CarriedItem(itemId: 'weapon_rifle_545', attachments: attachments);

    test('a second optic does not go on top of the first', () {
      final pack = Inventory(
        worn: [
          rifle(attachments: const ['att_red_dot']),
        ],
        carried: const [CarriedItem(itemId: 'att_red_dot')],
      );

      // The same part, so this leans on the place rather than on the id: with
      // two different optics in the game the rule would be the same one.
      final after = pack.attach(
        pack.worn.single,
        pack.carried.single,
        catalogue,
      );

      expect(after.worn.single.attachments, ['att_red_dot']);
    });

    test(
      'a laser and a light are the same rail, so it is one or the other',
      () {
        final pack = Inventory(
          worn: [
            rifle(attachments: const ['att_laser']),
          ],
          carried: const [CarriedItem(itemId: 'att_weapon_light')],
        );

        final after = pack.attach(
          pack.worn.single,
          pack.carried.single,
          catalogue,
        );

        expect(after.worn.single.attachments, ['att_laser']);
        expect(
          after.carried,
          hasLength(1),
          reason: 'the light stayed in the bag',
        );
      },
    );

    test('but a different place is a different question', () {
      final pack = Inventory(
        worn: [
          rifle(attachments: const ['att_red_dot']),
        ],
        carried: const [CarriedItem(itemId: 'tool_suppressor')],
      );

      final after = pack.attach(
        pack.worn.single,
        pack.carried.single,
        catalogue,
      );

      expect(
        after.worn.single.attachments,
        containsAll(['att_red_dot', 'tool_suppressor']),
      );
    });
  });

  group('what a part says it does', () {
    test('an optic reads in minutes of angle', () {
      expect(attachmentEffect(catalogue['att_red_dot']!), contains('−1.2 MOA'));
    });

    test('a magazine reads as what is in it', () {
      expect(
        attachmentEffect(catalogue['mag_rifle_545']!, rounds: 7, capacity: 30),
        contains('7 / 30'),
      );
    });

    test('a suppressor reads in decibels, derived from the range', () {
      // ⚠️ Derived, not typed in beside the multiplier. Cutting the range a
      // shot is heard from to 0.29 of it is about eleven decibels — sound
      // falls off with distance — and not the thirty-five a catalogue would
      // claim. One number, one source: change the multiplier to change this.
      final said = attachmentEffect(catalogue['tool_suppressor']!)!;

      expect(said, contains('dB'));
      expect(said, contains('−11'));
    });

    test('and something that changes nothing measurable says nothing', () {
      // Not every part moves a number. A row with an empty right-hand column
      // is honest; an invented one is not.
      expect(attachmentEffect(catalogue['weapon_rifle_545']!), isNull);
    });
  });
}
