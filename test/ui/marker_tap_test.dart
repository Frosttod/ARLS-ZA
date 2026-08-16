import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:flutter_test/flutter_test.dart';

/// DOTKNIĘCIE ZNACZNIKA (§3.6).
///
/// The markers are circles the platform view draws, and the gesture arena is
/// won by our own detector, so which one a finger landed on is arithmetic we
/// do ourselves. It is the same arithmetic that once went wrong on the zoom:
/// MapLibre's zoom is defined against logical pixels, and treating them as
/// device pixels made a kilometre into three hundred metres.
void main() {
  const centre = GeoPoint(52.4084, 16.9342);

  MapMarker markerAt(String id, {double north = 0, double east = 0}) =>
      MapMarker(
        id: id,
        kind: MarkerKind.loot,
        at: GeoPoint(
          centre.latitude + north / metresPerDegreeLat,
          centre.longitude + east / metresPerDegreeLon(centre.latitude),
        ),
      );

  test('a tap on the middle finds what the player is standing on', () {
    final found = markerAtOffset(
      [markerAt('here')],
      Offset.zero,
      centre: centre,
      zoom: 16,
    );

    expect(found?.id, 'here');
  });

  test('a tap on empty street finds nothing', () {
    final found = markerAtOffset(
      [markerAt('far', north: 800)],
      Offset.zero,
      centre: centre,
      zoom: 16,
    );

    expect(found, isNull);
  });

  test('screen y grows downwards and latitude grows up', () {
    // The sign that is wrong half the time, and wrong silently: a tap above
    // the player would select the marker below them.
    final metres = metresPerPixel(16, centre.latitude);
    final found = markerAtOffset(
      [markerAt('north', north: 60 * metres), markerAt('south', north: -60 * metres)],
      Offset(0, -60),
      centre: centre,
      zoom: 16,
    );

    expect(found?.id, 'north');
  });

  test('east is to the right', () {
    final metres = metresPerPixel(16, centre.latitude);
    final found = markerAtOffset(
      [markerAt('east', east: 60 * metres), markerAt('west', east: -60 * metres)],
      Offset(60, 0),
      centre: centre,
      zoom: 16,
    );

    expect(found?.id, 'east');
  });

  test('the nearest of two on one corner wins', () {
    final metres = metresPerPixel(16, centre.latitude);
    final found = markerAtOffset(
      [markerAt('further', north: 18 * metres), markerAt('closer', north: 4 * metres)],
      const Offset(0, -6),
      centre: centre,
      zoom: 16,
    );

    expect(found?.id, 'closer');
  });

  test('a finger is wider than a pixel', () {
    // 20 logical pixels off the middle of the dot still means that dot.
    final metres = metresPerPixel(16, centre.latitude);
    final found = markerAtOffset(
      [markerAt('near', north: 20 * metres)],
      Offset.zero,
      centre: centre,
      zoom: 16,
    );

    expect(found?.id, 'near');
  });

  test('zooming out makes a pixel cover more ground', () {
    // The same tap reaches further at a wider zoom, which is what makes a
    // marker tappable when the whole district is on screen.
    expect(
      metresPerPixel(13, centre.latitude),
      closeTo(metresPerPixel(16, centre.latitude) * 8, 0.001),
    );
  });

  test('and a marker that fits the slop at 12 does not at 18', () {
    // ⚠️ The zoom numbers moved by one when the tile convention was corrected:
    // MapLibre serves 512-pixel tiles, so its zoom z is the ground of a
    // 256-tile z+1. Everything measured in pixels shifted with it.
    final markers = [markerAt('block', north: 300)];

    expect(
      markerAtOffset(markers, Offset.zero, centre: centre, zoom: 12)?.id,
      'block',
    );
    expect(
      markerAtOffset(markers, Offset.zero, centre: centre, zoom: 18),
      isNull,
    );
  });
}
