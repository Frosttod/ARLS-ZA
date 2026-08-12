/// Everything the region screen needs, in one place (§16.6).
///
/// Ties the bundled catalogue to the packs on disk, the free space to the
/// download, and the installed pack's own header to the coverage test. Kept out
/// of the widgets so the sequence — read catalogue, see what is installed, ask
/// what it covers — is testable without pumping a UI.
library;

import 'dart:io';

import 'free_space.dart';
import 'map_source.dart';
import 'pack_coverage.dart';
import 'pack_store.dart';
import 'pmtiles_header.dart';
import 'region_pack.dart';

/// A region as the picker needs to show it.
class RegionStatus {
  const RegionStatus({
    required this.pack,
    required this.installed,
    this.header,
  });

  final RegionPack pack;
  final bool installed;

  /// The installed file's own description, when there is one.
  final PmtilesHeader? header;

  /// Whether this pack can be offered at all. A region published without a
  /// checksum is refused by the store, so offering it would be a button that
  /// cannot work (§16.6).
  bool get downloadable => pack.sha256.isNotEmpty;

  /// True when the file is here but is not something the style can draw.
  bool get unusable => installed && header != null && !header!.isUsable;

  /// Whether the archive can be read over the network instead of installed
  /// (§16.6). Every published pack can: PMTiles is addressed by byte range, so
  /// the same file serves both ways.
  bool get streamable => downloadable && pack.url.startsWith('http');
}

class PackManager {
  PackManager({
    required this.catalogue,
    required this.store,
    this.freeSpace = const PlatformFreeSpace(),
  });

  final RegionCatalogue catalogue;
  final PackStore store;
  final FreeSpace freeSpace;

  Directory get directory => store.directory;

  /// Every region, with what is known about it on this device.
  Future<List<RegionStatus>> statuses() async {
    final installed = await store.installedIds();

    return [
      for (final pack in catalogue.packs)
        RegionStatus(
          pack: pack,
          installed: installed.contains(pack.id),
          header: installed.contains(pack.id)
              ? await _headerOrNull(pack)
              : null,
        ),
    ];
  }

  /// The pack the game should be using, or null on a first run.
  ///
  /// When more than one is installed — a player who has travelled and kept both
  /// — the one containing [near] wins, because that is the map under their
  /// feet.
  Future<RegionStatus?> activePack({
    double? nearLatitude,
    double? nearLongitude,
  }) async {
    final all = await statuses();
    final present = all.where((status) => status.installed).toList();
    if (present.isEmpty) return null;

    if (nearLatitude != null && nearLongitude != null) {
      for (final status in present) {
        final bounds = status.header?.bounds ?? status.pack.bounds;
        if (bounds.contains(nearLatitude, nearLongitude)) return status;
      }
    }
    return present.first;
  }

  /// Coverage for an installed pack, built from the file's own extent (§16.6).
  ///
  /// Falls back to the catalogue's guess only when the header could not be
  /// read, and says so by returning a coverage with no bounds when there is no
  /// pack at all.
  PackCoverage coverageFor(RegionStatus? status) =>
      PackCoverage(bounds: status?.header?.bounds ?? status?.pack.bounds);

  /// Downloads and verifies [pack].
  ///
  /// The free-space check happens here rather than in the store, because "the
  /// platform would not say" is a policy question: an unknown amount is treated
  /// as enough, since refusing a download over a failed measurement is worse
  /// than attempting one that might not fit.
  Future<InstallOutcome> install(
    RegionPack pack, {
    void Function(InstallProgress)? onProgress,
    Future<bool> Function()? isCancelled,
  }) async {
    if (pack.sha256.isEmpty) return InstallOutcome.corrupted;

    if (!store.directory.existsSync()) {
      await store.directory.create(recursive: true);
    }

    final free = await freeSpace.bytesAt(store.directory);

    return store.install(
      pack,
      freeBytes: free ?? _unlimited,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  Future<void> delete(RegionPack pack) => store.delete(pack);

  /// Where the map should read tiles from for [status].
  ///
  /// An installed pack always wins: it is faster, it costs no traffic, and it
  /// tells nobody where the player is. Streaming is the fallback that lets
  /// somebody start playing in the time it takes to grant a permission rather
  /// than the time it takes to download a voivodeship.
  MapSource? sourceFor(RegionStatus? status) {
    if (status == null) return null;
    if (status.installed && !status.unusable) {
      return InstalledPack(store.fileFor(status.pack).path);
    }
    if (status.streamable) return StreamedPack(status.pack.url);
    return null;
  }

  Future<PmtilesHeader?> _headerOrNull(RegionPack pack) async {
    try {
      return await store.headerFor(pack);
    } on PmtilesFormatException {
      // A file that is not a pack: an interrupted rename, or an old build's
      // leftovers. Reported as installed-but-unusable rather than crashing the
      // screen that would let the player delete it.
      return null;
    }
  }
}

/// Stands in for a free-space answer the platform would not give.
const int _unlimited = 1 << 62;
