import 'dart:io';

import 'package:arls_za/l10n/app_localizations.dart';
import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// IKONY MIEJSC (§3.6, §10).
///
/// A dot that only says "something to search" sends a player three hundred
/// metres to a florist. What they are actually deciding is which errand is
/// worth the walk, and that decision needs the kind of place rather than the
/// fact of one.
///
/// Read off the loot table rather than the OSM tag, because the table is what
/// decides what is inside — and what is inside is the whole reason anybody
/// walks there.
void main() {
  group('what each table earns', () {
    test('the two places with medicine in them', () {
      expect(placeIconFor('poi_pharmacy'), PlaceIcon.medical);
      expect(placeIconFor('poi_hospital'), PlaceIcon.medical);
    });

    test('and the one with ammunition', () {
      expect(placeIconFor('poi_military'), PlaceIcon.guarded);
    });

    test('§18.2 kilograms come from workshops and warehouses', () {
      // The real bottleneck of the game is wood and metal, not cartridges.
      for (final table in const [
        'poi_hardware',
        'poi_industrial',
        'poi_warehouse',
        'proc_garage',
      ]) {
        expect(placeIconFor(table), PlaceIcon.tools, reason: table);
      }
    });

    test('weapons are sport, hunting and the gun shop', () {
      for (final table in const [
        'poi_weapons',
        'poi_sports',
        'proc_hunting_stand',
      ]) {
        expect(placeIconFor(table), PlaceIcon.weapons, reason: table);
      }
    });

    test('bins and roadsides are their own shape', () {
      expect(placeIconFor('proc_waste'), PlaceIcon.waste);
      expect(placeIconFor('proc_roadside'), PlaceIcon.waste);
    });

    test('and a car is a car', () {
      expect(placeIconFor('proc_abandoned_car'), PlaceIcon.vehicle);
    });
  });

  group('nothing is left without a shape', () {
    test('an unknown table still gets one', () {
      // A place with no glyph is a place the player cannot read at all, which
      // is worse than a slightly wrong glyph.
      expect(placeIconFor('poi_something_new'), isNotNull);
      expect(placeIconFor(null), isNotNull);
    });

    test('and the legend stays small enough to remember', () {
      // Eleven shapes read at arm's length in the rain is nothing.
      expect(PlaceIcon.values.length, lessThanOrEqualTo(9));
    });
  });

  test('a marker keeps its shape through a copy', () {
    const marker = MapMarker(
      id: 'poi.1',
      kind: MarkerKind.loot,
      at: GeoPoint(52.4, 16.9),
      icon: PlaceIcon.medical,
    );

    expect(marker.copyWith(count: 3).icon, PlaceIcon.medical);
  });

  group('a safe zone is not a reach ring (§8.1)', () {
    const shelter = MapMarker(
      id: 'shelter.1',
      kind: MarkerKind.shelter,
      at: GeoPoint(52.4, 16.9),
      reachM: 50,
    );
    const shop = MapMarker(
      id: 'poi.1',
      kind: MarkerKind.loot,
      at: GeoPoint(52.4, 16.9),
      reachM: 25,
    );

    test('nothing at all is drawn around the player', () {
      // ⚠️ Found on a phone: starting a shelter put a fifty-metre circle on
      // the player's feet that walked down the street with them, which says
      // the exact opposite of what §8.1 means. The answer then was to keep
      // shelters out of the player's rings; the answer now is that there are
      // no rings on the player — §10.2 gives places different reaches, and a
      // circle underfoot cannot say which place it stands for.
      expect(reachRingsOf(const [shelter, shop]), isEmpty);
    });

    test('both get a circle of their own, where they stand', () {
      final zones = zonesOf(const [shelter, shop]);

      expect(zones, hasLength(2));
      expect(zones.map((zone) => zone.radiusM), containsAll([50.0, 25.0]));
      for (final zone in zones) {
        expect(zone.at, shelter.at, reason: 'drawn on the place, not the feet');
      }
    });
  });
  group('a place says what it is (§3.6)', () {
    // ⚠️ Every loot place read "Skrzynia" — one word for a pharmacy, a wheelie
    // bin and an abandoned car alike. Reported from a walk, and worse than
    // untidy: §3.6 gives places different icons precisely so a player can
    // decide which errand is worth the walk, and a panel saying "crate" while
    // the map shows a car takes that decision back off them.
    testWidgets('the generated places are named, not called crates', (
      tester,
    ) async {
      late L10n l10n;
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
            builder: (context) {
              l10n = L10n.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(placeName(l10n, 'proc_abandoned_car'), 'Samochód');
      expect(placeName(l10n, 'proc_waste'), 'Śmietnik');
      expect(placeName(l10n, 'proc_police_car'), 'Radiowóz');
      expect(placeName(l10n, 'poi_pharmacy'), 'Apteka');

      // And a crate is what is left when nothing else fits — the one place
      // the old word was ever right.
      expect(placeName(l10n, 'something_new'), 'Skrzynia');
      expect(placeName(l10n, null), 'Skrzynia');
    });

    test('every table in the shipped data has a name of its own', () {
      // A table added without a name would silently read "Skrzynia" again,
      // which is exactly how this started.
      final tables = LootTableSet.parse(
        File('assets/data/loot_tables.json').readAsStringSync(),
      );

      final source = File('lib/ui/map_markers.dart').readAsStringSync();
      for (final table in tables.tables) {
        expect(
          source,
          contains("'${table.id}' =>"),
          reason: '${table.id} would fall back to "crate"',
        );
      }
    });
  });
}
