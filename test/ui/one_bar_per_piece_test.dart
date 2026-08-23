import 'dart:io';

import 'package:arls_za/inventory/inventory.dart';
import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/sim/body.dart';
import 'package:arls_za/ui/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// JEDEN PASEK NA JEDEN KAWAŁEK (§4.7, §11.1).
///
/// ⚠️ **Reported from a walk, with a photograph.** Two part-drunk bottles in
/// one pack, and starting to drink one of them drew a bar under *both* — the
/// same seconds, the same fill. §2.1a allows one action, so there was one
/// action; what there were two of was rows claiming it.
///
/// The rule the row draws by: the bar goes under the very piece in hand
/// (§11.1), never under everything that shares its name. Half a bottle and
/// another half bottle are two bottles, and that is the whole reason a piece
/// has a name of its own.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());
  final body = BodyProfile.from(
    const BodySpec(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80),
  );

  const water = 'drink_water_bottle_500';
  final now = DateTime.now().toUtc();

  /// The pack from the photograph: a stack, and two bottles somebody has
  /// already started on.
  ({Inventory pack, CarriedItem opened, CarriedItem other}) packFromTheWalk({
    String? openedUid = 'a.1',
    String? otherUid = 'b.1',
  }) {
    final opened = const CarriedItem(
      itemId: water,
    ).copyWith(uid: openedUid, portion: 0.55);
    final other = const CarriedItem(
      itemId: water,
    ).copyWith(uid: otherUid, portion: 0.26);

    return (
      pack: Inventory(
        carried: [
          const CarriedItem(itemId: water, count: 3).copyWith(uid: 'stack'),
          opened,
          other,
        ],
      ),
      opened: opened,
      other: other,
    );
  }

  Future<void> show(
    WidgetTester tester, {
    required Inventory pack,
    required CarriedItem? using,
  }) async {
    // ⚠️ Tall enough to hold the whole pack. §18.1a's worn slots fill a
    // default test viewport on their own, and a row that was never laid out
    // is a row this test would pass by not looking at.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('pl'),
        home: InventoryScreen(
          inventory: ValueNotifier(pack),
          order: ValueNotifier(PackOrder.name),
          catalogue: catalogue,
          names: names,
          body: body,
          onDrop: (_, _) {},
          action: ValueNotifier(
            Search.using(
              at: const GeoPoint(52.4064, 16.9252),
              now: now,
              itemId: water,
              duration: const Duration(seconds: 12),
              label: 'Pijesz: Woda 0,5 l',
            ),
          ),
          usingLine: ValueNotifier(using),
          onCancelAction: () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('one bar, under the bottle in hand', (tester) async {
    final walk = packFromTheWalk();
    await show(tester, pack: walk.pack, using: walk.opened);

    // "Przerwij" is the way out of a running action, and there is one action.
    expect(find.text('Przerwij'), findsOneWidget);
  });

  testWidgets('and the other bottle is left alone', (tester) async {
    final walk = packFromTheWalk();
    await show(tester, pack: walk.pack, using: walk.opened);

    // Both are on screen — this is not a test that the row disappeared.
    expect(find.textContaining('zostało 55%'), findsOneWidget);
    expect(find.textContaining('zostało 26%'), findsOneWidget);
  });

  testWidgets('nothing in hand draws nothing', (tester) async {
    final walk = packFromTheWalk();
    await show(tester, pack: walk.pack, using: null);

    expect(find.text('Przerwij'), findsNothing);
  });

  testWidgets('a piece with no name of its own draws one bar', (tester) async {
    // ⚠️ The case this bug was actually made of. A line that came from
    // [Inventory.add] — off the ground, off a shelf, out of a finished job —
    // has no uid, and [CarriedItem.isSame] then falls back to object
    // identity. Two nameless bottles must still be two bottles.
    final walk = packFromTheWalk(openedUid: null, otherUid: null);
    await show(tester, pack: walk.pack, using: walk.opened);

    expect(find.text('Przerwij'), findsOneWidget);
  });
}
