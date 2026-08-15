import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/ui/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// EKWIPUNEK (§3.6, §18.1a). The screen exists to answer "what am I carrying
/// and what is it costing me", so what is tested is that both costs are on it
/// — per item, not only as a total.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  Future<void> pump(
    WidgetTester tester,
    Inventory inventory, {
    void Function(CarriedItem, int)? onDrop,
    void Function(CarriedItem)? onTakeOff,
  }) async {
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
        home: InventoryScreen(
          inventory: ValueNotifier(inventory),
          catalogue: catalogue,
          names: names,
          body: body,
          onDrop: onDrop,
          onTakeOff: onTakeOff,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty pack says so rather than showing an empty list', (
    tester,
  ) async {
    await pump(tester, const Inventory());

    expect(find.text('Plecak jest pusty.'), findsOneWidget);
    expect(find.text('Tylko kieszenie'), findsOneWidget);
  });

  testWidgets('both limits are at the top, in their own units', (tester) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('mat_wood', catalogue, body: body, count: 4)
        .inventory;

    await pump(tester, inventory);

    // 4 x 2.0 kg plus the 0.9 kg pack, against 44 kg of limit; 16 l of 45.
    expect(find.text('8.9 / 44 kg'), findsOneWidget);
    expect(find.text('16.0 / 45 l'), findsOneWidget);
  });

  testWidgets('every line carries its own mass and bulk', (tester) async {
    // A total alone says something has to go without saying what.
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('food_canned_meat', catalogue, body: body, count: 2)
        .inventory;

    await pump(tester, inventory);

    expect(find.text('Konserwa mięsna  ×2'), findsOneWidget);
    expect(find.text('0.80 kg\n0.80 l'), findsOneWidget);
  });

  testWidgets('worn kit is listed apart from packed kit (§18.1a)', (
    tester,
  ) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .wear('cloth_winter_jacket');

    await pump(tester, inventory);

    expect(find.text('NA SOBIE'), findsOneWidget);
    expect(find.text('Kurtka zimowa'), findsOneWidget);
    // Worn, so it is not in the pack and the bulk gauge stays at zero.
    expect(find.text('0.0 / 45 l'), findsOneWidget);
  });

  testWidgets('an overloaded pack says what it costs, not just in colour', (
    tester,
  ) async {
    // §12: colour never carries information on its own.
    final inventory = const Inventory()
        .add('mat_metal', catalogue, body: body, count: 18)
        .inventory;

    await pump(tester, inventory);

    expect(
      find.text('Powyżej komfortowego obciążenia — każdy krok kosztuje więcej.'),
      findsOneWidget,
    );
  });

  testWidgets('the heaviest thing is at the top, being the one to leave', (
    tester,
  ) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add('med_bandage', catalogue, body: body)
        .inventory
        .add('mat_wood', catalogue, body: body)
        .inventory;

    await pump(tester, inventory);

    final wood = tester.getTopLeft(find.text('Drewno'));
    final bandage = tester.getTopLeft(find.text('Bandaż'));
    expect(wood.dy, lessThan(bandage.dy));
  });

  testWidgets('a book shows how far through it the player is (§4.6.3)', (
    tester,
  ) async {
    final inventory = const Inventory()
        .withPack('pack_daypack')
        .add(
          'lit_guide_survival',
          catalogue,
          body: body,
          pagesTotal: 160,
        )
        .inventory;

    await pump(tester, inventory);

    expect(find.textContaining('0 / 160'), findsOneWidget);
  });

  group('a stack is thinned, not emptied (§18.1a)', () {
    // Found on a phone: the only button dropped the whole pile, so a player
    // who wanted to shed one kilogram of wood lost six.
    final threeLogs = const Inventory()
        .withPack('pack_daypack')
        .add('mat_wood', catalogue, body: body, count: 3)
        .inventory;

    testWidgets('the plain button drops one', (tester) async {
      var count = 0;
      String? itemId;

      await pump(
        tester,
        threeLogs,
        onDrop: (line, dropped) {
          itemId = line.itemId;
          count = dropped;
        },
      );
      await tester.tap(find.text('Wyrzuć'));
      await tester.pump();

      expect(itemId, 'mat_wood');
      expect(count, 1);
    });

    testWidgets('and there is a way to drop the lot', (tester) async {
      var count = 0;

      await pump(tester, threeLogs, onDrop: (_, dropped) => count = dropped);
      await tester.tap(find.text('Wszystko'));
      await tester.pump();

      expect(count, 3);
    });

    testWidgets('a single item is not asked which', (tester) async {
      final one = const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body)
          .inventory;

      await pump(tester, one, onDrop: (_, _) {});

      expect(find.text('Wyrzuć'), findsOneWidget);
      expect(find.text('Wszystko'), findsNothing);
    });
  });

  group('worn kit comes off', () {
    final dressed = const Inventory()
        .withPack('pack_daypack')
        .wear('armor_vest_soft');

    testWidgets('there is a way to take it off at all (§4.4)', (tester) async {
      CarriedItem? taken;

      await pump(tester, dressed, onTakeOff: (line) => taken = line);
      await tester.tap(find.text('Zdejmij'));
      await tester.pump();

      expect(taken?.itemId, 'armor_vest_soft');
    });

    testWidgets('and it is the only thing offered for worn kit', (
      tester,
    ) async {
      // Taking a vest off and throwing it on the ground are different
      // decisions, and only one belongs a tap away on a screen read in the
      // dark.
      await pump(tester, dressed, onDrop: (_, _) {}, onTakeOff: (_) {});

      expect(find.text('Zdejmij'), findsOneWidget);
      expect(find.text('Wyrzuć'), findsNothing);
    });
  });

  testWidgets('the list follows the inventory, not the moment it opened', (
    tester,
  ) async {
    // ⚠️ The bug this exists for: the screen is a pushed route, its builder
    // runs once, and handed a plain value it kept showing what it opened with.
    // Dropping something looked like nothing had happened, so the same item
    // could be dropped over and over against a list already out of date.
    final inventory = ValueNotifier(
      const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body, count: 3)
          .inventory,
    );

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
        home: InventoryScreen(
          inventory: inventory,
          catalogue: catalogue,
          names: names,
          body: body,
          onDrop: (line, count) =>
              inventory.value = inventory.value.remove(
                line.itemId,
                count: count,
              )!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Drewno  ×3'), findsOneWidget);

    await tester.tap(find.text('Wszystko'));
    await tester.pumpAndSettle();

    expect(find.text('Drewno  ×3'), findsNothing);
    expect(
      find.text('Wyrzuć'),
      findsNothing,
      reason: 'nothing left to drop, so no button to press again',
    );
    expect(find.text('Plecak jest pusty.'), findsOneWidget);
  });


}
