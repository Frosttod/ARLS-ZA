import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/safety/spawn_exclusion.dart';
import 'package:test/test.dart';

/// §3.5, the one section marked mandatory. Its failures hurt people rather than
/// the simulation: a loot marker on a dual carriageway, on a railway, in a
/// river or in a hospital car park is an injury, a trespass or a distressed
/// stranger.
void main() {
  /// A point [metres] north of [from].
  GeoPoint north(GeoPoint from, double metres) =>
      GeoPoint(from.latitude + metres / metresPerDegreeLat, from.longitude);

  const origin = GeoPoint(52.2297, 21.0122);

  MapFeature line(Map<String, String> tags, List<GeoPoint> points) =>
      MapFeature(tags: tags, geometry: points, shape: FeatureShape.line);

  MapFeature area(Map<String, String> tags, List<GeoPoint> ring) =>
      MapFeature(tags: tags, geometry: ring, shape: FeatureShape.area);

  /// A square [halfSideM] metres to a side, centred on [centre].
  List<GeoPoint> square(GeoPoint centre, double halfSideM) {
    final dLat = halfSideM / metresPerDegreeLat;
    final dLon = halfSideM / metresPerDegreeLon(centre.latitude);
    return [
      GeoPoint(centre.latitude - dLat, centre.longitude - dLon),
      GeoPoint(centre.latitude - dLat, centre.longitude + dLon),
      GeoPoint(centre.latitude + dLat, centre.longitude + dLon),
      GeoPoint(centre.latitude + dLat, centre.longitude - dLon),
    ];
  }

  group('which tags exclude', () {
    test('§3.5 names four road classes, and their slip roads follow', () {
      for (final value in ['motorway', 'trunk', 'primary', 'secondary']) {
        expect(exclusionFor({'highway': value})?.kind, ExclusionKind.road);
        expect(
          exclusionFor({'highway': '${value}_link'})?.kind,
          ExclusionKind.road,
          reason: 'a slip road carries the same traffic as what it joins',
        );
      }
    });

    test('ordinary streets are where the game happens', () {
      // Residential and service streets are not excluded: exclude those and
      // there is no game in a city at all.
      expect(exclusionFor({'highway': 'residential'}), isNull);
      expect(exclusionFor({'highway': 'footway'}), isNull);
      expect(exclusionFor({'highway': 'living_street'}), isNull);
    });

    test('a live railway is excluded and a dismantled one is not', () {
      expect(exclusionFor({'railway': 'rail'})?.kind, ExclusionKind.railway);
      expect(exclusionFor({'railway': 'tram'})?.kind, ExclusionKind.railway);
      expect(
        exclusionFor({'railway': 'abandoned'}),
        isNull,
        reason: 'a dismantled embankment is a walk in the woods',
      );
    });

    test('the buffers are the ones §3.5 states', () {
      expect(exclusionFor({'highway': 'primary'})!.bufferM, 15);
      expect(exclusionFor({'railway': 'rail'})!.bufferM, 30);
    });

    test('water in all the forms OSM writes it', () {
      expect(exclusionFor({'natural': 'water'})?.kind, ExclusionKind.water);
      expect(exclusionFor({'waterway': 'river'})?.kind, ExclusionKind.water);
      expect(exclusionFor({'landuse': 'reservoir'})?.kind, ExclusionKind.water);
    });

    test('the sensitive places §3.5 lists', () {
      const sensitive = [
        {'amenity': 'hospital'},
        {'amenity': 'school'},
        {'amenity': 'kindergarten'},
        {'amenity': 'place_of_worship'},
        {'amenity': 'police'},
        {'landuse': 'cemetery'},
        {'landuse': 'military'},
        {'military': 'barracks'},
      ];

      for (final tags in sensitive) {
        expect(
          exclusionFor(tags)?.kind,
          ExclusionKind.sensitive,
          reason: '$tags',
        );
      }
    });

    test('private land is trespass, and named as such', () {
      expect(exclusionFor({'access': 'private'})?.kind, ExclusionKind.private);
      expect(
        exclusionFor({'landuse': 'residential'})?.kind,
        ExclusionKind.private,
      );
    });

    test('a private railway is still a railway', () {
      // Tag order matters where they overlap, and the wider buffer has to win.
      final rule = exclusionFor({'railway': 'rail', 'access': 'private'});

      expect(rule?.kind, ExclusionKind.railway);
      expect(rule?.bufferM, 30);
    });

    test('a park is not excluded — the game needs somewhere to be', () {
      expect(exclusionFor({'leisure': 'park'}), isNull);
      expect(exclusionFor({'landuse': 'grass'}), isNull);
    });
  });

  group('distance from a road (15 m, §3.5)', () {
    final road = line(
      {'highway': 'primary'},
      [const GeoPoint(52.2297, 21.0), const GeoPoint(52.2297, 21.03)],
    );
    final filter = SpawnFilter([road]);

    test('the carriageway itself is refused', () {
      expect(filter.allows(const GeoPoint(52.2297, 21.0122)), isFalse);
    });

    test('the verge is refused', () {
      expect(
        filter.allows(north(const GeoPoint(52.2297, 21.0122), 10)),
        isFalse,
        reason: 'ten metres from a trunk road is the hard shoulder',
      );
    });

    test('past the buffer is allowed', () {
      expect(
        filter.allows(north(const GeoPoint(52.2297, 21.0122), 20)),
        isTrue,
      );
    });

    test('the refusal says which rule refused it', () {
      final refusal = filter.refuse(
        north(const GeoPoint(52.2297, 21.0122), 10),
      );

      expect(refusal!.kind, ExclusionKind.road);
      expect(refusal.tags['highway'], 'primary');
      expect(
        refusal.distanceM,
        closeTo(10, 1),
        reason: '"excluded" without "by what" is not diagnosable',
      );
    });
  });

  group('distance from a railway (30 m, §3.5)', () {
    final rails = line(
      {'railway': 'rail'},
      [const GeoPoint(52.2297, 21.0), const GeoPoint(52.2297, 21.03)],
    );
    final filter = SpawnFilter([rails]);

    test('twenty metres away is still refused', () {
      expect(
        filter.allows(north(const GeoPoint(52.2297, 21.0122), 20)),
        isFalse,
        reason:
            'the widest buffer in §3.5, and the one worth being generous '
            'about',
      );
    });

    test('forty metres away is allowed', () {
      expect(
        filter.allows(north(const GeoPoint(52.2297, 21.0122), 40)),
        isTrue,
      );
    });
  });

  group('areas', () {
    test('inside a hospital is refused, outside the fence is not', () {
      final hospital = area({'amenity': 'hospital'}, square(origin, 100));
      final filter = SpawnFilter([hospital]);

      expect(filter.allows(origin), isFalse);
      expect(
        filter.allows(north(origin, 150)),
        isTrue,
        reason: 'the pavement outside a hospital is a public street',
      );
    });

    test('inside a lake is refused', () {
      final lake = area({'natural': 'water'}, square(origin, 200));

      expect(SpawnFilter([lake]).allows(origin), isFalse);
    });

    test('somebody\'s garden is refused', () {
      final plot = area({'landuse': 'residential'}, square(origin, 30));

      expect(SpawnFilter([plot]).allows(origin), isFalse);
    });

    test('a ring that does not repeat its first vertex still closes', () {
      // OSM writes both forms. A ring left open would leave one side of every
      // hospital unguarded.
      final ring = square(origin, 100);
      final open = area({'amenity': 'school'}, ring);
      final closed = area({'amenity': 'school'}, [...ring, ring.first]);

      expect(SpawnFilter([open]).allows(origin), isFalse);
      expect(SpawnFilter([closed]).allows(origin), isFalse);
    });
  });

  test('the nearest offender is the one reported', () {
    final filter = SpawnFilter([
      line(
        {'railway': 'rail'},
        [
          north(origin, 25),
          GeoPoint(origin.latitude + 25 / metresPerDegreeLat, 21.03),
        ],
      ),
      line(
        {'highway': 'primary'},
        [
          north(origin, 5),
          GeoPoint(origin.latitude + 5 / metresPerDegreeLat, 21.03),
        ],
      ),
    ]);

    expect(
      filter.refuse(origin)!.kind,
      ExclusionKind.road,
      reason: 'name the thing the player can actually see',
    );
  });

  test('open ground with nothing near it is allowed', () {
    final filter = SpawnFilter([
      area({'leisure': 'park'}, square(origin, 300)),
      line(
        {'highway': 'residential'},
        [
          north(origin, 5),
          GeoPoint(origin.latitude + 5 / metresPerDegreeLat, 21.03),
        ],
      ),
    ]);

    expect(filter.allows(origin), isTrue);
  });
}
