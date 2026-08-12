/// Where the tiles come from (§3.1, §16.6).
///
/// PMTiles is a single file addressed by byte range, which means the same
/// archive works two ways with no second pipeline:
///
/// * **Installed.** The file is on the device and the game needs no network at
///   all. This is what §1.2 wants and what a walk in a forest requires.
/// * **Streamed.** The file stays on the static host and MapLibre fetches only
///   the ranges for the tiles on screen. A player can start in the time it
///   takes to grant a permission, instead of waiting for 235 MB.
///
/// The trade-off is not battery or bandwidth, and it should not be sold as
/// such. **Streaming tells whoever hosts the file roughly where the player
/// is** — a tile request is a coordinate. The rest of the game keeps its
/// promise that nothing leaves the device; the map, while streamed, does not.
/// That is a sentence the player has to read before choosing, not a footnote.
library;

/// A place MapLibre can read tiles from.
sealed class MapSource {
  const MapSource();

  /// The `pmtiles://` URL for this source.
  String get url;

  /// Whether using it costs network traffic and reveals the player's area.
  bool get needsNetwork;
}

/// A verified pack on this device.
class InstalledPack extends MapSource {
  const InstalledPack(this.path);

  final String path;

  @override
  String get url {
    final normalised = path.replaceAll(r'\', '/');
    final rooted = normalised.startsWith('/') ? normalised : '/$normalised';
    return 'pmtiles://file://$rooted';
  }

  @override
  bool get needsNetwork => false;
}

/// The same archive, left on the host and read by byte range.
class StreamedPack extends MapSource {
  const StreamedPack(this.href);

  /// An ordinary https URL to the `.pmtiles` file. The host must answer range
  /// requests with 206; a host that ignores `Range` would make MapLibre pull
  /// the whole archive for every tile.
  final String href;

  @override
  String get url => 'pmtiles://$href';

  @override
  bool get needsNetwork => true;
}
