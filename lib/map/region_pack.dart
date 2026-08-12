/// Offline map packs (design doc §3.1, §16.6).
///
/// The game has no servers, so the map cannot be streamed. A player downloads
/// one PMTiles file for their region — 50 to 200 MB for a Polish voivodeship —
/// and everything after that works with the radio off.
///
/// §16.6 left this undesigned. The decisions taken here:
///
/// * **The catalogue is bundled, the packs are not.** The list of regions ships
///   with the app so the picker works before anything is downloaded; the files
///   themselves come from a static host.
/// * **Catalogue bounds are for the picker only.** The bounds that decide
///   whether the player has left the map come from the installed file's own
///   header, because that is the only description that cannot drift out of
///   date.
/// * **A pack is either verified or absent.** A half-written 200 MB file that
///   renders as grey squares is worse than no map, and much harder to explain.
library;

import 'dart:convert';
import 'dart:math' as math;

/// A rectangle of the world, in degrees.
class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  factory GeoBounds.fromJson(List<Object?> json) => GeoBounds(
    west: (json[0]! as num).toDouble(),
    south: (json[1]! as num).toDouble(),
    east: (json[2]! as num).toDouble(),
    north: (json[3]! as num).toDouble(),
  );

  final double south;
  final double west;
  final double north;
  final double east;

  bool contains(double latitude, double longitude) =>
      latitude >= south &&
      latitude <= north &&
      longitude >= west &&
      longitude <= east;

  /// The same rectangle grown by [metres] on every side.
  ///
  /// Used for the hysteresis around the edge: a player walking along the
  /// boundary must not be told they have left and come back every few seconds.
  GeoBounds inflated(double metres) {
    final dLat = metres / _metresPerDegreeLat;

    // Longitude degrees shrink towards the poles. Taking the latitude furthest
    // from the equator keeps the margin at least [metres] everywhere in the
    // rectangle.
    final worstLat = south.abs() > north.abs() ? south : north;
    final dLon = metres / _metresPerDegreeLon(worstLat);

    return GeoBounds(
      south: south - dLat,
      west: west - dLon,
      north: north + dLat,
      east: east + dLon,
    );
  }

  /// How far outside the rectangle a point is, in metres. Zero when inside.
  double metresOutside(double latitude, double longitude) {
    final northSouth = math.max(south - latitude, latitude - north);
    final eastWest = math.max(west - longitude, longitude - east);

    final dLat = math.max(northSouth, 0.0) * _metresPerDegreeLat;
    final dLon = math.max(eastWest, 0.0) * _metresPerDegreeLon(latitude);

    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  List<double> toJson() => [west, south, east, north];

  @override
  String toString() => 'GeoBounds($south, $west, $north, $east)';
}

/// Metres per degree of latitude. Constant enough for a bounding box.
const double _metresPerDegreeLat = 110540.0;

double _metresPerDegreeLon(double latitude) =>
    111320.0 * math.cos(latitude * math.pi / 180).abs();

/// One downloadable region.
class RegionPack {
  const RegionPack({
    required this.id,
    required this.name,
    required this.bounds,
    required this.bytes,
    required this.sha256,
    required this.url,
    this.streamable = false,
  });

  factory RegionPack.fromJson(
    Map<String, Object?> json, {
    String baseUrl = '',
    bool streamable = false,
  }) {
    final url = json['url']! as String;
    return RegionPack(
      id: json['id']! as String,
      name: json['name']! as String,
      bounds: GeoBounds.fromJson(json['bounds']! as List<Object?>),
      bytes: (json['bytes']! as num).toInt(),
      sha256: json['sha256']! as String,
      // Resolved here rather than at the point of use. Everything downstream —
      // the downloader, and the streamed map source of §16.6 — needs an
      // address it can use without also knowing about the catalogue.
      url: url.startsWith('http') ? url : '$baseUrl$url',
      streamable: json['streamable'] as bool? ?? streamable,
    );
  }

  /// Stable identifier. Also the file name, so a pack can be found on disk
  /// without consulting the catalogue.
  final String id;

  /// Shown in the picker, in the catalogue's own language. Region names are
  /// proper nouns and are not translated (§19.1.1).
  final String name;

  /// Roughly where the region is, for the picker and for suggesting a pack from
  /// the player's current position. Not authoritative — see the library note.
  final GeoBounds bounds;

  /// Download size. Shown before the download starts, and checked against the
  /// free space, because finding out at 180 MB is not a design.
  final int bytes;

  final String sha256;
  final String url;

  /// Whether this pack can be read over the network instead of installed
  /// (§16.6).
  ///
  /// Not a property of PMTiles — every archive is addressable by byte range —
  /// but of the host, which has to answer a `Range` request with 206
  /// **directly**.
  ///
  /// Measured, twice, because the first answer was a guess and the guess was
  /// confirmed the expensive way. A range request to a GitHub release asset
  /// without following redirects returns `302` and zero bytes; following it
  /// returns `206` and the bytes. MapLibre's tile source does not follow it per
  /// tile, and two runs on a phone drew a blank map. Offering the button anyway
  /// promises something the host cannot deliver.
  ///
  /// A per-region flag as well as a catalogue-wide default, so a city-sized
  /// pack on a direct host can stream while a voivodeship on Releases cannot.
  final bool streamable;

  /// Human-sized, for the picker.
  String get megabytes => (bytes / (1024 * 1024)).toStringAsFixed(0);

  String get fileName => '$id.pmtiles';
}

/// The bundled list of regions.
class RegionCatalogue {
  const RegionCatalogue(this.packs);

  factory RegionCatalogue.parse(String source) {
    final decoded = jsonDecode(source) as Map<String, Object?>;
    final baseUrl = decoded['baseUrl'] as String? ?? '';

    // A whole-catalogue default, because streaming is a property of where the
    // packs are hosted rather than of any one region.
    final streamable = decoded['streamable'] as bool? ?? false;
    final regions = decoded['regions']! as List<Object?>;
    return RegionCatalogue([
      for (final region in regions)
        RegionPack.fromJson(
          region! as Map<String, Object?>,
          baseUrl: baseUrl,
          streamable: streamable,
        ),
    ]);
  }

  final List<RegionPack> packs;

  RegionPack? byId(String id) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// The region a position falls in, if any.
  ///
  /// Used to preselect a pack on the first run. Bounding boxes overlap where
  /// regions interlock, so the smallest match wins — it is the more specific
  /// answer.
  RegionPack? forPosition(double latitude, double longitude) {
    RegionPack? best;
    for (final pack in packs) {
      if (!pack.bounds.contains(latitude, longitude)) continue;
      if (best == null || _area(pack.bounds) < _area(best.bounds)) {
        best = pack;
      }
    }
    return best;
  }

  static double _area(GeoBounds bounds) =>
      (bounds.north - bounds.south) * (bounds.east - bounds.west);
}
