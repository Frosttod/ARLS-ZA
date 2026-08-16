import 'dart:io';

import 'package:arls_za/map/geometry.dart';
import 'package:arls_za/map/region_pack.dart';
import 'package:test/test.dart';

/// The bundled catalogue is data the game cannot run without (§3.1). A typo in
/// it is a region nobody can download, which is not the sort of thing a code
/// review catches.
void main() {
  late RegionCatalogue catalogue;

  setUpAll(() {
    catalogue = RegionCatalogue.parse(
      File('assets/regions.json').readAsStringSync(),
    );
  });

  group('the bundled catalogue', () {
    test('lists all sixteen voivodeships, and may list cities too', () {
      const voivodeships = {
        'dolnoslaskie',
        'kujawsko-pomorskie',
        'lubelskie',
        'lubuskie',
        'lodzkie',
        'malopolskie',
        'mazowieckie',
        'opolskie',
        'podkarpackie',
        'podlaskie',
        'pomorskie',
        'slaskie',
        'swietokrzyskie',
        'warminsko-mazurskie',
        'wielkopolskie',
        'zachodniopomorskie',
      };
      final ids = catalogue.packs.map((pack) => pack.id).toList();

      expect(ids.toSet(), containsAll(voivodeships));
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'ids are file names — a collision overwrites a pack',
      );
    });

    test('a streamable pack names a host that is not GitHub Releases', () {
      // Measured: a release asset answers a range request with 302 and zero
      // bytes unless the client follows redirects, which MapLibre does not do
      // per tile. Anything offered for streaming has to be somewhere else.
      for (final pack in catalogue.packs.where((p) => p.streamable)) {
        expect(pack.url, isNot(contains('releases/download')), reason: pack.id);
      }
    });

    test('every pack has a plausible size and a well-formed extent', () {
      for (final pack in catalogue.packs) {
        // §3.1 guessed 50–200 MB per region and was wrong by a factor of
        // four: a bounding box around a voivodeship pulls in whatever dense
        // neighbour it clips, and Mazowieckie comes out at 748 MB. The bound
        // here is a sanity check against a truncated or empty file, not a
        // design target — the design target moved.
        expect(
          pack.bytes,
          inInclusiveRange(5 * 1024 * 1024, 1024 * 1024 * 1024),
          reason: pack.id,
        );
        expect(
          pack.bounds.north,
          greaterThan(pack.bounds.south),
          reason: pack.id,
        );
        expect(
          pack.bounds.east,
          greaterThan(pack.bounds.west),
          reason: pack.id,
        );
      }
    });

    test('every extent falls inside Poland', () {
      for (final pack in catalogue.packs) {
        expect(pack.bounds.south, greaterThan(48.9), reason: pack.id);
        expect(pack.bounds.north, lessThan(55.0), reason: pack.id);
        expect(pack.bounds.west, greaterThan(14.0), reason: pack.id);
        expect(pack.bounds.east, lessThan(24.2), reason: pack.id);
      }
    });

    test('the base url is resolved into every pack (§16.6)', () {
      // The catalogue keeps the host in one place; everything downstream — the
      // downloader, and the streamed map source — needs a usable address and
      // has no business knowing a base existed.
      for (final pack in catalogue.packs) {
        expect(pack.url, startsWith('https://'), reason: pack.id);
        expect(pack.url, endsWith('${pack.id}.pmtiles'), reason: pack.id);
      }
    });

    test('an absolute url in a region overrides the base', () {
      final catalogue = RegionCatalogue.parse('''
{
  "baseUrl": "https://example.invalid/maps/",
  "regions": [
    {
      "id": "elsewhere",
      "name": "Elsewhere",
      "bounds": [15.0, 51.0, 16.0, 52.0],
      "bytes": 52428800,
      "sha256": "abc",
      "url": "https://other.invalid/elsewhere.pmtiles"
    }
  ]
}
''');

      expect(
        catalogue.packs.single.url,
        'https://other.invalid/elsewhere.pmtiles',
      );
    });

    test('the id is the file name, so a pack is findable without it', () {
      for (final pack in catalogue.packs) {
        expect(pack.fileName, '${pack.id}.pmtiles');
      }
    });
  });

  group('finding a region from a position', () {
    test('Warsaw lands in Mazowieckie', () {
      expect(catalogue.forPosition(52.2297, 21.0122)?.id, 'mazowieckie');
    });

    test('Kraków lands in Małopolskie', () {
      expect(catalogue.forPosition(50.0647, 19.9450)?.id, 'malopolskie');
    });

    test('a position outside Poland matches nothing', () {
      // Berlin. The picker then asks rather than guessing.
      expect(catalogue.forPosition(52.52, 13.405), isNull);
    });
  });

  group('how far out a player may zoom (§3.6)', () {
    test('a kilometre across a phone lands near street level', () {
      // The number that matters is the distance, not the zoom: a survivor with
      // a phone knows their street and the next junction, not the district.
      final zoom = zoomForWidth(
        metresAcross: 1000,
        pixelWidth: 1080,
        latitude: 52.4,
      );

      // ⚠️ One level lower than the 256-pixel-tile figure. MapLibre serves
      // 512s, so its zoom z covers the ground of a 256-tile z+1 — the error
      // that put marker counts at twice their proper distance from the player.
      expect(zoom, closeTo(15.7, 0.3));
    });

    test('a wider screen shows the same distance at a closer zoom', () {
      // Which is exactly why this is computed rather than written down: the
      // same zoom number is a different distance on a different phone.
      final narrow = zoomForWidth(
        metresAcross: 1000,
        pixelWidth: 720,
        latitude: 52.4,
      );
      final wide = zoomForWidth(
        metresAcross: 1000,
        pixelWidth: 1440,
        latitude: 52.4,
      );

      expect(wide, greaterThan(narrow));
      expect(
        wide - narrow,
        closeTo(1, 0.01),
        reason:
            'twice the width is one '
            'zoom level',
      );
    });

    test('the far north needs a wider zoom for the same metres', () {
      // Web mercator stretches towards the poles, so a tile covers less ground
      // in Gdańsk than in Zakopane and the same kilometre needs pulling back.
      final gdansk = zoomForWidth(
        metresAcross: 1000,
        pixelWidth: 1080,
        latitude: 54.4,
      );
      final zakopane = zoomForWidth(
        metresAcross: 1000,
        pixelWidth: 1080,
        latitude: 49.3,
      );

      expect(gdansk, lessThan(zakopane));
    });
  });

  group('bounds', () {
    const warsawArea = GeoBounds(
      south: 52.0,
      west: 20.8,
      north: 52.4,
      east: 21.3,
    );

    test('a point inside is nought metres outside', () {
      expect(warsawArea.metresOutside(52.2, 21.0), 0);
    });

    test('a point due north is measured in metres, not degrees', () {
      // A tenth of a degree of latitude is about 11 km.
      expect(warsawArea.metresOutside(52.5, 21.0), closeTo(11054, 50));
    });

    test('a corner is measured diagonally, not along one axis', () {
      final diagonal = warsawArea.metresOutside(52.5, 21.4);
      final due = warsawArea.metresOutside(52.5, 21.0);

      expect(
        diagonal,
        greaterThan(due),
        reason: 'a point past two edges is further away than one past one',
      );
    });

    test('inflating grows the rectangle by the metres asked for', () {
      final grown = warsawArea.inflated(1000);

      expect(grown.contains(52.4, 21.0), isTrue);
      expect(
        grown.metresOutside(52.4 + 1000 / 110540 - 0.0001, 21.0),
        0,
        reason: 'a kilometre north of the old edge is now inside',
      );
    });
  });
}
