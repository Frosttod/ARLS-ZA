/// Reading a PMTiles file's own description of itself (§16.6).
///
/// The catalogue's bounds are a guess maintained by hand, good enough to
/// preselect a region in the picker. The bounds that decide whether the player
/// has left the map have to come from the file, because that is the only
/// description that cannot drift out of date — and because the extract a player
/// downloaded may not be the extract the catalogue was written against.
///
/// Only the fixed 127-byte v3 header is parsed. The directories, the metadata
/// and the tiles themselves are the renderer's business; everything the game
/// needs to know — where this map covers, and at what zoom — is in the header,
/// which means one short read rather than opening a 235 MB file.
///
/// Layout: https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md
library;

import 'dart:typed_data';

import 'region_pack.dart';

/// The fixed part of a PMTiles v3 file.
const int kPmtilesHeaderBytes = 127;

/// What kind of tiles a pack holds.
enum TileKind {
  unknown,

  /// Mapbox Vector Tiles. What Planetiler and Protomaps both produce, and what
  /// the map style expects.
  mvt,

  png,
  jpeg,
  webp,
  avif,
}

/// A pack's own description of itself.
class PmtilesHeader {
  const PmtilesHeader({
    required this.specVersion,
    required this.tileKind,
    required this.minZoom,
    required this.maxZoom,
    required this.bounds,
    required this.centre,
    required this.centreZoom,
    required this.tileCount,
  });

  final int specVersion;
  final TileKind tileKind;
  final int minZoom;
  final int maxZoom;

  /// The area this pack actually covers. Authoritative: `PackCoverage` is built
  /// from this, not from the catalogue.
  final GeoBounds bounds;

  final ({double latitude, double longitude}) centre;
  final int centreZoom;

  /// Distinct tiles in the file. Reported by the developer overlay, where an
  /// implausible number is the first sign of a truncated extract.
  final int tileCount;

  /// Whether this pack is something the game can render.
  ///
  /// A raster pack would display, but none of the styling, labelling or
  /// night-mode work of §3.6 applies to it, so it is refused rather than shown
  /// broken.
  bool get isUsable => specVersion == 3 && tileKind == TileKind.mvt;
}

/// Thrown when the bytes are not a PMTiles v3 header.
class PmtilesFormatException implements Exception {
  const PmtilesFormatException(this.message);

  final String message;

  @override
  String toString() => 'PmtilesFormatException: $message';
}

/// Parses the first [kPmtilesHeaderBytes] of a PMTiles file.
///
/// Everything in the header is little-endian, and the coordinates are integers
/// scaled by ten million — a hundredth of a millimetre, which is a great deal
/// more precision than a bounding box has any business carrying.
PmtilesHeader readPmtilesHeader(Uint8List bytes) {
  if (bytes.length < kPmtilesHeaderBytes) {
    throw PmtilesFormatException(
      'header is ${bytes.length} bytes, expected at least '
      '$kPmtilesHeaderBytes',
    );
  }

  const magic = 'PMTiles';
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic.codeUnitAt(i)) {
      throw const PmtilesFormatException('not a PMTiles file');
    }
  }

  final data = ByteData.sublistView(bytes, 0, kPmtilesHeaderBytes);
  final specVersion = data.getUint8(7);
  if (specVersion != 3) {
    // Version 2 exists in the wild and has a different layout. Reading it as
    // v3 would produce a plausible-looking rectangle in the wrong place.
    throw PmtilesFormatException('PMTiles spec version $specVersion, need 3');
  }

  double degrees(int offset) =>
      data.getInt32(offset, Endian.little) / 10000000.0;

  return PmtilesHeader(
    specVersion: specVersion,
    tileKind: _tileKind(data.getUint8(99)),
    minZoom: data.getUint8(100),
    maxZoom: data.getUint8(101),
    bounds: GeoBounds(
      west: degrees(102),
      south: degrees(106),
      east: degrees(110),
      north: degrees(114),
    ),
    centreZoom: data.getUint8(118),
    centre: (latitude: degrees(123), longitude: degrees(119)),
    tileCount: data.getUint64(88, Endian.little),
  );
}

TileKind _tileKind(int value) => switch (value) {
  1 => TileKind.mvt,
  2 => TileKind.png,
  3 => TileKind.jpeg,
  4 => TileKind.webp,
  5 => TileKind.avif,
  _ => TileKind.unknown,
};
