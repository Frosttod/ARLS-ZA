import 'package:arls_za/loot/procedural_points.dart';
import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
import 'package:test/test.dart';

/// §10.1. Without this layer the game only works in large cities: measured over
/// the same twelve kilometres, central Poznań carries 74 455 places and rural
/// Wielkopolska carries 263. What is tested here is that the invented places
/// are somewhere a person can stand, land on ground that suits them, and do not
/// move between sessions.
void main() {
  const centre = GeoPoint(52.15, 17.35);

  /// A road running east from a point [northM] north of the centre.
  MapFeature roadEast({double northM = 0, double lengthM = 3000}) {
    final lat = centre.latitude + northM / metresPerDegreeLat;
    return MapFeature(
      tags: const {'highway': 'minor'},
      shape: FeatureShape.line,
      geometry: [
        GeoPoint(lat, centre.longitude),
        GeoPoint(
          lat,
          centre.longitude + lengthM / metresPerDegreeLon(lat),
        ),
      ],
    );
  }

  /// A square of ground [sizeM] across, centred on the road it will contain.
  GeneratedArea areaAround(
    String selector, {
    double northM = 0,
    double sizeM = 400,
  }) {
    final lat = centre.latitude + northM / metresPerDegreeLat;
    final dLat = sizeM / 2 / metresPerDegreeLat;
    final dLon = sizeM / 2 / metresPerDegreeLon(lat);

    return GeneratedArea(
      selector: selector,
      ring: [
        GeoPoint(lat - dLat, centre.longitude - dLon),
        GeoPoint(lat - dLat, centre.longitude + dLon),
        GeoPoint(lat + dLat, centre.longitude + dLon),
        GeoPoint(lat + dLat, centre.longitude - dLon),
      ],
    );
  }

  List<dynamic> generate({
    int wanted = 12,
    int seed = 7,
    List<MapFeature>? roads,
    List<GeneratedArea> areas = const [],
    double radiusM = 3000,
  }) => generateProceduralPoints(
    centre: centre,
    radiusM: radiusM,
    wanted: wanted,
    seed: seed,
    roads: roads ?? [roadEast()],
    areas: areas,
  );

  group('what gets invented', () {
    test('nothing at all when the map has no roads either', () {
      // The last layer of §10.1 still needs something to hang off. A village
      // with no mapped roads is not a case worth inventing a village for.
      expect(generate(roads: const []), isEmpty);
    });

    test('nothing when the map is not thin — wanted is the shortfall', () {
      expect(generate(wanted: 0), isEmpty);
    });

    test('as many as asked for, and no more', () {
      // §10.1: twelve minus the density. Producing more would make a village
      // richer than a town.
      expect(generate(wanted: 5), hasLength(5));
    });

    test('spread along the road rather than bunched at its start', () {
      final points = generate(wanted: 4).cast<dynamic>();
      final distances =
          points
              .map((p) => (p.position as GeoPoint).distanceTo(centre))
              .toList()
            ..sort();

      expect(distances.last - distances.first, greaterThan(500));
    });
  });

  group('where they land', () {
    test('beside the road, never on it (§3.5)', () {
      // A generated point is still a place the game asks a person to walk to.
      final road = roadEast();
      final points = generate(roads: [road], wanted: 6);

      for (final point in points) {
        final distance = distanceToPolyline(
          point.position as GeoPoint,
          road.geometry,
        );
        expect(distance, greaterThan(15), reason: '§3.5 keeps 15 m from a road');
        expect(distance, lessThan(30), reason: 'still beside it, not adrift');
      }
    });

    test('a point in residential land is a house, and one outside is not', () {
      // The road runs three kilometres; the village is two across. Points
      // beyond it are roadside, which is the whole point of having both.
      final points = generate(
        roads: [roadEast()],
        areas: [areaAround('landuse.class=residential', sizeM: 2000)],
        wanted: 12,
      );

      final kinds = {for (final p in points) p.selectors.first as String};

      expect(kinds, contains('generated.house'));
      expect(kinds, contains(kRoadsideSelector));
    });

    test('a point in farmland is a barn', () {
      final points = generate(
        areas: [areaAround('landcover.class=farmland', sizeM: 2000)],
        wanted: 3,
      );

      expect(points.first.selectors.first, 'generated.barn');
    });

    test('a point in woodland is a hunting stand', () {
      final points = generate(
        areas: [areaAround('landcover.class=wood', sizeM: 2000)],
        wanted: 3,
      );

      expect(points.first.selectors.first, 'generated.hunting_stand');
    });

    test('a point on nothing in particular is roadside', () {
      expect(generate(wanted: 1).first.selectors.first, kRoadsideSelector);
    });

    test('nothing lands outside the radius it was asked for', () {
      final points = generate(radiusM: 800, wanted: 12);

      for (final point in points) {
        expect((point.position as GeoPoint).distanceTo(centre), lessThan(800));
      }
    });
  });

  group('a village that stays put', () {
    test('the same seed and map give the same places', () {
      // Otherwise the village rearranges itself every time the app opens, and
      // a player who walked to a barn yesterday finds a field.
      List<String> run() => generate(wanted: 8)
          .map((p) => (p.id as String))
          .toList();

      expect(run(), run());
    });

    test('a different seed gives a different village', () {
      final first = generate(seed: 1, wanted: 8).map((p) => p.id).toList();
      final second = generate(seed: 99, wanted: 8).map((p) => p.id).toList();

      expect(first, isNot(second));
    });

    test('the order roads arrive in does not change the answer', () {
      // Tiles decode in whatever order they decode. Two devices reading the
      // same map must invent the same village.
      final roads = [roadEast(northM: 300), roadEast(), roadEast(northM: -300)];

      final forwards = generate(roads: roads, wanted: 6).map((p) => p.id);
      final backwards = generate(
        roads: roads.reversed.toList(),
        wanted: 6,
      ).map((p) => p.id);

      expect(forwards, backwards);
    });
  });
}
