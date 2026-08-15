import 'dart:io';

import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/items/item_names.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/loot/dropped_items.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/ground_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// NA ZIEMI (§4.8).
///
/// The panel could only ever offer the nearest single row, so a player
/// standing where they emptied their pack had to pick up six bandages to reach
/// the rifle underneath. The list is the fix, and what it has to get right is
/// that it stays true while things are taken off it.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final names = ItemNames.parse(File(kItemNamesAsset).readAsStringSync());

  const here = GeoPoint(52.4084, 16.9342);
  final droppedAt = DateTime.utc(2026, 8, 15, 12);

  DroppedItem lying(
    String itemId, {
    required int id,
    double metres = 0,
    int count = 1,
    double? condition,
  }) => DroppedItem(
    id: id,
    itemId: itemId,
    count: count,
    condition: condition,
    position: GeoPoint(
      here.latitude + metres / metresPerDegreeLat,
      here.longitude,
    ),
    droppedAt: droppedAt,
  );

  Future<void> open(
    WidgetTester tester, {
    required ValueNotifier<List<DroppedItem>> dropped,
    ValueNotifier<GeoPoint?>? at,
    void Function(GroundPile)? onTake,
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
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showGroundItems(
              context,
              dropped: dropped,
              at: at ?? ValueNotifier<GeoPoint?>(here),
              reachM: 15,
              catalogue: catalogue,
              names: names,
              onTake: onTake ?? (_) {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('everything underfoot is on one screen', (tester) async {
    await open(
      tester,
      dropped: ValueNotifier([
        lying('med_bandage', id: 1, count: 3),
        lying('melee_knife', id: 2, metres: 4),
        lying('mat_wood', id: 3, metres: 8),
      ]),
    );

    expect(find.text('Bandaż  ×3'), findsOneWidget);
    expect(find.text('Nóż'), findsOneWidget);
    expect(find.text('Drewno'), findsOneWidget);
  });

  testWidgets('three drops of one thing are one row, not three', (
    tester,
  ) async {
    await open(
      tester,
      dropped: ValueNotifier([
        lying('med_bandage', id: 1),
        lying('med_bandage', id: 2, metres: 2),
        lying('med_bandage', id: 3, metres: 3),
      ]),
    );

    expect(find.text('Bandaż  ×3'), findsOneWidget);
    expect(find.text('Podnieś'), findsOneWidget);
  });

  testWidgets('each row says how far off and how worn it is', (tester) async {
    await open(
      tester,
      dropped: ValueNotifier([
        lying('melee_knife', id: 1, metres: 6, condition: 45),
      ]),
    );

    expect(find.textContaining('6 m'), findsOneWidget);
    expect(find.textContaining('45%'), findsOneWidget);
  });

  testWidgets('the pile a player asks for is the pile they get', (
    tester,
  ) async {
    // The whole point: reaching the knife should not mean taking the bandages
    // first.
    GroundPile? taken;
    await open(
      tester,
      dropped: ValueNotifier([
        lying('med_bandage', id: 1, count: 3),
        lying('melee_knife', id: 2, metres: 5),
      ]),
      onTake: (pile) => taken = pile,
    );

    final knifeRow = find.ancestor(
      of: find.text('Nóż'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: knifeRow.first, matching: find.text('Podnieś')),
    );
    await tester.pumpAndSettle();

    expect(taken?.itemId, 'melee_knife');
  });

  testWidgets('what has been picked up leaves the list', (tester) async {
    // A pushed route over a running game: handed a copy, it would keep
    // offering things already in the pack.
    final dropped = ValueNotifier([
      lying('med_bandage', id: 1),
      lying('melee_knife', id: 2, metres: 5),
    ]);

    await open(tester, dropped: dropped);
    expect(find.text('Nóż'), findsOneWidget);

    dropped.value = [lying('med_bandage', id: 1)];
    await tester.pumpAndSettle();

    expect(find.text('Nóż'), findsNothing);
    expect(find.text('Bandaż'), findsOneWidget);
  });

  testWidgets('walking away from the heap empties the list', (tester) async {
    final at = ValueNotifier<GeoPoint?>(here);

    await open(
      tester,
      dropped: ValueNotifier([lying('med_bandage', id: 1)]),
      at: at,
    );
    expect(find.text('Bandaż'), findsOneWidget);

    at.value = GeoPoint(here.latitude + 60 / metresPerDegreeLat, here.longitude);
    await tester.pumpAndSettle();

    expect(find.text('Już nic tu nie ma.'), findsOneWidget);
  });

  testWidgets('and so does taking the last of it', (tester) async {
    final dropped = ValueNotifier([lying('med_bandage', id: 1)]);

    await open(tester, dropped: dropped);
    dropped.value = const [];
    await tester.pumpAndSettle();

    expect(find.text('Już nic tu nie ma.'), findsOneWidget);
  });
}
