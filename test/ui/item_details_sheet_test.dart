import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/ui/item_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// SZCZEGÓŁY PRZEDMIOTU (§4.2–§4.7).
///
/// A player standing over a second vest is not asking what it does, they are
/// asking whether to swap. Both answers have to be in one window, with the
/// direction marked, because "protection 4 against protection 2, coverage 40
/// against 55" is arithmetic nobody does in a street in the rain.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  Future<void> open(
    WidgetTester tester, {
    String? itemId,
    CarriedItem? line,
    required Inventory inventory,
    VoidCallback? onWear,
    String? wearLabel,
  }) async {
    final entry = line ?? CarriedItem(itemId: itemId!);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showItemDetails(
              context,
              line: entry,
              inventory: ValueNotifier(inventory),
              catalogue: catalogue,
              names: names,
              onWear: onWear,
              wearLabel: wearLabel,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Which way the row is marked, read off the row rather than off the screen:
  /// several rows carry an icon and only one of them is this reading's.
  IconData? markOn(WidgetTester tester, String label) {
    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(Row),
    );
    final icons = find.descendant(of: row.first, matching: find.byType(Icon));
    if (icons.evaluate().isEmpty) return null;
    return tester.widget<Icon>(icons.first).icon;
  }

  testWidgets('an item alone is just its own numbers', (tester) async {
    await open(
      tester,
      itemId: 'armor_vest_soft',
      inventory: const Inventory(),
    );

    expect(find.text('Ochrona'), findsOneWidget);
    expect(find.text('Pokrycie'), findsOneWidget);
    // Nothing to compare with, so nothing claims to be better or worse.
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('mass and bulk are on it, being what everything costs', (
    tester,
  ) async {
    await open(tester, itemId: 'mat_wood', inventory: const Inventory());

    expect(find.text('Masa'), findsOneWidget);
    expect(find.text('Objętość'), findsOneWidget);
  });

  group('a second vest, against the one being worn', () {
    // §4.4: soft vest is protection 2 over 55% of the torso at 2.6 kg; the
    // plate carrier is protection 4 over 40% at 8.5 kg. Neither is simply
    // better, which is exactly why the screen exists.
    final wearingSoft = const Inventory().wear('armor_vest_soft');

    testWidgets('it says what it is being compared with', (tester) async {
      await open(
        tester,
        itemId: 'armor_vest_plate',
        inventory: wearingSoft,
      );

      expect(find.textContaining('Porównanie z'), findsOneWidget);
      expect(find.textContaining('na sobie'), findsOneWidget);
    });

    testWidgets('more protection is a plus', (tester) async {
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Ochrona'), Icons.add);
    });

    testWidgets('less coverage is a minus', (tester) async {
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Pokrycie'), Icons.remove);
    });

    testWidgets('six kilograms more is a minus, not a plus', (tester) async {
      // The reading that is easiest to get backwards: the number goes up and
      // the player is worse off.
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Masa'), Icons.remove);
    });

    testWidgets('and the other way round, from the plate to the soft', (
      tester,
    ) async {
      await open(
        tester,
        itemId: 'armor_vest_soft',
        inventory: const Inventory().wear('armor_vest_plate'),
      );

      expect(markOn(tester, 'Ochrona'), Icons.remove);
      expect(markOn(tester, 'Masa'), Icons.add);
    });

    testWidgets('a reading that is identical is marked neither way', (
      tester,
    ) async {
      // Both vests insulate 0.3 clo. An arrow there would be noise.
      await open(tester, itemId: 'armor_vest_plate', inventory: wearingSoft);

      expect(markOn(tester, 'Izolacja'), isNull);
    });
  });

  testWidgets('a jacket is not compared with a vest', (tester) async {
    // Different slots, so one never displaces the other (§4.4).
    await open(
      tester,
      itemId: 'cloth_winter_jacket',
      inventory: const Inventory().wear('armor_vest_soft'),
    );

    expect(find.textContaining('Porównanie z'), findsNothing);
  });

  testWidgets('two in the pack still compare, nothing being worn', (
    tester,
  ) async {
    // The case a player hits first: the new one is found before the old one
    // comes off.
    await open(
      tester,
      itemId: 'armor_vest_plate',
      inventory: const Inventory(
        carried: [CarriedItem(itemId: 'armor_vest_soft')],
      ),
    );

    expect(find.textContaining('w plecaku'), findsOneWidget);
  });

  testWidgets('the swap can be made from here, without going back', (
    tester,
  ) async {
    var worn = 0;

    await open(
      tester,
      itemId: 'armor_vest_plate',
      inventory: const Inventory().wear('armor_vest_soft'),
      onWear: () => worn++,
      wearLabel: 'Załóż',
    );
    await tester.tap(find.text('Załóż'));
    await tester.pumpAndSettle();

    expect(worn, 1);
    // And the sheet gets out of the way, since the screen behind it changed.
    expect(find.text('Ochrona'), findsNothing);
  });

  testWidgets('what is already worn offers no way to put it on again', (
    tester,
  ) async {
    await open(
      tester,
      itemId: 'armor_vest_soft',
      inventory: const Inventory().wear('armor_vest_soft'),
    );

    expect(find.text('Załóż'), findsNothing);
  });

  group('two copies of one vest, which is the case a player hits', () {
    // Found on a phone: "found a new vest, I have an old one" is usually the
    // same model twice, and comparing an item with itself was refused, so the
    // screen said nothing at all.
    const battered = CarriedItem(itemId: 'armor_vest_soft', condition: 40);
    const found = CarriedItem(itemId: 'armor_vest_soft', condition: 90);

    testWidgets('the worn copy is what the found one is measured against', (
      tester,
    ) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(worn: [battered], carried: [found]),
      );

      expect(find.textContaining('Porównanie z'), findsOneWidget);
      expect(find.textContaining('na sobie'), findsOneWidget);
    });

    testWidgets('and the difference between them is how worn each is', (
      tester,
    ) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(worn: [battered], carried: [found]),
      );

      expect(find.text('Stan'), findsOneWidget);
      expect(markOn(tester, 'Stan'), Icons.add);
    });

    testWidgets('the battered one, held against the good one, reads as a loss',
        (tester) async {
      await open(
        tester,
        line: battered,
        inventory: const Inventory(worn: [found], carried: [battered]),
      );

      expect(markOn(tester, 'Stan'), Icons.remove);
    });

    testWidgets('a copy is never compared with itself', (tester) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(carried: [found]),
      );

      expect(find.textContaining('Porównanie z'), findsNothing);
    });

    testWidgets('two in the pack compare with each other', (tester) async {
      await open(
        tester,
        line: found,
        inventory: const Inventory(carried: [found, battered]),
      );

      expect(find.textContaining('w plecaku'), findsOneWidget);
    });
  });
}
