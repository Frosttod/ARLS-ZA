import 'dart:io';

import 'package:arls_za/inventory/body_slots.dart';
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
    void Function(CarriedItem)? onWear,
    void Function(CarriedItem)? onUse,
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
          onWear: onWear,
          onUse: onUse,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The worn figure is ten rows tall, so the pack sits below the fold on a
  /// test-sized screen. Nothing about the layout is wrong; the finger has to
  /// get there, and so does the test.
  /// A ListView builds lazily, so something below the fold does not exist for
  /// a finder until it has been scrolled to. Scroll first to build it, then
  /// align it, then touch it.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        120,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapInPack(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('an empty pack says so rather than showing an empty list', (
    tester,
  ) async {
    await pump(tester, const Inventory());

    expect(find.text('Plecak jest pusty.'), findsOneWidget);
    // §4.4's back slot, empty like the rest of the figure.
    expect(find.text('PLECY'), findsOneWidget);
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

    await reveal(tester, find.text('Bandaż'));

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
      await tapInPack(tester, find.text('Wyrzuć'));

      expect(itemId, 'mat_wood');
      expect(count, 1);
    });

    testWidgets('the stepper says how many, up to the whole stack', (
      tester,
    ) async {
      var count = 0;

      await pump(tester, threeLogs, onDrop: (_, dropped) => count = dropped);
      await tapInPack(tester, find.byIcon(Icons.add));
      await tapInPack(tester, find.text('Wyrzuć'));

      expect(count, 2);
    });

    testWidgets('and never past it', (tester) async {
      var count = 0;

      await pump(tester, threeLogs, onDrop: (_, dropped) => count = dropped);
      for (var i = 0; i < 6; i++) {
        await tapInPack(tester, find.byIcon(Icons.add));
      }
      await tapInPack(tester, find.text('Wyrzuć'));

      expect(count, 3);
    });

    testWidgets('a single item is not asked how many', (tester) async {
      // A stepper beside one bandage is a control with one setting.
      final one = const Inventory()
          .withPack('pack_daypack')
          .add('mat_wood', catalogue, body: body)
          .inventory;

      await pump(tester, one, onDrop: (_, _) {});

      expect(find.text('Wyrzuć'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });
  });

  group('the worn figure (§4.4)', () {
    testWidgets('every slot is a row, filled or not', (tester) async {
      // The gap is the information: a list of only what exists cannot tell
      // somebody they have no gloves.
      await pump(tester, const Inventory());

      expect(find.text('GŁOWA'), findsOneWidget);
      expect(find.text('PANCERZ'), findsOneWidget);
      expect(find.text('STOPY'), findsOneWidget);
      expect(find.text('puste'), findsNWidgets(10));
    });

    test('every slot in the data has a place on the figure', () {
      // A garment whose slot the figure does not know would be worn and
      // invisible.
      for (final item in catalogue.all) {
        final slot = item.props['slot'] as String?;
        if (slot == null) continue;
        expect(BodySlot.fromWire(slot), isNotNull, reason: item.id);
      }
    });

    testWidgets('what is worn shows in its own slot', (tester) async {
      await pump(
        tester,
        const Inventory().wear('armor_vest_soft', catalogue),
      );

      expect(find.text('Kamizelka kuloodporna'), findsOneWidget);
      expect(find.text('puste'), findsNWidgets(9));
    });
  });

  group('putting things on and using them', () {
    testWidgets('a vest in the pack can be put back on', (tester) async {
      // The bug this exists for: taking a vest off left no way to wear it
      // again, so the first mistake was permanent.
      CarriedItem? worn;
      final packed = const Inventory()
          .withPack('pack_daypack')
          .add('armor_vest_soft', catalogue, body: body)
          .inventory;

      await pump(tester, packed, onWear: (line) => worn = line);
      await tapInPack(tester, find.text('Załóż'));

      expect(worn?.itemId, 'armor_vest_soft');
    });

    testWidgets('food and water can be used, wood cannot', (tester) async {
      final mixed = const Inventory()
          .withPack('pack_daypack')
          .add('drink_water_bottle_500', catalogue, body: body)
          .inventory
          .add('mat_wood', catalogue, body: body)
          .inventory;

      await pump(tester, mixed, onUse: (_) {});
      await reveal(tester, find.text('Drewno'));

      expect(find.text('Użyj'), findsOneWidget);
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

    await reveal(tester, find.text('Drewno  ×3'));
    expect(find.text('Drewno  ×3'), findsOneWidget);

    // Three taps of the plus, then drop: the whole stack, one deliberate
    // action rather than one careless one.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }
    await tester.tap(find.text('Wyrzuć'));
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
