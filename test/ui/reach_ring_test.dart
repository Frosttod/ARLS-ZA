import 'package:arls_za/loot/loot_table.dart';
import 'package:arls_za/loot/search.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:flutter_test/flutter_test.dart';

/// ZASIĘG NA MAPIE (§10.2, §4.8).
///
/// Twenty-five metres to a building and fifteen to a pile at your feet are
/// numbers nobody can judge by eye on a map that zooms. Drawn as a ring, "am I
/// close enough yet" stops being a guess and becomes something to walk into.
///
/// The ring is metres shown in pixels, which is the same arithmetic the zoom
/// bug once got wrong: MapLibre's zoom is defined against logical pixels.
void main() {
  const at = GeoPoint(52.4084, 16.9342);

  double ringPixels(double metres, double zoom) =>
      metres / metresPerPixel(zoom, at.latitude);

  test('a ring is as wide as the reach it stands for', () {
    // At zoom 17 in Poznań a metre is about a pixel, so a 25 m reach is a
    // ring of roughly that many pixels across the radius.
    final pixels = ringPixels(kSearchReachM, 17);

    expect(
      pixels,
      closeTo(kSearchReachM / metresPerPixel(17, at.latitude), 0.001),
    );
    expect(pixels, greaterThan(10));
  });

  test('zooming out shrinks the ring, because the ground does not move', () {
    final close = ringPixels(kSearchReachM, 17);
    final far = ringPixels(kSearchReachM, 14);

    expect(far, closeTo(close / 8, 0.001));
  });

  test('a pile is a tighter ring than a building', () {
    expect(
      ringPixels(kStillnessM, 17),
      lessThan(ringPixels(kSearchReachM, 17)),
    );
  });

  test('a marker carries its own reach, or none at all', () {
    const place = MapMarker(
      id: 'p',
      kind: MarkerKind.loot,
      at: at,
      reachM: kSearchReachM,
    );
    const enemy = MapMarker(id: 'e', kind: MarkerKind.enemy, at: at);

    expect(place.reachM, kSearchReachM);
    expect(enemy.reachM, isNull, reason: 'nothing to reach on an enemy');
  });

  test('and keeps it when the marker moves', () {
    const place = MapMarker(
      id: 'p',
      kind: MarkerKind.loot,
      at: at,
      reachM: kSearchReachM,
    );

    expect(
      place.copyWith(at: const GeoPoint(52.5, 16.9)).reachM,
      kSearchReachM,
    );
  });

  group('one dot for a heap (§4.8)', () {
    // A player who emptied their pack on a corner left fourteen rows in one
    // place, and fourteen overlapping circles is a smear rather than a map.
    MapMarker dropped(String id, double metres) => MapMarker(
      id: id,
      kind: MarkerKind.dropped,
      at: GeoPoint(at.latitude + metres / metresPerDegreeLat, at.longitude),
    );

    test('dropped kit is never folded together (§10.2)', () {
      // ⚠️ It used to be: fourteen rows in one place made fourteen overlapping
      // circles, which is a smear rather than a map. That was written when a
      // search dropped everything on the box's own pin. §10.2 scatters a haul
      // over a metre to three now, and a dot standing for all of it says where
      // none of them is — while the walk to each is the game.
      final clustered = clusterMarkers([
        dropped('a', 0),
        dropped('b', 4),
        dropped('c', 9),
      ]);

      expect(clustered, hasLength(3));
      expect(clustered.every((marker) => marker.count == 1), isTrue);
    });

    test('and each dot stays exactly where its thing is', () {
      // A marker that drifts to the average of a group ends up in the middle
      // of a road, pointing at nothing.
      final clustered = clusterMarkers([dropped('a', 0), dropped('b', 10)]);

      expect(clustered.first.at.latitude, closeTo(at.latitude, 1e-9));
      expect(clustered.last.at.latitude, greaterThan(at.latitude));
    });

    test('things a street apart stay apart', () {
      final clustered = clusterMarkers([dropped('a', 0), dropped('b', 80)]);

      expect(clustered, hasLength(2));
      expect(clustered.every((marker) => marker.count == 1), isTrue);
    });

    test('two enemies are never one dot', () {
      // ⚠️ A pile of kit is one thing to pick up; two Walkers are two things
      // to shoot, and folding them together takes away the only way to aim at
      // either of them.
      final clustered = clusterMarkers([
        MapMarker(id: 'e1', kind: MarkerKind.enemy, at: at),
        MapMarker(
          id: 'e2',
          kind: MarkerKind.enemy,
          at: GeoPoint(at.latitude + 3 / metresPerDegreeLat, at.longitude),
        ),
      ]);

      expect(clustered, hasLength(2));
      expect(clustered.every((marker) => marker.count == 1), isTrue);
    });

    test('a pile and a shop are never one dot', () {
      // Two different answers to "what is that", and merging them says
      // neither.
      final clustered = clusterMarkers([
        dropped('a', 0),
        MapMarker(id: 'shop', kind: MarkerKind.loot, at: at),
      ]);

      expect(clustered, hasLength(2));
    });

    test('one thing alone is left exactly as it was', () {
      final one = dropped('a', 0);

      expect(identical(clusterMarkers([one]).single, one), isTrue);
    });

    test('the reach ring survives the fold', () {
      // Places still fold — a row of shelves in one shop is one dot — and the
      // ring that says how far a search reaches has to come through with it.
      final clustered = clusterMarkers([
        MapMarker(id: 'a', kind: MarkerKind.loot, at: at, reachM: kStillnessM),
        MapMarker(
          id: 'b',
          kind: MarkerKind.loot,
          at: GeoPoint(at.latitude + 3 / metresPerDegreeLat, at.longitude),
        ),
      ]);

      expect(clustered.single.reachM, kStillnessM);
      expect(clustered.single.count, 2);
    });
  });

  group('where a dot lands on screen', () {
    test('the middle is the player', () {
      expect(offsetOf(at, centre: at, zoom: 16), Offset.zero);
    });

    test('north is up and east is right', () {
      final metres = metresPerPixel(16, at.latitude);
      final north = GeoPoint(
        at.latitude + 50 * metres / metresPerDegreeLat,
        at.longitude,
      );
      final east = GeoPoint(
        at.latitude,
        at.longitude + 50 * metres / metresPerDegreeLon(at.latitude),
      );

      expect(offsetOf(north, centre: at, zoom: 16).dy, closeTo(-50, 0.5));
      expect(offsetOf(east, centre: at, zoom: 16).dx, closeTo(50, 0.5));
    });

    test('and it is the inverse of the tap maths', () {
      // A badge drawn a few pixels off the dot it counts is worse than none.
      final marker = MapMarker(
        id: 'a',
        kind: MarkerKind.dropped,
        at: GeoPoint(at.latitude + 0.0002, at.longitude + 0.0003),
      );

      final where = offsetOf(marker.at, centre: at, zoom: 16);
      final found = markerAtOffset([marker], where, centre: at, zoom: 16);

      expect(found?.id, 'a');
    });
  });

  group('the circle belongs to the place, not to the player (§10.2)', () {
    // ⚠️ It was one ring round the player for months, and the argument was
    // symmetry: being within twenty-five metres of a shop is the shop being
    // within twenty-five metres of you, so one ring said what sixty-five said
    // and cost a fraction — which mattered, because a ring per marker meant
    // sixty-five circles through the platform channel on every frame of a
    // pinch and the game stopped answering.
    //
    // That held exactly as long as every place had the same reach. §10.2 now
    // gives a bin thirty metres and a supermarket fifty, and a ring on the
    // player's feet cannot say which of the two it belongs to.
    MapMarker place(String id, double reach) =>
        MapMarker(id: id, kind: MarkerKind.loot, at: at, reachM: reach);

    test('nothing is drawn around the player any more', () {
      expect(reachRingsOf([place('p', kBuildingReachM)]), isEmpty);
    });

    test('every marker that can be reached carries its own circle', () {
      final zones = zonesOf([
        place('bin', kNearReachM),
        place('shop', kBuildingReachM),
      ]);

      expect(zones, hasLength(2));
      expect(
        zones.map((zone) => zone.radiusM),
        containsAll([kNearReachM, kBuildingReachM]),
      );
    });

    test('and it is drawn where the place is', () {
      final zones = zonesOf([place('shop', kBuildingReachM)]);

      expect(zones.single.at.latitude, at.latitude);
      expect(zones.single.at.longitude, at.longitude);
    });

    test('a marker with nothing to reach gets none', () {
      const enemy = MapMarker(id: 'e', kind: MarkerKind.enemy, at: at);

      expect(zonesOf([enemy]), isEmpty);
    });

    test('a bin is a tighter circle than a shop', () {
      // The whole reason there are two numbers: a building's door is not
      // where the map puts its dot, and a wheelie bin is reached by hand.
      expect(kNearReachM, lessThan(kBuildingReachM));
      expect(searchReachFor(PlaceSize.tiny), kNearReachM);
      expect(searchReachFor(PlaceSize.small), kNearReachM);
      expect(searchReachFor(PlaceSize.normal), kBuildingReachM);
    });
  });

  group('a sound spreading (§5.6.5)', () {
    final fired = DateTime.utc(2026, 8, 16, 12);
    final wave = NoiseWave(at: at, radiusM: 700, startedAt: fired);

    test('it starts at the shot and grows', () {
      expect(wave.progressAt(fired), 0);
      expect(
        wave.progressAt(fired.add(const Duration(milliseconds: 750))),
        closeTo(0.5, 0.01),
      );
    });

    test('and is over in about a second and a half', () {
      // §5.6.5's own figure. A ring that lingers is a ring that stops meaning
      // "just now".
      expect(
        wave.progressAt(fired.add(const Duration(milliseconds: 1499))),
        greaterThan(0.99),
      );
      expect(wave.progressAt(fired.add(NoiseWave.spread)), isNull);
    });

    test('a shot from a minute ago draws nothing', () {
      expect(wave.progressAt(fired.add(const Duration(minutes: 1))), isNull);
    });

    test('it carries the radius the noise actually reached', () {
      // Not the weapon's nominal figure: night, weather and built-up ground
      // have all had their say by the time it gets here (§5.6.1).
      expect(wave.radiusM, 700);
    });
  });
  group('a circle only when it is a question worth asking', () {
    // ⚠️ A ring per place is honest and, at any distance, a smear: fifteen
    // active boxes each with one turns a zoomed-out map into overlapping
    // bubbles that say nothing. The question a reach ring answers is "can I
    // open *this* one", and that is only ever asked about somewhere the
    // player is nearly at.
    test('the reach ring appears inside seventy-five metres', () {
      expect(kReachRingVisibleM, 75);
    });

    test('and an enemy shows its eyes twice as far out', () {
      // A warning rather than an invitation: how close can I get before it
      // notices is decided well before being on top of it.
      expect(kSightRingVisibleM, 150);
      expect(kSightRingVisibleM, greaterThan(kReachRingVisibleM));
    });

    test('an enemy circle is marked dangerous, a place is not', () {
      // ⚠️ They are the same shape and mean opposite things. A reach ring
      // says step inside and you may open this; an enemy's sight says step
      // inside and it can see you. One colour for both would read the second
      // as the first, which is the worst way to be wrong about a Walker.
      final zones = zonesOf([
        MapMarker(
          id: 'shop',
          kind: MarkerKind.loot,
          at: at,
          reachM: kBuildingReachM,
        ),
        MapMarker(id: 'walker', kind: MarkerKind.enemy, at: at, reachM: 80),
      ]);

      final place = zones.firstWhere((zone) => zone.radiusM == kBuildingReachM);
      final walker = zones.firstWhere((zone) => zone.radiusM == 80);

      expect(place.danger, isFalse);
      expect(walker.danger, isTrue);
    });

    test('and a marker with no ring draws none at all', () {
      // Which is how the distance gate is expressed: too far away is a
      // marker whose reach was never set.
      const far = MapMarker(id: 'shop', kind: MarkerKind.loot, at: at);

      expect(zonesOf(const [far]), isEmpty);
    });
  });
}
