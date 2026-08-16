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

    expect(pixels, closeTo(kSearchReachM / metresPerPixel(17, at.latitude), 0.001));
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

    expect(place.copyWith(at: const GeoPoint(52.5, 16.9)).reachM, kSearchReachM);
  });
}
