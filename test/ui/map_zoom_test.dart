import 'dart:math' as math;

import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/ui/maplibre_surface.dart';
import 'package:flutter_test/flutter_test.dart';

/// §3.6: the widest view is a kilometre across, because the character knows
/// their street and the next junction and does not have a satellite.
///
/// The limit is written as a distance rather than a zoom number, and a distance
/// only survives the trip to MapLibre if the width it is computed against is in
/// the units MapLibre lays out in.
void main() {
  /// How many metres actually fit across a screen this wide at the widest zoom
  /// the game allows. The inverse of `zoomForWidth`.
  double metresAcrossAt(double logicalWidth, {double latitude = 52.4}) {
    final zoom = widestGameZoom(logicalWidth: logicalWidth, latitude: latitude);
    final metresPerPixel =
        156543.03392 *
        math.cos(latitude * math.pi / 180).abs() /
        math.pow(2, zoom);

    return metresPerPixel * logicalWidth;
  }

  test('a kilometre across really is a kilometre (§3.6)', () {
    // The regression this exists for: the width was multiplied by the device
    // pixel ratio, which is not the unit a zoom level is defined in. On a phone
    // at three times density the widest view was 330 m, and pulling back
    // further simply stopped there.
    for (final width in const [320.0, 393.0, 411.0, 800.0]) {
      expect(
        metresAcrossAt(width),
        closeTo(1000, 1),
        reason: '${width.round()} logical px wide',
      );
    }
  });

  test('the limit is the same distance on every screen', () {
    // Which is why it is computed. A fixed zoom number would show a small phone
    // half of what a tablet shows.
    final small = widestGameZoom(logicalWidth: 320, latitude: 52.4);
    final large = widestGameZoom(logicalWidth: 640, latitude: 52.4);

    expect(large - small, closeTo(1, 0.001));
    expect(metresAcrossAt(320), closeTo(metresAcrossAt(640), 1));
  });

  test('and the same distance at both ends of the country', () {
    expect(
      metresAcrossAt(393, latitude: 54.4),
      closeTo(metresAcrossAt(393, latitude: 49.3), 1),
    );
  });

  test('the widest view is still further out than the closest', () {
    expect(
      widestGameZoom(logicalWidth: 393, latitude: 52.4),
      lessThan(kClosestZoom),
    );
  });

  test('zoomForWidth is unit-agnostic, so the caller owns the mistake', () {
    // It cannot catch being fed physical pixels — it just answers a different
    // question, one zoom level per doubling.
    final logical = zoomForWidth(
      metresAcross: 1000,
      pixelWidth: 393,
      latitude: 52.4,
    );
    final physical = zoomForWidth(
      metresAcross: 1000,
      pixelWidth: 393 * 3,
      latitude: 52.4,
    );

    expect(physical - logical, closeTo(math.log(3) / math.ln2, 0.001));
  });
}
