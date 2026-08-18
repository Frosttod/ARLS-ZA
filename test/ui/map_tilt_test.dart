import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/map_markers.dart';
import 'package:test/test.dart';

/// RZUT POCHYLONEJ MAPY (§3.6).
///
/// MapLibre draws the tiles and Flutter draws everything else — every dot,
/// ring, cone and glyph. The two have to agree about where a street corner is
/// to within a pixel or so, or every marker sits off its own street. These
/// tests are about the pair of functions that make that promise, and mostly
/// about them being each other's inverse.
void main() {
  const centre = GeoPoint(52.4084, 16.9342);
  const zoom = 16.0;

  // A phone, upright. The camera distance is a multiple of this.
  const tilted = MapTilt(degrees: 45, viewportHeightPx: 800);

  GeoPoint at({double north = 0, double east = 0}) => GeoPoint(
    centre.latitude + north / metresPerDegreeLat,
    centre.longitude + east / metresPerDegreeLon(centre.latitude),
  );

  group('flat is exactly what it always was', () {
    test('the centre is the middle of the screen', () {
      expect(offsetOf(centre, centre: centre, zoom: zoom), Offset.zero);
      expect(
        offsetOf(centre, centre: centre, zoom: zoom, tilt: tilted),
        Offset.zero,
      );
    });

    test('a tilt of nought changes no pixel', () {
      // ⚠️ The regression that matters most. The flat formula is what every
      // marker has been drawn with since the map existed, and a tilt that is
      // switched off has to give back the same numbers to the pixel — or
      // turning the feature off would move the whole world slightly.
      const off = MapTilt(degrees: 0, viewportHeightPx: 800);

      for (final point in [
        at(north: 120),
        at(north: -300, east: 40),
        at(east: 250),
        at(north: 75, east: -90),
      ]) {
        final flat = offsetOf(point, centre: centre, zoom: zoom);
        final zero = offsetOf(point, centre: centre, zoom: zoom, tilt: off);

        expect((zero.dx - flat.dx).abs(), lessThan(0.001));
        expect((zero.dy - flat.dy).abs(), lessThan(0.001));
      }
    });
  });

  group('what a tilt does to the picture', () {
    test('north is squashed towards the middle', () {
      // The whole point of leaning back: the ground ahead is compressed, so
      // more of the street the player is walking into fits on the screen.
      final flat = offsetOf(at(north: 200), centre: centre, zoom: zoom);
      final lean = offsetOf(
        at(north: 200),
        centre: centre,
        zoom: zoom,
        tilt: tilted,
      );

      expect(lean.dy, greaterThan(flat.dy), reason: 'nearer the middle');
      expect(lean.dy, lessThan(0), reason: 'still above the centre');
    });

    test(
      'and what is behind the player is squashed less than what is ahead',
      () {
        // ⚠️ Both halves are squashed — cos 45° takes a third off everything —
        // and the first version of this test expected the near half to stretch.
        // It does not: perspective only makes it shrink *less*. That difference
        // is the whole of the effect, so it is the thing worth asserting.
        double squash(double north) {
          final flat = offsetOf(
            at(north: north),
            centre: centre,
            zoom: zoom,
          );
          final lean = offsetOf(
            at(north: north),
            centre: centre,
            zoom: zoom,
            tilt: tilted,
          );
          return lean.dy.abs() / flat.dy.abs();
        }

        final ahead = squash(200);
        final behind = squash(-200);

        expect(behind, greaterThan(ahead), reason: 'the near half keeps more');
        expect(ahead, lessThan(1), reason: 'and the far half keeps less');
        expect(behind, lessThan(1), reason: 'but nothing grows at 45°');
      },
    );

    test('east and west stay symmetrical', () {
      final left = offsetOf(
        at(east: -150),
        centre: centre,
        zoom: zoom,
        tilt: tilted,
      );
      final right = offsetOf(
        at(east: 150),
        centre: centre,
        zoom: zoom,
        tilt: tilted,
      );

      expect(left.dx, closeTo(-right.dx, 0.001));
      expect(left.dy, closeTo(right.dy, 0.001));
    });

    test('something far enough behind the camera is not drawn on screen', () {
      // Past the horizon there is no ground under the pixel. Folding it back
      // into view would put a Walker on the wrong side of the player.
      final behind = offsetOf(
        at(north: -100000),
        centre: centre,
        zoom: zoom,
        tilt: tilted,
      );

      expect(behind.dy.abs(), greaterThan(10000));
    });
  });

  group('a tap lands where the dot was drawn', () {
    List<MapMarker> markerAt(GeoPoint where) => [
      MapMarker(id: 'x', kind: MarkerKind.loot, at: where),
    ];

    test('through the middle, near and far, tilted', () {
      for (final point in [
        at(north: 250),
        at(north: 90, east: 60),
        at(east: -120),
        at(north: -180, east: 30),
      ]) {
        final drawn = offsetOf(point, centre: centre, zoom: zoom, tilt: tilted);

        final found = markerAtOffset(
          markerAt(point),
          drawn,
          centre: centre,
          zoom: zoom,
          tilt: tilted,
        );

        expect(
          found?.id,
          'x',
          reason: 'drawn at $drawn but not found by tapping there',
        );
      }
    });

    test('and a finger the width of a finger away still finds it', () {
      final point = at(north: 200, east: 40);
      final drawn = offsetOf(point, centre: centre, zoom: zoom, tilt: tilted);

      expect(
        markerAtOffset(
          markerAt(point),
          drawn + const Offset(10, 10),
          centre: centre,
          zoom: zoom,
          tilt: tilted,
        )?.id,
        'x',
      );
    });

    test('but the far half of the map is not one giant button', () {
      // ⚠️ The slop is grown by the same foreshortening that shrank the point,
      // which is what makes the far half tappable at all. Grown too far and
      // every tap up there hits the same marker; this is the guard on it.
      final point = at(north: 250);
      final drawn = offsetOf(point, centre: centre, zoom: zoom, tilt: tilted);

      expect(
        markerAtOffset(
          markerAt(point),
          drawn + const Offset(200, 0),
          centre: centre,
          zoom: zoom,
          tilt: tilted,
        ),
        isNull,
      );
    });
  });

  group('the camera distance is MapLibre\'s own', () {
    test('one and a half screens, from the default field of view', () {
      // 0.5 / tan(fov / 2) × height, with fov = 0.6435 rad. Written as the
      // division rather than as 1.5 so it stays true if the fov changes.
      const tilt = MapTilt(degrees: 45, viewportHeightPx: 1000);

      expect(tilt.cameraDistancePx, closeTo(1500, 1));
      expect(0.5 / math.tan(kMapFovRad / 2), closeTo(1.5, 0.001));
    });

    test('a viewport of nothing is treated as flat', () {
      const nothing = MapTilt(degrees: 45, viewportHeightPx: 0);

      expect(nothing.isFlat, isTrue);
      expect(
        offsetOf(at(north: 200), centre: centre, zoom: zoom, tilt: nothing),
        offsetOf(at(north: 200), centre: centre, zoom: zoom),
      );
    });
  });
}
