import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
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
}
