import 'dart:convert';

import 'package:arls_za/map/map_style.dart';
import 'package:test/test.dart';

/// §1.2 and §3.1. The map has to draw in a forest with the radio off. A style
/// that reaches for a sprite sheet or a font server works perfectly on a desk
/// and fails in the only place that matters.
void main() {
  const packPath =
      '/data/user/0/com.raidodevelopment.arlsza/files/'
      'maps/wielkopolskie.pmtiles';

  Map<String, Object?> style() => mapStyle(packPath: packPath);

  group('offline, without exception', () {
    test('no part of the style names a network host', () {
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
        pmtilesUrl(r'C:\Users\przem\packs\wielkopolskie.pmtiles'),
        'pmtiles://file:///C:/Users/przem/packs/wielkopolskie.pmtiles',
      );
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
      final encoded = mapStyleJson(packPath: packPath);

      expect(jsonDecode(encoded), style());
    });
  });
}
