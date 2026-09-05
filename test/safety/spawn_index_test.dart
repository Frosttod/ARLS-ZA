import 'dart:math';

import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
import 'package:test/test.dart';

/// §3.5, and the reason the fast version is allowed to exist.
///
/// [SpawnFilter] was a loop over every feature and every vertex — the right
/// answer written the obvious way, and a hang once §6.5 started asking it sixty
/// times per empty hotspot slot on a real city. It is indexed now, and this
/// checks the index against the loop it replaced on random cities.
///
/// ⚠️ **This decides where the game sends a person.** An index that is faster
/// and quietly disagrees is worse than the slow one it replaced, so the
/// comparison is the test rather than a benchmark.
void main() {
  const centre = GeoPoint(52.4064, 16.9252);

  /// What the filter did before it was indexed.
  Exclusion? brute(List<MapFeature> features, GeoPoint point) {
    Exclusion? worst;
    for (final feature in features) {
      final rule = exclusionFor(feature.tags);
      if (rule == null) continue;

      final distance = feature.distanceFrom(point);
      final excluded = rule.bufferM > 0
          ? distance <= rule.bufferM
          : distance <= (feature.shape == FeatureShape.area ? 0 : 1);
      if (!excluded) continue;

      if (worst == null || distance < worst.distanceM) {
        worst = Exclusion(
          kind: rule.kind,
          distanceM: distance,
          tags: feature.tags,
        );
      }
    }
    return worst;
  }

  List<MapFeature> city(Random random, int count) => [
    for (var i = 0; i < count; i++)
      () {
        final shape = [
          FeatureShape.line,
          FeatureShape.area,
          FeatureShape.point,
        ][random.nextInt(3)];

        var at = centre.offsetBy(
          metres: random.nextDouble() * 1500,
          bearingDeg: random.nextDouble() * 360,
        );
        final geometry = <GeoPoint>[at];
        final vertices = shape == FeatureShape.point
            ? 0
            : 2 + random.nextInt(8);
        for (var v = 0; v < vertices; v++) {
          at = at.offsetBy(
            // Both kinds on purpose: streets drawn every few metres, and the
            // sprawling polygons — water, residential landuse — whose vertices
            // are half a kilometre apart.
            metres: 20 + random.nextDouble() * 900,
            bearingDeg: random.nextDouble() * 360,
          );
          geometry.add(at);
        }

        return MapFeature(
          shape: shape,
          geometry: geometry,
          tags: [
            const {'highway': 'primary'},
            const {'railway': 'rail'},
            const {'natural': 'water'},
            const {'landuse': 'residential'},
            // Something with no rule at all, because most of a city has none.
            const {'shop': 'bakery'},
          ][random.nextInt(5)],
        );
      }(),
  ];

  test('the index refuses exactly what the loop refused', () {
    final random = Random(11);
    var checked = 0;
    var refused = 0;

    for (var round = 0; round < 12; round++) {
      final features = city(random, 120);
      final filter = SpawnFilter(features);

      for (var probe = 0; probe < 300; probe++) {
        final point = centre.offsetBy(
          metres: random.nextDouble() * 1600,
          bearingDeg: random.nextDouble() * 360,
        );

        final fast = filter.refuse(point);
        final slow = brute(features, point);
        checked++;
        if (slow != null) refused++;

        expect(
          fast == null,
          slow == null,
          reason: 'refusal disagreed at $point',
        );

        // ⚠️ The distance, not the kind. Two features can refuse the same
        // point at the same distance — a railway crossing a residential
        // polygon refuses at nought metres twice — and which of them gets
        // named is a tie the loop broke by list order and the index breaks by
        // cell order. Both answers are true, and nothing downstream reads the
        // kind for anything but the developer overlay.
        expect(
          fast?.distanceM,
          slow?.distanceM,
          reason: 'distance disagreed at $point',
        );
      }
    }

    expect(
      refused,
      greaterThan(200),
      reason: 'a run where nothing was refused would prove nothing',
    );
    expect(checked, 3600);
  });

  test('a point in the middle of a lake is still in the lake', () {
    // ⚠️ The bug the comparison above actually caught. Indexing a polygon by
    // its outline leaves its middle in no cell at all, so the fast answer for
    // somewhere deep inside a reservoir was "go ahead".
    final lake = MapFeature(
      shape: FeatureShape.area,
      geometry: [
        centre.offsetBy(metres: 600, bearingDeg: 0),
        centre.offsetBy(metres: 600, bearingDeg: 90),
        centre.offsetBy(metres: 600, bearingDeg: 180),
        centre.offsetBy(metres: 600, bearingDeg: 270),
      ],
      tags: const {'natural': 'water'},
    );

    expect(SpawnFilter([lake]).refuse(centre)?.kind, ExclusionKind.water);
  });

  test('and a road drawn with two far-apart points still has a middle', () {
    // The same hole, in a line: a motorway sampled every kilometre has
    // vertices in two cells and passes through fifteen.
    final motorway = MapFeature(
      shape: FeatureShape.line,
      geometry: [
        centre.offsetBy(metres: 1000, bearingDeg: 270),
        centre.offsetBy(metres: 1000, bearingDeg: 90),
      ],
      tags: const {'highway': 'motorway'},
    );

    expect(SpawnFilter([motorway]).refuse(centre)?.kind, ExclusionKind.road);
  });
}
