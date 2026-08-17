import 'package:arls_za/loot/procedural_points.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/map/poi_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// POJAZDY I POJEMNIKI (§10.1, §10.3.3).
///
/// Nobody maps the Passat outside number 14, and nobody maps the bin beside
/// it — but both are the most ordinary things on any street, and both carry
/// exactly what §18.2 is short of. So the generator that already invents
/// houses and barns invents these too.
///
/// ⚠️ The rule that keeps this from being content creep: they are shares of
/// the *same* points, not extra ones. §10 counts its density in places, so a
/// street that grows cars and bins grows them **instead of** something else.
void main() {
  const centre = GeoPoint(52.4064, 16.9252);

  group('the mix on ordinary ground', () {
    test('every share adds up to a whole', () {
      for (final entry in kGeneratedMix.entries) {
        var total = 0;
        for (final row in entry.value) {
          total += row.share;
        }
        expect(total, 100, reason: entry.key);
      }

      var roadside = 0;
      for (final row in kRoadsideMix) {
        roadside += row.share;
      }
      expect(roadside, 100);
    });

    test('a street can produce a car and a bin', () {
      // Both are ordinary. Neither is a windfall: what comes out of them is
      // wood, metal, plastic and cloth — the bottleneck of §18.2 — and never
      // a weapon.
      final selectors = {
        for (final row in kRoadsideMix) row.selector,
        for (final row in kGeneratedMix['landuse.class=residential']!)
          row.selector,
      };

      expect(selectors, contains(kCarSelector));
      expect(selectors, contains(kWasteSelector));
    });

    test('and a wood produces neither', () {
      // A car in the middle of a forest is a map that reads as random rather
      // than as abandoned.
      final wood = kGeneratedMix['landcover.class=wood']!;

      expect(wood.map((row) => row.selector), isNot(contains(kCarSelector)));
      expect(wood.map((row) => row.selector), isNot(contains(kWasteSelector)));
    });
  });

  group('the two vehicles worth a table of their own (§10.3.3)', () {
    Poi anchor(String selector) => Poi(
      position: centre,
      selectors: [selector],
      name: null,
      layer: 'poi',
    );

    test('an ambulance stands outside a hospital', () {
      final made = vehiclesBeside([anchor('poi.class=hospital')], seed: 7);

      expect(made, hasLength(1));
      expect(made.single.selectors, [kAmbulanceSelector]);
    });

    test('and a patrol car outside a station', () {
      final made = vehiclesBeside([anchor('poi.class=police')], seed: 7);

      expect(made.single.selectors, [kPoliceCarSelector]);
    });

    test('beside it, not on top of it', () {
      final made = vehiclesBeside([anchor('poi.class=hospital')], seed: 7);

      expect(
        made.single.position.distanceTo(centre),
        closeTo(kAnchoredVehicleM, 1),
      );
    });

    test('nothing else earns one', () {
      // They are the richest things in the game per kilogram carried, so they
      // are attached to a building rather than sprinkled about.
      expect(vehiclesBeside([anchor('poi.class=florist')], seed: 7), isEmpty);
    });

    test('and the same seed puts it in the same place', () {
      // §11: a village that rearranges itself between sessions is a village
      // nobody can learn.
      final first = vehiclesBeside([anchor('poi.class=hospital')], seed: 7);
      final again = vehiclesBeside([anchor('poi.class=hospital')], seed: 7);

      expect(
        first.single.position.distanceTo(again.single.position),
        lessThan(0.5),
      );
    });
  });
}
