import 'dart:convert';

import 'package:arls_za/map/map_source.dart';
import 'package:arls_za/map/map_style.dart';
import 'package:test/test.dart';

/// §1.2 and §3.1. The map has to draw in a forest with the radio off. A style
/// that reaches for a sprite sheet or a font server works perfectly on a desk
/// and fails in the only place that matters.
void main() {
  const packPath =
      '/data/user/0/com.raidodevelopment.arlsza/files/'
      'maps/wielkopolskie.pmtiles';

  Map<String, Object?> style() =>
      mapStyle(source: const InstalledPack(packPath));

  group('offline, without exception', () {
    test('an installed pack names no network host at all', () {
      // Walks the whole structure rather than checking the fields we happen to
      // remember. A sprite or glyphs URL added later has to fail this.
      final found = <String>[];

      void walk(Object? node) {
        switch (node) {
          case String value when value.contains('http'):
            found.add(value);
          case Map<Object?, Object?> map:
            map.values.forEach(walk);
          case List<Object?> list:
            list.forEach(walk);
        }
      }

      walk(style());
      expect(found, isEmpty, reason: 'the game has no servers');
    });

    test('a streamed pack names exactly one, and it is the tiles', () {
      // Streaming is a choice the player makes (§16.6). What must never creep
      // in is a second address — a sprite sheet or a font server — because
      // those fail in a forest whether or not the tiles are local.
      final found = <String>[];
      void walk(Object? node) {
        switch (node) {
          case String value when value.contains('http'):
            found.add(value);
          case Map<Object?, Object?> map:
            map.values.forEach(walk);
          case List<Object?> list:
            list.forEach(walk);
        }
      }

      walk(
        mapStyle(
          source: const StreamedPack(
            'https://example.invalid/maps/wielkopolskie.pmtiles',
          ),
        ),
      );

      expect(found, [
        'pmtiles://https://example.invalid/maps/wielkopolskie.pmtiles',
      ]);
    });

    test('no glyphs and no sprite, so no font stack to ship', () {
      expect(style().containsKey('glyphs'), isFalse);
      expect(style().containsKey('sprite'), isFalse);
    });

    test('no layer draws text, which is what would need the glyphs', () {
      final layers = style()['layers']! as List<Object?>;

      for (final layer in layers) {
        final type = (layer! as Map<String, Object?>)['type'];
        expect(type, isNot('symbol'), reason: '$layer');
      }
    });
  });

  group('the source', () {
    test('points at the installed pack through the pmtiles protocol', () {
      final sources = style()['sources']! as Map<String, Object?>;
      final source = sources['openmaptiles']! as Map<String, Object?>;

      expect(source['type'], 'vector');
      expect(source['url'], 'pmtiles://file://$packPath');
    });

    test('a Windows path is turned into a URL, not pasted into one', () {
      // The developer build runs on a desktop often enough for this to matter.
      expect(
        const InstalledPack(r'C:\Users\przem\packs\wielkopolskie.pmtiles').url,
        'pmtiles://file:///C:/Users/przem/packs/wielkopolskie.pmtiles',
      );
    });

    test('a streamed pack keeps its https url intact', () {
      const href = 'https://example.invalid/maps/wielkopolskie.pmtiles';

      expect(const StreamedPack(href).url, 'pmtiles://$href');
      expect(const StreamedPack(href).needsNetwork, isTrue);
      expect(const InstalledPack('/x.pmtiles').needsNetwork, isFalse);
    });

    test('every layer draws from that one source', () {
      final layers = style()['layers']! as List<Object?>;

      for (final entry in layers) {
        final layer = entry! as Map<String, Object?>;
        if (layer['type'] == 'background') continue;
        expect(layer['source'], 'openmaptiles', reason: '${layer['id']}');
      }
    });
  });

  group('the two palettes (§12)', () {
    Map<String, Object?> layer(String id, MapPalette palette) =>
        (mapStyle(
                  source: const InstalledPack(packPath),
                  palette: palette,
                )['layers']!
                as List<Object?>)
            .cast<Map<String, Object?>>()
            .firstWhere((l) => l['id'] == id);

    /// Rough luminance of a `#rrggbb` string, 0 to 1.
    double luminance(String hex) {
      final value = int.parse(hex.substring(1), radix: 16);
      final r = (value >> 16) & 0xFF;
      final g = (value >> 8) & 0xFF;
      final b = value & 0xFF;
      return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
    }

    String colourOf(String id, MapPalette palette, String key) =>
        (layer(id, palette)['paint']! as Map<String, Object?>)[key]! as String;

    test('dark is dark and light is light', () {
      expect(luminance(MapPalette.dark.background), lessThan(0.2));
      expect(
        luminance(MapPalette.light.background),
        greaterThan(0.8),
        reason: 'a black map under a bright sky cannot be read at all',
      );
    });

    test('roads carry more contrast than anything else on the map', () {
      // The one thing that has to be legible at arm's length while walking is
      // where the streets go — so whatever else is on the map, the roads stand
      // furthest from the ground.
      //
      // ⚠️ This used to say *which direction*: light roads on the dark map,
      // dark roads on the light one. That was true of the old light palette
      // and is false of this one. Voyager puts **white streets on a warm
      // ground**, which is the whole reason it reads as a street plan at any
      // size, and the direction was never the rule — the ranking is.
      for (final palette in [MapPalette.dark, MapPalette.light]) {
        final ground = luminance(palette.background);
        final road = luminance(colourOf('road-major', palette, 'line-color'));

        // ⚠️ Against what a street runs *between*, not against water. A blue
        // area is nobody's idea of a street, so it is free to carry real
        // colour — in this palette it carries more than the roads do, and
        // that is right rather than a fault.
        for (final other in [palette.building, palette.green]) {
          expect(
            (road - ground).abs(),
            greaterThan((luminance(other) - ground).abs()),
            reason: 'roads must read before $other does, in $palette',
          );
        }
      }
    });

    test('major roads outrank minor ones in both', () {
      for (final palette in [MapPalette.dark, MapPalette.light]) {
        final major = luminance(colourOf('road-major', palette, 'line-color'));
        final minor = luminance(colourOf('road-minor', palette, 'line-color'));
        final ground = luminance(palette.background);

        expect(
          (major - ground).abs(),
          greaterThan((minor - ground).abs()),
          reason: 'a trunk road has to read before a service road does',
        );
      }
    });

    test('buildings sit close to the ground, not against it', () {
      // A city block of high-contrast outlines reads as a wall of shapes.
      for (final palette in [MapPalette.dark, MapPalette.light]) {
        expect(
          (luminance(palette.building) - luminance(palette.background)).abs(),
          lessThan(0.15),
          reason: '$palette',
        );
      }
    });

    test('the palette reaches every layer that has a colour', () {
      final dark = mapStyle(
        source: const InstalledPack(packPath),
        palette: MapPalette.dark,
      );
      final light = mapStyle(
        source: const InstalledPack(packPath),
        palette: MapPalette.light,
      );

      expect(
        dark.toString(),
        isNot(light.toString()),
        reason: 'a palette that changes nothing is a palette nobody applied',
      );
    });
  });

  group('what is drawn', () {
    List<String> layerIds() => [
      for (final layer in style()['layers']! as List<Object?>)
        (layer! as Map<String, Object?>)['id']! as String,
    ];

    test('the things a player navigates by are all present', () {
      expect(
        layerIds(),
        containsAll(<String>[
          'background',
          'water',
          'building',
          'road-minor',
          'road-major',
          'railway',
        ]),
      );
    });

    test('major roads are drawn over minor ones', () {
      // Draw order is list order. A trunk road buried under a service road is
      // exactly the wrong way round for a map read at arm's length.
      final ids = layerIds();
      expect(ids.indexOf('road-major'), greaterThan(ids.indexOf('road-minor')));
    });

    test('buildings only appear once they mean something', () {
      final layers = style()['layers']! as List<Object?>;
      final building = layers.cast<Map<String, Object?>>().firstWhere(
        (layer) => layer['id'] == 'building',
      );

      expect(
        building['minzoom'],
        greaterThanOrEqualTo(13),
        reason: 'a city of building outlines at district zoom is a grey smear',
      );
    });

    test('the style survives a round trip through JSON', () {
      // It is handed to the platform as a string, so anything unencodable here
      // becomes a blank map on a phone rather than an error in a test.
      final encoded = mapStyleJson(source: const InstalledPack(packPath));

      expect(jsonDecode(encoded), style());
    });
  });
}
