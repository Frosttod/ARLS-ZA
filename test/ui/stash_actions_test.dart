import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/shelter/stash.dart';
import 'package:arls_za/ui/inventory_screen.dart' show PackAction, PackOrder;
import 'package:arls_za/ui/stash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PÓŁKI SĄ RĘKĄ, NIE SKRZYNIĄ (§18.2, §12).
///
/// Eating off a shelf and eating out of a bag are the same motion in the
/// world. These tests are about the shelf offering the same things the pack
/// does — and about the sort being one choice seen on two screens rather than
/// two choices that can disagree.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  String nameOf(String id) =>
      names.lookup('item.$id.name', language: 'pl') ?? id;

  Future<void> open(
    WidgetTester tester, {
    required Stash shelves,
    Inventory pack = const Inventory(),
    ValueNotifier<PackOrder>? order,
    void Function(int index, PackAction action)? onAct,
    void Function(int index)? onDetails,
    bool Function(CarriedItem line)? canDismantle,
    String? Function(CarriedItem line, PackAction action)? refusalOf,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: StashScreen(
          title: 'Półki',
          stash: ValueNotifier(shelves),
          pack: ValueNotifier(pack),
          catalogue: catalogue,
          nameOf: nameOf,
          onStore: (_) {},
          onTake: (_) {},
          order: order ?? ValueNotifier(PackOrder.name),
          onAct: onAct,
          onDetails: onDetails,
          canDismantle: canDismantle,
          refusalOf: refusalOf,
        ),
      ),
    );
    await tester.pump();
  }

  Stash shelfOf(List<CarriedItem> lines) =>
      Stash(lines: lines, capacityKg: 100);

  testWidgets('food on a shelf can be eaten where it lies', (tester) async {
    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'food_canned_meat')]),
      onAct: (_, _) {},
    );

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });

  testWidgets('and a coat on a shelf can be put on', (tester) async {
    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'cloth_winter_jacket')]),
      onAct: (_, _) {},
    );

    expect(find.byIcon(Icons.checkroom), findsOneWidget);
  });

  testWidgets('a tin offers no way to put it on', (tester) async {
    // The rule that applies everywhere: a control that cannot be used is
    // absent, not greyed.
    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'food_canned_meat')]),
      onAct: (_, _) {},
    );

    expect(find.byIcon(Icons.checkroom), findsNothing);
  });

  testWidgets('the dismantle glyph waits to be told (§18.6)', (tester) async {
    // The shelf screen has no recipe book, so it asks the caller — the same
    // caller that answers for the pack, with the same figures.
    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'weapon_rifle_545')]),
      onAct: (_, _) {},
      canDismantle: (_) => false,
    );
    expect(find.byIcon(Icons.handyman), findsNothing);

    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'weapon_rifle_545')]),
      onAct: (_, _) {},
      canDismantle: (_) => true,
    );
    expect(find.byIcon(Icons.handyman), findsOneWidget);
  });

  testWidgets('an action that cannot happen greys and says why', (
    tester,
  ) async {
    var acted = false;

    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'food_canned_meat')]),
      onAct: (_, _) => acted = true,
      refusalOf: (_, action) =>
          action == PackAction.use ? 'To się nie mieści w plecaku.' : null,
    );

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    await tester.tap(find.byIcon(Icons.restaurant));
    await tester.pump();

    expect(acted, isFalse, reason: 'a refused tap does nothing');
    expect(find.textContaining('nie mieści'), findsOneWidget);
  });

  testWidgets('the numbers are one tap away (§5.6.3)', (tester) async {
    var opened = -1;

    await open(
      tester,
      shelves: shelfOf(const [CarriedItem(itemId: 'weapon_rifle_545')]),
      onDetails: (index) => opened = index,
    );

    await tester.tap(find.byIcon(Icons.info_outline));
    expect(opened, 0);
  });

  group('sorting (§18.1a)', () {
    final shelf = shelfOf(const [
      CarriedItem(itemId: 'weapon_rifle_545'),
      CarriedItem(itemId: 'food_canned_meat'),
      CarriedItem(itemId: 'med_bandage'),
    ]);

    test('the shelves and the pack share one order', () {
      // ⚠️ A notifier owned by the caller, like the pack's. A choice held
      // inside a pushed route is a choice forgotten every time the player
      // closes it — six times over in this codebase now.
      final order = ValueNotifier(PackOrder.mass);
      expect(order.value, PackOrder.mass);
    });

    testWidgets('heaviest first is heaviest first', (tester) async {
      await open(tester, shelves: shelf, order: ValueNotifier(PackOrder.mass));

      final rifle = tester.getTopLeft(find.text(nameOf('weapon_rifle_545')));
      final tin = tester.getTopLeft(find.text(nameOf('food_canned_meat')));
      final gauze = tester.getTopLeft(find.text(nameOf('med_bandage')));

      expect(rifle.dy, lessThan(tin.dy));
      expect(tin.dy, lessThan(gauze.dy));
    });

    testWidgets('and the button cycles through the three', (tester) async {
      final order = ValueNotifier(PackOrder.kind);
      await open(tester, shelves: shelf, order: order);

      await tester.tap(find.byType(TextButton).first);
      await tester.pump();
      expect(order.value, PackOrder.name);

      await tester.tap(find.byType(TextButton).first);
      await tester.pump();
      expect(order.value, PackOrder.mass);

      await tester.tap(find.byType(TextButton).first);
      await tester.pump();
      expect(order.value, PackOrder.kind);
    });

    testWidgets('a sorted list still takes the right thing off (§18.2)', (
      tester,
    ) async {
      // ⚠️ The row on screen is not the row in the stash. Handing the caller a
      // screen position would take the wrong item off the shelf the moment the
      // order is anything but the stored one.
      var taken = -1;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('pl'),
          home: StashScreen(
            title: 'Półki',
            stash: ValueNotifier(shelf),
            pack: ValueNotifier(const Inventory()),
            catalogue: catalogue,
            nameOf: nameOf,
            onStore: (_) {},
            onTake: (index) => taken = index,
            order: ValueNotifier(PackOrder.mass),
          ),
        ),
      );
      await tester.pump();

      // Heaviest first puts the rifle at the top; it is index 0 in the stash
      // as well, so pick the last row instead — the bandage, stored third.
      await tester.tap(find.text('Weź').last);
      expect(taken, 2);
    });
  });

  testWidgets('looking at something does not move it', (tester) async {
    // ⚠️ Reported from a shelter in one sentence: tapping the information
    // glyph dragged whatever it was into the pack. It did — the sheet needed
    // the piece in the pack for its attachment rows, so the details action
    // picked it up first like every other shelf action.
    //
    // Reaching for a thing is an action. Reading its weight is not.
    final shelf = shelfOf(const [CarriedItem(itemId: 'weapon_rifle_545')]);
    var taken = -1;
    var opened = -1;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: StashScreen(
          title: 'Półki',
          stash: ValueNotifier(shelf),
          pack: ValueNotifier(const Inventory()),
          catalogue: catalogue,
          nameOf: nameOf,
          onStore: (_) {},
          onTake: (index) => taken = index,
          order: ValueNotifier(PackOrder.name),
          onDetails: (index) => opened = index,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump();

    expect(opened, 0, reason: 'the sheet was asked for');
    expect(taken, -1, reason: 'and nothing was taken off the shelf');
  });
}
