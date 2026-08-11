import 'dart:convert';
import 'dart:typed_data';

import 'package:arls_za/map/pmtiles_header.dart';
import 'package:test/test.dart';

/// §16.6. The catalogue's bounds are maintained by hand and are only good
/// enough to preselect a region; these are the ones that decide whether the
/// player has walked off the map.
void main() {
  /// The real first 127 bytes of the Wielkopolskie pack, as Planetiler wrote
  /// it: OpenMapTiles schema, zoom 0–15, built 2026-08-11. A synthetic header
  /// would only prove that the parser agrees with the test's idea of the
  /// format.
  final wielkopolskie = base64Decode(
    'UE1UaWxlcwN/AAAAAAAAAH4AAAAAAAAAQzSyDgAAAAAZBQAAAAAAAFw5sg4AAAAAsHoCAAAAAAAA'
    'QAAAAAAAAEP0sQ4AAAAApVABAAAAAADVTAEAAAAAALBLAQAAAAAAAQICAQAPENdkCezNch6s5mYL'
    'BBT/Hwfe3mUK+PA4Hw==',
  );

  group('a real pack', () {
    late PmtilesHeader header;

    setUpAll(() => header = readPmtilesHeader(wielkopolskie));

    test('reports the extent it actually covers', () {
      // Wielkopolska. The catalogue's guess for this region is a slightly
      // larger rectangle, which is exactly why the file is asked instead.
      expect(header.bounds.west, closeTo(15.760, 0.001));
      expect(header.bounds.south, closeTo(51.084, 0.001));
      expect(header.bounds.east, closeTo(19.129, 0.001));
      expect(header.bounds.north, closeTo(53.681, 0.001));
    });

    test('reports the zoom range it was built with', () {
      expect(header.minZoom, 0);
      expect(
        header.maxZoom,
        15,
        reason: 'street level; a pack cut at 14 renders blank when zoomed in',
      );
    });

    test('is vector tiles, so the style applies to it', () {
      expect(header.tileKind, TileKind.mvt);
      expect(header.isUsable, isTrue);
    });

    test('the centre falls inside the extent', () {
      expect(
        header.bounds.contains(header.centre.latitude, header.centre.longitude),
        isTrue,
        reason: 'latitude and longitude read in the wrong order would not',
      );
      expect(header.centre.latitude, closeTo(52.38, 0.01));
      expect(header.centre.longitude, closeTo(17.44, 0.01));
    });

    test('carries a plausible tile count', () {
      expect(header.tileCount, greaterThan(10000));
    });
  });

  group('what is refused', () {
    test('a file that is not PMTiles at all', () {
      final notATile = Uint8List(kPmtilesHeaderBytes)
        ..setAll(0, utf8.encode('<!DOCTYPE html>'));

      expect(
        () => readPmtilesHeader(notATile),
        throwsA(isA<PmtilesFormatException>()),
        reason: 'a captive portal answering the download with a login page',
      );
    });

    test('a truncated header', () {
      expect(
        () => readPmtilesHeader(wielkopolskie.sublist(0, 64)),
        throwsA(isA<PmtilesFormatException>()),
      );
    });

    test('an older spec version, rather than misreading it', () {
      final v2 = Uint8List.fromList(wielkopolskie)..[7] = 2;

      // v2 has a different layout. Read as v3 it would produce a
      // plausible-looking rectangle somewhere else entirely.
      expect(
        () => readPmtilesHeader(v2),
        throwsA(isA<PmtilesFormatException>()),
      );
    });

    test('raster tiles, which the style cannot work with', () {
      final png = Uint8List.fromList(wielkopolskie)..[99] = 2;

      final header = readPmtilesHeader(png);
      expect(header.tileKind, TileKind.png);
      expect(
        header.isUsable,
        isFalse,
        reason: 'it would draw, but none of §3.6 would apply to it',
      );
    });
  });
}
