import 'dart:io';
import 'dart:math';

import 'package:arls_za/items/item_catalogue.dart';
import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/loot/loot_spawner.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/place_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// CO WIADOMO O MIEJSCU (§10, §19.3).
///
/// A yellow dot that says only "something is here" makes every dot worth the
/// same walk, which makes none of them a decision. What this shows is what a
/// player could tell from the street: how far, whether the door is hanging
/// open, whether they have already been, and what kind of place it is — never
/// what the roll will give.
void main() {
  final catalogue = ItemCatalogue.load([
    for (final asset in kBundledItemAssets)
      ItemSource(asset, File(asset).readAsStringSync()),
  ]);
  final tables = LootTableSet.parse(
    File('assets/data/loot_tables.json').readAsStringSync(),
  );

  const centre = GeoPoint(52.4084, 16.9342);
  final now = DateTime.utc(2026, 8, 15, 12);

  LootBox boxAt({
    String tableId = 'poi_pharmacy',
    DateTime? opened,
    int searchUnits = 0,
    DateTime? looted,
    DateTime? respawn,
  }) => LootBox(
    poiId: 'p1',
    position: centre,
    tableId: tableId,
    name: 'Apteka',
    spawnedAt: now,
    openedAt: opened,
    searchUnits: searchUnits,
    lootedAt: looted,
    respawnAt: respawn,
  );

  /// Where the player is standing, as a notifier — the sheet reads the
  /// distance live rather than being handed a number taken when it opened.
  late ValueNotifier<GeoPoint?> standingAt;

  Future<void> open(
    WidgetTester tester, {
    required LootBox box,
    double distanceM = 240,
  }) async {
    // The box sits at [centre]; the player is put that many metres south of
    // it, so the sheet has a real distance to work out.
    standingAt = ValueNotifier(
      GeoPoint(
        centre.latitude - distanceM / metresPerDegreeLat,
        centre.longitude,
      ),
    );
    addTearDown(standingAt.dispose);

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
            onPressed: () => showPlaceDetails(
              context,
              box: box,
              table: tables[box.tableId],
              standingAt: standingAt,
              catalogue: catalogue,
              now: now,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('it says how far the walk is', (tester) async {
    await open(tester, box: boxAt(), distanceM: 310);

    expect(find.text('310 m'), findsOneWidget);
  });

  testWidgets('and keeps saying it while the player walks', (tester) async {
    // ⚠️ The one number on this sheet that changes while it is being looked
    // at. A reading frozen at the moment it opened says the player is not
    // getting any closer, which is worse than showing nothing.
    await open(tester, box: boxAt(), distanceM: 310);
    expect(find.text('310 m'), findsOneWidget);

    standingAt.value = GeoPoint(
      centre.latitude - 120 / metresPerDegreeLat,
      centre.longitude,
    );
    await tester.pump();

    expect(find.text('120 m'), findsOneWidget);
    expect(find.text('310 m'), findsNothing);
  });

  testWidgets('and what is in the way', (tester) async {
    await open(tester, box: boxAt());

    expect(find.text('Zamknięte drzwi'), findsOneWidget);
  });

  testWidgets('or that somebody got there first', (tester) async {
    await open(tester, box: boxAt(opened: now));

    expect(find.text('Otwarte'), findsOneWidget);
  });

  testWidgets('an untouched place says so', (tester) async {
    await open(tester, box: boxAt());

    expect(find.text('Jeszcze nie'), findsOneWidget);
  });

  testWidgets('a place half turned over says how much is left', (tester) async {
    // One quick pass out of six units: two thirds of it still standing.
    await open(tester, box: boxAt(searchUnits: SearchDepth.shallow.cost));

    expect(find.textContaining('67%'), findsOneWidget);
  });

  testWidgets('a stripped place says when something will be back', (
    tester,
  ) async {
    await open(
      tester,
      box: boxAt(
        searchUnits: kSearchBudget,
        looted: now,
        respawn: now.add(const Duration(hours: 5)),
      ),
    );

    expect(find.textContaining('5 h'), findsOneWidget);
  });

  testWidgets('it names the kinds of thing a pharmacy holds', (tester) async {
    await open(tester, box: boxAt());

    expect(find.textContaining('Medykament'), findsOneWidget);
  });

  testWidgets('but never what is actually in it', (tester) async {
    // Naming the contents in advance would turn the walk into a shopping trip.
    final table = tables['poi_pharmacy']!;
    final random = Random(1);
    final drop = table.roll(
      random,
      depth: SearchDepth.deep,
      catalogue: catalogue,
    );

    await open(tester, box: boxAt());

    for (final itemId in drop.keys) {
      final name = catalogue[itemId]!.name.resolve(
        language: 'pl',
        lookup: (_) => null,
      );
      expect(find.textContaining(name), findsNothing, reason: itemId);
    }
  });

  group('what the place still has room for (§10.3.5)', () {
    testWidgets('an untouched place offers all three passes', (tester) async {
      await open(tester, box: boxAt());

      expect(find.textContaining('Pobieżnie'), findsOneWidget);
      expect(find.textContaining('Gruntownie'), findsOneWidget);
    });

    testWidgets('one quick look later, the deep pass is gone from the list', (
      tester,
    ) async {
      // "67% left" is a number; "a quick look or a thorough one, not a deep
      // one" is the decision itself.
      await open(tester, box: boxAt(searchUnits: SearchDepth.shallow.cost));

      expect(find.textContaining('Pobieżnie'), findsOneWidget);
      expect(find.textContaining('Gruntownie'), findsNothing);
    });

    testWidgets('a stripped place says there is nothing left', (tester) async {
      await open(
        tester,
        box: boxAt(
          searchUnits: kSearchBudget,
          looted: now,
          respawn: now.add(const Duration(hours: 4)),
        ),
      );

      expect(find.text('Nie ma już czego przewracać'), findsOneWidget);
    });
  });
}
